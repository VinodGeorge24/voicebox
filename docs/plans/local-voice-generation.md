# Local voice generation for the TikTok factory

Status: approved and implemented locally; factory validation passed.
Reviewed: 2026-10-22.

## Preserved source and local hardware

- Upstream: https://github.com/jamiepine/voicebox
- Reviewed source commit: `8af7efe62fab8d33e2a5dfbedabaa45f68a5184f`.
- Local checkout: `C:\Users\vgeor\GitHub\voicebox`.
- Fork: https://github.com/VinodGeorge24/voicebox. GitHub CLI was authorized
  through the user's phone using GitHub's device flow. Fork Actions are disabled.
- Observed hardware: NVIDIA RTX 5060 Laptop GPU, 8151 MiB dedicated VRAM,
  approximately 31.3 GiB physical RAM, and 587.7 GiB free on C: at inspection.
- Installed Voicebox 0.5.0, its cu128 CUDA backend, Kokoro, and Chatterbox Turbo.
  Runtime data is at `%USERPROFILE%\.local\share\voicebox`; the service binds
  only to `127.0.0.1:17493`. No paid service, hosted inference, global MCP
  registration, or OS startup task was configured.
- Launcher: `scripts/start-local-voicebox.ps1`. The factory runbook is
  `C:\Users\vgeor\GitHub\tiktok-trivia-factory\docs\local-voicebox.md`.

## Recommendation

Use Voicebox as a separate local speech service accessed over HTTP. Preserve
upstream source and a small downstream integration plan; avoid modifying the
Voicebox application unless a verified integration gap requires it.

Voicebox is a studio and service around multiple models. The engine, voice
profile, reference recording, and delivery settings determine the result.

| Candidate | Initial use | Tradeoff | Model license |
| --- | --- | --- | --- |
| Chatterbox Turbo | English character dialogue and expressive narration | Supports sound tags; cloned characters need suitable authorized reference audio | MIT |
| Kokoro 82M | Routine narration and low-resource fallback | Lightweight preset voices; does not offer the same cloning workflow | Apache-2.0 |
| Qwen3-TTS / VoiceDesign | A later comparison for multilingual or original character voices | Larger models and a separate compatibility/quality check | Apache-2.0 for the reviewed official models |

Voicebox code is MIT licensed. Check the exact selected weights and dependencies
separately. Both selected models were generated and benchmarked locally; equal
quality to ElevenLabs has not been established. Local inference avoids
metered hosted speech API calls, but uses local disk, compute, power, and time.

## Verified results

- Factory regression suite: 108 tests passed.
- Real CLI/Telegram adapter flow produced, reviewed, and approved a local MP4.
  Publish preparation produced 30 fps video with an identical reviewed AAC
  stream hash. No TikTok upload or public posting was performed.
- Rendered question and answer frames were visually checked; narration fits
  the effective scene boundaries and the countdown follows question narration.
- Warm generation comparison on this laptop: Kokoro 0.80-0.95 seconds for
  6.73-10.58 seconds of audio; Chatterbox Turbo 8.05-12.08 seconds for
  5.92-9.64 seconds of audio. These are small local samples, not general claims.
- Chatterbox uses a reference generated from the local Kokoro preset. No real
  person's voice was imported. WAV samples and comparison metadata are under
  ignored `data/factory-samples/`.
- Release CUDA archive checksums and Chatterbox LFS weight hashes were checked.
  Windows model snapshot symlink failures were resolved with regular files,
  without changing privileges or security settings.

The sequence below records the approved implementation approach.

## Proposed installation and integration sequence

1. Authenticate GitHub CLI as the intended owner, create the requested GitHub
   fork, retain the original repository as `upstream`, and connect this checkout
   to the fork. Preserve the reviewed commit and downstream documentation.
2. With installation approval, use an official Windows release with RTX
   50-series support and its CUDA backend. Pin the version actually tested;
   verify its API before writing the adapter because this checkout's main branch
   can differ from the packaged release. Download only selected models initially.
   The documented packaged CUDA libraries are approximately 4 GB, plus the
   server core, application, and model files. Source-backend installation is a
   fallback if the packaged release lacks a required verified capability.
3. Check port ownership before starting. Bind the speech server to
   `127.0.0.1`; the documented app port is 17493. Validate `/health`, GPU support,
   a preset-voice generation, and audio export. Keep personal voice recordings,
   model caches, and generated audio outside version control.
4. Compare the same short narration and dialogue scripts using Kokoro and
   Chatterbox Turbo. Measure generation time, peak VRAM, duration, pronunciation,
   missing/repeated words, and consistency across repeat runs. Use a preset or
   an explicitly authorized recording; do not import third-party voice samples.
5. After approval of the implementation plan, add a `voicebox` provider to the
   factory. Keep ML dependencies in the speech service. Configure URL, engine,
   and profile through the factory's existing settings, with bounded request
   timeouts and clear failures. Preserve approval gates.
6. Generate narration before final scene timing, measure the resulting audio,
   and normalize it to the factory mixer contract: 44.1 kHz, mono, signed 16-bit
   PCM WAV. Cache audio by text, engine, profile/reference version, and settings.
   Make review previews and upload renders use the same approved audio assets.
7. Validate with adapter tests and one real local MP4 reviewed for audible
   narration, pacing, and clipping. Add explicit tests for generation failures,
   asynchronous completion, sample-rate conversion, and narration surviving the
   upload rerender. Finish with an operator runbook. Enable startup automation
   only if requested after the manual flow is working.

## API evidence and factory changes

The reviewed source exposes `POST /generate`, `GET /history/{generation_id}`,
and `GET /audio/{generation_id}`. `/generate` returns a queued generation record;
the caller must wait for completion before downloading audio. The request
includes `profile_id`, `text`, `language`, `engine`, and optional generation
settings. Use the file-generation API for videos; `/speak` is intended for agent
playback. Keep personality rewriting disabled for approved scripts.

Before integration, the factory accepted `none` and `windows_sapi` voice providers,
used fixed scene boundaries, and lost narration during the upload rerender. The
implemented `voicebox` adapter, measured speech timing, and approved-AAC stream
copy resolve these gaps without adding ML dependencies to the factory.

Relevant factory files: `config.py`, `audio.py`, `render_manifest.py`,
`renderer.py`, `uploads.py`, CLI/Telegram callers, and audio/upload tests.

## Sources

- [Voicebox license](https://github.com/jamiepine/voicebox/blob/main/LICENSE)
- [Voicebox GPU setup and Blackwell support](https://docs.voicebox.sh/overview/gpu-acceleration)
- [Voicebox API implementation](https://github.com/jamiepine/voicebox/blob/main/backend/routes/generations.py)
- [Voicebox request models](https://github.com/jamiepine/voicebox/blob/main/backend/models.py)
- [Chatterbox Turbo model](https://huggingface.co/ResembleAI/chatterbox-turbo)
- [Kokoro model](https://huggingface.co/hexgrad/Kokoro-82M)
- [Qwen VoiceDesign model](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign)
