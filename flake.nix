{
  description = "Homelab development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/a1bab9e494f5f4939442a57a58d0449a109593fe";

    nur = {
      url = "github:MacroPower/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    talhelper = {
      url = "github:budimanjojo/talhelper/0574f072ee800297268dc77d9a6c4a8ceac9695a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nur, talhelper }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nurPkgs = nur.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.argocd
              pkgs.auth0-cli
              pkgs.cilium-cli
              pkgs.natscli
              pkgs.spacectl
              pkgs.talosctl
              pkgs.wrangler

              nurPkgs.kat
              nurPkgs.kclipper
              nurPkgs.kcl-lsp
              talhelper.packages.${system}.default
            ];

            env = {
              KCL_LIB_HOME = ".nix/kcl/lib";
              KCL_PKG_PATH = ".nix/kcl/kpm";
              KCL_CACHE_PATH = ".nix/kcl/cache";
            };

            shellHook = ''
              mkdir -p "$KCL_LIB_HOME" "$KCL_PKG_PATH" "$KCL_CACHE_PATH"
            '';
          };
        });
    };
}
