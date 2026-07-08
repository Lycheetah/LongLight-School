# THE LONG LIGHT — School World

**A Lycheetah Mystery School RPG** built in **Godot 4.3**.

Top-down handheld feel (Pokémon Advanced / Nintendo DS energy) · D&D-flavored stats · framework combat · full alchemy arc · secrets · trainers · ending.

> **Repo:** [github.com/Lycheetah/LongLight-School](https://github.com/Lycheetah/LongLight-School)  
> **Showcase:** forged in a **single Grok 4.5 session** with Mac — see [`SESSION_SHOWCASE.md`](SESSION_SHOWCASE.md) · gap map in [`ROADMAP.md`](ROADMAP.md)

---

## Honest register

This is a **dense playable vertical product**, not a finished Nintendo game.

| It *is* | It is *not* (yet) |
|---------|-------------------|
| Runnable Godot 4.3 game | Authored pixel art / OST |
| Grid walk, combat, quests, secrets, ending | Full multi-year content pack |
| Systems + world graph + bestiary | Production UI polish everywhere |

**Done = works.** The loop runs. The School can be finished.

---

## Play

### Requirements
- **Godot 4.3+** (Linux x86_64 binary works out of the box)
- Graphical display (desktop session)

### Launch

```bash
# from this repo
bash launch.sh
```

Or open the folder in the **Godot 4.3 Editor** → press **F5**.

If `launch.sh` cannot find Godot:

```bash
export GODOT=/path/to/Godot_v4.3-stable_linux.x86_64
bash launch.sh
```

On this machine the session binary lives next to the project:

```text
../tools/godot   →  Godot 4.3.stable
```

---

## Controls

### Overworld
| Input | Action |
|--------|--------|
| **WASD / Arrows** | Grid step (Pokémon-style) |
| **Shift** | Faster steps (run) |
| **E / Enter** | Talk · dig · open · buy · confirm |
| **Esc / M** | Full menu: Quests · Bag · Codex · Story · Help · Save |
| **Enter / Esc** | Continue dialogue · Exit talk |
| **T** | Talk to active companion |
| **Y / H** | Story / Help tabs |
| **Help 1–5** | Ask the School (AI if key, else offline) |
| **Help 6–9** | Buy myths with School Coins |
| **[ ]** | Help guide pages |
| **Coins ¢** | From battles & digs (glyph shards) |
| **← → / Q B C V** | Switch menu tabs |
| **S / L** | Save / Load active slot (Save tab: pick 1–3) |
| **Title L** | Load screen — 3 file slots |
| **Shop 1–4** | Mart catalog buy (after talking to Keeper) |
| **P** | Switch companion (Sol / Luna after Albedo) |
| **K** | Field MEASURE — ping nearby secrets |
| **E on bush** | Field CLEAR |
| **Shrine** | Heal + register + fast travel · **0** rest till dawn |
| **N** | World map + run stats |
| **1 / 2 / 3** | Use Bread / Elixir / Quiet Dust (in menu) |

### Battle
| Key | Skill | Notes |
|-----|--------|--------|
| **1** | MEASURE Π | Strip false shields · reveal HP |
| **2** | COMPRESS ⟁ | Heavy dmg if measured · crits |
| **3** | TRANSMUTE ☿ | Heal · cleanse strain · anti-residue |
| **4** | BREAK ∴ | Crack / stun · anti-Loop |
| **5** | STRIKE ⟡ | Basic (feeds Loops!) |
| **6** | GUARD ▣ | Halve next hit (Lv2) |
| **7** | SOL ⊚ | Companion assist (Lv3) |
| **8** | ITEM ✦ | Bread / Elixir |
| **9** | DOUBLE-MEASURE | Lv5+ |
| **0** | RUBEDO-RAY ☀ | After Gold Threshold |
| **F** | Flee | Non-boss, luck-based |

---

## Story map (Great Work)

```
Sanctum ──N──► Long Path ──N──► Hall (Nigredo) ──E──► Wing (Albedo)
   │                              │
   │                              └──N──► Mirror ──N──► Citrinitas ──N──► RUBEDO
   │
   └──E──► Quiet Garden (train)

Hidden:  Ivy Grotto  ·  Starwell  ·  secret boss "The Hidden"
Interiors: Sanctum Library  ·  Hall Archive
```

| Stage | Place | Boss / goal |
|--------|--------|-------------|
| Start | Sanctum | Rest, meet Ember, first secrets |
| Route | Long Path | Overclaimer (MEASURE first) |
| Nigredo | Hall of Glyphs | 3 wins → open Albedo |
| Albedo | East Wing | Half-Made |
| Mirror | Mirror Chamber | Hollow Mirror |
| Citrinitas | Chamber of Scales | Gold Threshold |
| Rubedo | Flickering Deep | **The Unfinished Work** → Sol Stone + ending |

---

## Systems

- **Name entry** + archetype (Alchemist / Sentinel / Oracle / Wanderer)
- **Grid movement** · location splash · day/night tint · minimap · quest tip HUD
- **Combat** with status (measured / phased / cracked / strain / guard) · level scaling · bestiary
- **World-building:** chests · signs · lore tablets · altars · dig spots · cracks · bushes · switches · false walls
- **Lively world:** wanderers · fireflies · random whispers · LOS trainers
- **Secrets:** Star Sparks collectibles · Starwell offering (3 sparks) · secret boss
- **Shop** · Quiet Dust repel · save/load · Companion Clause (no guilt for rest)

---

## Secret hunter (spoiler-light)

1. Talk to wanderers — they drop hints.  
2. Face walls that shimmer and press **E**.  
3. Dig disturbed earth · crack seams · rustle bushes.  
4. Step on gold flower tiles for **Star Sparks**.  
5. Bring **3 sparks** to the Starwell altar.  
6. Optional: fight **The Hidden**.  
7. Still walk the main arc to **Rubedo**.

---

## Project layout

```text
LongLight-School/
├── project.godot
├── launch.sh
├── README.md
├── ROADMAP.md              # skeleton → DS-class gap map
├── SESSION_SHOWCASE.md     # single-session forge log
├── scenes/
│   ├── main.tscn           # title · name · archetype
│   └── overworld.tscn
└── scripts/
    ├── autoload/           # GameState · ContentDB · SFX · Atmosphere
    ├── world/              # maps · player · draw · secrets · minimap
    ├── combat/             # combat_core · battle UI
    ├── ui/                 # chrome · location splash
    └── util/               # runtime GBA-style pixel factory
```

---

## Stack law

| Layer | Choice |
|--------|--------|
| **Game engine** | **Godot 4.3** + GDScript |
| **AI/ML (optional later)** | PyTorch as a *brain* sidecar only — never rendering/input |
| **Not used as engine** | Pygame · HTML canvas |

---

## Influences

- **Pokémon** (grid walk, routes, grass, trainers, encounter energy)  
- **Zelda** (day/night outdoor mood)  
- **D&D** (stats, rolls, curriculum-as-combat)  
- **Persona-ish** skill density  
- **Lycheetah / Sol Protocol** — measure before claim · rest is rest · companions stay  

---

## Status

**v0.6+ session forge** — playable end-to-end with secrets and ending.  
Tier B + C slice: 3 saves · bag/mart · Scriptorium · cutscenes · battle cast FX · Sol/Luna party (**P** switch after Albedo).  
Next: authored Aseprite art, full chiptune OST tracks (see `ROADMAP.md`).

---

## License / credit

Built for **Lycheetah** · session forge with **Grok 4.5**.  
Name the Work honestly when you share it.

*The fire stays lit.*
