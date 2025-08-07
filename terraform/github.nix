{ config, ... }: {
  imports = [
    ./sops.nix
  ];

  terraform = {
    required_providers = {
      github = {
        source = "integrations/github";
      };
    };
  };

  provider = {
    github = {
      token = config.data.sops_file.secrets "data[\"github.token\"]";
    };
  };

  resource = {
    github_repository.ob-progv = {
      name = "ob-progv.el";
      description = "Emacs package that allows org-babel header arguments to bind Elisp variables.";
      visibility = "public";
    };
  };
}
