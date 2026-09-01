# AI Strategic Advisor — Hearts of Iron IV 1.19

This is a hybrid HOI4 mod + local Python bridge. Clausewitz scripting cannot directly make HTTP
requests, so the mod exports game state through `game.log`; the bridge sends it to Pawan.Krd,
then uses the HOI4 console to execute a tightly whitelisted set of actions and injects the answer
into the mod's localization file.

## Features
- Pawan.Krd OpenAI-compatible chat API.
- Four personas selected through the in-game Decisions panel.
- Custom character/system prompt in `bridge_config.json`.
- Reads current country data, enemies, and owned-state data from `game.log`.
- AI returns advice plus structured actions.
- Can execute broad actions: declare war, move units, change laws, trade, diplomacy,
  create/declare wargoals, set guarantees/access, add faction membership, etc.
- Responses are shown back in-game by reloading localization and firing `ai_advisor.2`.

## Important
Use a normal non-Ironman single-player game. Console-driven execution is not suitable for Ironman.
The bridge deliberately rejects dangerous cheats such as annex, tag switching, instant construction,
manpower/PP injection, and AI toggles.

## Install
1. Put `ai_strategic_advisor` under your HOI4 `mod/` directory.
2. Enable the mod.
3. Copy `bridge/bridge_config.example.json` to `bridge/bridge_config.json`.
4. Put your Pawan.Krd API key in the config or set `PAWAN_API_KEY`.
5. Set `HOI4_USER_DIR` to your Paradox user directory.
6. Start `bridge.py` before or during the game.
7. In HOI4, open Decisions -> AI Strategic Advisor.
8. Select a persona, then Ask the Advisor.

The bridge defaults to approval mode. Set `auto_execute` to true if you want the AI to
execute allowed actions automatically. It still applies the command whitelist.

## Pawan.Krd
The API is OpenAI-compatible. The default endpoint is:
https://api.pawan.krd/v1/chat/completions
Select an accessible chat model in the config.

### Persona behavior
The selected in-game persona is exported with each request, so the bridge follows the decision you selected. The Custom persona uses `custom_prompt` from `bridge_config.json`.
