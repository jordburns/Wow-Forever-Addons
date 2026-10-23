# Class Macros

**Ready-made class macros and saved action bar profiles for WoW Forever.**

Set up your macros and bars once. Load them on every character of the same class, also on a new level 1 character.

Type `/classmacros` to open the window.

---

## Features

- Macro sets for all 9 classes: Warrior, Paladin, Druid, Hunter, Mage, Priest, Rogue, Shaman and Warlock.
- Spell names checked against the WoW Forever spellbooks.
- No modifier keys. The macros use targets, stances, forms and equipment instead.
- An in-game editor: change, add or delete macros and whole sets.
- Gear slots: macros that equip your weapons and shield use your own item names.
- Bar profiles: save all your action bars and load them on another character.
- Import and export: share a set, all sets or a bar profile as a text string.

---

## How the macros work

- **Heals and buffs** go to your mouseover target if it is a friend. Else they go to your friendly target. Else they go to you.
- **Attacks** go to your mouseover target if it is an enemy. Else they go to your target. Melee attacks also start auto attack.
- **Stance macros** (Warrior) change to the correct stance first. The next press uses the ability.
- **Forms, aspects and stealth** do not cancel when you press them a second time.
- **Shield macros** equip your one-hand weapon and shield first, if they are not equipped.
- A macro shows a question mark until you learn its spell. Then it shows the spell icon. So you can put every macro on your bars at level 1.

---

## The main window

Type `/classmacros`. The window shows the macro sets of the class you play.

Each set has one row:

- The set icon, name and tab: **Character tab** (only this character) or **General tab** (all your characters).
- A count, for example `5/7`. It is green when all macros of the set exist.
- **Make** makes or updates all macros of the set.
- **Delete** deletes the macros of the set, after a confirmation.
- **+** opens the set. You then see every macro with a tick box. A green name means the macro exists.

Buttons at the bottom:

- **Make all** makes all sets.
- **Delete all** deletes all sets, after a confirmation.
- **Make selected** makes only the macros that you ticked.

At the top:

- **Edit sets** opens the editor.
- **Import / Export** opens the sharing window.

---

## Gear

Some macros equip weapons, for example Shield Block or a two-hand swap. They use the item names that you set in the **Gear** area of the main window:

- Drag the item from your bags onto its slot, or
- Equip the item and click **Use equipped**.

All macros that use gear update at once. Gear is saved per character.

### Placeholders: use your gear in your own macros

A macro does not contain your item names directly. It contains a **placeholder**, for example `<2H>`. When Class Macros makes the macro, it puts in the item name that you set in the Gear area. So one macro works on every character, with each character's own weapons.

Warrior, Paladin and Shaman have these placeholders:

| Placeholder | Gear slot |
|---|---|
| `<1H>` | One-hand weapon |
| `<SHIELD>` | Shield |
| `<2H>` | Two-hand weapon |

To make your own gear macro:

1. Click **Edit sets**, choose a set and click **New macro**.
2. Write the placeholder where the item name goes. For example, this macro equips your one-hand weapon and shield, then casts Shield Block:

    ```
    #showtooltip Shield Block
    /equipslot 16 <1H>
    /equipslot 17 <SHIELD>
    /cast Shield Block
    ```

3. Click **Save macro**, then **Make** for the set in the main window.

In /macro you see the real item names. In the editor you always see the placeholders.

### Your own gear slots

Every class can have its own gear slots, also classes with no gear slots yet:

1. Click **Edit sets**, then **Gear slots**.
2. Click **New gear slot**. Give it a name (for example "Ranged") and a placeholder word (for example RANGED, which becomes `<RANGED>`).
3. Choose where **Use equipped** takes the item from: Main hand, Off hand, Ranged, Trinket 1 or Trinket 2.
4. Click **Save gear slot**. The new slot shows in the Gear area of the main window.

A class can have up to 6 gear slots. If you rename a placeholder, Class Macros changes it in all macros of that class. Exported sets keep their placeholders, so the macros use the gear of the person who imports them.

---

## Bar profiles

A bar profile saves every action bar slot: macros, spells and items, on all bars and stance pages.

- **Save bars** saves your bars as a profile. Give it a name.
- Choose a profile in the **Bar profile** dropdown.
- **Load bars** puts the profile on this character, after a confirmation. Only the slots in the profile change.
- **Delete profile** deletes the profile. Your bars and macros do not change.

On a new character, click **Make all** first, then **Load bars**.

If the character does not know a spell yet, or does not have an item yet, that slot waits. When you learn the spell or get the item, Class Macros puts it in its slot.

Profiles are shared by all your characters of the same class. Class Macros uses the game's own action slots, so it also works with bar addons such as Bartender.

---

## The editor

Click **Edit sets**.

- Click a set to edit it: name, tab (Character or General) and icon.
- Click the set icon to choose an icon. You can search by the name of a spell, item or macro. You can also drag a spell, item or macro onto the icon.
- Click a macro to change its name or text, or click **New macro**. A macro name can have 16 letters. A macro text can have 255 letters.
- **New set**, **Delete set**, **Move up** and **Move down** change the list of sets.
- **Gear slots** lets you add your own gear slots for the class, for example a ranged weapon. See "Placeholders" above.
- **Copy sets from** copies the sets of another of your characters of the same class.
- **Reset to built-in** goes back to the built-in sets.

Your changes are saved per character. A new character starts with the built-in sets. After a change, click **Make** in the main window to update your macros.

---

## Import and export

Click **Import / Export**.

- **Export all sets**, **Export bar profile** or **Export set** (choose a set first) makes a text string. Press Ctrl+C to copy it.
- To import, click in the box, paste the string with Ctrl+V and click **Import**.

Importing never runs code. But a macro can contain `/run` code. Class Macros warns you when an imported macro uses `/run` or `/script`. Only import strings from people you trust.

---

## Good to know

- Nothing changes while you are in combat.
- Warrior: there is no Charge macro. With the Vanguard talent, Charge is a different spell, and only the spellbook version works in Defensive Stance. Drag Charge from your spellbook onto your bar.
- Every delete and every load asks for a confirmation first.
- Macros that you made yourself with other names are never changed.
- The General tab holds 120 macros for your whole account. If you play many classes, make only the General sets that you need.
- Profiles and your own sets are saved in the game's saved data. They are not part of the addon download.

---

## Commands

- `/classmacros` opens and closes the window.
- `/classmacros slots` prints every filled action bar slot in chat. Use it if a slot does not load as expected.

---

Made by **Crypto**.
