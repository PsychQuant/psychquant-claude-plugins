---
name: openai-docs-guide
description: |
  Query OpenAI API documentation with accurate, up-to-date information.
  Use this skill proactively when the conversation involves:
  - OpenAI API usage (Responses API, Chat Completions, models, pricing)
  - OpenAI SDK (Python, Node.js, Go, Java, C#)
  - Function calling, structured outputs, tool use
  - Agents SDK, Agent Builder, ChatKit
  - Realtime API, WebRTC, WebSocket
  - Fine-tuning, embeddings, moderation
  - Image/video/audio generation, speech-to-text, text-to-speech
  - OpenAI model selection (GPT-4.1, GPT-5, o3, gpt-oss)
allowed-tools: WebFetch
---

# OpenAI Docs Guide

Query OpenAI official documentation directly via WebFetch.

## When to Use

When the user asks about or the conversation involves:
- OpenAI API endpoints or SDK usage
- Model selection or capabilities
- Function calling, tools, structured outputs
- Agents, Realtime API, fine-tuning
- Any OpenAI product or feature

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the topic and WebFetch the corresponding URL

Base URL: `https://developers.openai.com/docs`

**Core Concepts:**

| Topic | URL |
|-------|-----|
| Text generation | /docs/guides/text |
| Code generation | /docs/guides/code-generation |
| Images & vision | /docs/guides/images-vision |
| Audio | /docs/guides/audio |
| Structured outputs | /docs/guides/structured-outputs |
| Function calling | /docs/guides/function-calling |
| Migrate to Responses API | /docs/guides/migrate-to-responses |

**Models & Pricing:**

| Topic | URL |
|-------|-----|
| Models overview | /docs/models |
| Pricing | /docs/pricing |
| Model changelog | /docs/changelog |
| Rate limits | /docs/guides/rate-limits |

**Agents:**

| Topic | URL |
|-------|-----|
| Agents overview | /docs/guides/agents |
| Agent Builder | /docs/guides/agent-builder |
| Agents SDK | /docs/guides/agents-sdk |
| ChatKit | /docs/guides/chatkit |
| Voice agents | /docs/guides/voice-agents |
| Agent evals | /docs/guides/agent-evals |

**Tools:**

| Topic | URL |
|-------|-----|
| Tools overview | /docs/guides/tools |
| Web search | /docs/guides/tools-web-search |
| File search | /docs/guides/tools-file-search |
| Code interpreter | /docs/guides/tools-code-interpreter |
| Image generation tool | /docs/guides/tools-image-generation |
| Computer use | /docs/guides/tools-computer-use |
| MCP connectors | /docs/guides/tools-connectors-mcp |
| Local shell | /docs/guides/tools-local-shell |

**Realtime API:**

| Topic | URL |
|-------|-----|
| Realtime overview | /docs/guides/realtime |
| WebRTC | /docs/guides/realtime-webrtc |
| WebSocket | /docs/guides/realtime-websocket |
| SIP | /docs/guides/realtime-sip |
| Transcription | /docs/guides/realtime-transcription |

**Run & Scale:**

| Topic | URL |
|-------|-----|
| Conversation state | /docs/guides/conversation-state |
| Streaming | /docs/guides/streaming-responses |
| Background tasks | /docs/guides/background |
| Prompt caching | /docs/guides/prompt-caching |
| Prompt engineering | /docs/guides/prompt-engineering |
| Reasoning | /docs/guides/reasoning |
| Webhooks | /docs/guides/webhooks |

**Fine-tuning & Optimization:**

| Topic | URL |
|-------|-----|
| Model optimization | /docs/guides/model-optimization |
| Supervised fine-tuning | /docs/guides/supervised-fine-tuning |
| Vision fine-tuning | /docs/guides/vision-fine-tuning |
| DPO | /docs/guides/direct-preference-optimization |
| Reinforcement fine-tuning | /docs/guides/reinforcement-fine-tuning |

**Specialized Models:**

| Topic | URL |
|-------|-----|
| Image generation | /docs/guides/image-generation |
| Video generation | /docs/guides/video-generation |
| Text-to-speech | /docs/guides/text-to-speech |
| Speech-to-text | /docs/guides/speech-to-text |
| Deep research | /docs/guides/deep-research |
| Embeddings | /docs/guides/embeddings |
| Moderation | /docs/guides/moderation |

**Production:**

| Topic | URL |
|-------|-----|
| Production best practices | /docs/guides/production-best-practices |
| Latency optimization | /docs/guides/latency-optimization |
| Cost optimization | /docs/guides/cost-optimization |
| Batch API | /docs/guides/batch |
| Safety best practices | /docs/guides/safety-best-practices |

**API Reference (for endpoint details):**

| Topic | URL |
|-------|-----|
| Responses API | /docs/api-reference/responses |
| Chat Completions | /docs/api-reference/chat |
| Images | /docs/api-reference/images |
| Audio | /docs/api-reference/audio |
| Embeddings | /docs/api-reference/embeddings |
| Fine-tuning | /docs/api-reference/fine-tuning |
| Files | /docs/api-reference/files |
| Models | /docs/api-reference/models |

### Step 2: WebFetch with full URL

Prepend `https://developers.openai.com` to the path:

```
WebFetch("https://developers.openai.com/docs/guides/function-calling", "Extract the documentation content about...")
```

### Step 3: Parse and respond

Extract relevant information from WebFetch results and answer the user directly.

## If topic is not in the table

If you can't find the right URL:
1. Try the `mcp__openai-docs__search_openai_docs` tool (search works, only fetch is broken)
2. Use the URL from search results with WebFetch
3. Fall back to `WebFetch("https://developers.openai.com/docs/overview", "...")` for the main index

## Important Reminders

- **Never answer OpenAI API questions from memory** - always WebFetch first
- The `mcp__openai-docs__fetch_openai_doc` tool is broken (returns 404) - do NOT use it
- The `mcp__openai-docs__search_openai_docs` tool works fine for discovery
- The `mcp__openai-docs__get_openapi_spec` tool works fine for API endpoint specs
