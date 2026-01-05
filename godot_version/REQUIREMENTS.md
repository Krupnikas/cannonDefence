# Cannon Defence - Complete Requirements Document

## Core Vision
A minimalist, strategy-focused tower defense game with difficult but fair economics.
The challenge comes from resource management, not reflexes.

---

## 1. VISUAL DESIGN
- [x] OLED-friendly pure black background
- [x] Minimalist aesthetic
- [x] Colorful projectile effects (fire, ice, acid, laser, tesla)
- [x] Status effect visual feedback (burn aura, freeze aura)
- [ ] Clean, non-cluttered UI

## 2. LEVEL SYSTEM
- [x] 5x3 grid of 15 levels
- [x] Progressive unlocking (complete level N to unlock N+1)
- [x] Star ratings (1-3 stars based on score thresholds)
- [x] Save/load progress persistence
- [ ] **Variable grid dimensions per level** (some levels 6x4, others 10x6, etc.)
- [ ] Level-specific starting conditions

## 3. CANNON TYPES (9 types)
| Type | Mechanic | Status |
|------|----------|--------|
| Gun | Balanced starter | [x] Done |
| Sniper | Long range, critical hits | [x] Done |
| Rapid | Fast fire, low damage | [x] Done |
| Fire | Burn DoT effect | [x] Done |
| Ice | Slow effect | [x] Done |
| Acid | Splash damage | [x] Done |
| Laser | Pierce through enemies | [x] Done |
| Tesla | Chain lightning | [x] Done |
| Miner | Generates coins over time, no attack | [x] Done |

### Cannon Features
- [x] Progressive unlock by level
- [x] Sell mechanic (right-click, 70% refund)
- [x] Cannons have HP and can be destroyed by enemies
- [ ] Upgrade system (optional)

## 4. ENEMY TYPES (6 types)
| Type | Mechanic | Status |
|------|----------|--------|
| Regular | Standard | [x] Done |
| Fast | High speed, low HP | [x] Done |
| Tank | Slow, high HP, physical resist | [x] Done |
| Flying | Ignores obstacles, physical resist | [x] Done |
| Dodger | 40% dodge chance | [x] Done |
| Resistant | Immune to status effects | [x] Done |

### Enemy Features
- [x] Fire + Ice cancel each other (THAW/DOUSED feedback)
- [x] Physical resistance for some types
- [x] Status effect immunity for Resistant type
- [x] Enemies attack cannons when in range
- [ ] Pathfinding around cannons
- [ ] Cannot place cannon if it blocks all paths

## 5. ECONOMY & DIFFICULTY
Core principle: **Barely possible to progress, but achievable with optimal strategy**

### Current
- [x] Starting money varies by level
- [x] Wave completion bonuses
- [x] Kill rewards
- [x] Sell cannons at 70%
- [x] Difficulty multiplier per level

### TODO
- [x] Miner cannon for passive income (60s payback at 2.5 coins/sec)
- [ ] Balanced economy simulation/testing
- [ ] Interest on banked money (optional)
- [ ] Tight resource constraints forcing strategic choices

## 6. PATHFINDING SYSTEM
- [ ] Enemies pathfind around placed cannons
- [ ] **Path validation before cannon placement**
- [ ] Visual preview of blocked placement
- [ ] Flying enemies ignore ground obstacles

## 7. CAMERA SYSTEM (Feature Flag)
- [ ] Zoom in/out (mouse wheel)
- [ ] Pan/navigate (WASD or drag)
- [ ] Feature flag to enable/disable
- [ ] Useful for larger grid levels

## 8. FEATURE FLAGS & SETTINGS
All experimental features controlled via settings:
- [ ] `ENABLE_CAMERA_CONTROLS`: bool
- [ ] `ENABLE_PATHFINDING`: bool
- [ ] `ENABLE_CANNON_HP`: bool
- [ ] `ENABLE_ENEMY_ATTACKS`: bool
- [ ] `ENABLE_MINER_CANNON`: bool
- [ ] `DEBUG_SHOW_PATHS`: bool
- [ ] `DEBUG_SHOW_RANGES`: bool
- [ ] `DEBUG_INFINITE_MONEY`: bool

## 9. TESTING & BALANCE
- [ ] Economy simulation tests
- [ ] Verify levels are completable
- [ ] DPS calculations per cannon
- [ ] Expected income vs expenses per wave
- [ ] Difficulty curve validation

---

## PRIORITY ORDER

### Phase 1: Core Improvements (Critical) ✓ COMPLETED
1. ~~Add Miner cannon~~ ✓
2. ~~Add cannon HP system~~ ✓
3. ~~Add enemy attacks on cannons~~ ✓
4. ~~Balance economy for difficulty~~ ✓ (Miner: 60s payback)

### Phase 2: Pathfinding (Important)
5. Implement A* pathfinding for enemies
6. Path validation for cannon placement
7. Flying enemies ignore ground cannons

### Phase 3: Polish (Nice to Have)
8. Variable grid dimensions per level
9. Camera zoom/pan with feature flag
10. Feature flags system
11. Economy tests

---

## BALANCE TARGETS

### Economy
- Player should be 10-20% short of "comfortable" at all times
- Selling cannons should be a strategic decision, not a mistake fix
- Miner cannon payback period: ~60 seconds
- Wave bonus should cover ~30% of next wave's cannon needs

### Difficulty
- Level 1-5: Learning curve, forgiving
- Level 6-10: Requires planning, some retries expected
- Level 11-15: Demands optimal play, multiple attempts likely

### Combat
- Single cannon should NOT hold a lane alone
- Combined effects (slow + damage) should be rewarded
- No single "best" cannon - all should be situationally useful
