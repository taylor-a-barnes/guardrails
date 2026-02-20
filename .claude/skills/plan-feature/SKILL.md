---
name: plan-feature
description: Helps the user plan a feature. Use when the user asks for help designing or planning a feature, or when the user asks for assistance writing, modifying, fleshing out, completing, expanding, or detailing a requirements file.
allowed-tools: Read, Grep, Glob, AskUserQuestion, Write
---

Do not start implementation. Focus only on planning and documentation. Do not write to anything except requirements file(s).

## Examine the Codebase

Read CLAUDE.md, as well as any architecture or design documents referenced by CLAUDE.md.

Check if there is already a requirements file corresponding to the feature in question.  If the user's prompt already appears to be satisfied by an existing requirements file, report this and stop execution of this skill.

If the user's prompt is at least partially different from the existing requirements file, continue executing the skill, but focus on clarifying any required modifications to the existing file. Write any modifications to the existing file.

Check if other existing requirements files describe features that are relevant to the user's prompt.

Scan the relevant source directories to understand existing patterns and determine the project's existing language(s). Use the detected language(s) while executing this skill.

## Example Requirements Files

A complete example requirements file is available at `.claude/skills/plan-feature/bse.md`. Read this file.

## Feature Scope

Features should be as small and self-contained as reasonably possible. Consider whether the user's feature idea can be cleanly subdivided into smaller components. If so, use the AskUserQuestion tool to ask the user if it is acceptable to subdivide the feature into multiple smaller requirements files corresponding to each of these natural subdivisions.

## Ask Clarifying Questions

Use the AskUserQuestion tool to ask the user clarifying questions regarding the planned feature. Anticipate edge cases, and ask the user how they should be handled. Batch related questions into a single call. Continue requesting clarification from the user until every identified edge case has an assigned handling strategy and the API surface is fully specified.

## Markdown File Location

Create a requirements markdown file in the `rqm` directory.  The file name should be brief and descriptive of the feature.  The file should begin with a clear description of the feature.

Features that have been subdivided into smaller components may be organized into appropriate subdirectories of `rqm`.

## Feature API Section

If a feature will create any functions, classes, or types that are expected to be accessible to other portions of the code, the interface to these functions must be clearly indicated, along with the expected behavior.

For example, a feature that implements a function in Rust might include:

```
## Feature API

### Functions

- `fetch_basis(element: &str, basis_name: &str) -> Result<PathBuf, BseError>`
  - Validates the element symbol against the known periodic table (elements 1–118).
  - Normalizes `basis_name` to lowercase and `element` to title case before use in file paths and
    API requests.
  - Checks whether a valid cached file already exists at `data/basis/{basis_name}/{element}.json`.
  - If the cache is missing or corrupt, downloads the basis set data for the given element from the
    BSE REST API in QCSchema (JSON) format, creating any missing directories, and overwrites the
    cache file with the fresh response.
  - Returns the `PathBuf` to the cached file on success.

### Types

- `BseError` — error type returned by `fetch_basis`. Must include at minimum:
  - `InvalidElement(String)` — the element symbol does not correspond to a known element (Z = 1–118).
  - `InvalidBasisSetName(String)` — the basis set name is empty or otherwise malformed before any
    API request is made.
  - `ElementNotInBasisSet { element: String, basis_name: String }` — the basis set exists but does
    not include data for this element.
  - `UnknownBasisSet(String)` — the BSE does not recognise the basis set name (HTTP 404).
  - `NetworkError(String)` — a network or HTTP-level failure (unreachable host, timeout, or
    non-200/404 status code).
  - `IoError(String)` — a filesystem operation failed (directory creation, file write, or file read).
  - `InvalidResponse(String)` — the BSE returned a response that could not be parsed as valid JSON.
```

## Gherkin Scenarios Section

The requirements document must include a section for Gherkin Scenarios. These scenarios should clarify the requirements as well as the proper handling for any edge cases. Be complete and thorough.

When the feature is later implemented, these scenarios will be used to construct unit tests, and they should therefore be designed to be suitable for this purpose. It should ideally be straightforward and reasonable to construct a single unit test corresponding to each scenario.

The following provides a subset of the Gherkin scenarios that might be included in the Gherkin Scenarios section:

```gherkin
Feature: Fetch basis set from Basis Set Exchange

  Background:
    Given the BSE base URL is "https://www.basissetexchange.org"

  Scenario: Download a basis set that is not cached
    Given the file "data/basis/sto-3g/H.json" does not exist
    And the BSE API will return a valid QCSchema JSON response for element "H" and basis "sto-3g"
    When fetch_basis("H", "sto-3g") is called
    Then the file "data/basis/sto-3g/H.json" is created
    And the file contains the JSON response returned by the BSE API
    And fetch_basis returns Ok with the path "data/basis/sto-3g/H.json"

  Scenario: Return cached file when a valid cache exists
    Given a non-empty, valid JSON file exists at "data/basis/sto-3g/H.json"
    When fetch_basis("H", "sto-3g") is called
    Then no HTTP request is made to the BSE API
    And fetch_basis returns Ok with the path "data/basis/sto-3g/H.json"

  Scenario: Reject an unrecognised element symbol
    When fetch_basis("Xx", "sto-3g") is called
    Then no HTTP request is made to the BSE API
    And fetch_basis returns Err(BseError::InvalidElement("Xx"))

  Scenario: Basis set name is not known to the BSE
    Given the file "data/basis/unknown-basis/H.json" does not exist
    And the BSE API will return HTTP 404 for element "H" and basis "unknown-basis"
    When fetch_basis("H", "unknown-basis") is called
    Then fetch_basis returns Err(BseError::UnknownBasisSet("unknown-basis"))
    And no file is written to disk
```

## Other Sections

Add any other sections that are useful for specifying the feature requirements, or for handling the implementation. These sections can optionally include Data Model, Performance Constraints, Security Considerations, Migration Notes, External API Details, etc.

