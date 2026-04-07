## What

First-person shooter prototype built in Godot 4.6 with GDScript. A horror-themed labyrinth FPS: player navigates dark interconnected rooms and corridors with a flashlight, fights placed enemies, collects a key, unlocks the exit, and escapes. Three enemy variants (standard, runner, brute) with line-of-sight-aware direct-chase AI, procedurally generated sound effects, dark zone-colored level geometry, health/damage with visual feedback, HUD with key status and kills tracking, and a complete game loop (explore → fight → find key → exit → victory or death → restart).

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- **Two-tier scene hierarchy:** persistent `game.tscn` shell (Player, HUD, run state) wraps swappable level scenes
- `game.gd` owns run state (`_kills`, `_elapsed_time`, `_game_over`), wires Player↔HUD signals, loads levels into `LevelContainer`
- Level scripts own level-local state (key, door, ambient audio) and emit `level_completed` signal; receive Player/HUD refs via `setup()`
- `LEVELS` array in `game.gd` defines the ordered level sequence; game advances or shows final victory based on index
- Enemies placed as static scene instances in each level, not dynamically spawned

## Core Flow

Player spawns in level (positioned at SpawnPoint Marker3D) → explores rooms and corridors using flashlight → fights placed enemies → finds key pickup → door slides open → reaches exit trigger → level emits `level_completed` → game shell advances to next level or shows final victory. Death at any point triggers game over. Restart reloads the entire game shell via `change_scene_to_file`.

## System State

- Player: movement, mouse-look, jump, rate-limited hitscan shooting with muzzle flash, toggleable SpotLight3D flashlight (F key, off by default), damage overlay on hit, hit confirmation signal, healing via pickups, death
- Labyrinth: GridMap-based multi-room level with ceiling, corridors, chokepoints, and obstacles; walls built from a MeshLibrary with dark zone-colored materials; enclosed with dark ceiling at Y=4; horror atmosphere with volumetric fog, SSAO, glow, desaturated color grading; 10 ceiling-mounted SpotLight3D lamps aimed downward with emissive fixture meshes (all shadow-casting); rooms include spawn room, south hall, two combat rooms, north hall, key room, NW corridor, and exit room; floor, pillars, and cover objects remain as CSG
- Enemies: 7 placed instances — 4 standard, 2 runners, 1 brute in key room; line-of-sight-gated direct-chase AI, telegraphed melee, hit stagger, tween death effect, 3D spatial sounds
- HUD: color-coded health bar, crosshair with hitmarker, damage direction indicators, kills counter, key status, game over/victory panels
- Health pickups: 3 placed in level; Area3D with duck-typed `heal()` on player contact
- Key pickup: gold emissive rotating key shape (bow + shaft + teeth) in key room; Area3D emits `picked_up` signal
- Key/door/exit progression: key pickup → door opens → exit trigger → victory
- Audio: all sounds procedurally generated at runtime via AudioStreamWAV
- Game loop: explore → fight → find key → door opens → reach exit → victory or death → restart

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction and sine-based head bob
- SpotLight3D flashlight on camera (off by default, F to toggle) for horror visibility
- Mouse-look using `screen_relative`, yaw/pitch separated, pitch clamped +-89 deg
- RayCast3D hitscan shooting with duck-typed damage, fire rate cooldown, muzzle flash, camera kick recoil
- Horror environment: volumetric fog, SSAO, glow bloom, desaturated color grading, debanding
- 10 downward SpotLight3D ceiling lamps with zone-colored unsettling tones (amber, blood-red, cold blue, eerie green)
- Enemy LOS detection, attack telegraph, hit stagger, death tween, direct-chase AI
- Damage direction indicators, hitmarker feedback, health bar color coding
- Signal-driven HUD, victory/game-over states, scene restart

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- GridMap with MeshLibrary for wall geometry; CSG for floor, ceiling, pillars, and cover objects
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
