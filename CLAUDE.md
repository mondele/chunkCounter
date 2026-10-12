# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChunkCounter is a Bible translation resource comparison tool built with Free Pascal / Lazarus. It compares "chunks" (translation segments) across languages and resource types in the BTT-Writer ecosystem, identifying differences between source resources and target translations.

## Build Commands

Requires Free Pascal Compiler and Lazarus (lazbuild 4.0+).

```bash
# Build the main GUI application (currently has compile errors in mainform.pas)
lazbuild chunkCounter.lpi

# Build the test/CLI program (this compiles successfully)
lazbuild TestBibleResourceManager.lpi

# Run the CLI test tool
./TestBibleResourceManager -1 arb -2 arb -r1 nav -r2 avd -book gen -v
```

### TestBibleResourceManager CLI flags
- `-1` / `-2`: language codes to compare
- `-r1` / `-r2`: resource types to compare
- `-book`: book code (e.g., `gen`, `exo`)
- `-v`: verbose output
- `-h`: help

## Architecture

### Data Model Hierarchy

```
TLanguageContainer (BibleResourceManager.pas)
  └─ Languages: map by language code
     └─ Books: map by "{bookCode}_{resourceType}"
        └─ TBook (BibleBook.pas)
           └─ TChapterList: chapters by ID
              └─ TChapter (BibleChapter.pas)
                 └─ TChunkList
                    └─ TChunk (BibleChunk.pas) — Name + ExistsOnDisk flag
```

### Key Units

- **BibleResourceManager.pas** — Top-level manager. Loads resource containers from BTT-Writer library paths, organizes by language, and provides `CompareBooks()` for cross-language/resource comparison.
- **BibleBook.pas** — Loads a book from disk by parsing `toc.yml`. `CompareWith()` returns chapter-level differences.
- **BibleChapter.pas** — `CompareChunks()` returns a TStringList of differences between two chapters.
- **BibleChunk.pas** — `IsEquivalentTo()` compares chunk name and disk existence.
- **ResourceContainerUnit.pas** — Structures for resource containers and content folders.
- **ManifestProcessor.pas** — Parses JSON manifest files from resource containers.
- **climenu.pas** — Reusable recursive CLI menu framework.
- **Globals.pas** — Global `Verbose` flag.

### BTT-Writer Library Paths

Resource containers are loaded from platform-specific BTT-Writer library locations:
- Linux: `~/.config/BTT-Writer/library/resource_containers/`
- macOS: `~/Library/Application Support/BTT-Writer/library/resource_containers/`
- Windows: `%APPDATA%\Local\BTT-Writer\library\resource_containers\`

Directory naming convention: `{langCode}_{bookCode}_{resourceType}` (e.g., `arb_gen_nav`).

### Current State

The GUI app (`chunkCounter.lpi`) has compile errors — `mainform.pas` references a removed `ParseResourceDirName` method. The CLI test programs compile and work. Test programs (`TestBibleChunk.lpr`, `TestBibleChapter.lpr`, `TestBibleBook.lpr`, `TestBibleResourceManager.lpr`) are standalone executables, not a test framework.

## Conventions

- Compiler mode: `{$mode objfpc}{$H+}` (Object Free Pascal with AnsiStrings)
- Unit file names use PascalCase (e.g., `BibleBook.pas`, `BibleChapter.pas`)
- Classes use `T` prefix (e.g., `TBook`, `TChapter`, `TChunk`)
- Platform-specific code uses `{$IFDEF WINDOWS}` / `{$IFDEF DARWIN}` / `{$IFDEF LINUX}` conditionals
