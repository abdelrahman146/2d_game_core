# Termination Protocol

> A fired employee collects their severance one coin at a time — by grabbing cash mid-air after being thrown out of a 10,000-floor skyscraper.

## Overview

Termination Protocol is an endless vertical-fall arcade game for mobile. The player controls an employee who has been hurled out of a skyscraper window by their aggressive ex-manager. The only "severance package" is whatever cash and coins the player can snatch while plummeting past hazards, enemies, and deadly architecture.

The game world scrolls upward while the player stays mostly stationary on the vertical axis, moving only left and right to dodge dangers and collect money. One hit means death. The core tension comes from reading incoming chunk layouts, choosing when to free-fall at full speed versus wall-slide to slow the scroll, and threading through increasingly chaotic obstacle arrangements.

There is no bottom. The fall is infinite. Every run ends in death — the only question is how far and how rich the player gets before it happens.

## Identity

| Property        | Value                                          |
| --------------- | ---------------------------------------------- |
| Title           | Termination Protocol                           |
| Genre           | Endless arcade                                 |
| Subgenre        | Vertical-fall, obstacle avoidance, score-chase |
| Playstyle       | Twitchy, reactive, one-more-run addictive      |
| Camera          | Vertical scroll (chunks move upward)           |
| Art direction   | Pixel art, 32×32 base tile size                |
| Orientation     | Portrait                                       |
| Target platform | Mobile                                         |
| Scope           | Full release                                   |

## Core hook

The player is always falling. There is no safe state. Every second spent alive is a second closer to the next hazard, and the scroll speed keeps increasing. The wall-slide mechanic creates a constant risk-reward decision: slide to slow down and buy reaction time, but risk getting crushed by faster-falling hazards that catch up. Free-fall to outrun dangers from above, but leave less time to react to what's below.

Cash placement amplifies this tension. Large piles of money sit in the most dangerous spots — tight corridors, narrow gaps between hazards, the center of enemy crossfire. The leaderboard combines distance and cash, so the safest path is never the highest-scoring path.

## Gameplay loop

### Moment-to-moment

The player reads the incoming chunk layout as it scrolls into view from below. They use a virtual joystick to move left and right — movement is instant and responsive, critical for a fast-paced game where tapping or multi-tapping would be too imprecise. When approaching a tower wall or platform side, they can slide against it to slow the scroll speed and buy time to assess the next threat. They grab cash and coins along the way.

When moving left or right, the character performs a flipping animation. When sliding on a wall or platform side, the character clings to the surface and falls slower.

### Session structure

1. The run begins immediately — the employee is thrown from the window.
2. Chunks scroll upward with increasing speed. Early chunks are simpler; later chunks draw from harder archetypes and denser hazard layouts.
3. Between every few challenge chunks, a connector provides a brief visual breather with low or no threat.
4. The player dies on any contact with a hazard, platform floor, or enemy contact or attack.
5. On death, the player can watch a rewarded ad to continue once per run.
6. The game-over screen shows final score (distance + cash) and leaderboard position.

### Long-term progression

There is no meta-progression. No unlocks, no upgrades, no permanent power-ups. Every run starts equal. The only persistent state is the global leaderboard. Mastery is the progression system.

## Player

### Character

A regular office employee — just fired, still in work clothes, tumbling through the air. The character is small (fits within the 32×32 tile grid) and visually expressive despite the pixel art scale.

### Controls and input

| Action     | Input                              | Effect                                                       |
| ---------- | ---------------------------------- | ------------------------------------------------------------ |
| Move left  | Virtual joystick — tilt/push left  | Instant horizontal movement to the left; triggers flip animation |
| Move right | Virtual joystick — tilt/push right | Instant horizontal movement to the right; triggers flip animation |
| Wall-slide | Move into a tower wall or platform side | Cling to surface; trigger wall-slide animation; fall speed (scroll speed) reduced to ~50% |
| Release    | Move away from wall                | Resume normal fall speed; trigger default falling animation   |

The virtual joystick is chosen over tap controls because the game demands instant, fluid, continuous movement. Tapping and multi-tapping are too imprecise and fatiguing for the speed and precision this game requires.

Movement is strictly horizontal. The player has no vertical control — gravity and scroll speed are constant (modified only by wall-slide).

### Abilities and actions

- **Horizontal dodge:** Move left and right to weave between hazards. This is the primary survival tool.
- **Wall-slide:** Contact a wall or platform side to slow the scroll. Useful for timing gaps in moving hazards, but dangerous if faster-falling objects are above.
- **Flip animation:** Visual feedback when changing horizontal direction. Purely cosmetic but adds game feel.

## Mechanics

### Resources

There are no managed resources. No health bar, no ammo, no energy. The player has exactly one hit point — any contact with a hazard or enemy attack is instant death.

### Scoring

Score is calculated from two components:

| Component | Description                                   |
| --------- | --------------------------------------------- |
| Distance  | How far the player has fallen (in game units) |
| Cash      | Total value of coins and bills collected       |

The final score combines both. The global leaderboard ranks players by this combined score.

### Power-ups and collectibles

| Collectible | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| Coins       | Common, scattered throughout chunks. Small score value.      |
| Cash bills  | Less common, higher value. Often placed in risky positions.  |

<!-- TODO: clarify — are there any power-ups (shields, magnets, slow-time) planned, or strictly coins/cash only? -->

### Inventory / loadout

None. The player has no equipment, items, or loadout selection.

## Challenge and difficulty

### Core challenge

Reading the incoming chunk layout and making split-second dodge decisions. The player must constantly evaluate:

- Is it safer to free-fall or wall-slide right now?
- Which horizontal lane is the safest path through this chunk?
- Is the obvious safe path actually a trap (Bait and Switch archetype)?
- Can I grab that pile of cash without dying?

### Difficulty scaling

Difficulty increases through the chunk selection system. The game uses a difficulty cursor that advances with distance. As the cursor increases:

- Harder chunk archetypes become available
- Chunk hazard density increases
- Scroll speed accelerates over time (base speed + acceleration, capped at a maximum)

Chunks are selected from a pool filtered by difficulty proximity. A custom chunk selector prevents excessive repetition of the same archetype category. Connectors appear every few challenge chunks to provide brief breathing room.

### Death and failure

One-hit death. Any contact with a hazard, enemy, enemy projectile, or lethal surface kills the player instantly. There are no checkpoints, no lives counter, and no health bar.

On death, the player may watch one rewarded ad per run to continue from where they died. After that, death is final.

## World and levels

### Structure

The world is an infinite vertical corridor. It is composed of **chunks** — pre-designed sections of obstacles, enemies, and collectibles — stitched together at runtime. There is no fixed level structure; the game generates an endless sequence of chunks.

Chunks belong to **archetypes** that define their design philosophy:

| Archetype       | Design goal                                                        |
| --------------- | ------------------------------------------------------------------ |
| Friction Puzzle | Forces wall-slide usage; tight corridors with timed hazard gaps    |
| Traffic Jam     | Punishes wall-slide; open areas with fast-falling hazards from above |
| Bait and Switch | Misdirection; the obvious safe path is a trap                     |
| Needle Thread   | Pure precision; static geometry with tight weaving requirements    |
| Arena           | Chaos management; multiple interacting hazard types simultaneously |

Each archetype can produce many distinct chunk layouts. The game aims for a large number of chunks to keep runs feeling fresh.

**Connectors** are simple, low-threat, visually appealing transitional sections placed between challenge chunks. They give the player a moment to breathe and appreciate the art.

### Environments

The player falls through the gap between two massive skyscrapers. Only the inner sides of these towers are visible — they form the left and right walls of the playable corridor. The tower walls use a **parallax scrolling effect** to create the sensation of continuous falling even though the player is vertically stationary.

Chunks and platforms are designed as structures that connect the two towers or protrude from them — bridges, scaffolding, pipes, ledges, mounted equipment, and other architectural elements that logically belong on the exterior of giant buildings.

The **background** is a layered cascade of distant skyscrapers, also parallax-scrolled at different rates to create depth. Multiple parallax layers give the scene a sense of scale and velocity.

### Navigation

There is no navigation. The player moves only left and right within the gap between the two towers. The world scrolls upward automatically. The player cannot go back up or choose a path — they fall through whatever the chunk selector provides.

## Enemies and hazards

The enemy and hazard roster is actively evolving. The following types are confirmed but the list is expected to grow over time:

### Enemy types

| Enemy              | Behavior                                                     |
| ------------------ | ------------------------------------------------------------ |
| Scooter            | Charges horizontally toward the player at high speed         |
| Laser drone        | Hovers in place or patrols; fires laser beams at the player  |
| Bomb drone         | Flies and drops bombs downward toward the player             |
| Loyal employee     | Stands on platforms; swings briefcases at the player on proximity |
| Scanner            | Static or mounted; fires cartridges horizontally across the corridor |

### Bosses

None. The game is an endless arcade experience with no boss encounters. The manager is the narrative antagonist but does not appear in gameplay.

### Environmental hazards

| Hazard          | Behavior                                                      |
| --------------- | ------------------------------------------------------------- |
| Spiky gates     | Open and close on a timer; lethal when closed                 |
| Robotic arms    | Extend from tower walls on a pattern; lethal on contact       |
| Tower walls     | The two building sides forming the corridor; safe to wall-slide on unless a hazard is mounted on that section |
| Platform floors | The top surface of platforms is **lethal** — the player is falling, so landing on a platform floor means a fatal impact |
| Platform sides  | The left and right edges of platforms are **safe** — the player can slide along them just like tower walls |

The platform collision rule (sides safe, floor lethal) is a core design constraint. It forces the player to dodge around platforms horizontally rather than land on them, and it makes wall-sliding on platform edges a viable survival tool.

## Narrative and setting

### Setting

A dystopian corporate world where an employee's termination is literal. The game takes place in the narrow gap between two 10,000-floor mega-skyscrapers, with a layered cityscape visible in the background. The tone is dark comedy — the absurdity of the premise is played for laughs even though the gameplay is intense.

### Story

An employee is fired by an abusive manager. Rather than processing severance paperwork, the manager throws the employee out of the window from the 10,000th floor. The employee's only option is to grab whatever cash and coins they can find on the way down — that's their severance now.

There are no cutscenes, dialogue trees, or story progression. The narrative is the premise, delivered through the game's visual design and the absurdity of the situation.

### Characters

| Character | Role                                                        |
| --------- | ----------------------------------------------------------- |
| Employee  | The player character. Fired, falling, grabbing cash.        |
| Manager   | The antagonist. Appears only in the premise, not in gameplay. |

## Audio and feel

### Music

Not yet finalized. The target direction is arcade and exciting — fast-paced, high-energy tracks. Retro or chiptune styles would complement the pixel art aesthetic.

<!-- TODO: clarify — specific music style once decided -->

### Sound design

Not yet finalized. Key audio cues to design for:

- Cash/coin collection (satisfying pickup sound)
- Enemy attack warnings (laser charge, bomb drop, scooter rev)
- Wall-slide activation and release
- Death impact
- Hazard activation (gate closing, arm extending)

<!-- TODO: clarify — specific sound design direction once decided -->

### Game feel

- **Flip animation** on horizontal direction change adds visual responsiveness
- **Wall-slide cling** provides clear visual and mechanical feedback
- **Screen shake** and **hit-stop** on death to emphasize the finality of one-hit kills
- **Cash collection** should feel rewarding — particle effects, satisfying sounds, score pop-ups
- **Speed ramping** should be felt through visual motion blur or parallax intensity changes

<!-- TODO: clarify — specific juice/game-feel elements once decided -->

## Multiplayer and social

Single-player only. The social component is a **global leaderboard** ranking players worldwide by combined score (distance + cash). The leaderboard drives competition and replayability.

## Technical notes

- **Engine:** Godot 4, using the 2D game core addon (`addons/game_core`)
- **World system:** Chunk-based streaming via `GCWorldController` + `GCStreamChunkSource`. Chunks scroll upward; player is vertically stationary.
- **Chunk selection:** Custom `GCChunkSelector` subclass handles difficulty ramping, anti-repetition, and archetype pool filtering based on a difficulty cursor that advances with distance.
- **Tile size:** 32×32 pixels
- **Collision layers:** Player, Walls, Enemies, Projectiles, Hazards, Detection, Collectibles (7 layers)
- **Physics model:** `CharacterBody2D` for the player; `move_and_slide()` for horizontal movement. Vertical movement is handled by the scroll driver, not player physics.
- **Scroll driver:** `GCScrollDriver` controls upward scroll speed with configurable base speed, acceleration, and max speed. Wall-slide applies a speed modifier (~50%).
- **Monetization integration:** Ad SDK for interstitial and rewarded ads. Rewarded ad triggers on death for one-continue-per-run.
- **Target frame rate:** 60 FPS
- **Portrait resolution:** The game must be fully responsive across all mobile screen aspect ratios with no black bars or letterboxing. Use Godot's stretch mode and expand settings to adapt the visible area to any screen shape while keeping the pixel art crisp. The corridor width (distance between the two towers) remains constant; extra vertical space is revealed on taller screens.
- **Parallax layers:** Multiple background layers (distant cityscape, mid-ground buildings, near-ground structures) scrolling at different rates to create depth and reinforce the falling sensation. Tower wall edges use their own parallax rate.
