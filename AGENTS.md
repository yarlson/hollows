# Godot 4.x FPS Project — Agent Instructions

## GDScript Rules

### Code Order in Every Script

```
@tool / class_name / extends
signals
enums
constants
@export vars
regular vars
@onready vars
_ready() / _process() / _physics_process()
public methods
_private methods
```

Violating this order causes editor warnings and inconsistent codebase.

### Naming

- Files/folders/functions/variables/signals: `snake_case`
- Classes/nodes: `PascalCase`
- Constants/enum members: `CONSTANT_CASE`
- Private members: prefix `_`

### Type Hints — Always

Static typing is mandatory. It catches errors at parse time and generates 28-59% faster bytecode.

```gdscript
var speed: float = 5.0
var direction := Vector3.ZERO  # := when type is obvious from RHS
func take_damage(amount: int) -> void:
```

Never combine `@onready` and `@export` on the same variable.

### Call Down, Signal Up

- Parents call methods on children (direct calls go DOWN the tree)
- Children emit signals to parents (signals go UP the tree)
- Never do `get_parent().something()` or reach across siblings

### Cache Node References

```gdscript
# GOOD — resolved once in _ready
@onready var _head: Node3D = $Head

# BAD — traverses tree every frame
func _physics_process(delta: float) -> void:
    $Head.rotation.x = ...  # Don't do this
```

### StringName for Input Actions

Use `&"action_name"` not `"action_name"` for input checks — avoids string allocation every frame.

```gdscript
Input.is_action_pressed(&"move_forward")
```

## Physics Rules

### \_physics_process vs \_process

- ALL movement, velocity, collision code: `_physics_process()` (fixed 60Hz)
- Visual-only updates, UI: `_process()` (variable framerate)

Putting movement in `_process()` causes jittery, framerate-dependent movement.

### Collision Shapes

- Moving bodies (CharacterBody3D): only CapsuleShape3D, BoxShape3D, SphereShape3D
- Never ConcavePolygonShape3D (trimesh) on moving bodies — physics breaks
- StaticBody3D for level geometry: any shape is fine

### Collision Layers

Always name layers in Project Settings > Layer Names > 3D Physics. Configure:

- **Layer** = "I exist on this layer"
- **Mask** = "I detect/collide with these layers"

## FPS Camera Rules

### Mouse Look

```gdscript
func _unhandled_input(event: InputEvent) -> void:  # NOT _input
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * sensitivity)           # yaw on body
        _head.rotate_x(-event.relative.y * sensitivity)     # pitch on head
        _head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
```

Critical mistakes to avoid:

- **Never multiply mouse motion by delta** — mouse events are already frame-independent
- **Use `_unhandled_input`** not `_input` — so UI can consume events first
- **Separate yaw and pitch** — body rotates Y, head/camera rotates X
- **Clamp pitch** to ~+-89 degrees — prevents camera flip

### Mouse Capture

```gdscript
Input.mouse_mode = Input.MOUSE_MODE_CAPTURED   # in _ready
Input.mouse_mode = Input.MOUSE_MODE_VISIBLE    # on death/menu
```

## FPS Character Setup

Use `CharacterBody3D`. This is the only correct choice for FPS player/enemies in Godot 4.

```
Player (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D)
├── Head (Node3D, y=eye_height)
│   └── Camera3D
│       └── RayCast3D (for hitscan)
```

Movement pattern:

```gdscript
var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
```

`transform.basis *` converts local direction to world space accounting for body rotation.

## Hitscan Weapons

```gdscript
raycast.force_raycast_update()  # must call before checking
if raycast.is_colliding():
    var collider := raycast.get_collider()
    if collider.has_method(&"take_damage"):
        collider.take_damage(damage)
```

The `has_method` pattern is the damage interface — any damageable node just implements `take_damage()`.

## Enemy Navigation

- Requires `NavigationRegion3D` in the level with a baked `NavigationMesh`
- CSG geometry must have `use_collision = true` to be parsed for navmesh
- Don't set `target_position` every frame — update every 0.25s
- Wait one physics frame after bake before spawning enemies

## Lint and Format

After each implementation phase, run:

```bash
gdformat scenes/**/*.gd
gdlint scenes/**/*.gd
```

Fix all issues before moving on. Code must pass both checks cleanly.

## Scene/File Hygiene

- `queue_free()` dead enemies and expired projectiles — they leak memory otherwise
- One script per scene root, named to match the scene
- Keep scripts under 200-300 lines; split if larger
- No autoloads unless genuinely global (this project needs none)
- No deep inheritance — prefer flat composition
- Only create files/scenes/scripts that are actually needed right now
