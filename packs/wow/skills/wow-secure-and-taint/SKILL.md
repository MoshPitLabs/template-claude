---
name: wow-secure-and-taint
description: Load before writing or reviewing WoW addon code that touches secure templates, protected frames or actions, action or unit buttons, combat lockdown, hooks into Blizzard UI, or diagnosing "action blocked" or taint errors.
---

# WoW secure and taint

Execution is secure until it reads or runs anything an addon wrote; from then on it is tainted, and a tainted path that reaches a protected function is blocked ("Interface action failed because of an AddOn"). Taint spreads through globals, fields written into Blizzard tables and frames, and functions replaced on Blizzard objects.

- Hook, do not replace: `hooksecurefunc(table, "Method", fn)` and `frame:HookScript("OnShow", fn)` run after the original without tainting it. Never assign to a Blizzard global, method or frame field that secure code reads.
- Protected work in combat: when `InCombatLockdown()` is true, protected frames cannot be created, shown, hidden, moved, resized, reparented or given new attributes. Queue the change and apply it on `PLAYER_REGEN_ENABLED`; check before acting, since `PLAYER_REGEN_DISABLED` arrives after lockdown has begun.
- Click-to-act buttons use secure templates (`SecureActionButtonTemplate`, `SecureUnitButtonTemplate`) configured through `SetAttribute` out of combat. State changes in combat go through restricted environments (`SecureHandlerStateTemplate`, `RegisterStateDriver`, secure snippets), whose Lua subset is limited; verify each snippet API at the pinned tag.
- Button click registration and key-down behavior changed on retail around 10.0; copy the pattern from a current Blizzard or repository call site.
- Combat information on Mainline-family clients (retail, Forever) may be restricted for addons: secret values that pass `type()` but fail arithmetic, comparison and concatenation. Guard with `issecretvalue`, hand health and power straight to `StatusBar:SetMinMaxValues` / `SetValue`, check the pinned build's documentation for the exact API, and degrade instead of erroring.
- `pcall` does not make a protected call safe: the client reports "Interface action failed because of an AddOn" without a Lua error. Early Forever reports also say secure snippets failed to compile (`loadstring_untainted` missing), breaking click-casting and action-bar paging; confirm on the pinned build before relying on restricted environments there, and prefer the addon's own buttons. Do not call chat-activation functions (`ChatFrame_OpenChat`, `ChatEdit_ActivateChat`) or `C_SuperTrack.SetSuperTrackedUserWaypoint` from insecure code; route item-link clicks through `HandleModifiedItemClick` and map pins through `C_Map.SetUserWaypoint` (verify at the pinned tag).

Never work around a protected-action or hardware-event restriction, or automate a decision the player should make: that is a hard stop under Blizzard's add-on policy.

Diagnose with `/console taintLog 1` (or `2` for more detail), reproduce, then read `Logs/taint.log` in the game folder (read-only). Taint errors are in-game checks the user runs.
