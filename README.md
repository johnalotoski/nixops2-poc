* A simple poc for testing an old version of nixops (IOHK custom, plugins, pre 2.0) and nixops 2.0
* Copy file `envrc` to `.envrc` if you use direnv and lorri, then `direnv allow`
* After entering the nix-shell, you should have both a `nixops` and `nixops2` command available to experiment with
* PYTHONPATH is unset so they will run side-by-side in the same shell
