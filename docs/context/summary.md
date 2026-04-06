## What

First-person shooter prototype built in Godot 4.6 with GDScript. A labyrinth-based FPS: player navigates interconnected rooms and corridors, fights placed enemies, collects a key, unlocks the exit, and escapes. Three enemy variants (standard, runner, brute) with line-of-sight-aware direct-chase AI, procedurally generated sound effects, zone-colored level geometry, health/damage with visual feedback, HUD with key status and kills tracking, and a complete game loop (explore → fight → find key → exit → victory or death → restart).

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (IDLE/CHASE/ATTACK/DEAD)
- Level script (`labyrinth.gd`) owns game state, wires signals between player, enemies, and HUD
- Enemies placed as static scene instances in the level, not dynamically spawned

## Core Flow

Player spawns in labyrinth → explores rooms and corridors → fights placed enemies → finds key pickup (guarded by brute) → door slides open → reaches exit trigger → victory. Death at any point triggers game over. Restart reloads the level scene via `change_scene_to_file`.

## System State

- Player: movement, mouse-look, jump, rate-limited hitscan shooting with muzzle flash, damage overlay on hit, hit confirmation signal, healing via pickups, death
- Labyrinth: CSG-based multi-room level with corridors, chokepoints, and obstacles; zone-colored materials (spawn warm gray, south halls blue-gray, combat rooms clay, north areas cool dark, key room gold, exit area green) with accent OmniLight3D in key room and exit; rooms include spawn room, south hall, two combat rooms, north hall, key room, NW corridor, and exit room
- Enemies: 7 placed instances — 4 standard (2 in combat west, 1 in combat east, 1 in north hall), 2 runners (one in combat east, one near north hall pillar), 1 brute in key room (with extended LOS memory); all use line-of-sight-gated direct-chase AI with configurable LOS memory duration, distance-based attack, telegraphed melee with lunge, hit stagger, tween death effect, 3D spatial hit and alert sounds
- HUD: color-coded health bar (green/yellow/red by HP percentage), crosshair with hitmarker flash, damage direction indicators, kills counter, key status label with gold flash on collection ("KEY: ---" / "KEY: FOUND"), game over panel (kills + time), victory panel (kills + time)
- Health pickups: 3 green emissive spheres placed in the level; persist until collected; Area3D with duck-typed `heal()` on player contact; procedural pickup chime on collection
- Key pickup: gold emissive rotating cube in key room; Area3D emits `picked_up` signal on player contact; level script plays chime, flashes HUD key status gold, animates door open
- Door: StaticBody3D blocking exit corridor; collision disabled immediately on key collection, then tweened upward over 0.8s with procedural rumble sound before `queue_free()`
- Exit trigger: Area3D behind the door; entering it with key triggers victory
- Audio: all sounds procedurally generated at runtime via AudioStreamWAV (no audio asset files); includes shoot, hurt, enemy hit, enemy alert growl, health pickup chime, key chime, door rumble, and looping ambient drone
- Game loop: explore labyrinth → fight → find key → door opens → reach exit → victory or death → restart

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction and sine-based head bob while moving
- Mouse-look using `screen_relative` (Godot 4.3+), yaw/pitch separated, pitch clamped +-89 deg
- RayCast3D hitscan shooting with duck-typed damage, fire rate cooldown, OmniLight3D muzzle flash, camera kick recoil with smooth recovery
- Damage overlay (ColorRect flash) on player hit
- Crosshair hitmarker: flashes white on confirmed hit via `hit_landed` signal
- Procedural audio generation: shoot/hurt on player, 3D spatial hit/alert on enemies, pickup chimes, door rumble, ambient drone
- Enemy line-of-sight detection: `PhysicsDirectSpaceState3D.intersect_ray()` against Environment layer; IDLE→CHASE requires LOS; chase persists for configurable `los_memory_duration` after losing sight
- Enemy attack telegraph: configurable orange flash + one-shot TelegraphTimer before damage, with forward lunge on hit
- Enemy hit stagger: brief movement pause on taking damage
- Enemy death effect: white flash + scale-to-zero tween before `queue_free()`
- Enemy direct-chase with `move_and_slide()` obstacle sliding through corridors
- Damage direction indicators: 4 edge ColorRects on HUD show which direction damage came from
- Static enemy placement: enemies placed as scene instances under `Enemies` node, `died` signal wired by level script at `_ready()`
- Zone-colored level geometry: StandardMaterial3D per zone (7 zone materials + dark floor) with OmniLight3D accents in key room and exit area
- Key/door/exit progression with feedback: key pickup triggers chime + gold HUD flash + door slide animation with rumble sound, exit trigger behind door triggers victory
- Kill counter and elapsed time tracked by level script, kills displayed on HUD
- Signal-driven HUD (health bar, key status with flash, kills, game over summary, victory summary)
- Victory state: freezes player input, releases mouse, shows victory UI
- Scene restart via `change_scene_to_file.call_deferred()`

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- CSG primitives for level geometry
- `gdformat` / `gdlint` for code formatting and linting
- Design resolution 1280x720 with `canvas_items` stretch mode
- No external assets or plugins
