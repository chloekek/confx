{clangStdenv, ats2}:
clangStdenv.mkDerivation {
    name = "confx";
    src = ./.;
    buildInputs = [ats2];
    phases = ["unpackPhase" "buildPhase" "installPhase" "fixupPhase"];
    buildPhase = ''
        patscc_flags=(
            -ccats
        )

        clang_compile_flags=(
            -O2 -flto=thin
            -I$PATSHOME
            -I$PATSHOME/ccomp/runtime
            -DATS_MEMALLOC_LIBC
        )

        clang_link_flags=(
            -O2 -flto=thin
        )

        objects=()

        for module in main value; do
            patscc "''${patscc_flags[@]}" $module.dats
            clang "''${clang_compile_flags[@]}" -c ''${module}_dats.c
            objects+=(''${module}_dats.o)
        done

        clang "''${clang_link_flags[@]}" -o confx "''${objects[@]}"
    '';
    installPhase = ''
        mkdir --parents $out/bin
        mv confx $out/bin
    '';
}
