---
name: search
description: Search academic papers via Semantic Scholar or Zotero library
argument-hint: [query]
allowed-tools:
  - mcp__che-zotero-mcp__academic_search
  - mcp__che-zotero-mcp__zotero_search
  - mcp__che-zotero-mcp__zotero_semantic_search
  - mcp__che-zotero-mcp__zotero_search_by_doi
  - mcp__che-zotero-mcp__academic_search_author
---

# Academic Search

1. If query looks like a DOI → use `zotero_search_by_doi`
2. If query looks like an author name → use `academic_search_author`
3. Otherwise → use `academic_search` for external papers, `zotero_search` for library
4. Show results with title, authors, year, DOI, and citation count
