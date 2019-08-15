let nixpkgs = import ./nix/nixpkgs.nix {}; in
{
    confx = nixpkgs.callPackage ./confx {};
}
