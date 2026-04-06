## What

First-person shooter prototype built in Godot 4.6 with GDScript. Targets a minimal playable FPS: player movement, mouse-look, hitscan shooting, enemies with navigation AI, health/damage, HUD, and game loop (death + restart) in a single enclosed arena.

## Architecture

- Scene-centric layout: each gameplay entity is a scene + co-located script
- Flat composition, no deep inheritance, no autoloads
- "Call down, signal up" for node communication
- Duck-typed damage interface via `has_method(&"take_damage")`
- Inline enum state machine for enemy AI (not separate state nodes)

## Core Flow

Player spawns in arena → moves with WASD + mouse-look → shoots hitscan weapon → enemies chase via NavigationAgent3D → enemies deal melee damage → player health tracked via signals → death triggers game over UI → restart reloads scene.

## System State

- Player controller: movement, mouse-look, jump implemented
- Arena: CSG-based 30x30 enclosed space with 3 obstacles, sky, directional light
- NavigationRegion3D present but navmesh not yet baked
- RayCast3D present on camera but disabled (shooting not yet wired)
- Enemies, HUD, and game loop not yet implemented

## Capabilities

- CharacterBody3D player with lerp-based acceleration/friction
- Mouse-look using `screen_relative` (Godot 4.3+), yaw/pitch separated, pitch clamped +-89 deg
- CSG geometry arena with collision on Environment layer
- Procedural sky, directional light with shadows, ACES tonemap

## Tech Stack

- Godot 4.6.1 (Forward+ renderer)
- GDScript with mandatory static typing
- CSG primitives for level geometry
- No external assets or plugins
