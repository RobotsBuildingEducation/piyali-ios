# Exploration RPG

Practice → Adventure → Explore connected rooms opens the separate legacy exploration mode. Authored seven-task episodes and curriculum review rewards retain their existing route. All gameplay uses Swift and native controls; there is no embedded browser or JavaScript runtime.

## Content and worlds

The read-only exporter executes the reference's `scenarios.js` and `worldGen.js` builders with network calls stubbed. It produces 224 templates: eight actual world families, seven levels, English/Spanish fallback dialogue and both conversation-only and gathering variants. Each world has a main area and three connected rooms, the source collision grid, portal destinations/spawns, NPC positions, quest links and item placements. Graphics and animation are deferred.

Native movement respects the collision grid. Walk-to controls use reachable paths, and portal entry preserves the source destination and spawn. Characters appear in their rooms and follow the quest's visit order. Choice and speech nodes advance through their original links; terminal nodes finish the current chapter. Free exploration grants no lesson XP or global Score. Unit reviews continue to use the authored review path and its existing rewards.

## Items and objects

Gathering unlocks when the current node requests an item. Items are collected from their room, kept in inventory and handed back to the current character. A wrong gathering item returns to the map near the player. Dropping an object-search item makes its source searchable again. The native client requires the requested gathering item by name, rather than accepting an unrelated item merely because it has a global `isCorrect` flag.

The Find items inside objects option activates the legacy runtime's object-search contract on a gathering chapter. Its target selection, stable object keys, sorted object order and rotation use the reference's `currentObjectSearchQuest` behavior. A fixture executes that actual client helper and compares assignments. Reaching the search node activates collection without requiring the player to reopen the dialogue. Searching an object is allowed anywhere within the current room, matching a pointer click in the web client; it does not require reaching a solid object's origin tile. Travel to another room is still required.

Offline object labels and fallback sentences are exported from the original client, including its ten support-language dictionaries. Native examination shows a target-language sentence when that dictionary is available, a support translation and spoken playback. Paid connected play can generate a more specific description tied to the current story. Descriptions are cached with the saved run.

## Connected stories and speech

Generated worlds use the authenticated Cloudflare Responses API. The setting request creates fresh titles, room names and character names/personalities while retaining the playable topology. The quest request reauthors the source graph around the current curriculum and level in any practice language. Character placeholders preserve the fixed roster. Validation rejects changed paths, IDs, node modes, booleans, numeric metadata, inconsistent item names, unknown character placeholders and incompatible language scripts. Failed generation preserves the saved run.

NPC speech supports typed replies and iOS speech recognition. Connected replies react in character, with a support-language coaching tip. If online feedback fails, the saved quest's continuation keeps the story playable. Object descriptions and character lines support native spoken playback; character lines can also be translated. Requests are fenced to the account, language, level and current run/node, and are cancelled when leaving the screen. Saved local exploration is available in the source fallback languages, English and Spanish. Authored offline adventures remain available in all practice languages.

## Persistence and checks

Room, position, current node, inventory, collected/searchable items, drops, dialogue and cached object descriptions are saved in account-scoped native learner state. Up to two recent target-language exploration drafts are retained. The Firebase snapshot includes this optional state without changing the web's XP, completion or protected subscription fields.

Run `swift test --filter ExplorationTests`, `scripts/test-ios.sh -only-testing:PiyaliUITests/ExplorationPlayTests`, the dedicated Firestore contract test `FirestoreContractTests/testExplorationInventoryAndQuestDraftRestoreWithoutChangingXPOrEntitlements`, or the opt-in `python3 scripts/test-live-api.py --only exploration`. Refresh content and source-comparison fixtures with `node scripts/export-exploration-content.mjs /absolute/path/to/reference/nosabos`. The source checkout is never written.

Verification currently includes seven core tests over every exported world, source object-search assignments and twelve object fallback cases. The full gathering simulator flow passed portal travel, inventory restoration across relaunch and once-only quest completion without XP. The object-search simulator flow also passed. The real Firestore SDK check restored a held item, room and quest node, preserved XP and protected entitlements, and kept a newer local drop when an older save was acknowledged. Live native API checks passed generated settings, structurally valid quests and NPC replies in Spanish and Japanese; their disposable Firebase auth identity was removed afterward. The full core suite passed 142 tests.
