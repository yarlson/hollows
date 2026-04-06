## What

First-person shooter prototype built in Godot 4.6 with GDScript. A labyrinth-based FPS: player navigates interconnected rooms and corridors, fights placed enemies, collects a key, unlocks the exit, and escapes. Three enemy variants (standard, runner, brute) with direct-chase AI, procedurally generated sound effects, health/damage with visual feedback, HUD, and a complete game loop (explore → fight → find key → exit → victory or death → restart).

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- Level script (`labyrinth.gd`) owns game state, wires signals between player, enemies, and HUD
- Enemies placed as static scene instances in the level, not dynamically spawned

## Core Flow

Player spawns in labyrinth → explores rooms and corridors → fights enemies placed throughout the level → finds key pickup (guarded by enemies) → door unlocks → reaches exit trigger → victory. Death at any point triggers game over. Restart reloads the level scene via `change_scene_to_file`.

## System State

- Player: movement, mouse-look, jump, rate-limited hitscan shooting with muzzle flash, damage overlay on hit, hit confirmation signal, healing via pickups, death
- Labyrinth: CSG-based multi-room level with corridors, chokepoints, and obstacles; rooms include spawn room, south hall, two combat rooms, north hall, key room, NW corridor, and exit room
- Enemy variants: three types sharing one script (`enemy.gd`) with `@export` configuration — standard (red, balanced), runner (green, small, fast, fragile), brute (purple, large, slow, tanky, high damage); all use direct-chase AI (no navmesh), distance-based detection/attack, telegraphed melee with lunge, hit stagger, tween death effect, 3D spatial hit sound
- HUD: color-coded health bar (green/yellow/red by HP percentage), crosshair with hitmarker flash, damage direction indicators, key status indicator, kills counter, game over panel with summary, victory panel with summary
- Health pickups: green emissive spheres placed in the level; persist until collected; Area3D with duck-typed `heal()` on player contact
- Key pickup: gold rotating cube; on contact emits `picked_up` signal; level script unlocks the door
- Door: StaticBody3D blocking exit corridor; removed via `queue_free()` when key is collected
- Exit trigger: Area3D behind the door; triggers victory when entered with key
- Audio: all sounds procedurally generated at runtime via AudioStreamWAV (no audio asset files)
- Game loop: explore labyrinth → fight → find key → unlock door → reach exit → victory or death → restart

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction and sine-based head bob while moving
- Mouse-look using `screen_relative` (Godot 4.3+), yaw/pitch separated, pitch clamped +-89 deg
- RayCast3D hitscan shooting with duck-typed damage, fire rate cooldown, OmniLight3D muzzle flash, camera kick recoil with smooth recovery
- Damage overlay (ColorRect flash) on player hit
- Crosshair hitmarker: flashes white on confirmed hit via `hit_landed` signal
- Procedural audio generation: shoot/hurt sounds on player, 3D spatial hit sound on enemies
- Enemy attack telegraph: configurable orange flash + one-shot TelegraphTimer before damage, with forward lunge on hit
- Enemy hit stagger: brief movement pause on taking damage
- Enemy death effect: white flash + scale-to-zero tween before `queue_free()`
- Enemy direct-chase with `move_and_slide()` obstacle sliding through corridors
- Damage direction indicators: 4 edge ColorRects on HUD show which direction damage came from
- Static enemy placement: enemies placed as scene instances in the level, `died` signal wired by level script
- Key/door/exit progression: key pickup triggers door removal, exit trigger behind door triggers victory
- Kill counter and elapsed time tracked by level script, displayed on HUD and in end-of-game summaries
- Signal-driven HUD (health bar, key status, kills, game over summary, victory summary)
- Victory state: freezes player input, releases mouse, shows victory UI
- Scene restart via `change_scene_to_file.call_deferred()`

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- CSG primitives for level geometry
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
