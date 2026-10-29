---
title: Documentation Front Matter Hook
description: Enforces standard metadata whenever a Markdown document is created or updated.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, documentation, front-matter]
---

# Documentation Front Matter

When a `.md` file is created without YAML front matter, inject this template at the first line and prompt the author to complete it before review:

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

Validate that all required fields are populated with concrete values before proposing a commit or PR.