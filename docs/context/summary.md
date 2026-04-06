## What

First-person shooter prototype built in Godot 4.6 with GDScript. A minimal playable FPS: player movement, mouse-look, hitscan shooting, enemies with direct-chase AI, health/damage, HUD, and game loop (death + restart) in a single enclosed arena.

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- Arena script wires signals between player, enemies, and HUD

## Core Flow

Player spawns in arena → moves with WASD + mouse-look → shoots hitscan weapon → enemies chase player directly using distance checks + `move_and_slide()` → enemies deal melee damage on timer → player health tracked via signals → HUD updates health bar → death triggers game over UI → restart loads fresh scene via `change_scene_to_file`.

## System State

- Player: movement, mouse-look, jump, hitscan shooting, take_damage, death
- Arena: CSG-based 30x30 enclosed space with 3 obstacles, sky, directional light
- Enemies: direct-chase AI (no navmesh), distance-based detection/attack, timer-based melee
- HUD: health bar, crosshair, game over panel with restart button
- Game loop: spawn → fight → die → restart (full cycle works)

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction
- Mouse-look using `screen_relative` (Godot 4.3+), yaw/pitch separated, pitch clamped +-89 deg
- RayCast3D hitscan shooting with duck-typed damage
- Enemy direct-chase with `move_and_slide()` obstacle sliding
- Signal-driven HUD (health bar, game over panel)
- Scene restart via `change_scene_to_file.call_deferred()`

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- CSG primitives for level geometry
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
