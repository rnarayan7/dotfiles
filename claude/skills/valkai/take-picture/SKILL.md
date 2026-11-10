---
name: take-picture
description: Capture one window with a click and read the image into this session, then act on any prompt given with it. Use for /take-picture or "take a picture of this window".
argument-hint: "[what to do with the picture]"
---

# Take picture

## 1. Capture

Run:

```bash
f="${TMPDIR:-/tmp}/take-picture-$(date +%Y%m%d-%H%M%S).png"; screencapture -iwo "$f"; ls "$f"
```

The cursor becomes a camera and highlights the window under it. One click captures that window. Use a Bash timeout of 120000.

* **`could not create image from window`, or a blank or desktop-only image:** the terminal app lacks Screen Recording permission. Tell the user to turn it on in System Settings → Privacy & Security → Screen Recording, then quit and reopen the terminal.
* **No file and no error:** the user pressed Esc. Say the capture was canceled and stop.

## 2. Read and answer

Read the PNG with the Read tool.

* **With an argument:** do what it asks with the picture.
* **No argument:** describe the window in one line and wait for the next message.
