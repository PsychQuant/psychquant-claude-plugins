---
name: che-zotero-mcp
description: Guide for using Zotero MCP tools to manage references, search academic papers, generate citations, and build knowledge graphs. Use when user asks about Zotero, citations, bibliography, literature review, academic search, or knowledge graph.
allowed-tools:
  - mcp__che-zotero-mcp__*
---

# Zotero MCP — Academic Reference Management

50 tools across 5 categories for managing academic references and building knowledge.

## Tool Categories

### 1. Zotero Library (18 tools — Start Here)

| Tool | Purpose |
|------|---------|
| `zotero_search` | Search library by keyword |
| `zotero_semantic_search` | AI-powered semantic search (needs `zotero_build_index` first) |
| `zotero_search_by_doi` | Find item by DOI |
| `zotero_get_recent` | Recently added items |
| `zotero_get_metadata` | Full metadata for an item |
| `zotero_get_collections` | List all collections |
| `zotero_get_items_in_collection` | Items in a specific collection |
| `zotero_get_tags` | All tags in library |
| `zotero_get_annotations` | Highlights and notes from PDFs |
| `zotero_get_attachments` | Attached files (PDFs, etc.) |
| `zotero_get_notes` | Standalone notes |
| `zotero_get_my_publications` | Items marked as your publications |
| `zotero_list_groups` | Shared group libraries |
| `zotero_get_config` | Current API configuration |
| `zotero_set_config` | Update API configuration |
| `zotero_find_duplicates` | Detect duplicate items |
| `zotero_normalize_titles` | Fix title casing |
| `zotero_build_index` | Build semantic search index |

### 2. Zotero Write Operations (6 tools)

| Tool | Purpose |
|------|---------|
| `zotero_create_item` | Create item manually |
| `zotero_add_item_by_doi` | Add item by DOI (auto-fills metadata) |
| `zotero_add_attachment` | Attach file to item |
| `zotero_add_to_collection` | Add item to collection |
| `zotero_create_collection` | Create new collection |
| `zotero_delete_item` | Delete item |
| `zotero_delete_collection` | Delete collection |
| `zotero_set_in_my_publications` | Toggle "My Publications" flag |

### 3. Citation & Export (3 tools)

| Tool | Purpose |
|------|---------|
| `zotero_to_apa` | Generate APA citation |
| `zotero_to_biblatex_apa` | Generate BibLaTeX entry (APA style) |
| `resolve_references` | Resolve in-text references to DOIs |

### 4. Academic Search (7 tools — Semantic Scholar + ORCID)

| Tool | Purpose |
|------|---------|
| `academic_search` | Search papers on Semantic Scholar |
| `academic_search_author` | Search by author name |
| `academic_lookup_doi` | Look up paper by DOI |
| `academic_get_citations` | Papers that cite a given paper |
| `academic_get_references` | References of a given paper |
| `academic_compare_papers` | Compare two papers side-by-side |
| `orcid_get_publications` | Get publications from ORCID ID |
| `import_publications_to_zotero` | Import from Semantic Scholar to Zotero |

### 5. Knowledge Graph (13 tools)

| Tool | Purpose |
|------|---------|
| `graph_stats` | Graph overview (nodes, edges, density) |
| `graph_add_node` | Add paper/author/concept node |
| `graph_add_edge` | Add relationship edge |
| `graph_remove_node` | Remove node |
| `graph_remove_edge` | Remove edge |
| `graph_save` | Persist graph to disk |
| `graph_neighbors` | Find connected nodes |
| `graph_shortest_path` | Path between two nodes |
| `graph_co_author_stats` | Co-authorship statistics |
| `graph_citation_network` | Citation flow analysis |
| `graph_community` | Detect research communities |
| `graph_query` | Custom graph queries |
| `graph_import_from_zotero` | Import Zotero library into graph |

## Common Workflows

### Literature Review
1. `academic_search` — find papers on a topic
2. `academic_get_references` — explore key papers' references
3. `import_publications_to_zotero` — add relevant papers to Zotero
4. `zotero_add_to_collection` — organize into collection
5. `zotero_to_biblatex_apa` — generate bibliography entries

### Citation Generation
1. `zotero_search` or `zotero_search_by_doi` — find item
2. `zotero_to_apa` — for in-text or reference list
3. `zotero_to_biblatex_apa` — for LaTeX documents

### Knowledge Graph Analysis
1. `graph_import_from_zotero` — populate graph from library
2. `graph_community` — find research clusters
3. `graph_co_author_stats` — identify key collaborators
4. `graph_citation_network` — trace influence paths

### Semantic Search (First Use)
1. `zotero_build_index` — build vector index (one-time, takes ~30s)
2. `zotero_semantic_search` — search by meaning, not just keywords

## Best Practices

1. **Use `academic_search` for discovery, `zotero_search` for your library** — don't confuse external search with local search
2. **Build semantic index once** — `zotero_build_index` only needs to run when library changes significantly
3. **Use DOI whenever possible** — `zotero_add_item_by_doi` auto-fills all metadata correctly
4. **Check duplicates periodically** — `zotero_find_duplicates` prevents bibliography bloat
5. **Organize with collections** — use `zotero_create_collection` + `zotero_add_to_collection` for project-based organization
