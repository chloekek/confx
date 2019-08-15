dynload "value.dats"

staload value = "value.sats"

implement main0() =
  let
    val undef = $value.create_undef()
    val ()    = $value.destroy_undef(undef)
    val ()    = $value.drop(undef)
  in
    ()
  end
