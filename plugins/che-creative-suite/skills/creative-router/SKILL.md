---
description: "Route image tasks to the correct MCP server (svg or pixel). Auto-triggered when user mentions image editing, graphic design, or visual asset creation."
---

# Creative Router

Intelligently route image processing tasks to the correct MCP server.

## Decision Matrix

| Task | MCP Server | Tool Prefix |
|------|-----------|-------------|
| Create shapes, paths, text | **che-svg-mcp** (`svg`) | `mcp__svg__*` |
| Edit vector graphics | **che-svg-mcp** (`svg`) | `mcp__svg__*` |
| Create diagrams, icons, logos | **che-svg-mcp** (`svg`) | `mcp__svg__*` |
| Apply gradients to shapes | **che-svg-mcp** (`svg`) | `mcp__svg__*` |
| Export SVG to PNG/PDF | **che-svg-mcp** (`svg`) | `mcp__svg__export_png`, `mcp__svg__export_pdf` |
| Photo editing, filters | **che-pixel-mcp** (`pixel`) | `mcp__pixel__*` |
| Color adjustment, grading | **che-pixel-mcp** (`pixel`) | `mcp__pixel__adjust_colors` |
| Resize, crop, rotate images | **che-pixel-mcp** (`pixel`) | `mcp__pixel__resize`, `mcp__pixel__crop`, `mcp__pixel__rotate` |
| Blur, sharpen, denoise | **che-pixel-mcp** (`pixel`) | `mcp__pixel__gaussian_blur`, `mcp__pixel__sharpen` |
| Composite/overlay images | **che-pixel-mcp** (`pixel`) | `mcp__pixel__composite` |
| Batch image processing | **che-pixel-mcp** (`pixel`) | `mcp__pixel__batch_process` |
| Format conversion (to raster) | **che-pixel-mcp** (`pixel`) | `mcp__pixel__save_document` |

## Mixed Workflows

When a task requires both vector and raster operations, chain them:

### SVG → Raster Pipeline
1. Create/edit SVG with `mcp__svg__*`
2. Export to PNG: `mcp__svg__export_png`
3. Open PNG in pixel: `mcp__pixel__open_document`
4. Apply raster effects: `mcp__pixel__*`
5. Save final: `mcp__pixel__save_document`

### Raster → SVG Overlay Pipeline
1. Process photo with `mcp__pixel__*`
2. Save processed photo: `mcp__pixel__save_document`
3. Create SVG overlay: `mcp__svg__create_document`
4. Add vector elements: `mcp__svg__add_text`, `mcp__svg__add_rect`, etc.
5. Export SVG overlay: `mcp__svg__export_png`
6. Composite: `mcp__pixel__composite`

## Key Distinctions

### When to use SVG (Vector)
- Scalable graphics that need to look sharp at any size
- Diagrams, flowcharts, UI mockups
- Icons, logos, badges
- Text-heavy graphics
- Graphics that need to be edited element-by-element

### When to use Pixel (Raster)
- Photos and photographs
- Applying visual effects (blur, glow, artistic filters)
- Color correction and grading
- Image compositing and blending
- Batch processing existing image files
- Final export for web/social media

## Availability Check

If a task requires a server that isn't available:
- Check `mcp__svg__*` tools exist for vector tasks
- Check `mcp__pixel__*` tools exist for raster tasks
- Suggest installing the missing plugin if needed
