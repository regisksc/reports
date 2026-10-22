# Animation handoff: submitted to town hall

## Deliverable

Create a short, silent, text-free animation as an editable HyperFrames project and an MP4 at `renders/submitted-to-townhall.mp4`. Keep this as a standalone video. The reports app already has a separate approved plan for a native Flutter vector success animation; do not change app source or replace that route in this task.

## Story and art direction

Use these working defaults unless the user changes them: 16:9, 1920×1080, 30 fps, about 5.5 seconds, pure white background, silent.

1. Show a centered, wide, rounded orange button with the same orange face and darker orange lower shadow as `references/submit-button-reference.png`. Do not draw the word “Submit” or any other text.
2. Push the button toward camera until its orange shape fills the frame. Let the rounded rectangle fold and taper into a matching orange envelope with a clear triangular flap.
3. Keep the background white as the envelope shoots across the source scene and exits through its right edge. Use a curved route, a few clean orange speed strokes, and a brief offscreen handoff.
4. Reveal a friendly, simple cartoon town hall built from original vector shapes. The building should read as civic architecture without names, signs, logos, flags, or lettering. Have the envelope enter beyond the left edge of this scene and fly rightward toward the door.
5. Have the envelope decelerate and slip into the visible mail slot. Finish with a small warm glow or a few simple sparkles, then hold on the completed scene.

The envelope exits through the source scene’s right edge, then enters beyond the town-hall scene’s left edge and flies rightward to the door. This MP4 is the visual reference for ticket 25; the app still needs its native animation.

Keep the button-to-envelope silhouette and orange palette recognizable throughout. Draw the envelope, speed lines, and town hall as SVG/vector shapes in the project. Do not use diffusion-generated frames or external image assets; this is a clean shape-morph animation and should render consistently at every seeked frame.

## Local workspace

- Project: this directory (`animation/submitted-to-townhall/`).
- Main composition: `index.html`.
- Supplied reference: `references/submit-button-reference.png` (byte-identical copy of the user attachment; use it for shape and color only, not as a visible frame).
- HyperFrames CLI: pinned at `0.8.185`; scripts are in `package.json`.
- GSAP: installed locally at exact version `3.14.2`. The blank starter currently loads GSAP from a CDN; replace that script with the installed local package before authoring so the composition has no runtime network dependency.
- Local model: `qwen3.5:9b-q4_K_M`, downloaded in Ollama `0.40.8`, 6.6 GB. It accepts text and images. Launch with `ollama run qwen3.5:9b-q4_K_M` only when memory allows; keep its context modest for this coding task. `ollama ps` was empty after download, so it is not left loaded.
- Renderer: Node.js `26.11.1`, FFmpeg/FFprobe `8.1`, and HyperFrames' headless Chrome are installed/cached. Docker is optional for local rendering and is not running.

## Next-model workflow

1. Read `AGENTS.md` and this file. Load the installed `/hyperframes` skill first, then its CLI, motion, format, and runtime references.
2. Build the complete scene in editable HTML/SVG/CSS and GSAP. Register a paused GSAP timeline in `window.__timelines` under the root `data-composition-id`; explicitly set the initial state so seeking to frame zero is deterministic.
3. Use the background preview workflow from `AGENTS.md`, review the motion, run `npm run check`, fix reported errors, then render the MP4. A preview process should be stopped with the project's documented command when review is finished.
4. Save the MP4 under `renders/` and retain the editable source. Do not add words to signage or use generated text as a visual element.

Commands from this directory:

```sh
npx --yes hyperframes@0.8.185 preview --background
npx --yes hyperframes@0.8.185 preview --status
npm run check
mkdir -p renders
npx hyperframes@0.8.185 render --output renders/submitted-to-townhall.mp4
npx --yes hyperframes@0.8.185 preview --stop
```

The source image contains the word “Submit”; remove it completely. No words, letters, numbers, signs, logos, captions, or narration should appear in the video. No TTS or music package is needed for this silent visual story.

## Machine constraint

The latest HyperFrames preflight saw only 2.0 GB available on the 16 GB M2 Pro, just above its memory threshold; the first check saw 1.8 GB. Treat memory as tight: close memory-heavy apps before preview/render, and do not keep Qwen loaded while rendering. Ollama unloads it with `ollama stop qwen3.5:9b-q4_K_M`. The model is for authoring, not frame generation.

The doctor reports `ok: false` because optional Kokoro TTS and MusicGen are absent and Docker is not running. This silent, vector-only project needs neither audio package, and Docker is optional for local rendering: <https://hyperframes.heygen.com/guides/rendering>.
