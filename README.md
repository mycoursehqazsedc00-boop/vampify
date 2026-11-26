# Vampify (Patched for WoW 1.12 / Turtle WoW)

> Tracks the silent healing returned by the **Vampirism** item stat on Turtle WoW 1.12.1, displaying live totals, Single-Target/AoE splits, per-ability breakdowns, upgrade previews, and optional scrolling combat text.

## Client Mods Used

| Mod | Purpose in this addon | Required? |
|---|---|---|
| **Nampower** (`v4.6+`) | Outgoing damage/cast events (`SPELL_DAMAGE_EVENT_SELF`, `AUTO_ATTACK_SELF`, `SPELL_GO_SELF`), incoming/heal events (`*_OTHER`, `SPELL_HEAL_BY_*`), `GetNampowerVersion()`, `GetUnitGUID()`, `GetEquippedItems()` + `GetItemStatsField("spellID")` gear scan fast-path, and `GetSpellNameAndRankForId()` / `GetSpellRecField()` + `GetSpellIconTexture()` fallbacks | **Required** |
| **SuperWoW** | Optional `UnitExists()` GUID lookup, `SpellInfo()` spell names & icons, and `ExportFile()` debug/watchdog/per-hit disk export | Optional |
| **ClassicAPI** | Optional `UnitGUID()` fallback when SuperWoW and Nampower GUID APIs are absent | Optional |
| **CombatHub** *(optional addon)* | Routes `VampifyDamageFrame` and `VampifyIncomingFrame` through a single shared combat event dispatcher (`capture\combathub.lua`) to eliminate duplicate combat-event overhead across addons | Optional |

*(The addon automatically detects available client mods at runtime and falls back cleanly when optional mods are absent.)*

## Features

- **Server-Matched Vampirism Model:** Evaluates each equipped Vampirism source independently (`max(1, floor(pct * D / 100))` for `D > 1`), with AoE damping (`0.7`) proven by distinct target GUIDs and retroactive first-hit correction.
- **Compact Movable Bar:** Live fight healing, Single-Target vs. AoE ratio pill, HPS, optional equipped gear percentage, and optional **Fade bar out of combat** (`35%` opacity when idle, `100%` in combat or on hover).
- **Per-Ability Breakdown & Row Detail:** Hover the bar for `SESSION`, `LIFETIME`, and `LAST` fight tabs; hover any row for hit count, average damage, effective rate vs. gear nominal, floor share, and per-source contributions.
- **Quick Row Actions & Chat Reporting:** `Shift-Click` any breakdown row to print/insert its `#spellId`, `Alt+Right-Click` to exclude non-triggering procs/shields, or click **Report** (or `/vf report`) to share a concise summary in raid/party/guild/say chat.
- **Scrolling Combat Text:** Choice of Vampify's own SCT (`Free anchor` or `At the bar`) with color, font size, rise height, fade duration, outline, shadow, and per-cast coalescing, or Blizzard's `Blizzard_CombatText`.
- **Upgrade Advisor & Watchdog:** Built-in hit-size histogram (`/vf upgrade [pct]`) compares adding a new Vampirism source vs. upgrading your weakest piece; watchdog invariants and optional solo HP reconciliation (`/vf watch`).

## What Was Added / Improved

- **Added:**
  - Nampower instant gear-detection fast-path (`GetEquippedItems` + `GetItemStatsField("spellID")` for `45420–45424`), reducing tooltip scans and supporting non-English clients while keeping full tooltip fallback for enchants.
  - `/vf trace [on|off]` lightweight live per-hit debug trace in chat (no disk writes).
  - `/vf report [say|party|raid|guild|self] [session|last|lifetime]` and a **Report** button on the breakdown panel.
  - **Fade bar out of combat** option (`VampifyDB.fadeOOC`) in `/vf options`.
  - Breakdown row quick actions: `Shift-Click` to inspect/insert `#spellId`, `Alt+Right-Click` to exclude a spell.
  - Direct Nampower version detection (`GetNampowerVersion()`) in `/vf status` and the Options info panel.
  - Optional `CombatHub` adapter (`capture\combathub.lua`).
- **Improved:**
  - Zero-allocation target/player GUID resolution with Nampower `GetUnitGUID()` and ClassicAPI `UnitGUID()` fallbacks (ST/AoE split and `/vf watch` now work without SuperWoW).
  - Nampower `GetSpellRecField("spellIconID")` + `GetSpellIconTexture()` fallback for breakdown icons and `ATTACK` / main-hand weapon fallback for melee icon.
  - Defaulted `perhitEnabled = false` so fresh profiles do not allocate per-hit export tables or subscribe `*_OTHER` events unless opted in; persisted `spSrc`/`lfSrc` per-source breakdowns across `/reload`.
- **Fixed:**
  - `core/config.lua`: Synced `DEFAULTS.dbVersion` / `CHAR_DEFAULTS.dbVersion` with `C.DB_VERSION` and stamped `dbVersion` on fresh/reset profiles so first-session ST/AoE split data is not wiped on the first `/reload`.
  - `core/commands.lua`: Cleared `creditedAt` in `beginFight()` to prevent cross-fight retroactive AoE corrections from driving `fHeal` negative or triggering false Watchdog I3 alarms.
  - `gui/options.lua`: Suppressed `OnValueChanged` during `refreshSliders()` on `OnShow`, disabled/greyed `Text shadow` in `Blizzard FCT` mode, and wired `cbPerHit` to `VampifyIncoming.setPerHitWanted`.
  - `core/const.lua`: Scoped `installErrorCapture` to Vampify-only errors so other addons' errors always forward cleanly to `!BugGrabber`/`BugSack`.
  - `capture/combathub.lua`: Checked `VampifyIncoming.isOn()` before `Frame:IsEventRegistered` for stock 1.12 compatibility.
  - `core/aggregate.lua` & `gui/display.lua`: Added defensive `table.setn(out, n)` on reused buffers (`A.shares`, `V.snapshotShares`, `V.shareOfMax`).

## Usage

`/vampify` or `/vf`:

| Command | What it does |
|---|---|
| `/vf status` | Equipped sources, Nampower version, and current totals |
| `/vf options` | Open the options window |
| `/vf reset [session\|lifetime\|last\|both]` | Reset totals (default: `session`) |
| `/vf pos` | Move the display back to its default position |
| `/vf lock` | Toggle dragging of the display |
| `/vf fct` / `/vf sct` | Toggle scrolling combat text (`duration <s>`, `shadow on\|off`) |
| `/vf sctmove` | Reposition Vampify's free-floating SCT anchor |
| `/vf source add <pct>` / `clear` | Add or clear manual Vampirism sources |
| `/vf exclude add <id>` / `remove <id>` / `list` | Manage non-triggering spell exclusions |
| `/vf report [say\|party\|raid\|guild\|self] [scope]` | Share a Vampirism healing summary to chat |
| `/vf trace [on\|off]` | Toggle live per-hit debug trace in chat |
| `/vf perhit on\|off\|status` | Per-hit debug export to `imports\vampify_perhit_*.txt` |
| `/vf upgrade [pct]` | Evaluate adding a source vs. swapping your weakest source |
| `/vf watch [on\|off]` | Solo HP-reconciliation watchdog |

Minimap button: **Left-Click** toggles the display, **Right-Click** opens Options.

## Credits & License

- Original addon: **ShempError** (`Vampify v0.4.0`)
- Patches, client-mod integrations & QoL upgrades: Community fork for Turtle WoW 1.12.1
- License: MIT (same as original addon; see `LICENSE`).
