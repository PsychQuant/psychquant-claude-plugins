---
name: all
description: |
  Query ALL AI platform documentation at once (OpenAI, Gemini, Claude).
  Use this skill when:
  - Comparing features across AI platforms (e.g., structured output, function calling, vision)
  - Need to check how multiple providers handle the same concept
  - Building multi-provider AI applications
  - User says "all AI docs" or wants a cross-platform comparison
argument-hint: "[topic to look up across all providers]"
allowed-tools: WebFetch
---

# All AI Docs Guide

Query OpenAI, Gemini, and Claude documentation simultaneously via WebFetch.

## When to Use

When the user wants to compare or look up information across multiple AI providers at once.

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation from ALL THREE providers - never answer from memory!**

### Step 1: Identify the topic

The user's query: $ARGUMENTS

### Step 2: WebFetch from all three providers IN PARALLEL

Launch parallel WebFetch calls to all three documentation sources based on the topic.

**URL Mapping by Topic:**

| Topic | OpenAI | Gemini | Claude |
|-------|--------|--------|--------|
| Models | https://developers.openai.com/docs/models | https://ai.google.dev/gemini-api/docs/models | https://platform.claude.com/docs/en/docs/about-claude/models |
| Text generation | https://developers.openai.com/docs/guides/text | https://ai.google.dev/gemini-api/docs/text-generation | https://platform.claude.com/docs/en/docs/build-with-claude/text-generation |
| Vision / Images | https://developers.openai.com/docs/guides/images-vision | https://ai.google.dev/gemini-api/docs/image-understanding | https://platform.claude.com/docs/en/docs/build-with-claude/vision |
| Structured output | https://developers.openai.com/docs/guides/structured-outputs | https://ai.google.dev/gemini-api/docs/structured-output | https://platform.claude.com/docs/en/docs/build-with-claude/structured-output |
| Function calling | https://developers.openai.com/docs/guides/function-calling | https://ai.google.dev/gemini-api/docs/function-calling | https://platform.claude.com/docs/en/docs/agents-and-tools/tool-use |
| Audio | https://developers.openai.com/docs/guides/audio | https://ai.google.dev/gemini-api/docs/audio | https://platform.claude.com/docs/en/docs/build-with-claude/audio |
| Embeddings | https://developers.openai.com/docs/guides/embeddings | https://ai.google.dev/gemini-api/docs/embeddings | https://platform.claude.com/docs/en/docs/build-with-claude/embeddings |
| Pricing | https://developers.openai.com/docs/pricing | https://ai.google.dev/gemini-api/docs/pricing | https://platform.claude.com/docs/en/docs/about-claude/pricing |
| Rate limits | https://developers.openai.com/docs/guides/rate-limits | https://ai.google.dev/gemini-api/docs/rate-limits | https://platform.claude.com/docs/en/docs/build-with-claude/rate-limits |
| Batch API | https://developers.openai.com/docs/guides/batch | https://ai.google.dev/gemini-api/docs/batch-api | https://platform.claude.com/docs/en/docs/build-with-claude/batch-processing |
| Streaming | https://developers.openai.com/docs/guides/streaming-responses | https://ai.google.dev/gemini-api/docs/text-generation | https://platform.claude.com/docs/en/docs/build-with-claude/streaming |
| Prompt caching | https://developers.openai.com/docs/guides/prompt-caching | https://ai.google.dev/gemini-api/docs/caching | https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching |
| Reasoning | https://developers.openai.com/docs/guides/reasoning | https://ai.google.dev/gemini-api/docs/thinking | https://platform.claude.com/docs/en/docs/build-with-claude/extended-thinking |
| Computer use | https://developers.openai.com/docs/guides/tools-computer-use | https://ai.google.dev/gemini-api/docs/computer-use | https://platform.claude.com/docs/en/docs/agents-and-tools/computer-use |
| MCP | https://developers.openai.com/docs/guides/tools-connectors-mcp | — | https://platform.claude.com/docs/en/docs/agents-and-tools/mcp |
| Image generation | https://developers.openai.com/docs/guides/image-generation | https://ai.google.dev/gemini-api/docs/image-generation | — |
| Video generation | https://developers.openai.com/docs/guides/video-generation | https://ai.google.dev/gemini-api/docs/video | — |
| Code execution | https://developers.openai.com/docs/guides/tools-code-interpreter | https://ai.google.dev/gemini-api/docs/code-execution | — |
| Web search | https://developers.openai.com/docs/guides/tools-web-search | https://ai.google.dev/gemini-api/docs/google-search | — |
| Agents | https://developers.openai.com/docs/guides/agents | https://ai.google.dev/gemini-api/docs/coding-agents | https://platform.claude.com/docs/en/docs/agents-and-tools/claude-ai-agents |
| Fine-tuning | https://developers.openai.com/docs/guides/supervised-fine-tuning | — | https://platform.claude.com/docs/en/docs/build-with-claude/fine-tuning |
| Tokens | — | https://ai.google.dev/gemini-api/docs/tokens | — |
| Long context | — | https://ai.google.dev/gemini-api/docs/long-context | https://platform.claude.com/docs/en/docs/build-with-claude/context-windows |

### Step 3: Present findings

After fetching from all providers, present a structured comparison:

```
## [Topic]

### OpenAI
[Key findings]

### Gemini
[Key findings]

### Claude
[Key findings]

### Comparison Summary
| Feature | OpenAI | Gemini | Claude |
|---------|--------|--------|--------|
| ... | ... | ... | ... |
```

## If topic is not in the table

Construct URLs based on each provider's pattern:
- OpenAI: `https://developers.openai.com/docs/guides/<topic-slug>`
- Gemini: `https://ai.google.dev/gemini-api/docs/<topic-slug>`
- Claude: `https://platform.claude.com/docs/en/docs/build-with-claude/<topic-slug>`

## Important Reminders

- **Always WebFetch all three providers** - never answer from memory
- **Parallel calls** - fetch all three at the same time for speed
- If one provider doesn't support a feature, note it explicitly
- "—" in the table means that provider doesn't have a direct equivalent
