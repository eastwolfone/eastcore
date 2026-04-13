# EastCore — CLAUDE.md

## Project Overview
EastCore is a personal AzerothCore WotLK 3.3.5a private server for solo play with playerbots,
running in WSL2 Ubuntu 24.04. Built for custom development, modding, and LLM-powered game systems.

Uses the mod-playerbots fork of AzerothCore with Eluna Lua scripting, autobalance scaling,
and (planned) Claude API-powered bot dialogue via mod-llm-chatter.

## Directory Layout
- `~/eastcore/azerothcore/` — AC source (playerbots fork, git repo with 3 remotes)
- `~/eastcore/build/` — CMake build output (not in git)
- `~/eastcore/custom/` — THIS REPO: Lua scripts, SQL patches, configs, tools
- `~/eastcore/backups/` — Database dumps (not in git)
- `C:\Users\Logan\Desktop\Projects\EastCore\client\` — WoW 3.3.5a client (Windows side)

## Key Paths
- Server binaries: `~/eastcore/build/bin/`
- Server configs: `~/eastcore/build/bin/configs/`
- Module configs: `~/eastcore/build/bin/configs/modules/`
- Lua scripts deploy to: `~/eastcore/build/bin/lua_scripts/`
- Community modules: `~/eastcore/azerothcore/modules/`

## Build Commands

### CMake Configure (after adding/removing modules or first time)
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

### Build (after code changes)
```bash
cmake --build ~/eastcore/build --config RelWithDebInfo -j $(nproc)
```

### Quick rebuild shortcut
```bash
~/eastcore/custom/tools/build.sh
```

## Database
- MySQL 8.0 on localhost:3306
- User: acore / Password: acore
- Databases: acore_auth, acore_characters, acore_world
- First run: worldserver creates databases automatically
- Custom SQL: apply from custom/sql/ via `mysql -u acore -pacore acore_world < file.sql`

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

### Updating from upstream
```bash
cd ~/eastcore/azerothcore
git fetch playerbots-upstream
git merge playerbots-upstream/Playerbot
```

## Module Management
Community modules are independent git repos in `azerothcore/modules/`.
- Update a module: `cd modules/mod-name && git pull`
- Disable a module: delete the directory or add to -DDISABLED_AC_MODULES cmake flag
- After adding/removing modules: re-run CMake configure, then build.
- Module versions tracked in: `custom/tools/module-manifest.json`

### Installed Modules
**Tier 1 (Essential):** mod-playerbots, mod-autobalance, mod-solo-lfg, mod-eluna-lua-engine
**Tier 2 (QoL):** mod-transmog, mod-ah-bot, mod-npc-enchanter, mod-npc-buffer
**Tier 3 (LLM, planned):** mod-llm-chatter (Claude API / Ollama)

## Lua Scripting (Eluna)
- Write scripts in `custom/lua/scripts/` (version controlled)
- Deploy to `build/bin/lua_scripts/` with `custom/tools/deploy-lua.sh`
- Hot-reload in-game: `.reload eluna`
- Eluna API docs: https://www.azerothcore.org/pages/eluna/

## Running the Server
1. Ensure MySQL is running: `sudo service mysql start`
2. Start authserver: `cd ~/eastcore/build/bin && ./authserver`
3. Start worldserver: `./worldserver`
4. Or use: `~/eastcore/custom/tools/run-server.sh`

## Account Management (worldserver console)
```
account create USERNAME PASSWORD
account set gmlevel USERNAME 3 -1
```

## Common GM Commands (in-game, GM level 3)
```
.server info              — server status
.reload eluna             — reload Lua scripts
.reload config            — reload server config
.additem ITEMID [COUNT]   — add item to inventory
.tele LOCATION            — teleport to named location
.npc add ENTRY            — spawn creature
.modify speed VALUE       — change movement speed
.modify money AMOUNT      — add money (in copper)
.levelup [LEVELS]         — level up character
```

## Playerbot Commands
```
.playerbots bot add                    — add a random bot to your group
.playerbot bot init=auto               — cycle bot spec + level up to yours

# In party/whisper chat:
/p attack                              — all bots attack your target
/w BOTNAME talents spec prot pve       — set bot spec
/w BOTNAME maintenance                 — bot manages own gear/skills
/w BOTNAME autogear                    — bot equips best available gear

# Strategies (whisper to specific bot):
/w BOTNAME nc ?                        — show non-combat strategies
/w BOTNAME co ?                        — show combat strategies
/w BOTNAME co +cc                      — enable crowd control
/w BOTNAME co -save mana              — disable mana saving
/w HEALERBOT nc -dps assist           — healer stops DPSing, just heals
/w BOTNAME los                        — bot lists interactable objects nearby
/w BOTNAME u [Object Name]           — bot interacts with named object
```

## Build Troubleshooting (escalation order)
1. Clean build: `rm -rf ~/eastcore/build && rebuild`
2. Delete suspect module folders, rebuild
3. Reset source: `cd ~/eastcore/azerothcore && git restore ./`
4. Reset playerbots module: `cd modules/mod-playerbots && git restore ./`
5. Full reinstall: backup DB, re-clone, rebuild, reimport

## Config Editing
- Never edit .conf.dist files (upstream templates)
- Copy to .conf and edit that
- Store your customizations in `custom/configs/` for version control
