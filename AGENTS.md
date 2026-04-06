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

Handle window focus changes — mouse capture is lost when switching windows:

```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
        if _mouse_captured:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
```

When mouse is not captured, click anywhere to re-capture. Escape always releases.

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

## Enemy AI

### Direct Chase Over NavigationAgent3D

For simple arenas, use direct movement toward the player with `move_and_slide()` — it handles obstacle collision/sliding automatically. Do NOT use `NavigationAgent3D` unless pathfinding around complex geometry is absolutely required.

`NavigationAgent3D` has severe issues:

- `get_next_path_position()` returns the agent's own position after `change_scene_to_file()` — enemies freeze
- `is_navigation_finished()` returns true when no path exists yet — enemies never start moving
- Runtime navmesh baking with CSG requires fragile multi-frame timing that breaks on scene reload
- NavigationServer map sync is async in Godot 4.4+ — no reliable way to know when navigation is ready

The working pattern for simple FPS arenas:

```gdscript
# Distance-based state machine — no navmesh needed
var dist := _flat_distance_to(_target)
match _state:
    State.IDLE:
        if dist < DETECTION_RANGE:
            _state = State.CHASE
    State.CHASE:
        var direction := _flat_direction_to(_target)
        velocity.x = direction.x * CHASE_SPEED
        velocity.z = direction.z * CHASE_SPEED
        move_and_slide()  # handles obstacle sliding
```

### Timer-Based Attacks, Not Coroutines

Never use `await` in combat logic called from `_physics_process`. Use Timer nodes instead:

- `await` in per-frame functions spawns coroutines that pile up and cause hangs
- Multiple `_attack_loop()` coroutines can run simultaneously if state changes rapidly
- Timer nodes are deterministic, stoppable, and don't leak

```gdscript
# GOOD — Timer node
_attack_timer.start(ATTACK_COOLDOWN)

# BAD — coroutine from physics
func _attack_loop() -> void:
    while attacking:
        deal_damage()
        await get_tree().create_timer(1.0).timeout  # accumulates coroutines
```

## Lint and Format

After each implementation phase, run:

```bash
gdformat scenes/**/*.gd
gdlint scenes/**/*.gd
```

Fix all issues before moving on. Code must pass both checks cleanly.

## Scene Reload

- Always use `get_tree().change_scene_to_file.call_deferred()` for restart — never `reload_current_scene()` (breaks NavigationServer, physics state)
- Never call `change_scene_to_file()` directly from a signal handler — must be deferred or causes physics callback errors
- On player death, set `collision_layer = 0` to detach from all physics interactions before scene reload

## Material Sharing Trap

Scene instances share SubResource materials. Modifying a shared material (e.g., flash color) changes ALL instances. Always duplicate in `_ready()`:

```gdscript
_mesh.set_surface_override_material(0, _mesh.get_surface_override_material(0).duplicate())
```

## HiDPI / Retina Displays

Set a design resolution with `canvas_items` stretch mode in project.godot — Godot scales all UI automatically:

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

Without this, UI elements (crosshairs, health bars, text) are tiny on Retina displays.

## Writing .tscn Files

Write scene files as text directly rather than relying on MCP `add_node` tools — MCP tools often fail to persist properties like positions, shapes, and collision layers. The .tscn text format is straightforward and reliable.

## Scene Node Lookups

Use `$Path/To/Node` for node references in scripts. Avoid `%UniqueNameInOwner` syntax — it fails silently in some scene instancing contexts (e.g., CanvasLayer children).

## Scene/File Hygiene

- `queue_free()` dead enemies and expired projectiles — they leak memory otherwise
- One script per scene root, named to match the scene
- Keep scripts under 200-300 lines; split if larger
- No autoloads unless genuinely global (this project needs none)
- No deep inheritance — prefer flat composition
- Only create files/scenes/scripts that are actually needed right now
