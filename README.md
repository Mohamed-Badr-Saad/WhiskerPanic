# Whisker Panic

A cat vs. angry home appliances survivors game, made with Godot 4.7.2.

## Open it
1. Open Godot 4.7.2 (standard version).
2. Project Manager -> **Import** -> pick this folder's `project.godot` -> **Import & Edit**.
3. Press **F5** to play.

## Controls
- Move: WASD / arrow keys / gamepad stick / touch (drag anywhere on phones)
- Pause: Esc or P (or the II button)
- Level-up cards: click, or press 1 / 2 / 3

## Debug keys (only when run from the editor)
- F1 = level up instantly
- F2 = skip 1 minute
- F3 = spawn the Mega-Vac boss
- F4 = god mode on/off

## Where things are
- `scenes/player` - the cat
- `scenes/enemies` - appliances (enemy.gd is the shared base)
- `scenes/weapons` - the 6 weapons (weapon.gd is the shared base)
- `scenes/pickups` - treats, coins, hearts
- `scenes/main` - the game world, spawner (difficulty lives in wave_spawner.gd)
- `scenes/ui` - HUD, menus, Cat Tree shop
- `scripts/autoload` - GameState (save data) and Audio
- `scripts/data/upgrade_db.gd` - level-up card names and texts

See CREDITS.md for asset credits.
