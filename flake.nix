{
  description = "Box3D Roblox development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = system: import nixpkgs { inherit system; };

      spiderCliFor = pkgs:
        pkgs.writeShellApplication {
          name = "spider-cli";
          runtimeInputs = with pkgs; [ cargo git ];
          text = ''
            root="''${SPIDER_INSTALL_ROOT:-$PWD/.direnv/spider}"
            bin="$root/bin/spider-cli"

            if [ ! -x "$bin" ]; then
              mkdir -p "$root"
              cargo install \
                --git "https://github.com/SovereignSatellite/Spider" \
                --branch trunk \
                --root "$root" \
                spider-cli
            fi

            exec "$bin" "$@"
          '';
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          spider-cli = spiderCliFor pkgs;
        in
        {
          default = spider-cli;
          spider-cli = spider-cli;
        });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          spider-cli = spiderCliFor pkgs;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              cmake
              emscripten
              git
              ninja
              nodejs
              pkg-config
              rustc
              spider-cli
              stdenv.cc
              wabt
            ];

            shellHook = ''
              export PATH="$PWD/.direnv/spider/bin:$PATH"
              echo "Box3D dev shell"
              echo "Spider CLI: $(command -v spider-cli)"
            '';
          };
        });
    };
}
