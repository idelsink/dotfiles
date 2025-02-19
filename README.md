# dotfiles

My dotfiles managed by [chezmoi](https://www.chezmoi.io/).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Bootstrapping guide](#bootstrapping-guide)
- [SSH Keys `bin/provision-ssh-key.sh`](#ssh-keys-binprovision-ssh-keysh)
- [PGP subkeys `bin/provision-pgp-machine-key.sh`](#pgp-subkeys-binprovision-pgp-machine-keysh)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Bootstrapping guide

1.  Install [chezmoi](https://www.chezmoi.io/) on a new system.
2.  Download and initialize chezmoi.
    ```sh
    chezmoi init --apply git@github.com:idelsink/dotfiles.git
    ```

## SSH Keys `bin/provision-ssh-key.sh`

By default each machine will be provisioned by an ed25519 SSH key located in `~/.ssh/id_ed25519`.
When more keys are necessary, the [bin/provision-ssh-key.sh](bin/provision-ssh-key.sh) utility
script can be run. This can generate more keys and also add them to the keyring.

## PGP subkeys `bin/provision-pgp-machine-key.sh`

A machine can be provisioned with a pgp subkey for git commit signing. When confined,
the resulting gitconfig will also be checked for a potential missing User ID.
