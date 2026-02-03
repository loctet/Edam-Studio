# EDAM Studio Documentation

This folder contains the full documentation for EDAM Studio.

## Contents

| File | Description |
|------|-------------|
| **index.html** | **Start here** — Navigation hub to all documentation |
| `api.html` | Python API routes, handlers, parameters |
| `codegen.html` | Code generation: process, OCaml, Contract, Solidity |
| `api-deep.html` | API & Code Gen deep dive: EDAM→Solidity, transitions, parser, synthesis, adding Move, tests, ZIP |
| `frontend.html` | GUI components, props, state, functions |
| `ocaml.html` | OCaml files, types, functions with parameters |
| `studio-documentation.md` | Source Markdown (editable) |
| `studio-documentation.html` | Full doc: flow, scripts, config, troubleshooting |
| `doc-style.css` | Base stylesheet |
| `doc-nav.css` | Navigation/sidebar styles |
| `build-docs.ps1` | Build script for Windows (PowerShell) |
| `build-docs.sh` | Build script for Linux/macOS (Bash) |

## Viewing the Documentation

**Start with `index.html`** — it provides iterative navigation to:

- **API** — All Python routes and handlers with parameters
- **Code Gen** — Process, base generator, OCaml generator, Contract generator, Solidity generator
- **Frontend** — EDAMEditor, CodeGenerationResults, ConfigModal, utils, and other components
- **OCaml** — All .ml files with types and functions (parameters explained)
- **Full Doc** — Complete flow, scripts, configuration, troubleshooting

Open `index.html` in a browser. All CSS files must be in the same directory.

## Regenerating the HTML

After editing `studio-documentation.md`, regenerate the HTML:

### Windows (PowerShell)

```powershell
cd Documentation
.\build-docs.ps1
```

### Linux/macOS

```bash
cd Documentation
chmod +x build-docs.sh
./build-docs.sh
```

## Requirements

- **Pandoc** 3.x — [Download](https://pandoc.org/installing.html)

## Tool Choice: Why Pandoc?

Pandoc is the standard universal document converter. It:

- Converts Markdown → HTML (and many other formats)
- Produces clean, semantic HTML5
- Supports table of contents, syntax highlighting, metadata
- Works offline with no build dependencies beyond Pandoc
- Keeps source in readable Markdown for easy editing

**Alternatives considered:**

- **TypeDoc/JSDoc** — For API docs from TypeScript/JavaScript code only
- **Sphinx** — For Python API docs; heavier setup
- **MkDocs** — Requires Python and extra packages

For consolidated project documentation (README + setup + API reference + structure), Pandoc from a single Markdown file is the simplest and most portable approach.
