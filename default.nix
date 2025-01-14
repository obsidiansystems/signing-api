{ kpkgs ? import ./dep/kpkgs {}}:
let
  nix-thunk-src = (kpkgs.pkgs.fetchFromGitHub {
    owner = "obsidiansystems";
    repo = "nix-thunk";
    rev = "bab7329163fce579eaa9cfba67a4851ab806b76f";
    sha256 = "0wn96xn6prjzcsh4n8p1n40wi8la53ym5h2frlqbfzas7isxwygg";
  });
  inherit (import nix-thunk-src {}) thunkSource;

  pactSrc = thunkSource ./dep/pact ;

  signingProject = kpkgs.rp.project ({ pkgs, hackGet, ... }: with pkgs.haskell.lib; {
    name = "kadena-signing-api";
    overrides = self: super: {
      pact = dontCheck (addBuildDepend (self.callCabal2nix "pact" pactSrc {}) pkgs.z3);
      pact-time = dontCheck (self.callHackageDirect {
        pkg = "pact-time";
        ver = "0.2.0.0";
        sha256 = "1cfn74j6dr4279bil9k0n1wff074sdlz6g1haqyyy38wm5mdd7mr";
      } {});
      direct-sqlite = dontCheck (self.callHackageDirect {
        pkg = "direct-sqlite";
        ver = "2.3.26";
        sha256 = "1kdkisj534nv5r0m3gmxy2iqgsn6y1dd881x77a87ynkx1glxfva";
      } {});
    };

    packages = {
      kadena-signing-api = kpkgs.gitignoreSource ./kadena-signing-api;
      kadena-signing-api-docs = kpkgs.gitignoreSource ./kadena-signing-api-docs;
    };

    shellToolOverrides = ghc: super: {
      cabal-install = pkgs.haskellPackages.cabal-install;
      ghcid = pkgs.haskellPackages.ghcid;
      spectacle = pkgs.spectacle;
    };

    shells = {
      ghc = ["kadena-signing-api" "kadena-signing-api-docs"];
    };
  });
in
  {
    inherit signingProject;
    kadena-signing-api = signingProject.ghc.kadena-signing-api;
    kadena-signing-api-docs = signingProject.ghc.kadena-signing-api-docs;
  }
