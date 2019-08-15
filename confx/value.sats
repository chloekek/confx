/// The tag of a value determines what kind of value it is. The tag is reified at
/// runtime, a feature known as dynamic typing.
datasort Tag =
  | UNDEF
  | INT
  | STRING

/// Runtime-reification of the Tag sort. Note the absence of the “of” keyword:
/// the names between the parentheses are indices, not fields. The runtime
/// representation of this data type is an int, since all data constructors don’t
/// have any fields.
datatype Tag(t : Tag) =
  | UNDEF  (UNDEF)
  | INT    (INT)
  | STRING (STRING)

/// A ref is a pointer to a value. The value is reference-counted.
///
/// You must manually increment and decrement the reference count using the
/// inc_ref and dec_ref functions respectively, but the ATS type checker will
/// verify that you do so correctly, with no use-after-free errors or memory
/// leaks.
///
/// A ref can only be dereferenced if its reference count is at least one, and
/// this too is verified by the ATS type checker.
absviewtype Ref(int, Tag) =
  ptr

/// Create or destroy an UNDEF value.
fun create_undef() : Ref(1, UNDEF)
fun destroy_undef{u : Tag}(!Ref(1, UNDEF) >> Ref(0, u)) :<> void

/// Create or destroy an INT value.
fun create_int(n : llint) : Ref(1, INT)
fun destroy_int{u : Tag}(!Ref(1, INT) >> Ref(0, u)) :<> void

/// Create or destroy a STRING value.
// TODO: String creation routines.
fun destroy_string{u : Tag}(!Ref(1, STRING) >> Ref(0, u)) :<> void

/// Destroy a value, freeing the resources it occupies.
///
/// Since no other references to the same value may exist, the reference count
/// must be exactly one. After the call, the reference count will be zero.
fun destroy
  {t : Tag} {u : Tag}
  (!Ref(1, t) >> Ref(0, u))
  :<> void

/// There is nothing you can do with a value that has a reference count of zero,
/// so you can safely drop it. This is a no-op.
fun drop
  {t : Tag}
  (Ref(0, t))
  :<> void

/// Return the tag of a value.
///
/// Because this reads information from the value, the reference count cannot be
/// zero.
fun tag
  {n : pos} {t : Tag}
  (!Ref(n, t))
  :<> Tag(t)

/// Return the reference count of a value.
///
/// Because this reads information from the value, the reference count cannot be
/// zero.
fun ref_count
  {n : pos} {t : Tag}
  (!Ref(n, t))
  :<> size_t(n)

/// Increment the reference count of a value. This ensures that after dec_ref is
/// called once, the value is still alive.
///
/// Because this reads information from and writes information to the value, the
/// reference count cannot be zero.
fun inc_ref
  {n : pos} {t : Tag}
  (!Ref(n, t) >> Ref(n + 1, t))
  : void

/// Decrement the reference count of a value. This must be called once for every
/// call to create_* or inc_ref. Once the reference count reaches zero, the value
/// is destroyed.
///
/// Because this reads information from the value, the reference count cannot be
/// zero prior to calling this function.
fun dec_ref
  {n : pos} {t : Tag}
  (!Ref(n, t) >> Ref(n - 1, t))
  : void

/// Just like dec_ref, but it cannot reach zero. This is more efficient than
/// dec_ref, since it can omit the check for a zero reference count. The ATS type
/// checker verifies that the reference count will not drop to zero.
///
/// Because this reads information from and writes information to the value, the
/// reference count cannot be zero.
fun dec_ref_keep_alive
  {n : nat | n >= 2} {t : Tag}
  (!Ref(n, t) >> Ref(n - 1, t))
  : void
