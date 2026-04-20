---
name: search-notes
description: Search Apple Notes by keyword and show matching titles + snippets
allowed-tools:
  - mcp__che-apple-notes-mcp__search_notes
  - mcp__che-apple-notes-mcp__get_note
---

# Search Notes

Search Apple Notes via `search_notes` and summarise results.

Steps:
1. Parse the keyword(s) from the user's input.
2. For multiple keywords, default to `match_mode: "any"` (OR). If the user says
   "all of X Y Z", use `match_mode: "all"`.
3. Call `search_notes(keywords: [...], match_mode, limit: 10)`.
4. Present results as a numbered list with title, folder, modified date.
5. If the user then asks for details on a specific result, call `get_note`.

Default limit: 10. Adjust if the user asks for more.
