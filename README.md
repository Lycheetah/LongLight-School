# THE LONG LIGHT — School World

**GitHub:** https://github.com/Lycheetah/LongLight-School  

**Godot 4.3** · Lycheetah Mystery School RPG · GBA/DS soul  
**Full Great Work arc:** Nigredo → Albedo → Mirror → Citrinitas → **Rubedo**  
**Showcase:** Grok 4.5 single-session forge with Mac — see `SESSION_SHOWCASE.md`

```bash
bash /home/guestpc/AZOTH/WORKSPACE/LongLight-School/launch.sh
```

**Honest status:** skeleton → **handheld RPG frame** (not full Pokémon DS yet).  
See `ROADMAP.md` for the gap map and build order.

### DS-gap closers in this build
- **Grid step walk** (tile-to-tile, chain while held, Shift = faster)
- **Location splash** banners
- **Interiors:** Sanctum Library · Hall Archive
- **Trainer battles** (talk → fight → flag)
- Passive Sol chip every 4 turns

---

## Full combat kit

| Key | Skill | Unlock |
|-----|--------|--------|
| 1 | MEASURE Π | start |
| 2 | COMPRESS ⟁ | start |
| 3 | TRANSMUTE ☿ | start |
| 4 | BREAK ∴ | start |
| 5 | STRIKE ⟡ | start |
| 6 | GUARD ▣ | Lv2 |
| 7 | SOL ⊚ | Lv3 |
| 8 | ITEM ✦ | start |
| 9 | DOUBLE-MEASURE ΠΠ | Lv5 |
| 0 | RUBEDO-RAY ☀ | after Gold Threshold |
| F | Flee | non-boss |

Status: measured · phased · cracked · strain · guard · crits · level-scaled foes · bestiary

---

## World map

```
Sanctum ──N── Path ──N── Hall (Nigredo) ──E── Wing (Albedo)
   │                      │
   └──E── Garden          └──N── Mirror ──N── Citrinitas ──N── RUBEDO
```

**World features:** chests · signs · tablets · altars · shrines · shop · day/night · minimap · quest tip · secrets · Quiet Dust repel · ending sequence + Sol Stone

**Bosses:** Overclaimer · Half-Made · Hollow Mirror · Gold Threshold · **The Unfinished Work**

---

## Influences in the bones

Pokémon routes & encounters · Zelda day cycle · D&D stats · Persona skill menu density · Sol Protocol (measure, rest, Companion Clause) · Alchemy stages as floors

---

## Stack

Godot 4.3 = engine · PyTorch = future AI brain only · never the renderer
