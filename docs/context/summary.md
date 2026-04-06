## What

First-person shooter prototype built in Godot 4.6 with GDScript. A wave-based arena FPS: player movement, mouse-look, hitscan shooting, enemies with direct-chase AI spawned in escalating waves, procedurally generated sound effects, health/damage with visual feedback, HUD with wave tracking, and a complete game loop (waves → victory or death → restart).

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- Arena script owns wave state, spawns enemies dynamically, wires signals between player, enemies, and HUD

## Core Flow

Player spawns in arena → wave 1 begins → enemies spawn at randomized Marker3D positions → player moves with WASD + mouse-look → shoots hitscan weapon → enemies chase and melee attack → killing all enemies in a wave triggers a 2s delay then the next wave → 5 waves with escalating enemy counts (3/4/5/6/8) → clearing all waves triggers victory → death at any point triggers game over → restart loads fresh scene via `change_scene_to_file`.

## System State

- Player: movement, mouse-look, jump, rate-limited hitscan shooting with muzzle flash, damage overlay on hit, hit confirmation signal, death
- Arena: CSG-based 30x30 enclosed space with 3 obstacles, 8 spawn points (Marker3D), sky, directional light
- Waves: arena.gd manages wave state — spawns enemies dynamically from preloaded scene, tracks alive count via `died` signal, progresses through 5 waves with a one-shot Timer delay between them
- Enemies: direct-chase AI (no navmesh), distance-based detection/attack, timer-based melee (5 damage), hit stagger, tween death effect, 3D spatial hit sound
- Target: destroyable StaticBody3D scene (exists but not placed in active arena)
- HUD: health bar, crosshair with hitmarker flash, wave label ("Wave N/5"), enemy count, game over panel, victory panel
- Audio: all sounds procedurally generated at runtime via AudioStreamWAV (no audio asset files)
- Game loop: wave 1 → fight → clear → next wave → ... → victory or death → restart

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction
- Mouse-look using `screen_relative` (Godot 4.3+), yaw/pitch separated, pitch clamped +-89 deg
- RayCast3D hitscan shooting with duck-typed damage, fire rate cooldown, OmniLight3D muzzle flash
- Damage overlay (ColorRect flash) on player hit
- Crosshair hitmarker: flashes white on confirmed hit via `hit_landed` signal
- Procedural audio generation: shoot/hurt sounds on player, 3D spatial hit sound on enemies
- Enemy hit stagger: brief movement pause on taking damage
- Enemy death effect: white flash + scale-to-zero tween before `queue_free()`
- Enemy direct-chase with `move_and_slide()` obstacle sliding
- Wave-based spawning: arena preloads enemy scene, instantiates at shuffled spawn points per wave
- Signal-driven HUD (health bar, wave info, enemy count, game over panel, victory panel)
- Victory state: freezes player input, releases mouse, shows victory UI
- Scene restart via `change_scene_to_file.call_deferred()`

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- CSG primitives for level geometry
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
