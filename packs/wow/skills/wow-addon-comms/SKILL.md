---
name: wow-addon-comms
description: Load before designing or reviewing WoW addon-to-addon messages, sync between players, serialization, or import and export strings — the untrusted-input surface of an addon.
---

# WoW addon comms

Register the prefix once (`C_ChatInfo.RegisterAddonMessagePrefix`, at most 16 characters) and send with `C_ChatInfo.SendAddonMessage` (or `SendAddonMessageLogged`), respecting the message size limit and the per-prefix throttle of the pinned build; recent clients return a result code that says when a message was throttled. Long or frequent traffic goes through a library the repository already embeds (AceComm-3.0, ChatThrottleLib). Channels and their availability (party, raid, guild, whisper; restrictions inside instances or during encounters on current retail) must be verified at the pinned build.

Every received message is untrusted input from another player, as is any pasted import string:

- Check the prefix, the sender's channel and an explicit protocol version first; ignore what you do not understand.
- Bound sizes before decompressing or deserializing (LibDeflate, LibSerialize or AceSerializer), and bound the number and depth of fields after.
- Validate types and ranges of every field. Never pass received data to `loadstring`, never use it as a path into globals or tables of functions, and never let it trigger protected actions.
- Rate-limit per sender what a message can cause (UI updates, replies, sound).

Version the wire format: a new client must read messages from older versions or drop them cleanly, and an old client must survive messages from newer ones. A protocol change is `design-gated`, and untrusted-input handling engages `security-engineer`.
