# Wow-Forever-Addons

World of Warcraft addons for WoW Forever.

## Addons

| Folder | Addon | In game |
|---|---|---|
| `Class_Macros` | Class Macros | Type `/classmacros` |

Class Macros makes macro sets for each class, lets you edit them in game, and saves and loads your action bars as profiles.

## Scripts

Run the scripts from the repository root.

### Install into the game

```sh
scripts/install.sh
```

The script updates the addon in every game client that already has it, for example `_forever_` or `_classic_beta_` in `/Applications/World of Warcraft`. If no client has the addon yet, the script installs it into `_forever_`.

To install into specific clients, give their folder names, for example `scripts/install.sh _classic_beta_`.

The script replaces the addon folder in the game with the repository version. Files that are not in the repository are deleted from the game copy. Your saved data in the `WTF` folder does not change.

After the install, type `/reload` in game. If you added or removed a file in the `.toc`, restart the game.

### Make a release zip

```sh
scripts/release.sh [patch|minor|major|none]
```

1. The script increases the version in `Class_Macros/Class_Macros.toc`. The default is `patch` (for example 1.0.0 to 1.0.1). Use `none` to keep the version.
2. The script writes `dist/Class_Macros-<version>.zip`. The zip contains the addon folder, so you can upload it to CurseForge or Wago as it is.

The `dist` folder is not in git.

## Versions

The version in the `.toc` has the form `major.minor.patch`. The release script reads it from the `## Version:` line.
