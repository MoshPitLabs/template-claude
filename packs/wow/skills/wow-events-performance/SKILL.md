---
name: wow-events-performance
description: Load before adding or reviewing WoW event handlers, OnUpdate scripts, timers, caches or anything that runs per frame, per combat-log entry or per unit update.
---

# WoW events performance

Route events through one handler frame with a dispatch table (`frame:SetScript("OnEvent", function(self, event, ...) handlers[event](...) end)`). Register only the events in use, prefer `RegisterUnitEvent` for unit events, and unregister events once their purpose is done. Verify each event name and payload at the pinned tag (`wow-api-lookups`); payloads differ between flavors.

Per-frame and high-frequency work (`OnUpdate`, `COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_AURA`, bag and group updates) must be cheap:

- Throttle `OnUpdate` with an accumulated `elapsed`, or use `C_Timer.After` / `C_Timer.NewTicker` and cancel tickers you no longer need. Hide frames whose `OnUpdate` has nothing to do.
- Coalesce bursts of events into one update on the next frame.
- Do not allocate per call: reuse tables (`wipe`), avoid string building and closures in hot paths, and cache globals used in hot loops as locals.
- Use incremental payloads where the pinned build provides them (for example `UNIT_AURA` update info on retail) instead of rescanning everything.

Measure with the addon memory and CPU tools of the pinned build (`UpdateAddOnMemoryUsage` / `GetAddOnMemoryUsage`, and the addon profiler where the client has one). Performance claims without a measurement are hypotheses; list in-game measurements as user checks.
