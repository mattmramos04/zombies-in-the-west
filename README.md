# Zombies in the West - Checkpoint 1

A small, playable **Godot 4.6** reverse tower defense prototype. You control the zombie horde invading a Wild West settlement. Tested with Godot **4.6.1 Standard** (GDScript; no .NET or plugins needed).

## Run

1. Extract `Zombies_in_the_West_Checkpoint_1.zip` to a normal folder. The GitHub integration did not allow publishing this checkpoint; the ZIP contains the complete project.
2. Open Godot's Project Manager, click **Import**, and select this folder's `project.godot`.
3. Wait for the PNG imports, then press **F6** to run the open scene or **F5** to run the project. F5 works immediately because the main scene is configured.
4. Select a zombie type and route, then click **Deploy zombie** or press **Space** repeatedly.

The Compatibility renderer keeps this small 2D prototype usable on modest hardware. The game scales from a 1280 x 720 canvas.

To add this checkpoint to the team repository, copy the extracted project files into a new branch of your existing checkout, commit them, and open a pull request. Keep the existing `.github` rules.

## Checkpoint scope

- One settlement, two predefined routes, and four stationary gunslingers.
- Walker: 20 supply, 65 HP, 56 speed, 14 damage per attack.
- Brute: 50 supply, 180 HP, 37 speed, 26 damage per attack.
- Zombies stop to attack reachable defenses, then resume their path and attack the town hall.
- Defenders shoot the closest zombie in range; tracers and health bars show combat.
- Supply starts at 140, regenerates at 7/sec, caps at 250, and awards 25 per destroyed defense.
- Destroy the 360-HP town hall within 100 seconds to win. Let the timer expire to lose.
- Pause/resume, restart, win/lose screen, 0.3-second deployment cooldown, and 50-unit cap.

**The resource rules are temporary design choices**, since the pitch leaves the economy undecided. A concentrated north-route horde is a straightforward first winning strategy. This is intentionally an easy engine checkpoint, not a balanced level.

## Controls

| Action | Key / UI |
| --- | --- |
| Select Walker / Brute | 1 / 2 |
| Select North / South route | Q / E |
| Deploy selected zombie | Space / Deploy zombie |
| Pause or resume | P / Pause |
| Restart | R / Restart / Play again |

## Where to extend it

| File | Responsibility |
| --- | --- |
| `scenes/main.tscn` | Project entry scene |
| `scripts/game.gd` | Level routes, defense placement, supply, game state, UI, town health |
| `scripts/zombie.gd` | Zombie stats, waypoint movement, attack behavior, damage/death |
| `scripts/defender.gd` | Stationary defense targeting and shooting |
| `scripts/actor_visual.gd` | Five-frame animation and health-bar display |
| `assets/zombie.png` | Original supplied `spritesheet.png` |
| `assets/defender.png` | Original supplied `spritesheet_1.png` |
| `tests/smoke_test.gd` | Automated engine/gameplay checks |

Both supplied PNG sheets are used unchanged. Each has five 32 x 32 frames in a 4-column layout (four frames on the first row, one on the second). Brutes reuse the green animation with a blue ring and larger scale. The brown sheet is temporarily assigned to defenders. The GIF previews duplicate these animations and are not required at runtime. Town buildings and scenery are drawn placeholder shapes.

Balance constants are at the top of `game.gd`, unit stats live in `Zombie.STATS`, and both routes/defense locations are defined in `game.gd`. UI and actors are constructed in code so the initial project stays small; they can later be moved into reusable `.tscn` scenes.

Not implemented yet: campaign progression, permanent upgrades/unlocks, formations, special abilities, dynamic pathfinding, physical crowd separation, sounds, or finished art. Combat is range-based; shots are visual tracers and apply damage immediately.

## Verify

From the project folder, with the Godot executable on your PATH:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --fixed-fps 60 --script tests/smoke_test.gd
```

On Windows, use your Godot console executable (for example `Godot_v4.6.1-stable_win64_console.exe`) instead of `godot` if needed.

The first command imports resources and checks project loading. The second tests deployment costs/cooldowns, pause, insufficient supply, route/type selection, defense rewards, a real combat victory, game-over deployment blocking, and timeout defeat. It prints `Smoke tests: PASS` and exits with code 0 on success.
