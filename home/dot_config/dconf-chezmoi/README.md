# Dconf Chezmoi

Dconf is a low-level configuration system (database) backend used by Gnome to store desktop environment settings.
The `dconf.ini` file contains the sections and keys that are monitored and backed up using chezmoi.
Its stored in the `keyfile` format, which is similar to an ini file. See <https://help.gnome.org/admin/system-admin-guide/stable/dconf-keyfiles.html.en>

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [chezmoi apply](#chezmoi-apply)
  - [1. Export the dconf settings into a readable file](#1-export-the-dconf-settings-into-a-readable-file)
  - [2. Let chezmoi handle the `dconf.ini` file](#2-let-chezmoi-handle-the-dconfini-file)
  - [3. Import the `dconf.ini` into dconf system database](#3-import-the-dconfini-into-dconf-system-database)
- [Why is the export a hook but the import a script?](#why-is-the-export-a-hook-but-the-import-a-script)
- [Automatic dconf backups](#automatic-dconf-backups)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## chezmoi apply

What we try to do here, is to export settings from dconf (a database) into a readable file (dconf.ini) that can be backed-up and synced to other machines using chezmoi.

For this we need to do the following:

### 1. Export the dconf settings into a readable file

The chezmoi hook (see `.chezmoi.toml.tmpl` file with hook `hooks.read-source-state.pre`) is ran to export the current dconf settings into the `dconf.ini` file located at the destination direcory (`~/.config/dconf-chezmoi/dconf.ini`)

This hook will look at the current `dconf.ini` file to determine in what keys we're interested in. We can just add more keys (and sections) over time by just adding them to the `dconf.ini`.

### 2. Let chezmoi handle the `dconf.ini` file

Now that the `dconf.ini` at the destination represents the current settings of the system (export of dconf) and the `dconf.ini` at the source represents the one backed-up, chezmoi can simply check if the files differ and let us know if any of the values, be it in source or at the destination (system's dconf database) changed.

We can decide to either overwrite changed values or import changes into our chezmoi backed-up file.

### 3. Import the `dconf.ini` into dconf system database

The chezmoi `run_after_import-dconf-settings.sh` script is ran to import the dconf settings from the `dconf.ini` file into the dconf database.

This allows us to check if keys/sections that we beckup-up changed and to either write back the overwritten values or to add new keys all together.

## Why is the export a hook but the import a script?

Both export and import could be a hook, but the export, getting the values out of dconf and into the `dconf.ini` file, cannot be a script. This is due to the fact that we moddify the destination file that is "generated" from the monitored keys.

As the documentation states:

> chezmoi assumes that the source or destination states are not modified while chezmoi is being executed. This assumption permits significant performance improvements, including allowing chezmoi to only read files from the source and destination states if they are needed to compute the target state.
>
> chezmoi's behavior when the above assumptions are violated is undefined. For example, using a run_before_ script to update files in the source or destination states violates the assumption that the source and destination states do not change while chezmoi is running.
>
> <https://www.chezmoi.io/reference/application-order/>

## Automatic dconf backups

Whenever the import is run, it will create a dconf export (`dconf dump /`) and stores it in the dconf-backups directory, just in case something would go wrong. For simplicity and because we're dealing with small text files, old backups are not automatically deleted.
