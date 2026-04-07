## GDScript Conventions

- Static typing on all variables, parameters, and return types
- Code order: extends → signals → enums → constants → @export → vars → @onready → lifecycle → public → \_private
- `snake_case` for files/functions/variables/signals; `PascalCase` for classes/nodes; `CONSTANT_CASE` for constants
- `&"action_name"` (StringName) for all input action checks
- `@onready` to cache node references; never use `$Path` in per-frame code
- `_unhandled_input` for gameplay input (not `_input`), so UI can consume events first
- `_physics_process` for all movement/collision code; `_process` only for visual-only updates
- Run `gdformat` and `gdlint` on all `.gd` files after each implementation phase

## Collision Layers

- Layer 1 (value 1): Environment — static geometry
- Layer 2 (value 2): Player
- Layer 3 (value 4): Enemies
- Layer 4 (value 8): Projectiles

## Scene Organization

- One script per scene root, named to match the scene
- Co-locate scene + script in the same directory
- Scenes organized under `scenes/<entity>/`
- No autoloads; signal wiring done by the game shell (`game.gd`)

## Game Shell (game.gd / game.tscn)

- `game.tscn` is the main scene; contains Player, HUD, `LevelContainer` Node3D slot, and `FadeLayer` (CanvasLayer layer=100 with full-screen `FadeRect` ColorRect)
- `game.gd` owns run-global state: `_kills`, `_elapsed_time`, `_game_over`, `_transitioning`, `_current_level_index`
- Player added to `&"player"` group in `game.gd._ready()` so enemies can find it
- Player-HUD signal wiring (health_changed, hit_landed, damage_taken_from, died) done once in `game.gd._ready()`
- `LEVELS` const array defines ordered level file paths
- `_load_level(index)` frees previous level, instances next into `LevelContainer`, calls `_wire_level()`, resets key status, updates level label, positions player at SpawnPoint
- `_wire_level()` connects enemy `died` signals, level `level_completed` signal, and calls `level.setup(player, hud)`
- `_transition_to_next_level()`: disables player input → fade out (0.4s) → swap level → zero velocity → heal 25HP (`TRANSITION_HEAL`) → reset head pitch via `player.reset_for_level()` → re-enable input → show level announcement → fade in (0.4s)
- On `level_completed`: advances to next level via fade transition, or calls `_finish_game()` for final victory; guarded by `_transitioning` and `_game_over` flags
- On player `died`: shows game over panel with level reached
- Victory panel shows total levels, kills, and time; game over panel shows level, kills, and time
- HUD `restart_requested` reloads entire `game.tscn` via `change_scene_to_file.call_deferred()`
- Game starts with fade-in from black

## Level Contract

Each level scene must provide:

- Root Node3D with script that has `signal level_completed` and `func setup(player, hud)`
- `SpawnPoint` (Marker3D) for player positioning and facing
- `Enemies` (Node3D) container; children with `died` signal get auto-wired by game shell
- `Pickups` (Node3D) container for health pickups (self-contained, no wiring needed)
- `KeyPickup` (Area3D) with `picked_up` signal
- `Door` (StaticBody3D) on Environment layer
- `ExitTrigger` (Area3D) with collision_mask=2 (Player)
- `WorldEnvironment` with level-specific atmosphere settings
- Level-local state: `_has_key`, `_completed`, ambient audio, key/door references

## Damage and Healing Pattern

- `take_damage(amount: int, source_position := Vector3.INF) -> void` on the player; other damageable nodes use `take_damage(amount: int)`
- `heal(amount: int) -> void` on the player; clamps to `_max_health`, emits `health_changed`
- Both damage and healing checked via `has_method()` duck typing — no shared base class required
- Dead target detected by checking `collision_layer == 0`
- Player sets `collision_layer = 0` and disables physics/input processing on death
- When `source_position` is finite, player calculates angle to source and emits `damage_taken_from(angle)` for HUD direction indicators

## Health Pickup Pattern

- Area3D scene with collision_layer=0, collision_mask=2 (Player only)
- Uses duck-typed `body.has_method(&"heal")` on `body_entered`
- Pickups placed as static scene instances in the level; persist until collected
- Slow Y-axis rotation in `_process` for visual readability
- Procedural pickup chime reparented to pickup's parent before `queue_free()` so sound outlives the node

## Ammo Pickup Pattern

- Mirrors health pickup pattern exactly: Area3D, collision_layer=0, collision_mask=2
- Uses duck-typed `body.has_method(&"add_ammo")` on `body_entered`
- `@export var ammo_amount: int = 10` per pickup, clamped to `_max_ammo` on player
- Yellow/amber emissive CSG visual to distinguish from health (red cross)
- Player emits `ammo_changed(current, max)` signal; HUD wired via game shell same as `health_changed`

## Material Duplication

- All scene instances that modify material properties call `_mesh.get_surface_override_material(0).duplicate()` in `_ready()`
- Prevents shared SubResource materials from affecting all instances when flashing hit color

## Procedural Audio

- All game sounds are generated at runtime via `AudioStreamWAV` (no imported audio files)
- Synthesized from sine waves + noise with envelope decay
- Player uses `AudioStreamPlayer` (non-spatial) for shoot and hurt sounds
- Enemies use `AudioStreamPlayer3D` for spatially positioned hit and alert sounds
- Level script owns progression sounds (key chime, door rumble) and ambient drone
- Ambient drone uses `AudioStreamWAV.LOOP_FORWARD` with `loop_end` for seamless looping; pitch/harmonics vary per level
- For sounds that must outlive their source node: create AudioStreamPlayer, reparent to persistent parent, connect `finished` to `queue_free`

## Enemy AI Pattern

- Single `enemy.gd` script shared by all enemy variants; behavior tuned via `@export` vars (speed, health, damage, cooldowns, color, ranges, LOS memory)
- Variant scenes (`enemy.tscn`, `enemy_runner.tscn`, `enemy_brute.tscn`) override exports and mesh/collision dimensions
- Line-of-sight-gated detection: `PhysicsDirectSpaceState3D.intersect_ray()` from enemy eye height to player eye height against Environment layer (1); IDLE→CHASE requires both distance < `detection_range` AND unobstructed LOS
- LOS memory: CHASE state tracks `_time_since_last_seen`; returns to IDLE after `los_memory_duration` (configurable per variant)
- Direct movement toward player via `move_and_slide()` for obstacle sliding
- Timer-based attacks with telegraph: one-shot TelegraphTimer fires before damage, enemy flashes orange during wind-up
- Attack lunge: velocity impulse toward player on telegraph timeout
- Player found via `get_tree().get_nodes_in_group(&"player")`
- Hit stagger via float countdown in `_physics_process`
- Death uses `create_tween()` for shrink effect — `died` signal emits immediately, then `queue_free()` on tween callback

## Combat Feedback Pattern

- Player emits `hit_landed` signal when hitscan connects; game shell wires this to HUD
- HUD hitmarker: crosshair ColorRects flash white for 0.08s on hit confirmation
- Enemy hit flash: material set to white for 0.1s via await, guarded by `is_instance_valid` and state check
- Damage direction indicators: 4 semi-transparent red edge bars on HUD; counter-guarded await prevents overlapping hide calls
- Health bar color: green (>50%), yellow (25-50%), red (<=25%)
- Camera kick: small upward pitch impulse per shot; smooth recovery in `_physics_process`
- Head bob: sine-based vertical oscillation while moving on floor

## GridMap Wall System

- Walls use GridMap with a MeshLibrary (`wall_library.tres`) instead of individual CSG nodes
- Cell size: 0.5 x 4 x 0.5 (each cell is one wall block, 0.5m thick, 4m tall)
- `cell_center_x = false`, `cell_center_y = true`, `cell_center_z = false`
- 6 MeshLibrary items (one per zone color): wall_spawn(0), wall_south_hall(1), wall_combat(2), wall_north(3), wall_key_room(4), wall_exit(5)
- GridMap collision_layer = 1 (Environment), collision_mask = 0
- Pillars, cover objects, floor, and ceiling remain as individual CSG nodes

## Interior Lighting and Horror Atmosphere

- No DirectionalLight; enclosed levels use SpotLight3D lamps and player flashlight
- Each level has its own WorldEnvironment with distinct ambient light, fog density, color grading
- Ceiling-mounted SpotLight3D lamps aimed downward under a `Lamps` Node3D parent; each lamp is a Node3D with MeshInstance3D emissive fixture and SpotLight3D; all shadow-casting
- Lamp color palettes vary per level: Level 1 uses warm amber/red/blue/green; Level 2 uses cold violet/blue/green/deep red
- Player SpotLight3D flashlight on Camera3D (energy 8, range 25, angle 35, shadow-casting)
- Ceiling is CSGBox3D at Y=4.5 flush with wall tops at Y=4, collision_layer=1

## Horror Post-Processing

- Volumetric fog with dark albedo and anisotropy for light shafts; density varies per level
- SSAO for darkened corners and wall joints
- Glow for subtle light bleed
- Color adjustment: desaturated world; saturation/contrast vary per level
- Debanding enabled in project settings
- Dark material palette: wall albedo 0.12-0.30, floor 0.12-0.15, ceiling 0.08-0.10

## Physics Rules

- Moving bodies use only convex shapes (CapsuleShape3D, BoxShape3D, SphereShape3D)
- Never ConcavePolygonShape3D on moving bodies
- GridMap with collision for static wall geometry; CSG with `use_collision = true` and `collision_mask = 0` for non-wall static objects
- Never multiply mouse motion by delta
- Mouse yaw on body node, pitch on head node, pitch clamped +-89 deg

## Scene Restart

- Use `get_tree().change_scene_to_file.call_deferred()` for clean restart — reloads entire game shell
- Never call scene change from within a signal handler without deferring
