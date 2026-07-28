---
name: gemini-docs-guide
description: |
  Query Google Gemini API documentation with accurate, up-to-date information.
  Use this skill proactively when the conversation involves:
  - Gemini API usage (text generation, multimodal, structured output)
  - Google AI SDK (Python, Node.js, Go, Java, C#)
  - Function calling, tools, Google Search grounding
  - Gemini models (Gemini 3, 2.5, Flash, Pro, Nano)
  - Live API, WebSocket streaming
  - Image/video/audio generation (Veo, Imagen, Lyria)
  - Gemini model selection, pricing, rate limits
  - Google AI Studio, computer use, deep research
allowed-tools: WebFetch
---

# Gemini Docs Guide

Query Google Gemini API official documentation directly via WebFetch.

## When to Use

When the user asks about or the conversation involves:
- Gemini API endpoints or SDK usage
- Model selection or capabilities (Gemini 3, 2.5, Flash, Pro)
- Function calling, tools, structured outputs
- Live API, multimodal input/output
- Image/video/audio generation
- Any Google Gemini product or feature

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the topic and WebFetch the corresponding URL

Base URL: `https://ai.google.dev`

**Getting Started:**

| Topic | URL |
|-------|-----|
| Overview | /gemini-api/docs |
| Quickstart | /gemini-api/docs/quickstart |
| API keys | /gemini-api/docs/api-key |
| SDK libraries | /gemini-api/docs/libraries |
| Pricing | /gemini-api/docs/pricing |

**Models:**

| Topic | URL |
|-------|-----|
| All models overview | /gemini-api/docs/models |
| Gemini 3 | /gemini-api/docs/gemini-3 |
| Image generation (Nano Banana) | /gemini-api/docs/image-generation |
| Video generation (Veo) | /gemini-api/docs/video |
| Music generation (Lyria) | /gemini-api/docs/music-generation |
| Imagen | /gemini-api/docs/imagen |
| Speech generation (TTS) | /gemini-api/docs/speech-generation |
| Embeddings | /gemini-api/docs/embeddings |

**Core Capabilities:**

| Topic | URL |
|-------|-----|
| Text generation | /gemini-api/docs/text-generation |
| Image understanding | /gemini-api/docs/image-understanding |
| Video understanding | /gemini-api/docs/video-understanding |
| Document processing | /gemini-api/docs/document-processing |
| Audio | /gemini-api/docs/audio |
| Thinking (reasoning) | /gemini-api/docs/thinking |
| Structured output | /gemini-api/docs/structured-output |
| Function calling | /gemini-api/docs/function-calling |
| Long context | /gemini-api/docs/long-context |

**Tools & Agents:**

| Topic | URL |
|-------|-----|
| Tools overview | /gemini-api/docs/tools |
| Deep research | /gemini-api/docs/deep-research |
| Google Search grounding | /gemini-api/docs/google-search |
| Maps grounding | /gemini-api/docs/maps-grounding |
| Code execution | /gemini-api/docs/code-execution |
| URL context | /gemini-api/docs/url-context |
| Computer use | /gemini-api/docs/computer-use |
| File search | /gemini-api/docs/file-search |

**Live API (real-time streaming):**

| Topic | URL |
|-------|-----|
| Live API overview | /gemini-api/docs/live |
| Live guide | /gemini-api/docs/live-guide |
| Live tools | /gemini-api/docs/live-tools |
| Live session management | /gemini-api/docs/live-session |
| Ephemeral tokens | /gemini-api/docs/ephemeral-tokens |

**Guides:**

| Topic | URL |
|-------|-----|
| Coding agents | /gemini-api/docs/coding-agents |
| Batch API | /gemini-api/docs/batch-api |
| File input methods | /gemini-api/docs/file-input-methods |
| Files API | /gemini-api/docs/files |
| Context caching | /gemini-api/docs/caching |
| OpenAI compatibility | /gemini-api/docs/openai |
| Media resolution | /gemini-api/docs/media-resolution |
| Tokens & counting | /gemini-api/docs/tokens |
| Prompting strategies | /gemini-api/docs/prompting-strategies |

**Safety:**

| Topic | URL |
|-------|-----|
| Safety settings | /gemini-api/docs/safety-settings |
| Safety guidance | /gemini-api/docs/safety-guidance |

**Framework Integrations:**

| Topic | URL |
|-------|-----|
| LangGraph | /gemini-api/docs/langgraph-example |
| CrewAI | /gemini-api/docs/crewai-example |
| LlamaIndex | /gemini-api/docs/llama-index |
| Vercel AI SDK | /gemini-api/docs/vercel-ai-sdk-example |

**Resources:**

| Topic | URL |
|-------|-----|
| Changelog | /gemini-api/docs/changelog |
| Deprecations | /gemini-api/docs/deprecations |
| Rate limits | /gemini-api/docs/rate-limits |
| Billing | /gemini-api/docs/billing |
| Migration guide | /gemini-api/docs/migrate |
| Troubleshooting | /gemini-api/docs/troubleshooting |
| Available regions | /gemini-api/docs/available-regions |

**Google AI Studio:**

| Topic | URL |
|-------|-----|
| AI Studio quickstart | /gemini-api/docs/ai-studio-quickstart |
| Build mode | /gemini-api/docs/aistudio-build-mode |
| Full-stack apps | /gemini-api/docs/aistudio-fullstack |

**API Reference:**

| Topic | URL |
|-------|-----|
| All methods | /api/all-methods |
| Models | /api/models |
| Generate content | /api/generate-content |
| Live API | /api/live |
| Tokens | /api/tokens |
| Files | /api/files |
| Batch API | /api/batch-api |
| Caching | /api/caching |
| Embeddings | /api/embeddings |

### Step 2: WebFetch with full URL

Prepend `https://ai.google.dev` to the path:

```
WebFetch("https://ai.google.dev/gemini-api/docs/function-calling", "Extract the documentation content about...")
```

### Step 3: Parse and respond

Extract relevant information from WebFetch results and answer the user directly.

## If topic is not in the table

If you can't find the right URL:
1. WebFetch the main docs page: `https://ai.google.dev/gemini-api/docs`
2. Look for relevant links in the navigation
3. Try constructing a URL based on the pattern `/gemini-api/docs/<topic-slug>`

## Important Reminders

- **Never answer Gemini API questions from memory** - always WebFetch first
- Base URL is `https://ai.google.dev` (NOT `https://cloud.google.com` - that's Vertex AI, a different product)
- API reference pages use `/api/` prefix, guide pages use `/gemini-api/docs/` prefix
- Gemini has OpenAI-compatible endpoints documented at `/gemini-api/docs/openai`
