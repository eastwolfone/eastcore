# EastCore — CLAUDE.md

## Project Overview
EastCore is a personal AzerothCore WotLK 3.3.5a private server for solo play with playerbots,
running in WSL2 Ubuntu 24.04. Built for custom development, modding, and LLM-powered game systems.

Uses the mod-playerbots fork of AzerothCore with ALE (Lua scripting), autobalance scaling,
and (planned) Claude API-powered bot dialogue via mod-llm-chatter.

GitHub repos:
- AC fork: https://github.com/eastwolfone/eastcore-wotlk
- Custom repo: https://github.com/eastwolfone/eastcore

## Directory Layout
- `~/eastcore/azerothcore/` — AC source (playerbots fork, git repo with 3 remotes)
- `~/eastcore/build/` — CMake build output (not in git)
- `~/eastcore/custom/` — THIS REPO: Lua scripts, SQL patches, configs, tools
- `~/eastcore/backups/` — Database dumps (not in git)
- `C:\Users\Logan\Desktop\Projects\EastCore\` — Windows side (client, bat launchers, WSL2 shortcut)
- `C:\Users\Logan\Desktop\Projects\EastCore\client\` — WoW 3.3.5a client

## Key Paths
- Server binaries: `~/eastcore/build/install/bin/`
- Server configs: `~/eastcore/build/install/etc/`
- Module configs: `~/eastcore/build/install/etc/modules/`
- Lua scripts deploy to: `~/eastcore/build/install/bin/lua_scripts/`
- Community modules: `~/eastcore/azerothcore/modules/`
- Map/client data: `~/eastcore/build/install/bin/data/`

## Windows Launchers
Located in `C:\Users\Logan\Desktop\Projects\EastCore\`:
- `Start Server.bat` — launches MySQL + auth + world in WSL2 tmux sessions
- `Stop Server.bat` — graceful shutdown
- `Server Console.bat` — attach to worldserver console (Ctrl+B then D to detach)
- `Server Status.bat` — check if servers are running
- `Server Files (WSL2).lnk` — opens Explorer at the WSL2 server files

## Automation Scripts (~/eastcore/custom/tools/)
- `build.sh` — CMake configure + build + install (flags: --clean, --configure, --build-only, --jobs N)
- `run-server.sh` — starts MySQL + auth + world in tmux
- `stop-server.sh` — graceful shutdown
- `backup-db.sh` — timestamped dump of all 3 databases
- `restore-db.sh` — restore from backup
- `deploy-lua.sh` — copy Lua scripts to server lua_scripts/
- `update-modules.sh` — git pull all community modules
- `update-and-rebuild.sh` — pull upstream + modules, backup configs, rebuild, restore configs
- `apply-sql.sh` — apply custom SQL patches with tracking

## Build Commands

### Quick rebuild (RECOMMENDED)
```bash
~/eastcore/custom/tools/build.sh
```

### Manual CMake Configure (after adding/removing modules)
```bash
cd ~/eastcore
cmake -S azerothcore -B build \
  -DCMAKE_INSTALL_PREFIX=build/install \
  -DCMAKE_C_COMPILER=/usr/bin/clang \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
  -DTOOLS_BUILD=all \
  -DSCRIPTS=static \
  -DMODULES=static \
  -DWITH_WARNINGS=0 \
  -DBUILD_TESTING=OFF
```

### Manual Build
```bash
cmake --build ~/eastcore/build --target lualib -j $(nproc)
cmake --build ~/eastcore/build --config RelWithDebInfo -j $(nproc)
cmake --install ~/eastcore/build --config RelWithDebInfo
```

## IMPORTANT: Gotchas & Lessons Learned

### mod-ale (Lua engine) MUST be cloned as "mod-ale"
The repo is `azerothcore/mod-eluna` but the directory MUST be named `mod-ale`.
AC's build system checks `if (SOURCE_MODULE MATCHES "mod-ale")` at modules/CMakeLists.txt:81.
Wrong name = Lua include paths don't get configured = build fails.
```bash
git clone https://github.com/azerothcore/mod-eluna.git mod-ale
```

### Build order matters for Lua
build.sh handles this, but if building manually: build the `lualib` target FIRST,
then the full build. Otherwise ALE source files can't find lua.h.

### Module SQL must be applied manually on first install
AzerothCore auto-imports its own SQL, but module SQL (ah-bot, transmog, etc.) needs manual import.
Missing tables cause segfaults. Apply all module SQL:
```bash
for module_dir in ~/eastcore/azerothcore/modules/mod-*/; do
  for f in "$module_dir"/data/sql/db-world/*.sql "$module_dir"/data/sql/db_world/*.sql; do
    [ -f "$f" ] && mysql -u acore -pacore acore_world < "$f" 2>/dev/null
  done
  for f in "$module_dir"/data/sql/db-characters/*.sql "$module_dir"/data/sql/db_characters/*.sql; do
    [ -f "$f" ] && mysql -u acore -pacore acore_characters < "$f" 2>/dev/null
  done
  for f in "$module_dir"/data/sql/db-auth/*.sql "$module_dir"/data/sql/db_auth/*.sql; do
    [ -f "$f" ] && mysql -u acore -pacore acore_auth < "$f" 2>/dev/null
  done
done
```

### mmaps_generator config
The `mmaps-config.yaml` in build/install/bin/ must have `dataDir: "./data/"` (not `"./"`).

### WSL2 filesystem performance
NEVER run heavy I/O (builds, map extraction) on /mnt/c/. Use WSL2 native filesystem only.
The difference is orders of magnitude (mmaps: 5 hours on /mnt/c/ vs 3 minutes on native).

### AH Bot requires explicit setup
Must set EnableSeller=1, Account=2, GUID=999999 in mod_ahbot.conf.
The AH bot account and character were created manually in the DB.

### Playerbots first-launch character creation
First launch with high bot count can hang during "Waiting for N characters loading..."
Start with low count (50), let it create characters, then increase.
Current setting: 1000 bots. Characters already exist in DB.

## Database
- MySQL 8.0 on localhost:3306
- User: acore / Password: acore
- Databases: acore_auth, acore_characters, acore_world, acore_playerbots
- AH Bot account ID: 2, Character GUID: 999999
- Custom SQL: apply from custom/sql/ via `~/eastcore/custom/tools/apply-sql.sh`

## Git Strategy

### Remotes on azerothcore/
- `origin` -> github.com/eastwolfone/eastcore-wotlk (your fork)
- `playerbots-upstream` -> mod-playerbots/azerothcore-wotlk
- `ac-upstream` -> azerothcore/azerothcore-wotlk (vanilla)

### Branches
- `Playerbot` — clean tracking of playerbots-upstream. Never commit directly.
- `dev` — active working branch.
- `stable` — tagged from dev when known-good.
- `feature/*` — isolated experiments.

## Module Management
Community modules are independent git repos in `azerothcore/modules/`.
- Update a module: `cd modules/mod-name && git pull`
- Update all: `~/eastcore/custom/tools/update-modules.sh`
- Disable a module: delete the directory or add to -DDISABLED_AC_MODULES cmake flag
- After adding/removing modules: re-run CMake configure, then build.
- Module versions tracked in: `custom/tools/module-manifest.json`

### Installed Modules (all verified working)
**Tier 1:** mod-playerbots, mod-autobalance, mod-solo-lfg, mod-ale
**Tier 2:** mod-transmog (NPC 190010), mod-ah-bot, mod-npc-enchanter (NPC 601015), mod-npc-buffer (NPC 601016)
**Tier 3 (planned):** mod-llm-chatter (Claude API / Ollama)

## Lua Scripting (ALE — AzerothCore Lua Engine)
- Write scripts in `custom/lua/scripts/` (version controlled)
- Deploy: `~/eastcore/custom/tools/deploy-lua.sh`
- Hot-reload in-game: `.reload ale`
- Auto-reload enabled: saving a .lua file to lua_scripts/ triggers reload within 1 second
- ALE API docs: https://www.azerothcore.org/eluna/
- NOTE: ALE is NOT compatible with original Eluna scripts — different API

## Running the Server
```bash
~/eastcore/custom/tools/run-server.sh    # start
~/eastcore/custom/tools/stop-server.sh   # stop
```
Or use the Windows bat files in `C:\Users\Logan\Desktop\Projects\EastCore\`

## Player Account
- Username: admin / Password: admin123 / GM Level: 3
- Character: Cynnari (Horde)

## Common GM Commands
```
.gm on/off                — toggle GM mode (invisible to NPCs)
.revive                   — self-revive (must be alive to type; use server console if dead)
.server info              — server status
.reload ale               — reload Lua scripts
.reload config            — reload server config (picks up .conf changes)
.additem ITEMID [COUNT]   — add item to inventory
.tele LOCATION            — teleport (.tele orgrimmar, .tele stormwind, .tele gmisland)
.teleport name CHAR DEST  — teleport another character (server console: .teleport name Cynnari orgrimmar)
.revive CHARNAME          — revive a character (server console)
.npc add ENTRY            — spawn creature at your location
.lookup creature NAME     — find creature entry IDs
.modify speed VALUE       — change movement speed
.modify money AMOUNT      — add money (in copper)
.levelup [LEVELS]         — level up character
```

## Playerbot Commands
```
.playerbots bot list                   — show your current bots
.playerbots bot addclass warrior       — create and add a warrior bot
.playerbots bot addclass priest female — create a female priest bot
.playerbots bot add BOTNAME            — add existing bot by name (from /who)
.playerbots bot remove BOTNAME         — remove a bot from your group

# In party/whisper chat:
/p attack                              — all bots attack your target
/w BOTNAME talents spec prot pve       — set bot spec
/w BOTNAME maintenance                 — bot manages own gear/skills
/w BOTNAME autogear                    — bot equips best available gear
/w BOTNAME nc ?                        — show non-combat strategies
/w BOTNAME co ?                        — show combat strategies
/w BOTNAME co +cc                      — enable crowd control
/w BOTNAME co -save mana              — disable mana saving
/w HEALERBOT nc -dps assist           — healer stops DPSing, just heals
```

## Build Troubleshooting (escalation order)
1. Incremental rebuild: `~/eastcore/custom/tools/build.sh --build-only`
2. Clean rebuild: `~/eastcore/custom/tools/build.sh --clean`
3. Delete suspect module folders, rebuild
4. Reset source: `cd ~/eastcore/azerothcore && git restore ./`
5. Reset module: `cd modules/mod-name && git restore ./`
6. Full reinstall: backup DB, re-clone, rebuild, reimport

## Config Editing
- Never edit .conf.dist files (upstream templates)
- Copy to .conf and edit that
- Store your customizations in `custom/configs/` for version control
- `.reload config` applies most changes without restart

## Future Plans
- Story Engine: AI-driven narrative content generation (see references/story-engine-concept.md)
- mod-llm-chatter with Claude API (Haiku for bots, Sonnet for NPCs, Opus for scenario generation)
- Custom Lua scripts for gameplay modifications
- See references/ folder for full concept documents
