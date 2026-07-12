# CLAUDE.md

This file provides guidance to Claude Code, Codex, Cursor and other code agents when working with code in this repository.

## Project Overview

A Brazilian Portuguese (pt-BR), mobile-first port of the Dual N-Back brain-training game at [dual-n-back.io](https://dual-n-back.io) (GPL v3, by Jonathan Perry-Houts — source at github.com/jperryhouts/Dual-N-Back). The goal is behavior-identical gameplay to that reference, localized to pt-BR, deployable on GitHub Pages. The entire app is a single static file, `index.html`, with no dependencies or build step — HTML, CSS, vanilla JS, and the recorded letter audio embedded as base64.

## Running the App

No build/lint/test tooling. Open `index.html` directly in a browser (`open index.html`) — audio is embedded, so it works from `file://` and over HTTP alike. Deploy = push to GitHub and enable Pages on the repo root.

## Architecture (all in `index.html`)

- **Screens**: six absolutely-positioned `.screen` divs toggled by `showScreen()` (`SCREENS` array) — home (`N = X`, play button, `X / 20 hoje` counter), game (8-square SVG board, eye/speaker buttons), score (per-channel Acertos/Erros/Alarmes falsos table, colored d′ and N), help (instructions/credits), stats (charts) and rank (family ranking) — plus a slide-in config drawer (`#menu` + `#shader`). Navigation mirrors the reference: `history.pushState`/`onpopstate`, so the phone's back button works.
- **Game logic is a 1:1 port of the reference's `js/logic.js`** — same function names (`buildGameSequence`, `calculateScore`, `doTimestep`, `startGame`, `get_n_games`…), same constants (`N_plus = 20` scored steps after `N` warm-ups, `iFrequency = 3000` ms per step via `setInterval`), same sequence guarantees (4 position-only + 4 sound-only + 2 double matches per round, non-match steps use the skip-the-excluded-value trick), same scoring (`d′ = hit rate − false-alarm rate` with the reference's hardcoded `/6` divisors; `> 0.85` levels up, `< 0.7` levels down, floor N=1, **no ceiling**), same click bookkeeping (clicks recorded as `time - 1` step indices with press delays). When changing gameplay behavior, diff against the reference source first (`curl -s -A "Mozilla/5.0" https://dual-n-back.io/js/logic.js`).
- **Persistence**: localStorage keys `N`, `stats`, `config` with the *same JSON shapes as the reference*, so exported backups are interchangeable with dual-n-back.io's. `stats.games[]` entries: `{time, N, vStack, lStack, vClicks, lClicks, vDelays, lDelays, v}`. `config.reset_n` optionally resets N to 1 on the first play of each day. Init migrates the old `dualnback_n` key from the previous version of this app.
- **Audio**: 14 pt-BR letter recordings (the user's own voice) embedded in `AUDIO_B64` (base64 m4a/AAC). The game uses 10 of them, listed in `LETTERS` — chosen by dropping the most confusable pt-BR letter names (cê≈zê, gê≈dê, êne≈ême, pê≈bê); edit that array to swap letters. Playback is Web Audio API: `initAudio()` must be called from a user gesture (iOS requirement — the play/replay buttons do this), decodes all buffers once, then `playLetter()` plays `AudioBufferSourceNode`s.
- **Board flash**: the reference's paused-CSS-animation trick (`.box` with `fade 3s` keyframes, lit from 1%–17%); `setActiveBox()` restarts the animation via reflow instead of the original's node-cloning.
- **Stats charts**: dependency-free SVG step charts (`drawStepChart`) — N per round and mean reaction time — with crosshair+tooltip on hover/touch, plus a `<details>` table of the last 20 rounds (d′ recomputed from stored stacks via `scoreRound`).
- **Input**: `pointerdown` everywhere (fast on mobile); keyboard left = `a`/`d`/`j` (position), right = `;`/`f`/`k` (sound), per Blacker et al. 2017.
- **Ranking da família** (the *only* networked feature — everything else is offline): opt-in shared leaderboard over a single `RANK_URL` constant (kvdb.io bucket, kvdb-style REST). Username is the identity: `rankSlug()` (lowercase, de-accented, `[a-z0-9-]`) → key `u_<slug>`; joining stores `config.rank_user`. Each client **recomputes its own entry from local `stats` on every push** (`computeMyRankEntry`: weekly points = Σ N for rounds in the current ISO week via `isoWeekKey`, plus best-N, day-streak) — so entries self-heal and never drift from the server, and re-writing keeps kvdb's 3-month key TTL fresh. `rankPush()` runs at round end (in `doTimestep`) and on opening the screen; `rankFetchAll` lists `u_*` and `drawRankTable` sorts by weekly points (zeroing stale-week rows client-side), highlights the `me` row, renders medals/🔥streak. Names are injected via `textContent` only (untrusted). **Activation caveat:** a kvdb bucket rejects writes (403) until its owner clicks the email verification link; reads (403-free) still return `[]`, so the board degrades gracefully. Swapping backends (e.g. to Firebase RTDB) is a one-line `RANK_URL` + `rankPush`/`rankFetchAll` change. `config.rank_user` is not part of the exported backup (`downloadStats` exports only `{N, stats}`), so reference-backup interchange is unaffected.

## Audio pipeline

- `assets/audio/raw/<letter>_letra_NN.m4a` — original recordings, one letter each, filename's first character = the letter. Recorded letters: A B C D E F G M N P Q W Y Z.
- `assets/audio/letras/<letter>.m4a` — peak-normalized, faded, AAC 48kbps mono versions (what gets base64-embedded).
- `bash tools/gerar_audio.sh` regenerates everything and re-splices the `AUDIO_B64` block inside `index.html`. macOS-only (`afconvert`); `tools/normalize.py` is stdlib-only Python.
- To add/replace a letter: drop the raw file in `assets/audio/raw/` with the naming convention, run the script, and (if the game should speak it) add its key to `LETTERS`.

## Conventions

- All UI strings and spoken audio are pt-BR; keep new user-facing text consistent with that.
- License is GPL v3 (derivative of GPL code) — keep the header notice in `index.html` and credits in the help screen intact.
- `screenshots/` holds reference screenshots of dual-n-back.io used during development; it is gitignored, not part of the app.
