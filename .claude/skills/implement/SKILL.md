---
name: implement
description: Helps the user implement a feature.  Use when the user asks for help implementing new code, or when the user asks to implement functionality described in a requirements file.
---

Check for a markdown file in the `req` directory that corresponds to the requested feature. If no such file is found, instead execute the /plan-feature skill.

Ensure that the implemented code satisfies all Gherkin scenarios in the requirements file.

Create at least one test corresponding to every Gherkin scenario.

