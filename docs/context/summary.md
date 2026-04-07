## What

Multi-level horror FPS prototype built in Godot 4.6 with GDScript. Player navigates dark enclosed mazes with a flashlight, fights placed enemies, collects a key to unlock the exit, and progresses through levels. Three enemy variants (standard, runner, brute) with line-of-sight-aware direct-chase AI, procedurally generated sound effects, dark zone-colored level geometry, health/damage with visual feedback, ammo-limited hitscan weapon with ammo pickups, HUD with level indicator, ammo counter, key status, and kills tracking. Two handcrafted levels with fade-to-black transitions preserving player state across levels.

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- Two-tier scene hierarchy: persistent `game.tscn` shell (Player, HUD, run state, fade overlay) wraps swappable level scenes
- `game.gd` owns run state, wires Player-HUD signals, loads levels into `LevelContainer`, manages fade transitions
- Level scripts own level-local state (key, door, ambient audio) and emit `level_completed`; receive Player/HUD refs via `setup()`
- `LEVELS` array in `game.gd` defines ordered level sequence; game advances or shows final victory based on index
- Enemies placed as static scene instances in each level, not dynamically spawned

## Core Flow

Game shell loads level 1 with fade-in from black. Player explores rooms using flashlight, fights placed enemies, finds key pickup, door opens, reaches exit trigger. Level emits `level_completed`. Game shell disables player input, fades to black, swaps level, heals player 25HP, resets head pitch, repositions at SpawnPoint, re-enables input, fades in with level announcement. Completing final level shows victory with total stats. Death triggers game over showing level reached. Restart reloads entire game shell.

## System State

- Player: movement, mouse-look, jump, ammo-limited hitscan shooting (30 start / 60 max, 1 per shot, dry-fire click when empty), toggleable flashlight (F key, off by default), damage overlay, hit confirmation, healing, death
- Level 1: 36x36 GridMap maze; warm-to-cool zone lighting; 10 lamps; 7 enemies (4 standard, 2 runners, 1 brute); 3 health pickups; 3 ammo pickups (10 each)
- Level 2: 24x24 GridMap maze; colder atmosphere with denser fog, deeper ambient, more desaturated; 8 lamps; 8 enemies (4 standard, 3 runners, 1 brute); 3 health pickups; 3 ammo pickups (10 each); deeper ambient drone
- HUD: health bar, ammo counter (AMMO: current / max), crosshair with hitmarker, damage direction indicators, kills counter, key status, level label, level announcement overlay, game over/victory panels with run stats
- Run state persists across levels: health, ammo, flashlight, kills, elapsed time; 25HP heal on level transition
- Level-local state resets per level: key, door, enemies, pickups, geometry, lighting, ambient audio

## Capabilities

- Multi-level progression with fade-to-black transitions
- CharacterBody3D player with lerp-based acceleration/friction and sine-based head bob
- SpotLight3D flashlight on camera (off by default, F to toggle)
- RayCast3D hitscan shooting with ammo system, duck-typed damage, fire rate cooldown, muzzle flash, camera kick recoil
- Horror environment: volumetric fog, SSAO, glow bloom, desaturated color grading, debanding
- Ceiling SpotLight3D lamps with zone-colored unsettling tones per level
- Enemy LOS detection, attack telegraph, hit stagger, death tween, direct-chase AI
- Damage direction indicators, hitmarker feedback, health bar color coding
- Signal-driven HUD with level indicator, victory/game-over states, scene restart

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- GridMap with MeshLibrary for wall geometry; CSG for floor, ceiling, pillars, and cover objects
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
