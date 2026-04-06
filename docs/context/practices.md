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
- No autoloads; signal wiring done by the level scene script (`labyrinth.gd`)

## Damage and Healing Pattern

- `take_damage(amount: int, source_position := Vector3.INF) -> void` on the player; other damageable nodes use `take_damage(amount: int)`
- `heal(amount: int) -> void` on the player; clamps to `_max_health`, emits `health_changed`
- Both damage and healing checked via `has_method()` duck typing — no shared base class required
- Dead target detected by checking `collision_layer == 0`
- Player sets `collision_layer = 0` and disables physics/input processing on death
- When `source_position` is finite, player calculates angle from its forward direction to the source and emits `damage_taken_from(angle)` for HUD direction indicators

## Health Pickup Pattern

- Area3D scene with collision_layer=0, collision_mask=2 (Player only)
- Uses duck-typed `body.has_method(&"heal")` on `body_entered` — same pattern as damage interface
- Pickups placed as static scene instances in the level; persist until collected
- Slow Y-axis rotation in `_process` for visual readability
- `queue_free()` on collection

## Material Duplication

- All scene instances that modify material properties call `_mesh.get_surface_override_material(0).duplicate()` in `_ready()`
- Prevents shared SubResource materials from affecting all instances when flashing hit color

## Procedural Audio

- All game sounds are generated at runtime via `AudioStreamWAV` (no imported audio files)
- Synthesized from sine waves + noise with envelope decay
- Player uses `AudioStreamPlayer` (non-spatial) for shoot and hurt sounds
- Enemies use `AudioStreamPlayer3D` for spatially positioned hit sounds

## Enemy AI Pattern

- Single `enemy.gd` script shared by all enemy variants; behavior tuned via `@export` vars (speed, health, damage, cooldowns, color, ranges)
- Variant scenes (`enemy.tscn`, `enemy_runner.tscn`, `enemy_brute.tscn`) override exports and mesh/collision dimensions
- Distance-based detection and state transitions (no Area3D, no NavigationAgent3D)
- Direct movement toward player via `move_and_slide()` for obstacle sliding
- Timer-based attacks with telegraph: one-shot TelegraphTimer fires before damage (duration configurable per variant), enemy flashes orange during wind-up
- Attack lunge: velocity impulse toward player on telegraph timeout; ATTACK state uses `move_toward` decay (not instant zero) so lunge produces visible forward motion
- Player found via `get_tree().get_nodes_in_group(&"player")`
- Hit stagger via float countdown in `_physics_process` — skips movement while `_stagger_time > 0`, no extra Timer needed
- Death uses `create_tween()` for shrink effect — `died` signal emits immediately (so kill count updates), collision disabled, visual tween plays, then `queue_free()` on tween callback
- Color management via `_set_color()` helper with `normal_color` export / `TELEGRAPH_COLOR` constant; telegraph timer stopped on state exit to prevent stale color
- `_health` initialized from `max_health` export in `_ready()`; initial material color set from `normal_color` export

## Combat Feedback Pattern

- Player emits `hit_landed` signal when hitscan connects with a damageable target; level script wires this to HUD
- HUD hitmarker: crosshair ColorRects flash white for 0.08s on hit confirmation, then reset to default color
- Enemy hit flash: material set to white for 0.1s via await, guarded by `is_instance_valid` and state check
- Damage direction indicators: 4 semi-transparent red edge bars on HUD (top/bottom/left/right), shown based on angle from player forward to damage source; counter-guarded await prevents overlapping hide calls
- Health bar color: StyleBoxFlat fill override on ProgressBar, color set in `update_health()` — green (>50%), yellow (25-50%), red (<=25%)
- Camera kick: each shot applies a small upward pitch impulse to the head node; smooth recovery in `_physics_process` at a fixed angular rate, clamped to pitch limits; fully recovers so aim is never permanently offset
- Head bob: sine-based vertical oscillation on head node `position.y` while moving on floor; resets smoothly when stationary or airborne; base Y cached from scene transform in `_ready()`

## Physics Rules

- Moving bodies use only convex shapes (CapsuleShape3D, BoxShape3D, SphereShape3D)
- Never ConcavePolygonShape3D on moving bodies
- CSG with `use_collision = true` and `collision_mask = 0` for static environment
- Never multiply mouse motion by delta
- Mouse yaw on body node, pitch on head node, pitch clamped +-89 deg

## Level Management

- Level script (`labyrinth.gd`) owns game state: `_game_over`, `_kills`, `_elapsed_time`
- Player added to `&"player"` group in `_ready()` so enemies can find it
- Player signals (`health_changed`, `hit_landed`, `damage_taken_from`, `died`) wired to HUD in `_ready()`
- Enemies placed as child instances under an `Enemies` container node; level script iterates children and connects each `died` signal via `_wire_enemies()`
- Health pickups placed as child instances under a `Pickups` container node; no signal wiring needed (self-contained via duck-typed `heal()`)
- Key pickup `picked_up` signal connected to level script; sets `_has_key`, updates HUD key status, removes door via `queue_free()`
- Exit trigger `body_entered` signal connected to level script; checks player group + `_has_key` + not `_game_over` before triggering victory
- Game over on player death; victory on reaching exit with key; `_game_over` flag prevents duplicate end states and stops elapsed time counter
- Victory freezes player by disabling `_unhandled_input` and `_physics_process`, then releases mouse
- HUD `restart_requested` signal triggers `change_scene_to_file.call_deferred()`

## Scene Restart

- Use `get_tree().change_scene_to_file.call_deferred()` for clean restart
- Never call scene change from within a signal handler without deferring
