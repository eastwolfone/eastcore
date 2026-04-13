# EastCore Story Engine — Technical Concept Document
## "SillyTavern meets World of Warcraft"
### Status: Concept — to be built after base server is running
### Date: 2026-04-13

---

## Vision

A SillyTavern-like narrative engine where Claude acts as a game master, using WoW's
existing assets, systems, and 3D world as the medium. The LLM generates scenarios that
physically transform zones — spawning creatures, objects, weather, quests, and dialogue —
creating progressive, AI-driven storylines the player plays through.

**What makes this unique:**
- SillyTavern = LLM + text interface (great writing, no world)
- AI Dungeon = LLM + text adventure parser (no visuals, no real game mechanics)
- EastCore Story Engine = LLM + full 3D MMO engine + combat + loot + quests + cinematics + persistent world

---

## System Architecture

```
+------------------------------------------------------+
|                  CLAUDE (Opus/Sonnet/Haiku)           |
|                                                      |
|  Input: Zone intelligence package, player state,     |
|         story progress, design principles            |
|  Output: Structured scenario JSON                    |
+------------------------+-----------------------------+
                         |
              +----------v----------+
              |   SCENARIO SCHEMA   |  <-- Contract between Claude and engine
              |                     |
              |  theme, narrative,  |
              |  npcs[], objects[], |
              |  encounters[],     |
              |  quests[], loot[], |
              |  weather, phases,  |
              |  cinematics[]      |
              +----------+----------+
                         |
+------------------------v-----------------------------+
|              STORY ENGINE (Eluna Lua)                 |
|                                                      |
|  Zone Manager      -- spawn/despawn, transform zones |
|  Quest Manager     -- DB insert + hot reload         |
|  NPC Manager       -- dialogue routing to Claude API |
|  Encounter Manager -- boss scripts, waves, loot      |
|  Narrative Manager -- announcements, weather, pacing |
|  Cinematic Manager -- camera, choreography, subs     |
|  State Manager     -- progress tracking, save/load   |
|  Validation Engine -- sanity checks before deploy    |
+------------------------+-----------------------------+
                         |
+------------------------v-----------------------------+
|              AZEROTHCORE (Game Server)                |
|                                                      |
|  Creatures, GameObjects, Combat, Loot, Phasing,      |
|  Quests (via DB + hot reload), Weather, Waypoints    |
+------------------------------------------------------+
```

---

## Runtime Capabilities (No Restart, No Client Mod)

### Via Eluna Lua API:
- Spawn/despawn creatures: PerformIngameSpawn(1, entry, map, x, y, z, o, save, time, phase)
- Spawn/despawn game objects: PerformIngameSpawn(2, entry, map, x, y, z, o, save, time, phase)
- HTTP requests to LLM APIs: HttpRequest("POST", url, body, contentType, headers, callback) -- non-blocking
- Weather control: Map:SetWeather(zone, type, intensity) -- rain, snow, storm, blackrain
- Per-player phasing: Player:SetPhaseMask() + phased spawns (up to 32 phases)
- Dynamic NPC dialogue: GossipMenuAddItem() + GossipSendMenu()
- Custom loot: Loot:AddItem(), Loot:SetMoney(), Loot:Clear()
- Zone announcements: Player:SendBroadcastMessage()
- Creature AI hooks: CREATURE_EVENT_ON_AIUPDATE, ON_DAMAGE_TAKEN, ON_PRE_COMBAT, etc.

### Via Database Insert + Hot Reload:
- Real quests: INSERT into quest_template + .reload quest_template
- Custom creatures: INSERT into creature_template + .reload creature_template
- Custom items: INSERT into item_template + .reload item_template
- Structured loot tables: INSERT into creature_loot_template + .reload creature_loot_template
- Persistent dialogue: INSERT into gossip_menu + .reload gossip_menu
- NPC bark text: INSERT into creature_text + .reload creature_text
- Readable books: INSERT into page_text + .reload page_text
- Custom vendors: INSERT into npc_vendor + .reload npc_vendor
- Conditional content: INSERT into conditions + .reload conditions

### Key Limitation:
- Cannot change terrain, add new models/textures, or modify zone geometry at runtime
- All visual content limited to WoW 3.3.5a's existing ~10,000+ models/objects/effects
- Custom models possible via client-side MPQ patches (separate distribution)

---

## Quality Framework — "Blizzard-Level" Content Generation

### The Problem
Naive generation produces flat content (12 ghouls in a field). Quality requires:
- Spatial intelligence (where things go, sightlines, approach angles)
- Game design knowledge (pacing, difficulty curves, quest flow patterns)
- Environmental storytelling (show don't tell)
- Validation (sanity checks before deployment)

### Solution: Three-Layer Quality System

**Layer 1 — Zone Intelligence Packages**

Rich data bundles giving Claude visual + spatial + data understanding of each zone:

```
zone-packages/
  elwynn-forest/
    map.png                  -- Stitched minimap (top-down, annotated with POIs)
    heightmap.png            -- Topographic elevation data
    walkability.png          -- Where players can actually path
    existing_spawns.png      -- Current NPC/object positions overlaid on map
    screenshots/             -- Key viewpoint reference photos
      goldshire_approach.png
      goldshire_inn.png
      northshire_abbey.png
      tower_of_azora_vista.png
      fargodeep_mine_entrance.png
    zone_data.json           -- Structured locations with coordinates, design notes
    creatures.json           -- All creatures in zone with positions, levels, types
    objects.json             -- All game objects with positions
    quests.json              -- All quests in the zone
    patrol_routes.json       -- NPC movement paths (reveals road network)
    design_notes.md          -- Human-written game design analysis
```

Claude is multimodal — it can SEE the zone map and heightmap images. Combined with
coordinate data, it can make spatially intelligent placement decisions.

Data sources:
- Minimap tiles: BLP textures in MPQ files, stitch into zone maps
- Heightmaps: ADT terrain data, render as topographic images
- Database: MySQL queries for creatures, objects, quests, waypoints
- DBC files: 247 extracted DBC files with spells, areas, models, etc.
- Screenshots: Eluna script teleports GM to viewpoints, captures reference photos

**Layer 2 — Game Design Principles (System Prompt)**

Encoded in Claude's system prompt:

PACING:
- Start with environmental storytelling (atmosphere, clues, dead NPCs — no combat)
- First combat encounter easy, teaches threat type
- Ramp through contested areas with increasing density/difficulty
- Climax with set-piece encounter (boss, defense event, dramatic moment)
- Resolve with denouement (rewards, narrative payoff, world restoration)

SPATIAL DESIGN:
- Enemies cluster at strategic points (bridges, doorways, intersections), not random fields
- Use elevation for reveals (player crests hill, sees scope of destruction)
- Indoor spaces: fewer but more dangerous enemies (elites, not swarms)
- Open areas: patrols and small groups, not static clusters
- Leave safe pockets for breath-catching, lore reading, NPC conversations

ENVIRONMENTAL STORYTELLING:
- Overturned carts, dead NPCs, scattered items tell story before combat
- Decorations placed logically (banners at occupied buildings, cauldrons at water)
- Weather escalates with narrative (fog -> rain -> storm -> blackrain at climax)

QUEST FLOW (Blizzard hub-and-spoke pattern):
- Breadcrumb quest leads to zone (awareness)
- Hub NPC provides context + 2-3 fan-out objectives (spoke)
- Completing spokes unlocks next phase/hub
- Final quest is climax encounter + turn-in with narrative closure
- Side objectives reward exploration

DIFFICULTY:
- Trash: 80-100% of player level, groups of 2-4
- Mini-boss: 100-105%, solo elite
- Final boss: 105-110%, elite with 1-2 abilities
- Never exceed what player can handle in sightline
- Factor in playerbots if active

LOOT:
- Trash: consumables, materials, small gold
- Quest rewards: gear upgrades appropriate to level and class
- Boss drops: 1 signature item with name + flavor text tied to story
- Lore items: readable books/scrolls that deepen narrative

SCENARIO ARCHETYPES:
- Invasion/Defense (Quel'Danas style)
- Mystery/Investigation (Wrathgate chain style)
- Escort/Rescue (Battle for Undercity style)
- Dungeon Crawl (classic dungeon structure)
- Faction Conflict (Aldor vs Scryer style)
- Horror/Survival (Duskwood/Karazhan style)

**Layer 3 — Validation Engine**

Automated checks between generation and deployment:
- All coordinates within zone bounds
- Creature levels within +/-10% of player level
- Spawn density within limits per area
- Quest objectives achievable (kill targets actually spawn)
- Loot items exist in catalog and are level-appropriate
- Phases have logical progression
- Boss HP/damage survivable for player + bots
- Auto-fix common issues or flag for review in Workshop UI

---

## Asset Catalogs — Claude's Palette

### Creature Catalog
Every creature_template categorized by theme (undead, elemental, beast, humanoid, dragon)
with entry IDs, levels, model descriptions, abilities, and design notes.

### Game Object Catalog
Decorations and interactables by theme (scourge, nature, alliance, horde, generic) with
entry IDs, size descriptions, and placement guidance.

### Item Catalog
Items by slot, level range, and theme for reward generation. Stats, icons, flavor text.

### Spell Visual Catalog
Spell effects mapped to their visual description, for designing boss abilities by
compositing existing visuals with modified mechanics.

### Zone Templates
Named locations with coordinates, emotional role, spawn points, sightline notes.

All catalogs extracted from the AzerothCore database and DBC files via automated scripts.

---

## Scenario Workshop — The Retry/Edit UX

### Problem
LLM generation is probabilistic. Rarely perfect on first try. SillyTavern solves with
swipe-to-regenerate and message editing. We need the equivalent.

### Solution: Generation and Deployment Are Separate Steps

Phase 1 — Generate and Preview:
  Player enters prompt + parameters
  Claude generates scenario
  Presented in Workshop UI for review

Phase 2 — Edit and Refine:
  [Regenerate] — re-roll entire scenario
  [Edit Phase] — modify specific parts, regenerate just that section
  [Chat Refine] — "make the boss harder, add a betrayal twist"
  [Manual Override] — change creature entries, adjust counts, rename NPCs
  [Save Template] — store for replay or sharing

Phase 3 — Deploy:
  Only when satisfied, click [Start]
  Zone transforms, content appears

---

## In-Game GUI

Custom WoW addon communicating with server via AIO (Addon I/O) library.
Bidirectional Lua communication: Server (Eluna) <-> AIO <-> Client (Addon).

### UI Tabs:
- Library: Browse saved scenarios, community templates, story history
- Workshop: Generate/edit/refine scenarios (the retry/edit workflow)
- Active Story: Track progress, objectives, controls for running scenario
- Settings: API keys, model selection, content preferences, difficulty

Full custom frames: buttons, text input, scroll frames, dropdowns, tabs, sliders.
WoW 3.3.5a addon API fully supports this.

---

## Cinematics

WoW 3.3.5a supports in-game cinematics (Wrathgate proved this):
- Camera paths via CinematicCamera.dbc entries with keyframe sequences
- Letterboxing via WorldFrame manipulation
- NPC choreography via waypoint sequences
- Weather/lighting changes during scenes
- Camera controls via WoW Camera Tools addon

Story Engine generates cinematic scripts as part of scenarios:
  trigger: "on_boss_death"
  sequences: letterbox_in -> camera_pan -> npc_emote -> subtitle -> weather_clear -> letterbox_out

---

## SillyTavern Card Integration

### Import Flow
ST cards are PNGs with embedded JSON (name, personality, scenario, example dialogue, tags).

Import modes:
1. Single NPC Encounter — spawn as talkable NPC with AI dialogue (pure roleplay)
2. Full Scenario — Claude builds entire storyline around the card character
3. Companion — character becomes a playerbot with card personality driving dialogue
4. Recurring Character — permanent world NPC with daily routine, relationship progression

### Adaptation Wizard
Card data -> WoW mapping UI:
- Race/gender/model selection (auto-suggested from card description)
- Zone selection (auto-suggested from card tags/tone)
- Role selection (quest giver, companion, enemy, recurring NPC)
- User prompt for how they want to use the card
- Claude receives original card + WoW parameters, generates adapted scenario

### Multi-Card Scenarios
Import multiple cards, Claude weaves them into interconnected storyline.
Each NPC retains original card personality for dialogue but gets a new role in the story.

### Card Export
Export characters born in gameplay as ST cards.
Share on ST card repositories.
Two-way bridge between SillyTavern community and EastCore.

---

## Custom Models & Assets

### Current Pipeline
Text prompt -> AI 3D generator (Meshy, Tripo3D) -> Blender cleanup -> WoW Blender Studio (M2 export) -> MPQ patch

### Phased Approach
Phase 1 (now): Use WoW's existing ~10,000+ models via asset catalogs
Phase 2 (later): Build library of ~50-100 custom models for themes WoW lacks
Phase 3 (future): As AI 3D tools improve, shrink the Blender step toward automation

### Distribution
Custom models require client-side MPQ patch: client-patch/patch-eastcore.MPQ
Server tells client which model IDs to render. With patch: custom models show.
Without patch: fallback to default models.

---

## Mature/Adult Content

Technically identical to any other content — same spawns, dialogue, quests, items.
Maturity is in the narrative layer (Claude output) and optionally client-side model patches.
No system prompt filtering needed on personal API key.
Toggle in Settings tab of the GUI.
ST card import supports mature-tagged cards natively.

---

## Model Strategy

| Role               | Model  | ~Cost/call | Why                                          |
|---------------------|--------|-----------|----------------------------------------------|
| Scenario Author     | Opus   | $0.20     | Structural complexity, narrative quality      |
| Scenario Refinement | Opus   | $0.10     | Editing needs same quality as generation      |
| NPC Dialogue        | Sonnet | $0.003    | Good character voices, fast for conversation  |
| Ambient/Reactions   | Haiku  | $0.001    | Volume play, quick responses                  |
| Cinematic Scripts   | Sonnet | $0.005    | Structured output, moderate complexity        |

Session cost: ~$1-3 for a unique multi-hour campaign.

---

## Target Audience
- SillyTavern users wanting characters in a real game world
- WoW private server players wanting AI-driven content
- AI roleplay enthusiasts wanting more than a chat interface
- Solo RPG players wanting a game master
- Mature content community wanting immersive experiences

---

## Project Structure (when built)

```
~/eastcore/custom/
  lua/scripts/
    story-engine/
      engine.lua            -- Core scenario parser + executor
      zone_manager.lua      -- Spawn/despawn/phase management
      quest_manager.lua     -- DB insert + hot reload quest system
      npc_manager.lua       -- AI dialogue routing
      encounter_manager.lua -- Boss/wave encounters
      narrative.lua         -- Announcements, weather, pacing
      cinematic.lua         -- Camera, choreography, subtitles
      state.lua             -- Save/load story progress
      validation.lua        -- Pre-deployment sanity checks
      card_import.lua       -- SillyTavern card parser + adapter
  data/
    catalogs/
      creatures_by_theme.json
      gameobjects_by_theme.json
      items_by_theme.json
      spells_by_visual.json
    zone-packages/
      elwynn-forest/
        map.png, heightmap.png, zone_data.json, design_notes.md, screenshots/...
      duskwood/
        ...
    scenarios/              -- Saved/cached scenarios
    cards/                  -- Imported ST cards
  prompts/
    scenario_generator.md   -- Opus system prompt for scenario generation
    npc_dialogue.md         -- Sonnet/Haiku prompt for NPC conversation
    cinematic_writer.md     -- Sonnet prompt for cinematic scripts
  client-patch/
    patch-eastcore.MPQ      -- Custom models (optional)
    build-patch.sh
  tools/
    extract_minimap.py      -- BLP tiles -> stitched zone map PNG
    extract_heightmap.py    -- ADT data -> topographic PNG
    extract_zone_data.py    -- MySQL -> zone_data.json
    extract_catalogs.py     -- DB + DBC -> asset catalogs
    screenshot_tour.lua     -- Eluna: teleport to POIs, capture screenshots
    build_zone_package.sh   -- Orchestrates all extraction for a zone
  addon/
    EastCoreStoryEngine/    -- WoW client addon (Workshop UI, Library, Active Story)
```

---

## Implementation Order (after base server is running)
1. Build extraction pipeline (zone packages, asset catalogs)
2. Build Elwynn Forest zone package as proof of concept
3. Build core Story Engine Lua scripts (spawn/despawn, state, validation)
4. Build scenario generation prompt + schema with Opus
5. Test: generate and deploy one scenario in Elwynn
6. Build pseudo-quest system (gossip-based)
7. Upgrade to real quests (DB insert + hot reload)
8. Build NPC dialogue routing (Sonnet/Haiku)
9. Build the addon GUI (Workshop, Library, Active Story)
10. Add cinematic system
11. Add ST card import/export
12. Expand to more zones
13. Community features (scenario sharing, card exchange)
