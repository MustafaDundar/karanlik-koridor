# Hugging Face assets

## emergency-tr.wav

Generated through [wite-tech/pocket-tts-turkish](https://huggingface.co/spaces/wite-tech/pocket-tts-turkish), using the [Pocket TTS Turkish model by Wite Tech](https://huggingface.co/wite-tech/pocket-tts-turkish), licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Built-in synthetic voice `female_3`, neutral. No real person's recording was supplied. Output is unmodified. Attribution is retained for the model; this does not assert a separate copyright determination for generated audio.

Text: “Dikkat. Acil çıkışın elektriği kesildi. Yedek sigortayı bekleme alanında bulabilirsiniz.”

Produced 2026-10-23 on Hugging Face cpu-basic cloud hardware, public unauthenticated Gradio API; no paid provider or ZeroGPU account was used for this call. PCM 16-bit mono 24 kHz, 7.02 seconds. File structure and waveform checked; subjective listening review pending. Prototype announcement integrated with matching Turkish subtitles.

## cabinet-concept.webp

Generated using [FLUX.1 Schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell) through [evalstate/flux1_schnell](https://huggingface.co/spaces/evalstate/flux1_schnell). Model listed under Apache-2.0. Recipe and SHA-256 in `cabinet-recipe.json`. Concept reference only; not a 3D asset or PBR set.

## cabinet-triposr-raw.glb (production/staging)

Generated from the cabinet concept through [WeReCooking2/Dust3R-TripoSR](https://huggingface.co/spaces/WeReCooking2/Dust3R-TripoSR), using [Stability AI TripoSR](https://huggingface.co/stabilityai/TripoSR), listed under MIT. Reconstruction ran on the hosted cpu-basic machine. No local model weights downloaded.

Geometry audit passed: 49,804 triangles, finite geometry, GLB 2.0. Vertex colors, no UV set. Visual review found rounded/irregular manufactured surfaces and weak handle detail; **rejected for final gameplay use**. Kept in staging with `.gdignore`, not instantiated by the game. Four-view review image: `docs/cabinet-triposr-review.png` (view labels are conventional and the camera at π faces the drawers).

## Hunyuan cabinet candidate

Generated using [Tencent Hunyuan3D-2.1](https://huggingface.co/tencent/Hunyuan3D-2.1) through the user's selected public Space. Custom [Tencent Hunyuan 3D 2.1 Community License](https://huggingface.co/tencent/Hunyuan3D-2.1/blob/main/LICENSE), not MIT/Apache. Model/software distribution and output use are distinct; release review must read the full applicable terms. The model license excludes EU/UK/South Korea from its territory; do not assume unrestricted worldwide model/service distribution. This project only stores generated output, not model weights or service code.

Modifications to generated geometry: removed disconnected 2-face fragment; reduced from 521,236 faces to 20,000 faces. No generated UV/PBR. Review scene applies an authored mint material. Candidate is for development review and is not instantiated by default gameplay.
