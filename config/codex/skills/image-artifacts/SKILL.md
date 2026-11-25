---
name: image-artifacts
description: Create PNG image artifacts when a visual result will make human review easier, and show how to inspect them with kitty icat.
---

# Image artifacts

Use this skill when a task benefits from a human-inspectable image, such as a screen mockup, diagram, chart, or rendered visual result. Do not use it for HTML pages or other non-image deliverables.

## Workflow

1. Resolve `AI_BASE_DIR` from the applicable `AGENTS.md` instructions (default: `ai`).
2. Create the review image as a PNG under `AI_BASE_DIR/tasks/workspace/`. Keep the image focused on the result the user needs to inspect.
3. Confirm the PNG was written successfully and note its path.
4. In your response, link or name the image and tell the user to inspect it with `kitten icat <filename>` (substitute the actual path), for example:

   ```sh
   kitten icat ai/tasks/workspace/example.png
   ```

If image creation fails, report the failure and do not give an inspection command for a file that was not created.
