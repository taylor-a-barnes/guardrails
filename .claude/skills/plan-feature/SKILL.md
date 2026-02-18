---
name: plan-feature
description: Helps the user plan a feature. Use when the user asks for help designing or planning a feature, or when the user asks you to write a feature that is not already planned out in a requirements file.
allowed-tools: Read, Grep, Glob, AskUserQuestion
---

Ask the user clarifying questions regarding the planned feature.  Anticipate edge cases, and ask the user how they should be handled.

Do not start implementation. Focus only on planning and documentation.

Create a requirements markdown file in the `req` directory.  The file name should be brief and descriptive of the feature.  The file should begin with a clear description of the feature.  It should also include Gherkin scenarios to clearly indicate the requirements.  Include Gherkin scenarios for any edge cases.  Be complete and thorough.

