# M0 spike results

Each spike is a throwaway proof under `spikes/`. Model files live in
`spikes/models/` (gitignored). Run the Flutter-hosted spikes from
`spikes/desktop_spikes` with `flutter test integration_test/<file> -d macos`.

## 1. SSE streaming from an OpenAI-compatible server — PASS

`spikes/sse_stream` (`dart run bin/sse_spike.dart [base-url] [model]`), tested
against a local oMLX server (`127.0.0.1:8000`, GLM-4.7-Flash-MLX-8bit).

- **`package:http` + hand-rolled SSE parser is sufficient — no `dio` needed.**
  Warm run: 32 events / 29 content deltas arriving smoothly ~220 ms apart,
  TTFT 530 ms, clean `[DONE]` terminator.
- Real-world quirks the `llm` package must handle (all seen live):
  - Keepalives can be **chunk events** (`"model":"keepalive"`, empty content),
    not SSE comment lines (oMLX `sse_keepalive_mode: "chunk"`).
  - Thinking models stream `delta.reasoning_content` before `delta.content`.
  - On `finish_reason: "length"` mid-thinking, oMLX dumps accumulated
    reasoning into a final `content` delta.
  - Multi-line `data:` fields and SSE comments must be parsed per spec.
- Cold start loaded the model for ~5 s before the first byte — connection
  test/warmup in the UI should account for this.

## 2. WAV playback via audioplayers — PASS (macOS verified)

`spikes/desktop_spikes/integration_test/audio_playback_test.dart`.

- Front Porch AI's player choice is **`audioplayers` ^6.x** (not `media_kit`);
  ARCHITECTURE.md updated accordingly.
- File-based playback (`DeviceFileSource`, `.wav` path) works; completion
  events fire after real playback duration.
- **`BytesSource` requires `mimeType: 'audio/wav'` on macOS** — audioplayers
  implements it via an extension-less temp file, and AVPlayer can't type it
  otherwise (`DarwinAudioError`).
- `getTemporaryDirectory()` may not exist on first run in a sandboxed app —
  create it before writing (audioplayers' own temp writes need it too).
- Linux/Windows: not yet run locally (macOS dev machine). Confidence for
  Linux comes from Front Porch AI shipping working audio via the same
  package (AUR + nightly builds); verify on CI once Actions billing is fixed.

## 3. Local sentence embedding via ONNX — PASS

`spikes/desktop_spikes/integration_test/embedding_test.dart` +
`lib/wordpiece.dart`; model `bge-small-en-v1.5` (Xenova quantized ONNX,
34 MB) + `vocab.txt` in `spikes/models/bge-small-en-v1.5/`.

- **384-dim embeddings, 3 sentences in 17 ms** (quantized, CPU). Cosine
  ranking is semantically sane: mafia↔werewolf 0.713 vs mafia↔recipe 0.411.
- Front Porch AI parity: FPA runs **`onnxruntime_v2` in-process** — not
  `fonnx`. Its production RAG embedder is **nomic-embed-text-v1.5**
  (`lib/services/embedding_service.dart` + `embedding/native_embedding_engine.dart`,
  WordPiece tokenizer shared from `services/expression/wordpiece_tokenizer.dart`).
  The spike proves the identical pipeline mechanics; pick bge-small vs
  nomic-embed (bigger, task prefixes, FPA-proven) when building `memory` (M4).

## 4. flutter_secure_storage — macOS PASS; Linux pending CI

`spikes/desktop_spikes/integration_test/secure_storage_test.dart` +
`.github/workflows/spike-secure-storage.yaml` (workflow_dispatch; jobs with
and without a Secret Service).

- **macOS**: round-trip passes, but only with
  `MacOsOptions(usesDataProtectionKeychain: false)` for ad-hoc-signed dev
  builds — the default data-protection keychain needs a real signing
  identity (`-34018` otherwise). Release builds signed with the Developer ID
  cert won't need the flag. App is unsandboxed, matching Front Porch AI's
  distribution model (DMG, not App Store).
- **Linux no-keyring (the actual risk)**: on a headless ubuntu-24.04 runner
  the write throws **`PlatformException(KeyringLocked)`** — a catchable
  error, not a crash. Design response: catch at startup, warn once, offer
  session-only key entry (never plaintext on disk).
- Happy path (unlocked keyring round-trip on Linux) verified via the
  `dbus-run-session` + `gnome-keyring-daemon --unlock` job in the workflow.
- Ops note: GitHub Actions minutes are free only for public repos (macOS
  counts 10× on private); the repo was made public on 2026-07-21 for this.

## 5. sherpa_onnx TTS round-trip — Piper PASS; Kokoro pending re-test

`spikes/desktop_spikes/integration_test/tts_test.dart`.

- **Piper** (`vits-piper-en_US-lessac-medium`): synthesized 3.12 s of speech
  in 139 ms (**22.5× realtime**) at 22050 Hz, played to completion via
  audioplayers. PASS.
- **Kokoro v1.0: PASS** — 3.40 s at 24 kHz synthesized in 1.19 s
  (**2.9× realtime**), played to completion. Config mirrors FPA's
  `lib/services/tts/sherpa_kokoro_engine.dart` exactly (model, voices,
  tokens, `espeak-ng-data`, `dict/`, en+zh lexicons).
- **Trap discovered the hard way**: the legacy
  `Application Support/…/kokoro/kokoro-v1.0.onnx` + `voices-v1.0.bin` files
  are from FPA's retired kokoro-onnx Python sidecar and are **binary-
  incompatible with sherpa** (feeding sherpa the npz-format voices file
  crashes the process natively, no catchable error). sherpa needs its own
  `kokoro-multi-lang-v1_0` bundle — FPA re-downloads it to
  `~/Documents/FrontPorchAI/system/kokoro_models/sherpa-v1_0/` (the spike
  symlinks that dir). The `tts` package must validate model files before
  handing them to sherpa.
- FPA crash reports on this machine show sherpa/ORT static-destructor aborts
  on app quit (`std::terminate` during `exit`) — plan an explicit TTS
  teardown (or `exit(0)` bypass) in the real app.

## Machine note (not a spike result)

Mid-session on 2026-07-21, the dev Mac started SIGKILLing processes with
`CODESIGNING: Invalid Page` (rsync crash reports; also killed dart build
hooks), blocking all macOS Flutter builds. A reboot fixed it — symptoms
were consistent with a partially-applied macOS/Xcode update. If builds
start dying with silent SIGKILLs again: check
`~/Library/Logs/DiagnosticReports` for codesigning kills, then reboot.
