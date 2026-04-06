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
- No autoloads; signal wiring done by the level scene script (arena.gd)

## Damage Pattern

- `take_damage(amount: int) -> void` method on any damageable node
- Checked via `has_method(&"take_damage")` duck typing
- No shared base class or interface required
- Dead target detected by checking `collision_layer == 0`
- Player sets `collision_layer = 0` and disables physics/input processing on death

## Material Duplication

- All scene instances that modify material properties call `_mesh.get_surface_override_material(0).duplicate()` in `_ready()`
- Prevents shared SubResource materials from affecting all instances when flashing hit color

## Procedural Audio

- All game sounds are generated at runtime via `AudioStreamWAV` (no imported audio files)
- Synthesized from sine waves + noise with envelope decay
- Player uses `AudioStreamPlayer` (non-spatial) for shoot and hurt sounds
- Enemies use `AudioStreamPlayer3D` for spatially positioned hit sounds

## Enemy AI Pattern

- Distance-based detection and state transitions (no Area3D, no NavigationAgent3D)
- Direct movement toward player via `move_and_slide()` for obstacle sliding
- Timer-based attacks (no async coroutines in combat logic)
- Player found via `get_tree().get_nodes_in_group(&"player")`

## Physics Rules

- Moving bodies use only convex shapes (CapsuleShape3D, BoxShape3D, SphereShape3D)
- Never ConcavePolygonShape3D on moving bodies
- CSG with `use_collision = true` and `collision_mask = 0` for static environment
- Never multiply mouse motion by delta
- Mouse yaw on body node, pitch on head node, pitch clamped +-89 deg

## Scene Restart

- Use `get_tree().change_scene_to_file.call_deferred()` for clean restart
- Never call scene change from within a signal handler without deferring
