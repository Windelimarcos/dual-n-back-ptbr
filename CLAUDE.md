# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A personal, Brazilian Portuguese (pt-BR) implementation of the Dual N-Back brain-training exercise. The entire app is a single static file, `jogo.html`, with no dependencies, build step, or package manager — just HTML, CSS, and vanilla JS in one `<script>` block.

## Running the App

There is no build/lint/test tooling in this repo. To run the game, open `jogo.html` directly in a browser:

```
open jogo.html
```

The audio channel uses the browser's built-in Web Speech API (`SpeechSynthesisUtterance`), so it must be run in an actual browser (not headless) and voice quality/availability for `pt-BR` depends on the OS/browser's installed voices.

## Architecture

Everything lives in `jogo.html`:

- **Markup**: a fixed top-right `.top-bar` with two icon buttons (`?` instructions, `⚙` settings) that toggle two overlays — `#settingsPanel` (N stepper, voice `<select>`, speed slider) and `#instructionsModal` (how-to-play text) — plus the static 3x3 grid (`#c0`–`#c8` cells), the POSIÇÃO/SOM/start buttons, and the hits/misses + level-adjustment message display.
- **State**: global mutable variables — `n` (current N-back level, persisted in `localStorage['dualnback_n']`), `sequence` (the whole round pre-generated up front — array of `{pos, letterIdx, letter}` per step), `history` (append-only array of `{pos, letter, posClicked, letterClicked}` trial objects for the running session), `hits`, `misses`, `isPlaying`, `selectedVoice`, `speechRate` (persisted in `localStorage['dualnback_voiceURI']` / `['dualnback_rate']`).
- **Sequence generation**: `buildSequence()` (ported from dual-n-back.io's `buildGameSequence()`) builds the entire round *before* it starts so match counts are guaranteed instead of left to per-trial chance. Round length is `n + SCORED_TRIALS` (= `n + 20`): the first `n` steps are warm-up (unscoreable), the remaining 20 are scored. It picks `POS_MATCHES - DOUBLE_MATCHES` (4) position-only match steps, `LETTER_MATCHES - DOUBLE_MATCHES` (4) sound-only match steps, and `DOUBLE_MATCHES` (2) double-match steps — so exactly 6 position + 6 sound repeats per round, 2 of them coinciding. Match steps copy the stimulus from `n` steps back; all other steps pick a value *guaranteed not to equal* the one `n` back (via the `if (v >= seq[i-n].x) v++` skip-the-excluded-value trick).
- **Game loop**: `startGame()` resets state, calls `buildSequence()`, then `nextTurn()`. `nextTurn()` reads `sequence[history.length]`, pushes a trial record to `history`, shows/speaks it, then re-schedules itself via nested `setTimeout` calls until `history.length` reaches `sequence.length`, at which point it calls `applyLevelAdjustment()`.
- **Stimulus timing**: display duration and inter-trial interval are hardcoded inside `nextTurn()`'s `setTimeout` calls (1000ms display, 2000ms gap between trials).
- **Audio**: `speak()` wraps `SpeechSynthesisUtterance` with `lang` hardcoded to `pt-BR`, plus the selected `voice` and `rate`. `loadVoices()`/`populateVoiceSelect()` fill the voice `<select>` from `speechSynthesis.getVoices()` (re-run on `onvoiceschanged` since Chrome loads voices asynchronously), defaulting to: a saved `localStorage` choice, then a voice named like "Google português do Brasil", then any voice with `natural`/`enhanced`/`premium`/`neural` in its name, then the first available.
- **Matching/scoring**: `checkMatch(type)` compares the latest `history` entry against the entry `n` steps back, flags `posClicked`/`letterClicked` on that trial (used later for the level algorithm), and increments the live `hits`/`misses` display counters. Invoked via the POSIÇÃO/SOM buttons or keyboard shortcuts (`A` = position, `L` = sound).
- **Adaptive N-level**: `calculateLevelDelta()` runs once per completed round and computes a d′-style score (hit rate minus false-alarm rate, averaged across the position and audio channels) over the trials in `history`; `applyLevelAdjustment()` then moves `n` by ±1 (clamped to `[N_MIN, N_MAX]` = `[1, 9]`) and writes a colored message to `#level-msg`. The `> 0.85` level-up / `< 0.7` level-down thresholds mirror the logic in the reference app [dual-n-back.io](https://dual-n-back.io) (`js/logic.js`, `calculateScore()`). Because `buildSequence()` now guarantees exactly 6 position + 6 sound matches per round (same as the reference's generator), `calculateLevelDelta()` divides by the actual counted matches/non-matches — which equals the reference's hardcoded `/6` and `/(len-6)` divisors, but stays correct even if the match counts are ever tuned. `n` can also be changed manually via the settings panel's stepper, which is disabled while `isPlaying`.
- **Rendering**: `showPos()`/`clearGrid()` toggle the `.active` CSS class directly via DOM queries; `toggleSettings()`/`toggleInstructions()` toggle an `.open` class on the two overlays (mutually exclusive) — no framework or virtual DOM.

## Current Hardcoded Parameters

- Session length: `n + SCORED_TRIALS` steps per round (`SCORED_TRIALS = 20` scored + `n` warm-up); loop ends when `history.length` reaches `sequence.length`.
- Guaranteed matches per round: `POS_MATCHES = 6` position + `LETTER_MATCHES = 6` sound, of which `DOUBLE_MATCHES = 2` coincide on the same step.
- Stimulus/interval timing: 1000ms display + 2000ms gap, hardcoded in `nextTurn`'s `setTimeout` calls (3000ms/step, matching the reference's `iFrequency`).
- Audio stimulus set: fixed 6-letter array (`A`–`F`); grid has `NUM_POSITIONS = 9` cells.
- N-level bounds: `N_MIN = 1`, `N_MAX = 9`.

All UI strings and spoken audio are in Portuguese (pt-BR) — keep new user-facing text consistent with that. The instructions modal text is adapted/translated from dual-n-back.io's own instructions (fetched from its page source), not a verbatim copy, since this app's controls (button labels, 9-cell grid) differ from the reference.
