## GDScript Conventions

- Static typing on all variables, parameters, and return types
- Code order: extends → signals → enums → constants → @export → vars → @onready → lifecycle → public → _private
- `snake_case` for files/functions/variables/signals; `PascalCase` for classes/nodes; `CONSTANT_CASE` for constants
- `&"action_name"` (StringName) for all input action checks
- `@onready` to cache node references; never use `$Path` in per-frame code
- `_unhandled_input` for gameplay input (not `_input`), so UI can consume events first
- `_physics_process` for all movement/collision code; `_process` only for visual-only updates

## Collision Layers

- Layer 1: Environment (static geometry)
- Layer 2: Player
- Layer 3: Enemies
- Layer 4: Projectiles

## Scene Organization

- One script per scene root, named to match the scene
- Co-locate scene + script in the same directory
- Scenes organized under `scenes/<entity>/`
- No autoloads; signal wiring done by the level scene script

## Damage Pattern

- `take_damage(amount: int) -> void` method on any damageable node
- Checked via `has_method(&"take_damage")` duck typing
- No shared base class or interface required

## Physics Rules

- Moving bodies use only convex shapes (CapsuleShape3D, BoxShape3D, SphereShape3D)
- Never ConcavePolygonShape3D on moving bodies
- CSG with `use_collision = true` and `collision_mask = 0` for static environment
- Never multiply mouse motion by delta
- Mouse yaw on body node, pitch on head node, pitch clamped +-89 deg
