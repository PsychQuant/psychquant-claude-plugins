# mcs.pdf — Mathematics for Computer Science (pointer)

This directory may contain `mcs.pdf` — a local-only copy of Lehman / Leighton / Meyer, *Mathematics for Computer Science*, MIT OpenCourseWare textbook for 6.042J.

## Status

`mcs.pdf` is **git-ignored** (see [`../.gitignore`](../.gitignore)). Marketplace installs of this plugin do NOT bundle the PDF — only this pointer file is shipped.

If you want the PDF locally:

```bash
# Free download from MIT OCW (CC BY-NC-SA 4.0):
curl -o ~/Downloads/mcs.pdf \
  https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-spring-2015/resources/mit6_042js15_textbook/
# Or browse: https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-spring-2015/
# Then drop it here:
cp ~/Downloads/mcs.pdf <this-plugin>/references/mcs.pdf
```

`.gitignore` ensures the binary stays out of marketplace git history regardless.

## Why this convention

13 MB textbook × 39 plugins in the marketplace = git history bloat that hurts everyone. CC BY-NC-SA license also requires attribution + share-alike preservation, which is fragile when distributing through a marketplace. Local-only + pointer is the cleanest compromise.

## License (if you redistribute)

Lehman, Eric, F. Thomson Leighton, and Albert R. Meyer. *Mathematics for Computer Science*. MIT OpenCourseWare. License: CC BY-NC-SA 4.0. Source: <https://ocw.mit.edu>.

## Use cases inside math-tools

This pointer exists in case future skill bodies (v0.2.0+) want to cite MCS as a methodology reference (e.g. discrete math foundations for propositions extraction, induction proof patterns for L4 walk). v0.1.0 scaffolding doesn't yet — keep this pointer minimal for now.
