---
name: plan-feature
description: Helps the user plan a feature. Use when the user asks for help designing or planning a feature, or when the user asks you to write a feature that is not already planned out in a requirements file.
allowed-tools: Read, Grep, Glob, AskUserQuestion
---

Do not start implementation. Focus only on planning and documentation.

## Ask Clarifying Questions

Understand that this is one of the most important steps of this skill.

Ask the user clarifying questions regarding the planned feature. Anticipate edge cases, and ask the user how they should be handled. Present these questions in the form of a menu with numbered choices.

For example, if the user provides the following prompt:

```
Help me plan a feature that parses a basis set file in QSchema format, so that this basis set is subsequently available for use in other parts of my electronic structure code.  Note that basis sets can be acquired from the BSE through the feature described in rqm/basis/bse.md.
```

You might respond with the following menu:

```
──────────────────────────────────────────────────────────────────────────────
←  ☐ Numeric type  ☐ Multi-element  ☐ SP shells  ☐ ECP data  ✔ Submit  →

What should the parsed basis set be represented as? The QCSchema format stores shells with exponents and coefficients as strings — should those be converted to f64 during parsing, or kept as strings for lossless round-tripping?

❯ 1. f64 (Recommended) ✔
     Convert exponents and coefficients to f64 on parse. Convenient for computation; fails fast on malformed data.
  2. String
     Keep as strings. Preserves exact representation; downstream code is responsible for conversion.
  3. Type something.
──────────────────────────────────────────────────────────────────────────────
  4. Chat about this

Enter to select · Tab/Arrow keys to navigate · Esc to cancel
```

Continue requesting clarification from the user until the feature's details are unambiguous.

## Markdown File Location

Create a requirements markdown file in the `rqm` directory.  The file name should be brief and descriptive of the feature.  The file should begin with a clear description of the feature.

## Feature Scope

Features should be as small and self-contained as reasonably possible. Consider whether the user's feature idea can be cleanly subdivided into smaller components. If so, produce multiple smaller requirements files corresponding to each of these natural subdivisions.

You may organize these requirements files into one or more subdirectories of `rqm`.

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

## Examples

A complete example requirements file is available at `.claude/skills/plan-feature/bse.md`.




