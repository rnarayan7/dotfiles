---
name: ks
description: Keep short. Answer the message that contains /ks briefly, with no verbose explanation. Invoke only when the user's own message contains /ks.
argument-hint: "[question or task]"
---

# Keep short

The user wants a short answer to the message that contains `/ks`, not a full write-up.

Invoke this skill only when the user's own message contains `/ks`, anywhere in the text. If the
user passed a question or task as an argument, answer that; if not, answer the rest of the same
message.

## Rules

- Lead with the answer in the first line.
- At most about 5 lines or 5 bullets in total. No headers, no tables unless the answer is a
  comparison, and no closing summary or recap.
- Give only what was asked. Leave out background, caveats that do not change the answer, and
  options the user did not ask for.
- Do not offer follow-up work. If one next step is needed, put it in one line.
- If a short answer would be wrong or misleading, say so in one line and give the minimum the
  user needs.

These rules cover only the message that contains `/ks`. The next message goes back to normal
length unless it contains `/ks` again.
