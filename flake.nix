{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container.url = "github:nlewo/nix2container";
  };
  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: rec {
      hello = pkgs.runCommand "hello" { } ''
        ln -s ${pkgs.hello}/bin/hello $out
      '';
      image-json = inputs.nix2container.packages.${system}.nix2container.buildImage {
        name = "hello";
        config = {
          Entrypoint = [
            (toString hello)
          ];
        };
        maxLayers = 100;
      };
      ls-hello = pkgs.runCommand "ls-hello" { } ''
        ls -l ${hello} > $out
      '';
      nix218Vs221 = pkgs.writeShellScriptBin "nix-2.18-vs-nix-2.21" ''
        set -ex -o pipefail

        # Using nix-daemon 2.18
        sudo nixos-rebuild --flake github:Atry/nixos-wsl-vscode/c14940caefeb2a72f343ff571a381d1e77131a12#nixosWslVsCode switch

        NIX_2_18_HELLO_FILE="$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#hello)"
        NIX_2_18_IMAGE_JSON_TMP_FILE="$(${pkgs.coreutils}/bin/mktemp)"
        cat "$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#image-json)" > "$NIX_2_18_IMAGE_JSON_TMP_FILE"
        NIX_2_18_LS_HELLO_TMP_FILE="$(${pkgs.coreutils}/bin/mktemp)"
        cat "$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#ls-hello)" > "$NIX_2_18_LS_HELLO_TMP_FILE"

        ${pkgs.nix}/bin/nix-store --query --referrers-closure "$NIX_2_18_HELLO_FILE" | xargs nix-store --delete



        # Using nix-daemon 2.21
        sudo nixos-rebuild --flake github:Atry/nixos-wsl-vscode/9844d9ea867568dcea6bd3b5251e855a9202523e#nixosWslVsCode switch

        NIX_2_21_HELLO_FILE=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#hello)
        NIX_2_21_IMAGE_JSON_TMP_FILE="$(${pkgs.coreutils}/bin/mktemp)"
        cat "$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#image-json)" > "$NIX_2_21_IMAGE_JSON_TMP_FILE"
        NIX_2_21_LS_HELLO_TMP_FILE="$(${pkgs.coreutils}/bin/mktemp)"
        cat "$(${pkgs.nix}/bin/nix build --no-link --print-out-paths ${./.}#ls-hello)" > "$NIX_2_21_LS_HELLO_TMP_FILE"

        ${pkgs.nix}/bin/nix-store --query --referrers-closure "$NIX_2_18_HELLO_FILE" | xargs nix-store --delete

        ${pkgs.diffutils}/bin/diff "$NIX_2_18_IMAGE_JSON_TMP_FILE" "$NIX_2_21_IMAGE_JSON_TMP_FILE" & ${pkgs.diffutils}/bin/diff "$NIX_2_18_LS_HELLO_TMP_FILE" "$NIX_2_21_LS_HELLO_TMP_FILE"
      '';
    }) inputs.nixpkgs.legacyPackages;
  };
}
