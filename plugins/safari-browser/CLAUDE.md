## Design Principle: Non-Interference

All safari-browser commands default to non-interference — users can do other things simultaneously.

- No mouse/keyboard control unless `--allow-hid` / `--native`
- No system dialogs
- No sounds (`screencapture -x`)
- No window focus stealing

New commands must be classified by interference level before implementation.
Full spec: project repo `openspec/specs/non-interference/spec.md`
