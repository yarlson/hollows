# Hollows

A horror FPS built with Godot 4.6. Dark labyrinths, limited ammo, flashlight-dependent navigation, and enemies that hunt by line of sight.

[Read the full story](https://yarlson.dev/blog/godot-fps-with-my-daughter/)

## The Game

You wake up in a labyrinth. It's dark. You have a flashlight, a gun with 30 rounds, and no explanation. Find the key, unlock the door, reach the exit. Try not to die.

**Three enemy types** share a single AI script with exported parameters:

- **Standard** — moderate speed, moderate health, the baseline threat
- **Runner** — fast, fragile, ambush predator
- **Brute** — slow, tanky, hits like a freight train

**No imported assets.** Geometry is GridMap walls and CSG primitives. Lighting does all the visual work — SpotLight3D ceiling lamps, volumetric fog, SSAO, desaturated color grading. Sound effects are procedurally synthesized from sine waves and noise envelopes. Background music generated via Suno.

## Running

Requires Godot 4.6+.

```
# Clone and open in Godot editor
godot project.godot
```

Press F5 to play.

## Controls

| Key        | Action            |
| ---------- | ----------------- |
| WASD       | Move              |
| Mouse      | Look              |
| Left Click | Shoot             |
| Space      | Jump              |
| F          | Toggle flashlight |

## Architecture

Two-tier scene tree: persistent game shell + swappable level scenes.

- `game.tscn` — owns Player, HUD, run-global state (kills, time, level index)
- `level_*.tscn` — each level provides SpawnPoint, Enemies, KeyPickup, Door, ExitTrigger
- Signal-driven: "call down, signal up" — no autoloads, no singletons
- Duck-typed damage via `has_method(&"take_damage")`

## Credits

- Game code and design — Yar Kravtsov
- Monster art, boss design, and lore — TBD (creative director is 13 and just getting started)
