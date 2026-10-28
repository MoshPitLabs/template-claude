---
name: hytale-assets-ui
description: Load before authoring Hytale JSON assets, consumable interactions, or keyed custom HUD and page content.
---

# Hytale assets ui

Inspect current codecs and shipped assets selectively; do not distribute vanilla files. Validate every referenced item/effect/prefab/UI path and define collision-free IDs without assuming vanilla IDs use a namespace prefix.

On 0.7.3, `CustomUIHud` requires a key and `HudManager` exposes add/remove keyed entries. Never remove another plugin's HUD. Verify layout and replication in a client; a compiled constructor does not validate UI selectors or paths.

Food restoration must follow successful committed consumption exactly once. Chain-start and transient effect detection are insufficient proof; handle cancellation and repeated identical items. Provide explicit overrides for third-party consumable inference. A runtime feature toggle does not unregister assets already loaded from the pack.
