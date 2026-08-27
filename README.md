# InterruptThis

InterruptThis is a lightweight World of Warcraft addon designed to make interruptible enemy casts easier to notice.

When your current target begins an interruptible cast, InterruptThis can:

- Display an **INTERRUPT NOW!** warning on screen
- Highlight your interrupt ability on your action bar
- Automatically clear the warning and glow when the cast ends
- Detect the player's class and configured interrupt ability
- Provide built-in QA and debugging tools for testing

## Current Status

**InterruptThis is currently in active development and QA testing.**

The addon is not considered a finished release yet. Bugs, incomplete class support, UI compatibility issues and behaviour changes may occur between versions.

Current QA build:

**v0.4.0**

## Installation

1. Download the latest QA release.
2. Extract the `InterruptThis` folder.
3. Place it inside:

   `World of Warcraft/_retail_/Interface/AddOns/`

4. Start World of Warcraft or type `/reload` if already logged in.

## Settings

InterruptThis has an in-game settings panel available under:

**Options > AddOns > InterruptThis**

Current options include:

- Screen interrupt warning
- Interrupt button glow
- Alert sound preference
- Debug messages

## Commands

`/it help`  
Shows available commands.

`/it settings`  
Opens the InterruptThis settings panel.

`/it test`  
Displays a test warning.

`/it glowtest`  
Tests the interrupt button glow.

`/it soundtest`  
Tests the configured alert sound.

`/it status`  
Displays detected class, interrupt spell, action slot and button information.

`/it qa`  
Displays a compact QA summary useful for screenshots and bug reports.

`/it debug`  
Enables or disables detailed debugging messages.

## QA Testers Wanted

Testing on different classes, specs, action bar setups and combat situations is greatly appreciated.

Particularly useful testing includes:

- Different player classes and interrupt abilities
- Blizzard default action bars
- ElvUI
- Other action bar addons
- Interruptible NPC casts
- Non-interruptible NPC casts
- Channeled abilities
- PvP player casts
- Dungeons and Delves
- Target switching during casts

When reporting a problem, please include where possible:

- Your class and specialization
- The enemy or player being tested
- The ability being cast
- What you expected to happen
- What actually happened
- A screenshot
- `/it qa` output
- BugSack/Lua errors if one occurred

## Known Limitations

InterruptThis is being developed around World of Warcraft's current protected and secret-value API behaviour.

Visual interrupt detection and button highlighting are currently being actively tested.

The alert sound setting and sound preview are available, but automatic combat-triggered audio is not yet enabled while a reliable implementation is investigated.

## AI-Assisted Development in qa

InterruptThis is an independently maintained addon project developed with assistance from ChatGPT for Lua development, debugging, documentation and code iteration.

All generated or suggested changes are tested in World of Warcraft before being treated as working functionality, i will do my best to code this myself, but ill ask for review and code the changes myself.

## Feedback

Bug reports, compatibility results and constructive code review are welcome.

This project is currently intended for QA and development testing rather than production release.
