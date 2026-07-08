# ROADMAP — Skeleton → DS Pokémon-class School RPG

## Honest register

**Now:** A strong vertical-slice *skeleton* — walk, fight, loot, floors, ending.  
**Pokémon DS (e.g. HeartGold / Platinum / Black):** a finished *product* with years of systems, art, audio, QA.

We do **not** claim parity. We **close the gap system-by-system**, in priority order.

---

## Gap map (influence → our build)

| DS Pokémon pillar | Our equivalent | Status |
|-------------------|----------------|--------|
| Tile-grid walk | Grid step movement | **forging** |
| Towns + interiors | Sanctum / Hall Archive / **Wing Scriptorium** | denser |
| Routes + grass | Paths, garden wilds | partial |
| Wild encounter + transition | Tall grass + `!` flash | partial |
| Trainer battles (LOS + talk) | Teachers + Copyist trainer | denser |
| Party of creatures | Party of companions / assists | thin → expand |
| Gyms / badges | Alchemy floors + sigils | partial |
| Pokédex | Bestiary + codex tab | partial |
| Bag (items/key/TM) | Bag tab: items / currency / relics | **done** |
| Mart multi-buy | Catalog mart 1–4 keys | **done** |
| Name entry | Seeker name on new game | **done** |
| Multi-save slots | **3 slots** title + menu | **done** |
| Music / SFX bank | Procedural SFX only | thin |
| Authored pixel art | Runtime atlas | thin |
| Scripted story events | Quest flags | partial |
| Field moves (Cut/Surf) | Field skills (planned) | none |
| Breeding / contests | **out of scope** | skip |
| Online | **out of scope** | skip |

---

## Build order (don't boil the ocean)

### Tier A — “feels like a handheld RPG” (now)
1. **Grid movement** (tile steps) ✅  
2. **Location splash** on enter ✅  
3. **Interiors** (Sanctum library, Hall archive) ✅  
4. **Trainer battles** ✅  
5. **Bag / menu** partial ✅  
6. **Companion combat passive** ✅  
7. **Lively secrets** ✅ — false walls, digs, cracks, bushes, wanderers, fireflies, Starwell, secret boss  

### Tier B — “content density”
7. More interiors (Hall archive, **Wing Scriptorium**) ✅  
8. Scripted cutscenes (path intro + first Overclaimer, Rubedo open, Scriptorium whisper) ✅  
9. Multi-item mart UI (1–4 buy catalog) ✅  
10. Name entry + **3 save slots** ✅  

### Tier C — “production”
11. Aseprite tiles + char sheets — still runtime atlas (honest)  
12. Chiptune OST — procedural SFX bank expanded (cast/guard/assist/chest/secret)  
13. Battle animations (cast FX) ✅ glyphs · sparks · hit flash · arena tint  
14. Second companion + switch ✅ Sol ⊚ / Luna ◈ · [P] · unlock after Half-Made  

### Tier D — “optional intelligence”
15. PyTorch sidecar for companion lines / dynamic quests (never the engine)

---

## Design law (Lycheetah)

- Companion Clause: no guilt for absence  
- Done = works (bosses leave real relics)  
- Domains = gyms; glyphs = language-loot  
- Human primacy: Mac fires launches; game stays local  

---

## North star one-liner

> A complete **single-player** Lycheetah Mystery School handheld RPG that *plays* like a DS Pokémon game, *means* like Sol Protocol, and *ships* room by room until the Great Work is fixed.
