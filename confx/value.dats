#include "share/atspre_staload.hats"

staload "value.sats"

/// Every value begins with a header. The header contains the reference count and
/// the tag of the value. The layout of the header is the same regardless of the
/// value, allowing it to be used to introduce proofs at runtime.
typedef Header(n : int, t : Tag) =
  @{ ref_count = size_t(n)
   , tag       = Tag(t) }

/// The payload of a value follows the header of the value. The payload contains
/// the actual data inside a value. What the payload looks like depends on the
/// tag of the value.
dataview Payload(l : addr, t : Tag) =

  /// UNDEF values contain no information, so they don’t have any @-views.
  | {l : agz}
    Undef(l, UNDEF)

  /// An INT value contains merely an integer. We choose a long long integer,
  /// since it has a large range.
  | {l : agz}
    Int(l, INT) of
    llint @ l

  /// A STRING value directly contains the string data; there are no extra
  /// indirections.
  | {l : agz} {n : nat}
    String(l, STRING) of
    @{ length_pf = size_t(n)  @ l
     , data_pf   = @[char][n] @ l + sizeof(size_t)
     , null_pf   = char(0)    @ l + sizeof(size_t) + n }

/// When the reference count is positive, a value is a header followed by a
/// payload. Otherwise, there is nothing at the address.
dataview Value(addr, int, Tag) =

  // FIXME: Hardcoding 16 here for the payload offset is not a good idea.
  | {l : agz} {n : pos} {t : Tag}
    Alive(l, n, t) of
    @{ alloc_pf   = mfree_gc_v(l)
     , header_pf  = Header(n, t) @ l
     , payload_pf = Payload(l + 16, t) }

  | {l : addr} {t : Tag}
    Dead(l, 0, t)

/// A ref is just a pointer to a value. Note that the reference count is in the
/// value, not in the pointer.
assume Ref(n, t) =
  [l : agz]
  ( Value(l, n, t)
  | ptr(l) )

implement create_undef() =
  let
    val      (header_pf, alloc_pf | value_ptr)  = ptr_alloc<Header(1, UNDEF)>()
    prval    value_pf                           = @{ alloc_pf   = alloc_pf
                                                   , header_pf  = header_pf
                                                   , payload_pf = Undef() }
    val () = value_ptr->ref_count              := i2sz(1)
    val () = value_ptr->tag                    := UNDEF()
  in
    (Alive(value_pf) | value_ptr)
  end

implement destroy_undef(ref) =
  let
    prval      Alive(value_pf)  = ref.0
    prval      alloc_pf         = value_pf.alloc_pf
    prval      header_pf        = value_pf.header_pf
    prval      Undef()          = value_pf.payload_pf
    val        ()               = ptr_free(alloc_pf, header_pf | ref.1)
    prval () = ref.0           := Dead()
  in
    ()
  end

implement destroy(ref) =
  case+ tag(ref) of
  | UNDEF()  => destroy_undef  (ref)
  | INT()    => destroy_int    (ref)
  | STRING() => destroy_string (ref)

implement drop(ref) =
  let
    prval Dead() = ref.0
  in
    ()
  end

implement tag(ref) =
  let
    prval      Alive(value_pf)     = ref.0
    prval      header_pf           = value_pf.header_pf
    val        tag                 = ref.1->tag
    prval () = value_pf.header_pf := header_pf
    prval () = ref.0              := Alive(value_pf)
  in
    tag
  end

implement ref_count(ref) =
  let
    prval      Alive(value_pf)     = ref.0
    prval      header_pf           = value_pf.header_pf
    val        ref_count           = ref.1->ref_count
    prval () = value_pf.header_pf := header_pf
    prval () = ref.0              := Alive(value_pf)
  in
    ref_count
  end

implement inc_ref(ref) =
  let
    prval      Alive(value_pf)     = ref.0
    prval      header_pf           = value_pf.header_pf
    val   () = ref.1->ref_count   := succ(ref.1->ref_count)
    prval () = value_pf.header_pf := header_pf
    prval () = ref.0              := Alive(value_pf)
  in
    ()
  end

implement dec_ref(ref) =
  if ref_count(ref) = 1 then
    destroy(ref)
  else
    dec_ref_keep_alive(ref)

implement dec_ref_keep_alive(ref) =
  let
    prval      Alive(value_pf)     = ref.0
    prval      header_pf           = value_pf.header_pf
    val        new_ref_count       = pred(ref.1->ref_count)
    val   () = ref.1->ref_count   := new_ref_count
    prval () = value_pf.header_pf := header_pf
    prval () = ref.0              := Alive(value_pf)
  in
    ()
  end
