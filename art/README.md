# Logo generator

`make_logo.py` draws an addon logo: a rounded square with a shield emblem, the addon initials, the addon name, a row of 5 action bar icons and "by <author>". The script draws every shape itself, so the logo contains no Blizzard art.

## Requirements

- Python 3 with Pillow (`pip3 install pillow`).
- macOS fonts Impact and Trebuchet MS Bold (they are part of macOS).

## Usage

Run the script from the repository root:

```sh
python3 art/make_logo.py --name "Class Macros" --initials CM --description "class macros for warrior tank healer mage shaman"
```

The script writes three sizes to `dist/logos`. The file names start with the addon name:

| File | Use |
|---|---|
| `<Name>-logo-1024.png` | Large version, for example for GitHub |
| `<Name>-logo-400.png` | CurseForge project avatar |
| `<Name>-logo-64.png` | Small icon |

For "Class Macros" the files are `Class_Macros-logo-1024.png`, `Class_Macros-logo-400.png` and `Class_Macros-logo-64.png`. The `dist` folder is not in git, so make the logos again with the same command when you need them.

## Options

| Option | Meaning | Default |
|---|---|---|
| `--name` | Addon name. It is the title on the logo and the start of the file names. A long name gets a smaller font. | (required) |
| `--description` | Words about the addon. The script uses them to choose the action bar icons (see the table below). | none |
| `--icons` | Up to 5 icons, separated by commas, for example `bag,map,star`. This option replaces `--description`. | from the description |
| `--initials` | Letters on the shield. | first letters of the name |
| `--author` | Shown as "by <author>". | Crypto |
| `--theme` | Colours: `navy`, `crimson`, `forest` or `purple`. | `navy` |

Run `python3 art/make_logo.py --help` to see the options in the terminal.

## Icons

The script can draw these icons. With `--description`, an icon is chosen when the description contains one of its words. The script fills the remaining slots with sword, shield, flame, heal and bolt.

| Icon | Words that choose it |
|---|---|
| `sword` | sword, warrior, melee, attack, combat, damage, dps |
| `shield` | shield, tank, defense, protect, armor, paladin |
| `flame` | fire, flame, mage, spell, magic, warlock |
| `heal` | heal, healer, priest, health, restore, support |
| `bolt` | lightning, shaman, energy, fast, speed, macro, action |
| `bag` | bag, bags, inventory, item, items, loot, gold, vendor |
| `map` | map, quest, guide, route, travel, explore, zone |
| `star` | star, favorite, reputation, achievement, reward |
| `skull` | skull, boss, dungeon, raid, death, pvp, rogue |
| `book` | book, journal, spellbook, talent, lore, learn |
| `gear` | gear, settings, config, tool, profession, option |

The description does not create a new picture. It only chooses from these icons. To add an icon, write a new drawing function in `make_logo.py` and add it to the `ICONS` table with its background colour and words.

## Examples

```sh
python3 art/make_logo.py --name "Class Macros" --initials CM --description "class macros for warrior tank healer mage shaman"
python3 art/make_logo.py --name "Quest Helper" --description "quest guide map travel" --theme forest
python3 art/make_logo.py --name "Boss Timers" --icons skull,star,bolt,shield,heal --theme crimson
```
