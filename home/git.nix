{ ... }: {

  programs.git = {
    enable = true;
    settings = {
      user.name        = "nimjit";
      user.email       = "tidemanus@gmail.com";
      init.defaultBranch = "main";
      pull.rebase      = false;
      credential.helper = "store";
    };
  };
}
