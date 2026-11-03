---
title: Documentation Front Matter Hook
description: Enforces file-type-specific front matter for agent definitions, skills, and other Markdown documents.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, documentation, front-matter]
---

# Documentation Front Matter

Do not inject the full project metadata schema into every `.md` file. Apply front matter requirements by file type:

- Agent definitions in `.github/agents/` use the full project metadata schema below.
- Skills in `.github/skills/<skill-name>/SKILL.md` use Copilot's required `name` and `description` fields.
- Other Markdown files use front matter only when their format or an applicable project requirement calls for it; do not add agent-only fields by default.

When a new agent definition is created without YAML front matter, add this template at the first line and prompt the author to complete it before review:

```yaml
---
title: [Document Title]
description: [One-line description]
author: [Author name or team]
date: YYYY-MM-DD
version: 1.0.0
status: draft | review | approved
tags: [comma-separated tags]
---
```

Validate the fields required for that file type before proposing a commit or PR. For agent definitions, all fields in the template must have concrete values.