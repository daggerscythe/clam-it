# Clam It: Game Design Document

A 2D pearl farming game built in Godot 4.7. The player grows pearls inside clams on the sea floor, keeps them clean, speeds them up with chum, defends them from crabs, and sells the harvest at the surface to earn money and experience.

This document describes the game as it is currently built. All numbers listed here match the values in the code and are meant to be tuned during playtesting.

---

## Table of Contents

1. [Game Overview](#1-game-overview)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Controls](#3-controls)
4. [Core Mechanics](#4-core-mechanics)
5. [Stage 1: Tutorial](#5-stage-1-tutorial)
6. [Stage 2: Freeplay](#6-stage-2-freeplay)
7. [User Interface](#7-user-interface)
8. [Saving and Loading](#8-saving-and-loading)
9. [Technical Architecture](#9-technical-architecture)
10. [Tunable Values Reference](#10-tunable-values-reference)
11. [Assets](#11-assets)
12. [Building and Playtesting](#12-building-and-playtesting)
13. [Future Features](#13-future-features)

---

## 1. Game Overview

| Item | Detail |
|---|---|
| Engine | Godot 4.7 (Forward Plus renderer) |
| Genre | 2D farming and light defense |
| Design resolution | 1920 x 1080 |
| Default window size | 1280 x 720, resizable |
| Scaling | Stretch mode `canvas_items`, aspect `keep` (letterboxed at any window size) |
| Structure | Stage 1 (guided tutorial, Levels 1 to 4) followed by Stage 2 (freeplay, Level 5 onward) |

The game has two stages. The tutorial introduces one tool at a time through short milestones. Once the player reaches Level 5, freeplay begins: every level-up offers an upgrade, new pearl types unlock along the way, and crabs gradually become more numerous.

---

## 2. Core Gameplay Loop

```
Plant a pearl dummy
        ↓
Keep it clean (Brush) and speed it up (Chum)
        ↓
Chum attracts crabs → scare them off (Sonic Flare)
        ↓
Pearl matures → harvest it
        ↓
Sell at the surface dock → earn money and XP
        ↓
Level up → unlock pearls and upgrades → plant again
```

1. **Start growth.** Click an empty clam to plant a pearl dummy.
2. **Maintain and accelerate.** Scrub away sediment so growth keeps its full speed, and apply chum to jump the pearl's progress forward.
3. **Defend.** Heavy chum use draws crabs. Fire a sonic flare before a crab reaches a clam and destroys the pearl.
4. **Harvest and sell.** Collect the finished pearl, then click the surface dock to sell everything you are carrying for money and XP.

---

## 3. Controls

| Tool | Keys | Unlocks at | What it does |
|---|---|---|---|
| Hand | `1` or `H` | Level 1 | Plants a dummy in an empty clam, harvests a ready pearl, sells pearls at the dock |
| Brush | `2` or `B` | Level 2 | Scrubs sediment off a growing clam |
| Chum | `3` or `C` | Level 3 | Instantly advances a growing pearl |
| Sonic Flare | `4` or `F` | Level 4 | Scares off every crab within the flare radius around the click |
| Pause | `Esc` or the pause button | Always | Opens the pause menu; also closes the shop or the settings panel |

The mouse cursor changes to the selected tool's icon, and the toolbar in the bottom-left corner highlights the active tool. Selecting a tool that has not been unlocked yet posts a warning in the chat log.

---

## 4. Core Mechanics

### 4.1 Clams and Pearl Growth

Every clam is always in one of three states:

| State | Appearance | What the Hand tool does |
|---|---|---|
| `EMPTY` | Closed clam, no pearl | Plants a pearl dummy |
| `GROWING` | Closed clam with the dummy sprite and a green progress bar | Nothing (the chat log says the pearl is still growing) |
| `READY` | Open clam showing the finished pearl | Harvests the pearl |

**Growth rules**

- Progress only advances while the clam is `GROWING`.
- Each frame, `growth_progress += delta * growth_speed_multiplier`.
- `growth_speed_multiplier = 1.0 - (sediment_level * 0.9)`. Growth never stops completely: a fully dirty clam still grows at 10% speed.
- When `growth_progress` reaches `growth_time`, the pearl matures. At that exact moment its pearl type is rolled (see [6.3](#63-pearl-types)), so the open clam shows the correct pearl.
- The growing dummy sprite is the same for every pearl type, so what's inside stays a surprise until the clam opens.
- A green bar above the clam shows growth progress. It is hidden while the clam is empty or ready.

### 4.2 Sediment and the Scrub Brush

Sediment starts building up once the player reaches Level 2.

- Sediment only builds up while a clam is `GROWING`, at `0.15` per second, up to a maximum of `1.0`.
- Right after planting, and right after a clam is scrubbed fully clean, there is a **4 second grace period** during which no sediment builds up.
- Each Brush click removes `0.5` sediment. If that brings the clam to zero, the grace period starts again.
- The sediment overlay sprite appears once sediment passes `0.1`, and its opacity matches the sediment level.
- Scrubbing does not award XP. It was removed because it caused players to level up too early.

### 4.3 Chum

- Chum works only on `GROWING` clams. Using it on an empty or ready clam posts a warning.
- Each click instantly adds **3 seconds** of growth progress. It is a one-time jump, not a temporary speed boost.
- Each click also adds **2 points** to the chum meter and awards **2 XP**.
- If the jump completes the pearl, the clam matures immediately.

### 4.4 The Chum Meter and Crabs

The chum meter is shown in the top-right corner of the screen, with a white tick marking the crab spawn threshold.

**The meter**

| Property | Value |
|---|---|
| Range | 0 to 10 |
| Added per chum click | 2 |
| Decay | 0.2 per second, always |
| Base crab threshold | 4 (raised by the Crab Tolerance upgrade, see [6.4](#64-upgrades)) |

**Spawning**

- Crabs can only spawn once the player is Level 4 or higher.
- A crab spawns only when the meter is at or above the threshold, fewer than the maximum number of crabs are on screen, and at least one clam holds a pearl (growing, or mature and not yet harvested).
- The time between spawns shrinks as the meter fills: 6 seconds right at the threshold, down to 1.5 seconds with a full meter.
- Crabs enter from the left or right edge of the screen at a random height inside the water (y between 220 and 1050).
- The maximum number of crabs on screen starts at 4 and increases in freeplay (see [6.6](#66-crab-difficulty-scaling)).

**Behavior**

| Phase | What happens |
|---|---|
| Seeking | The crab picks a random clam that holds a pearl, either still growing or mature and waiting to be harvested, and walks toward it at 80 px/s. |
| Retargeting | A pearl maturing does not change the crab's target. The crab only picks a new random target when its clam becomes empty (harvested, or destroyed by another crab). If no clam holds a pearl, it leaves. |
| Attacking | The crab stops next to the clam. Growth and sediment freeze, and the green bar turns red and fills over 2 seconds. Mature pearls can be attacked too. |
| Saved by harvesting | If the player harvests a mature pearl while a crab is attacking it, the pearl is kept, the attack is cancelled, and the crab retargets. |
| Success | When the red bar fills, the pearl and any sediment are destroyed, the clam becomes empty, and the crab flees. |
| Fleeing | The crab walks off screen at double speed and is removed, which frees a spawn slot. |

Because targets are random, crabs tend to spread across the pond, but several crabs can still end up on the same clam. When the first one destroys the pearl, the others retarget. Leaving finished pearls unharvested is risky: they keep attracting crabs until they are collected.

### 4.5 Sonic Flares

- Unlocked at Level 4. With the Sonar tool selected, clicking anywhere in the water fires a flare at that point.
- Every crab within the flare radius flees immediately. A crab that was attacking lets go: a growing pearl resumes from where it was, and a mature pearl stays ready to harvest.
- **Radius:** 250 px at the start, raised by the Bigger Flare upgrade up to 500 px.
- **Animation:** a 5-frame shockwave (`sonic_flare_animation.png`, each frame 164 x 164) plays at the click point. It is scaled so that its outermost ring matches the real radius, which lets the player see exactly how far the flare reaches. The animation expands over 0.4 seconds and then fades out over 0.25 seconds.
- **Ammo:**

| Source | Amount |
|---|---|
| Starting ammo | 0 |
| Reaching Level 4 | +5 |
| Every level-up after Level 4 | +1 |
| Buying in the shop | $30 each, any time after Level 4 |

- The ammo count is shown on the Sonar slot of the toolbar. Firing with no ammo posts a warning in the chat log.

### 4.6 Harvesting and Selling

- Harvesting a ready pearl adds it to the player's inventory, broken down by pearl type, and awards 3 XP.
- Clicking the surface dock with the Hand tool sells every pearl being carried. Each pearl type has its own price and XP value (see [6.3](#63-pearl-types)).
- Floating text appears at the click point, showing the money earned or "No pearls to sell!".
- Selling is the main source of XP and the main way the player levels up.

---

## 5. Stage 1: Tutorial

**Goal:** teach every mechanic one at a time through short milestones, ending with the first large sale.

### 5.1 Level Progression

| Level | Unlocks | Active clams | Growth time |
|---|---|---|---|
| 1 | Hand tool | 1 | 2 s |
| 2 | Scrub Brush, sediment starts building up | 2 | 10 s |
| 3 | Chum | 3 | 10 s |
| 4 | Sonic Flare, crabs, +5 flares | 3 | 30 s |
| 5 | Freeplay begins (see [Stage 2](#6-stage-2-freeplay)) | 3 | 30 s |

Before Level 1 begins, a text-only welcome popup explains the basics: planting, waiting for growth, harvesting, and selling at the dock. After that, each unlock pauses the game with a popup that shows the tool's icon, how to use it, and what it does.

The very short 2 second growth time at Level 1 lets a new player complete their first pearl cycle almost immediately.

### 5.2 XP in Stage 1

| Action | XP |
|---|---|
| Plant a dummy | 2 |
| Harvest a pearl | 3 |
| Apply chum | 2 |
| Sell a Classic pearl | 40 |
| Scrub | 0 |

Level thresholds are calculated from the number of pearls the player must sell, rather than typed in by hand. One full pearl cycle (plant + harvest + sell) is worth `2 + 3 + 40 = 45 XP`.

| Level-up | Pearls sold | XP for this level | Total XP needed |
|---|---|---|---|
| 1 → 2 | 1 | 45 | 45 |
| 2 → 3 | 2 | 90 | 135 |
| 3 → 4 | 3 | 135 | 270 |
| 4 → 5 | 3 | 135 | 405 |

Because of this, the player can only level up by actually selling pearls; repeating small actions alone will not get them there. Only Classic pearls can appear during Stage 1.

---

## 6. Stage 2: Freeplay

Freeplay starts the moment the player reaches Level 5. From then on, every level gives an upgrade choice, new pearl types unlock on odd levels up to 15, and the crab threat slowly grows.

### 6.1 XP Curve

Each freeplay level costs more than the one before it, but the cost rises gently rather than exponentially:

```
XP for freeplay level N = FREEPLAY_BASE_XP + FREEPLAY_STEP * N^1.5
FREEPLAY_BASE_XP = 300, FREEPLAY_STEP = 60
N = 1 for the Level 5 → 6 step
```

| Step | N | XP needed |
|---|---|---|
| 5 → 6 | 1 | 360 |
| 6 → 7 | 2 | 469 |
| 7 → 8 | 3 | 611 |
| 8 → 9 | 4 | 780 |
| 9 → 10 | 5 | 970 |
| 14 → 15 | 10 | 2197 |
| 29 → 30 | 25 | 7800 |

Early freeplay levels come quickly, while late levels are a longer investment without becoming a grind. The XP bar shows progress within the current level (for example `120 / 360`).

### 6.2 Level-Up Rewards

| Reward | When |
|---|---|
| Upgrade pick (choose 1 of 3) | Every freeplay level |
| New pearl type | Odd levels from 5 to 15 |
| +1 sonic flare | Every level after 4 |
| +1 maximum crab | Every 3 levels after 5 (8, 11, 14, ...) |

**Popup order.** On a level that unlocks a pearl, the pearl popup appears first and the upgrade pick second. If one sale awards several levels at once, all of their popups are queued and shown one after another. The game stays paused until the last popup is closed.

### 6.3 Pearl Types

Each pearl type only changes the mature pearl sprite. The growing dummy looks the same for every type.

| Pearl | Description | Price | Sell XP | Weight | Unlocks |
|---|---|---|---|---|---|
| Classic | Inspired by Akoya pearls: cream-white with a soft rose sheen, perfectly round | $200 | 40 | 40 | Level 1 |
| Blush | Inspired by freshwater pearls: soft pink-lavender tint, slightly uneven (baroque) shape | $300 | 50 | 22 | Level 5 |
| Tahitian | Dark charcoal base with peacock green and violet overtones, round | $450 | 65 | 15 | Level 7 |
| Golden South Sea | Warm golden champagne color, large and glossy | $650 | 85 | 10 | Level 9 |
| Conch | Pink to salmon-orange with a wavy "flame" surface pattern, slightly oval | $900 | 110 | 7 | Level 11 |
| Melo | Rich orange-brown, extremely glossy, one of the rarest pearls in the real world | $1200 | 140 | 4 | Level 13 |
| Abalone | Irregular blister-like shape with rainbow blue-green-purple nacre | $1600 | 180 | 2 | Level 15 |

**How the type is rolled**

- The roll happens when a pearl matures, not when it is harvested, so the open clam already shows the right pearl.
- Only unlocked types can come out. Each type's chance is its weight divided by the total weight of all unlocked types, so the odds adjust automatically whenever a new type unlocks.
- With all seven unlocked, the odds are: Classic 40%, Blush 22%, Tahitian 15%, Golden South Sea 10%, Conch 7%, Melo 4%, Abalone 2%.
- At Level 7, for example, only Classic, Blush and Tahitian are unlocked. Their weights add up to 77, so Tahitian has a 15 / 77 (about 19%) chance.

After Level 15, odd levels only give the upgrade pick.

### 6.4 Upgrades

#### Upgrade Types

| Upgrade | Effect per stack | Cap | Base cost | Cost multiplier |
|---|---|---|---|---|
| New Clam Slot | Unlocks the next pre-placed clam | 3 stacks (6 clams total) | $600 | 1.8 |
| Faster Growth | Growth time -2 s | 12 stacks (30 s down to 6 s, never below 5 s) | $300 | 1.35 |
| Bigger Flare | Flare radius +50 px | 5 stacks (250 to 500 px) | $250 | 1.4 |
| Crab Tolerance | Crab spawn threshold +0.5 | 6 stacks (4 up to 7 out of 10) | $250 | 1.4 |

- **Cost scaling:** `cost = base_cost * cost_multiplier ^ (stacks already owned)`. For example, clam slots cost $600, then $1080, then $1944.
- **Caps** are calculated from the effect values in the code, so changing an effect value moves its cap automatically. The caps keep upgrades from making the game trivial: growth time never drops below 5 seconds, the flare never covers the whole pond, and crabs can always eventually spawn.
- Upgrades are permanent. A later pick, of the same or a different type, never replaces an earlier one.
- The upgrade list is data-driven, so a new upgrade type only needs a new entry and its effect. More types are planned.

#### The Upgrade Pick

1. At each freeplay level-up, three different upgrade types are chosen at random from the ones that are not maxed out.
2. The player clicks a card, which gets a gold border.
3. The player then chooses one of two buttons:
   - **Buy Now:** pays the cost and applies the upgrade immediately. It is disabled if the player can't afford it.
   - **Save for Later:** adds the pick to the shop's Available tab so it can be bought later.
4. Saved picks count toward a type's cap, so a type is no longer offered once owned plus saved picks reach the cap.
5. If fewer than three types are still available, fewer cards are shown. If none are left, the pick is skipped.

### 6.5 Clam Slots

There are six clams, all placed in the scene ahead of time. The first three unlock by level, and the rest unlock through purchases.

| Clam | Position | Unlocks by |
|---|---|---|
| Clam | (788, 808) | Level 1 |
| Clam2 | (509, 905) | Level 2 |
| Clam3 | (1344, 866) | Level 3 |
| Clam4 | (1043, 955) | 1st New Clam Slot purchase |
| Clam5 | (1670, 902) | 2nd New Clam Slot purchase |
| Clam6 | (161, 868) | 3rd New Clam Slot purchase |

Each clam has two unlock settings: `unlock_level` (the player's level must be at least this) and `purchase_slot` (0 means level only; N means the Nth clam slot purchase). A clam is unlocked only when both conditions are met.

### 6.6 Crab Difficulty Scaling

The maximum number of crabs on screen grows by one every three levels after Level 5:

`max_crabs = 4 + floor((level - 5) / 3)`

| Levels | Max crabs |
|---|---|
| 4 to 7 | 4 |
| 8 to 10 | 5 |
| 11 to 13 | 6 |
| 14 to 16 | 7 |
| 29 to 30 | 12 |

This keeps crabs a real threat as the player stacks Bigger Flare and Crab Tolerance upgrades.

### 6.7 Max Level

The player reaches max level once **every pearl type is unlocked** and **every upgrade type is owned or saved up to its cap**. At that point leveling stops, and the XP bar fills completely and reads **MAX LEVEL**.

With the current caps there are 3 + 12 + 5 + 6 = 26 upgrade picks. With one pick per level from Level 5 onward, max level is **Level 30**.

---

## 7. User Interface

### 7.1 HUD Layout

| Area | Element |
|---|---|
| Top left | Level label and XP bar, money counter |
| Top right | Chum meter with threshold tick, pause button, shop button |
| Right side | Chat log (between the shop button and the pearl counter) |
| Bottom left | Toolbar: Hand, Brush, Chum and Sonar slots, with flare ammo on the Sonar slot |
| Bottom right | Pearl counter: one slot per unlocked pearl type |
| Above each clam | Green growth bar, which turns red during a crab attack |

### 7.2 Pearl Counter

- Shows one slot for each unlocked pearl type, each with that pearl's sprite and how many the player is carrying.
- Classic stays in the bottom-right corner, and each newly unlocked type adds a slot to its left. During Stage 1 only the Classic slot is shown; from Level 5 there are Classic and Blush, and so on.
- The count text has a white outline so it stays readable on dark pearls such as Tahitian.
- Slots are rebuilt on every level-up and whenever the scene loads.

### 7.3 Chat Log

- A semi-transparent panel on the right side of the screen that lists every game action, color-coded:

| Color | Used for | Examples |
|---|---|---|
| White | Information | Planting, chum progress, scrubbing |
| Green | Good news | Harvests, sales, purchases, flare hits, saving |
| Orange | Warnings | Crab approaching or attacking, no ammo, locked tools |
| Gold | Big events | Level-ups |

- It always scrolls to the newest message and keeps the last 60.
- It ignores the mouse, so flares can still be fired over it.
- Messages are kept when a save is loaded.
- Every message is also printed to Godot's output and log file.

### 7.4 Popups

| Popup | Contents |
|---|---|
| Welcome | Text-only introduction to planting, harvesting and selling, with a "Let's Go!" button. Shown once per launch and not shown again after loading a save |
| Level-up (tool or pearl) | Title, icon, how to use it, what it does, "Got It!" button |
| Upgrade pick | Three upgrade cards, "Save for Later" and "Buy Now" buttons, and a hint line |

All popups pause the game, and pausing is blocked while a popup chain is open.

### 7.5 Shop

Opened with the shop button in the top-right corner. It becomes available at Level 4, when flares can first be bought, and pauses the game while open.

| Tab | Contents | Visible from |
|---|---|---|
| Available | One card per upgrade type with saved picks, showing "xN waiting", the cost and a Buy button | Level 5 |
| Owned | One card per upgrade type owned, showing the number purchased and the total effect (for example "Growth time -6s total") | Level 5 |
| Supplies | A sonic flare card showing current ammo, the $30 price and a Buy button | Level 4 |

Each tab wraps its card row in a margin container, so the cards sit 25 px away from the edges of the tab. The bottom of the shop shows the player's current money. Buy buttons are disabled when the player can't afford the item.

### 7.6 Pause Menu and Settings

| Button | Action |
|---|---|
| Save | Writes the save file and shows "Game saved!" |
| Load | Loads the save file, or shows "No save file found." |
| Settings | Opens the settings panel |
| Exit | Quits the game |

**Settings** (custom checkboxes, mainly for testing):

| Toggle | Effect |
|---|---|
| Infinite Flares | Flares never run out; the ammo counter shows ∞ |
| Instant Clean | One scrub removes all sediment |
| Instant Chum | One chum click finishes the pearl |

Settings stay the same after loading a save but are not written to the save file.

---

## 8. Saving and Loading

- **File:** `user://savegame.json`. On Windows this is `%APPDATA%\Godot\app_userdata\ClamIt\savegame.json`.
- **What is saved:**
  - Level, XP, money, flare ammo
  - Pearls held, by type
  - Owned upgrade stacks and saved-for-later picks
  - Each clam's state, growth progress, sediment level and rolled pearl type
- **Not saved:** crabs, the chum meter, settings, and whether the welcome popup has been seen. Crabs and the chum meter reset when a save is loaded; settings and the welcome flag carry over for the rest of the session.
- **How loading works:**
  1. `PlayerProgress` restores its state from the file.
  2. The chum meter, crab counter and spawn timer are reset.
  3. The game unpauses and the main scene reloads.
  4. As each clam loads, it collects its own saved data by node name.
  5. No level-up popups appear.
- JSON turns every dictionary key into text, so number keys such as pearl and upgrade types are converted back into numbers when loading.

---

## 9. Technical Architecture

### 9.1 Autoloads

| Autoload | Responsibility |
|---|---|
| `Global` | Active tool and cursor, tool hotkeys, chum meter, crab spawning, settings toggles |
| `PlayerProgress` | Level and XP, money, flares, pearl data and rolls, upgrade data and effects, clam unlocks, crab scaling, max level, save and load, welcome popup flag |
| `GameLog` | Stores chat log history and sends each new message to the chat log UI |

### 9.2 Scenes

| Scene | Contents |
|---|---|
| `main.tscn` | Background, surface dock, six clams, HUD, toolbar, chat log, pearl counter, and the `PauseUI` layer with the welcome popup, level-up popups, shop and menus |
| `clam.tscn` | Area2D with the clam, pearl and sediment sprites, a collision shape, and the growth bar. Belongs to the `clams` group |
| `crab.tscn` | Area2D with the crab sprite and collision shape. Joins the `crabs` group |
| `floating_text.tscn` | Label that rises and fades out (used for sale results) |

### 9.3 Scripts

| Script | Role |
|---|---|
| `global.gd` | Tools, chum meter, crab spawning, settings |
| `player_progress.gd` | All progression data and rules, save and load |
| `game_log.gd` | Chat log messages and their colors |
| `clam.gd` | Clam states, growth, sediment, tool handling, maturing, crab attacks, whether the clam is a crab target, saving each clam |
| `crab.gd` | Random target selection, retargeting, attacking and fleeing |
| `main.gd` | Chum meter bar, XP bar, money label, firing flares |
| `flare_effect.gd` | Flare animation scaled to the flare radius |
| `tool_selector.gd` | Toolbar slots, ammo counter, shop button |
| `pearl_counter.gd` | Pearl counter slots, one per type |
| `chat_log.gd` | Chat log panel display |
| `surface_dock.gd` | Selling at the dock and the floating text |
| `intro_popup.gd` | Welcome popup shown once per launch |
| `level_up_popup.gd` | Popup queue for tool, pearl and upgrade popups |
| `upgrade_pick_popup.gd` | Choosing 1 of 3 upgrades |
| `upgrade_card.gd` | Reusable card built in code (`class_name UpgradeCard`) |
| `upgrades_menu.gd` | Shop tabs: Available, Owned, Supplies |
| `pause_ui.gd` | Pause menu, save and load, settings, exit; blocks pausing while the welcome or level-up popups are open |

### 9.4 Communication Between Systems

**Signals**

| Signal | Emitted by | Listened to by |
|---|---|---|
| `state_changed` | Clam | Crabs, to retarget when their target clam becomes empty (harvested or destroyed) |
| `level_changed` | PlayerProgress | Popups, toolbar, pearl counter |
| `money_changed` | PlayerProgress | Money label, shop |
| `upgrades_changed` | PlayerProgress | Shop |
| `message_added` | GameLog | Chat log |
| `closed` | Upgrade pick popup | Level-up popup queue |

**Groups:** `clams` and `crabs`, declared as global groups in the project settings.

**Input:** the Hand, Brush and Chum tools act on a clam through that clam's own `input_event`. The Sonar tool fires anywhere through `main.gd`'s `_unhandled_input`. Toolbar and shop buttons use up the click, so pressing a button never fires a flare.

### 9.5 Key Design Decisions

- **Growth time is always recalculated** as `max(base time for level - growth stacks * 2 s, 5 s)`. This runs on every level-up and every purchase, so a level-up can never erase a growth upgrade.
- **The pearl type is rolled when the pearl matures**, so the open clam shows the correct sprite while the growing dummy stays a surprise.
- **Clam slots are placed in the scene ahead of time** and unlocked by purchase, instead of being spawned while the game runs.
- **Deferred shop refresh.** The shop rebuilds its cards at the end of the frame, so a Buy button is never deleted while it is still handling its own click.
- **Upgrade cards are built entirely in code** (Panel + StyleBoxFlat), so no scene or art is needed for them.

---

## 10. Tunable Values Reference

| System | Constant | Value | File |
|---|---|---|---|
| Clams | `sediment_rate` | 0.15 / s | clam.gd |
| Clams | `chum_boost` | 3.0 s | clam.gd |
| Clams | `sediment_grace_period` | 4.0 s | clam.gd |
| Clams | Scrub amount | 0.5 | clam.gd |
| Chum meter | `CHUM_METER_MAX` | 10 | global.gd |
| Chum meter | `CHUM_PER_USE` | 2 | global.gd |
| Chum meter | `METER_DECAY_RATE` | 0.2 / s | global.gd |
| Crabs | `CRAB_SPAWN_THRESHOLD` (base) | 4 | global.gd |
| Crabs | `SPAWN_INTERVAL_MAX` / `MIN` | 6.0 s / 1.5 s | global.gd |
| Crabs | `CRAB_ATTACK_DURATION` | 2.0 s | global.gd |
| Crabs | `SPEED` / `FLEE_SPEED_MULTIPLIER` | 80 px/s / 2x | crab.gd |
| Crabs | `BASE_MAX_CRABS` / `LEVELS_PER_EXTRA_CRAB` | 4 / 3 | player_progress.gd |
| XP | Plant / Harvest / Chum / Sell Classic | 2 / 3 / 2 / 40 | player_progress.gd |
| XP | `LEVEL_PEARLS_REQUIRED` | [1, 2, 3, 3] | player_progress.gd |
| XP | `FREEPLAY_BASE_XP` / `FREEPLAY_STEP` | 300 / 60 | player_progress.gd |
| Growth | `LEVEL_GROWTH_TIMES` | [2, 10, 10, 30] s | player_progress.gd |
| Growth | `MIN_GROWTH_TIME` | 5 s | player_progress.gd |
| Flares | `FLARES_ON_UNLOCK` / `FLARES_PER_LEVEL` | 5 / 1 | player_progress.gd |
| Flares | `FLARE_PRICE` | $30 | player_progress.gd |
| Flares | `FLARE_BASE_RADIUS` / `FLARE_MAX_RADIUS` | 250 / 500 px | player_progress.gd |
| Upgrades | `GROWTH_SECONDS_PER_STACK` | 2 s | player_progress.gd |
| Upgrades | `FLARE_RADIUS_PER_STACK` | 50 px | player_progress.gd |
| Upgrades | `CHUM_THRESHOLD_PER_STACK` / `CHUM_THRESHOLD_MAX` | 0.5 / 7 | player_progress.gd |
| Upgrades | `STAGE1_CLAM_SLOTS` / `MAX_CLAM_SLOTS` | 3 / 6 | player_progress.gd |
| Chat log | `MAX_MESSAGES` | 60 | game_log.gd |

Pearl prices, XP values and weights live in `PEARL_DATA`, and upgrade names, costs and icons live in `UPGRADE_DATA`, both in `player_progress.gd`.

---

## 11. Assets

**Sprites** (`assets/sprites/`)

| Category | Files |
|---|---|
| Clams | `clam_empty_growing.png`, `clam_ready_open.png`, `pearl_dummy.png`, `sediment_overlay.png` |
| Pearls | `akoya_pearl.png` (Classic), `blush_pearl.png`, `tahitian_pearl.png`, `southsea_pearl.png`, `conch_pearl.png`, `melo_pearl.png`, `abalone_pearl.png` |
| Tools | `hand.png`, `brush.png`, `chum.png`, `sonic_flare_icon.png` |
| Effects | `sonic_flare_animation.png` (5 frames stacked vertically, each 164 x 164) |
| Upgrades | `new_clam_slot.png`, `growth_boost.png`, `increase_sonic_radius.png`, `chum_threshold_increase.png` |
| UI | `shop_icon.png`, `money.png`, `pause.png`, `upgrade_icon.png` |
| World | `underwater_bg.png`, `surface_dock.png`, `sand.png`, `crab.png` |

**Other**

- Font: Slackey (`assets/fonts/Slackey/`), set as the project's default font.
- Theme: `theme/slot_outline.tres`, used for toolbar and pearl counter outlines.
- The UI panels, cards and bars are built from ColorRect, Panel and StyleBoxFlat, so they need no image files.

---

## 12. Building and Playtesting

**Export setup**

- A **Windows Desktop** export preset writes a single `build/ClamIt.exe`, with the game data (PCK) embedded in the executable.
- Export templates must match the Godot version (4.7).
- Export without debug for playtest builds. Zip the executable and share it through Google Drive, Discord or a private itch.io page.
- Windows SmartScreen will warn that the publisher is unknown. Testers should click **More info → Run anyway**.
- For Mac testers, add a macOS preset with built-in ad-hoc code signing. Testers open the app by right-clicking it and choosing **Open**.

**Before each build**

- Remove any testing shortcuts (for example, starting at Level 5 or with extra money).
- Make sure all three settings toggles default to off.

**Collecting feedback**

Every chat log message is also written to Godot's log file. Testers can send `godot.log` and `savegame.json` from `%APPDATA%\Godot\app_userdata\ClamIt\` on Windows, or `~/Library/Application Support/Godot/app_userdata/ClamIt/` on macOS, so that a bug can be reproduced from the exact saved state.

---

## 13. Future Features

These ideas are planned or under consideration but are not built yet.

| Feature | Notes |
|---|---|
| Free clam placement | Let the player place new clam slots anywhere in the pond instead of fixed positions |
| More upgrade types | The pick and shop systems already read from a data table, so new types plug in easily |
| Flawless and Radiant pearls | Recolored versions of existing pearls (palette shift plus a sparkle overlay) to keep a new pearl every other level after Level 15 |
| Pearl collection log | A screen showing every pearl type the player has ever harvested, reusing the existing pearl sprites |
| Pond decorations | Cosmetic purchases as a second way to spend money alongside upgrades |
| Idle and offline growth | Clams keep growing while the game is closed |
| Audio settings | Volume controls in the settings panel |
| Pearl glow effects | A sparkle or glow overlay on higher-tier pearls |
| Prestige system | A reset for very late freeplay; likely beyond the scope of this project |
