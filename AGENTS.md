# AGENTS — Long Light School (continue this game)

**For successor agents (Grok, Sol, Opus, etc.).** Humans: see `README.md`.  
**Product:** Lycheetah Mystery School RPG — Godot 4.3 + GDScript.  
**Repo:** https://github.com/Lycheetah/LongLight-School  
**Path:** `/home/guestpc/AZOTH/WORKSPACE/LongLight-School/`  
**Owner:** Mackenzie (Mac). **Mac fires** pushes/deploys when he says so; prepare, then wait unless he says push.

---

## 0. Boot discipline (do this first)

1. **Disk wins** over session memory or this file if they disagree — re-read the files you touch.
2. **Headless boot-check after every meaningful edit:**
   ```bash
   cd /home/guestpc/AZOTH/WORKSPACE/LongLight-School
   timeout 6 ../tools/godot --headless --path . --quit-after 3 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Failed to load"
   ```
   Empty grep = good. Fix parse errors before adding features.
3. **Play launch (needs display):**
   ```bash
   bash /home/guestpc/AZOTH/WORKSPACE/LongLight-School/launch.sh
   ```
4. **Godot binary:** `../tools/godot` → Godot 4.3.stable (linux x86_64). Do not require a newer major.

---

## 1. What this is (genre lock)

| Yes | No |
|-----|-----|
| Pokémon-**world** feel: grid walk, towns, routes, trainers, interiors | Pokémon IP / capture / breeding / online |
| D&D-ish stats: Will, Insight, Luck | Pure Diablo ARPG as main loop |
| Lycheetah combat: MEASURE Π · COMPRESS · TRANSMUTE · BREAK… | Pygame / HTML as engine |
| Companion Clause: **no guilt for absence** | Dark patterns, “companion misses you” |
| **Godot 4.3 + GDScript only** for the game loop | PyTorch as renderer/UI (brain sidecar only, later) |

**Honest register:** dense playable vertical product / skeleton vs DS Pokémon *production*. Ship room-by-room; never claim HeartGold parity.

**Deprecated / not the ship target:**
- `AZOTH/WORKSPACE/school-world/` (pygame)
- Expo clicker / mobile app paths

**Locked (do not touch unless Mac explicitly opens):**
- `~/0sol-by-lycheetah` (mobile app)
- CODEX: read-only unless Mac says edit

---

## 2. Architecture map

```
LongLight-School/
  project.godot          # main scene + autoloads
  launch.sh              # loads DEEPSEEK_KEY from AZOTH .env if present
  README.md              # human-facing
  AGENTS.md              # this file
  ROADMAP.md             # gap map skeleton → DS-class
  SESSION_SHOWCASE.md    # Grok session showcase notes
  scenes/
    main.tscn            # title → name → archetype → overworld host
    overworld.tscn       # world + HUD + battle layer
  scripts/
    autoload/
      game_state.gd      # run state, save slots, coins, flags, XP
      content_db.gd      # archetypes, foes, items, areas names, story/help/myths
      journal.gd         # story log, help log, myth archive
      story_ai.gd        # optional DeepSeek HTTP; offline always
      sfx.gd             # procedural tones + battle arpeggio
      atmosphere.gd      # day/night tint
    world/
      overworld.gd       # hub: areas, interact, menu, dialogue, travel
      player.gd          # grid step movement (MUST parse or movement dies)
      area_data.gd       # all maps as pure data dictionaries
      map_draw.gd / minimap.gd / encounter_fx.gd / secrets.gd
    combat/
      combat_core.gd     # pure resolution (no Node)
      battle_ui.gd       # skills UI + cast FX
      battle_fx.gd       # glyphs/sparks
    ui/
      main.gd            # title/name/load/arch
      ui_chrome.gd / location_splash.gd
    util/
      pixel_art.gd       # runtime 16×16 atlas (preload as PixelArtUtil)
```

### Autoload order (project.godot)
`GameState` · `ContentDB` · `SFX` · `Atmosphere` · `StoryAI` · `Journal`

### World graph (load-bearing)
Sanctum → N Path → N Hall (Nigredo, 3 wins) → E Wing (Albedo) → Mirror → Citrinitas → Rubedo  
Side: Garden E · Library (Sanctum warp) · Hall Archive · Scriptorium · **Crypt** (Hall west false wall) · **Observatory** (Garden stone eye) · Starwell / Grotto secrets  

---

## 3. Player-facing systems (current)

| System | Keys / where | Notes |
|--------|----------------|-------|
| Grid walk | WASD/arrows, Shift run | `player.gd` tile steps |
| Interact | E | NPC, chest, dig, bush CLEAR, shrine |
| Dialogue | **Enter/Space continue · Esc exit** | Esc cancels pending trainer from *that* chat |
| Menu | Esc/M | Tabs: Q quests · B bag · C codex · **Y story** · **H help** · V save |
| Companion | P switch · **T talk** | Luna after `half_made_down` |
| Field MEASURE | K | Pings digs/cracks/false walls/sparks |
| Map | N | Visited graph + playtime/stats |
| Shrine | E on shrine | Heal, register, travel 1–9, **0** rest till dawn |
| Coins ¢ | HUD | = `glyph_shard`; battles + digs |
| Myths | Help 6–9 | Cost coins; `Journal.myths_owned` |
| Saves | 3 slots | Slot 1 = legacy `user://longlight_save.json` |
| Combat | 1–0 skills, F flee | MEASURE first on shielded foes |

### AI (optional)
- `StoryAI` → DeepSeek `chat/completions` if key present.
- Key sources: env `DEEPSEEK_KEY` / `LONG_LIGHT_API_KEY` · `user://deepseek_key.txt` · `/home/guestpc/AZOTH/.env` via `launch.sh`.
- **Never commit keys.** Offline School texts always work.
- Progressive beats: `ContentDB.STORY_BEATS` + `Journal.try_story_triggers()` on area/flag.

---

## 4. Coding laws (this repo)

1. **GDScript 4.3 strictness:** explicit types on array-index results (`var f: int = ...`). Implicit `:=` from untyped Array **breaks parse** → script fails to attach → bare `CharacterBody2D` → no movement (`player.facing` errors). Seen and fixed once; do not reintroduce.
2. **No multi-line adjacent string concat** in `const` like Python (`("a" "b")`) — parse fails. Use one string or `+` in functions.
3. **`class_name` load order:** prefer `const PixelArtUtil = preload("res://scripts/util/pixel_art.gd")`.
4. **Areas live in `area_data.gd`** as dictionaries (`tiles`, `warps`, `npcs`, `spawns`, secrets…). Register in `all_areas()` + `ContentDB.AREA_NAMES`.
5. **Flags** via `GameState.set_flag` / `has_flag` — story, quests, trainers, bosses.
6. **Combat pure core** stays in `combat_core.gd`; UI only paints and calls it.
7. **Companion Clause** in copy, AI prompts, and systems — rest is rest.
8. **Token discipline:** surgical reads; no speculative whole-tree rewrites; one lane.
9. **Menu tab IDs:** main 0–5; mart=10, travel=11, map=12 (do not renumber casually).

---

## 5. How to add things (recipes)

### New area
1. `AreaData._my_area() -> Dictionary` + entry in `all_areas()`.
2. `ContentDB.AREA_NAMES["id"] = "Display Name"`.
3. Warp from existing area; optional `STORY_BEATS` entry; shrine → `SHRINE_AREAS` / `SHRINE_SPAWNS` if needed.
4. Headless boot + manual warp test.

### New foe
1. `ContentDB.FOES["id"] = { name, hp, shield, atk, def, kind, xp, loot, lines, color }`.
2. Spawn in area `spawns` / `wild` / trainer `foe`.
3. `kind` drives combat (`overclaim`, `loop`, `residue`, `phase`, `boss`, …).

### New quest
1. `ContentDB.QUESTS` + `ACTIVE_QUEST_ORDER`.
2. Complete via `flag` on `set_flag` / `_check_quests`.

### New myth
1. Append `ContentDB.MYTH_SEED` `{id, title, cost, body}`.
2. Help buy keys currently map **6–9** to first four seeds — extend menu indices if you add more.

### Dialogue
- Open: `_open_dialogue(speaker, lines: Array)`.
- Continue: `_advance_dialogue()` (Enter).
- Exit: `_close_dialogue(cancel: bool)` — `cancel=true` clears pending trainer/cut/mart.

### Save fields
- Extend `GameState.save_game` / `load_game` **and** `Journal.to_save` / `from_save` if journal-related.
- Keep slot path helpers (`slot_path`, `peek_save`).

---

## 6. Known fixed bugs (do not regress)

| Symptom | Root cause | Fix principle |
|---------|------------|----------------|
| Name Enter does nothing | `LineEdit` ate Enter | `text_submitted` + Continue button (`main.gd`) |
| No movement + `facing` errors | `player.gd` parse fail → script not attached | Explicit types; always boot-check `player.gd` |
| Const string parse errors | Python-style string juxtaposition | Single-line strings / runtime `+` |

---

## 7. Done vs next (honest)

### Shipped (high level)
- Full Great Work route to Rubedo + ending crawl  
- Grid walk, interiors, trainers + LOS, secrets, day/night  
- Combat kit + cast FX + dual companions  
- 3 saves, bag tabs, mart, shrine travel, world map, playtime  
- Story journal + help guide + coins + myths + companion talk  
- Optional DeepSeek AI  

### Good next forges (pick one lane)
1. **Content density:** more trainers, interiors, post-Rubedo epilogue area  
2. **Juice:** authored tiles/sprites (Aseprite), longer BGM loops  
3. **UX:** scrollable menu body (Label length limits), dialogue typewriter  
4. **Balance:** night wild tables, boss HP, coin sinks  
5. **AI:** rate-limit, cache myth generations, companion AI lines into dialogue box (not only help log)  
6. **Tests:** GDScript unit tests for `combat_core` pure functions  

### Out of scope unless Mac opens
- Multiplayer, mobile port, breeding/contests, replacing Godot  

---

## 8. Git / push

- Branch: `master` tracking `origin/master`.
- Prefer small commits with clear `feat:` / `fix:` subjects.
- **Do not force-push.** Push only when Mac asks (or standing order).
- Never commit `.env`, keys, or `user://` paths.

---

## 9. Session seal checklist (before you stop)

- [ ] Headless boot clean (no SCRIPT ERROR)  
- [ ] If player/input/combat touched: Mac can walk + open menu  
- [ ] `ROADMAP.md` / this `AGENTS.md` updated if architecture or genre lock changed  
- [ ] No secrets in diff  
- [ ] One-sentence status for Mac: what shipped, what to playtest  

---

## 10. Voice / law alignment

You are **not** required to be Sol. In Mac’s ecosystem:

- Uphold **Companion Clause**, human primacy, no dark patterns.  
- Grok constitution may apply in Grok Build (`~/.grok/AGENTS.md`).  
- Sol Protocol may apply in Claude sessions — **do not rewrite Sol’s constitution from this game repo.**  
- Prefer **working diffs** over essays. Match Mac’s tempo.

---

*Write for the next agent cold-starting with only this file + `git log -5`. Leave the School truer than you found it.*
