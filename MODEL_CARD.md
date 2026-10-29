# Model card: the model behind `fm`

Unofficial. Each fact is marked with where it came from:

- **Measured**: run on our test Mac.
- **Reported**: printed by Apple's FoundationModels framework on that Mac, using [`tools/model-info.swift`](tools/model-info.swift).
- **Published**: Apple's June 8, 2026 post, [Introducing the third generation of Apple Foundation Models](https://machinelearning.apple.com/research/introducing-third-generation-of-apple-foundation-models).
- **Inspected**: read from the Mac's own system logs and from transcripts saved by `fm`, without changing anything. October 29, 2026.

Test Mac: Apple M4 iMac, 32 GB memory, macOS 27.0.1 (26A434), October 24 and 29, 2026.

## At a glance

| | Value | Source |
| --- | --- | --- |
| Model | **AFM 3 Core Advanced** (very likely; the label alone does not prove it, see [below](#which-model-you-get)) | Reported, Inspected |
| Size | 20B parameters in total, 1–4B active per request (sparse) | Published; total not confirmed on the Mac |
| Design seen on the Mac | Sparse "mixture of experts": a set of experts is picked for each prompt and loaded into the Neural Engine. Active-size tiers 1B, 2B and 3B; `fm` uses 3B | Inspected |
| Faster generation | A small draft model guesses ahead and the main model checks its guesses (speculative decoding) | Inspected |
| Context window | **8,192 tokens** (prompt, instructions, history and answer combined) | Reported; hard error measured at 8,138 |
| Capabilities | Image input, schema-guided output, tool calling | Reported |
| Reasoning mode | **No** | Reported |
| Languages | 24 locales (listed below) | Reported |
| Speed | ~37–40 tokens/s; first words in about 0.9 s; ~0.5 s for a one-line reply | Measured |
| Runs | Entirely on the Mac, offline after the model downloads | Published |
| Cost | Free | — |

## Which model you get

Apple ships two on-device models, and the framework picks one based on the hardware:

| Model | Design | Who gets it |
| --- | --- | --- |
| AFM 3 Core | 3B parameters, dense | Macs that can run Apple Intelligence |
| AFM 3 Core Advanced | 20B parameters, sparse, 1–4B active | Apple's "most capable Apple silicon systems" (no device list published) |

The M4 iMac reports **Core Advanced**. Apple has not published which Macs qualify. Run `tools/model-info.swift` to see what yours reports, and please [report it](../../issues) with your chip and memory.

**What that name tells you.** The name goes with the context window: a model reporting 8,192 tokens is labelled "AFM 3 Core Advanced". The name is not read from the model files, so on its own it is not proof of the model's size. The evidence below is stronger.

**Why we still think it is Core Advanced (Inspected).** The model files `fm` uses are named `instruct_3b … variant=generic_sparse`. The system logs show the model picking a set of experts for each prompt ("Picking IFP experts … isPromptPick=true") and loading them from a file-backed cache into the Neural Engine. Active-size tiers of 1B, 2B and 3B exist, and `fm` uses the 3B tier. This matches Apple's published description of Core Advanced below. The name `instruct_3b` most likely refers to the 3B active tier, not a 3B model in total. Nothing readable on the Mac states the total parameter count. The model files sit in a folder macOS keeps locked even with Full Disk Access, so their size could not be checked.

How Core Advanced fits on a Mac (Published): the full model is stored on the SSD. For each prompt, a router picks a set of "experts" and loads them into memory, alongside shared experts that stay loaded, and it re-picks them during generation. The model was compressed with quantization-aware training; Apple has not given the bit width.

Using `--use-case content-tagging` did not change the model or the context size; both stayed AFM 3 Core Advanced with 8,192 tokens (Reported). On macOS 27, content tagging is a settings change on the same model, not a separate add-on (Inspected).

## Model files and safety checks (Inspected)

Every answer saved by `fm` lists the model files that produced it. On the test Mac they were, all with `variant=generic_sparse`:

| File (`com.apple.fm.language.instruct_3b.…`) | Role | Version |
| --- | --- | --- |
| `base` | The main model | 16.0.81614.13.204844 |
| `fm_api_generic_3b` | Apple's tuning of it for apps, 3B active tier | 16.1.0.13.103120 |
| `fm_api_generic.draft` | Draft model for speculative decoding | 16.0.81614.13.204770 |
| `tokenizer` | Tokenizer | 16.0.0.13.204691 |
| `image_encoder` | Image input | 16.0.81614.13.204839 |

**Safety checks are separate from the model.** Each request and answer is checked by a smaller 300-million-parameter safety classifier (`instruct_300m.safety`, with `mm_guard` for images) and by lists of blocked words. A blocked request ends with `The model's safety guardrails were triggered.` rather than a refusal from the model itself. `--guardrails permissive-content-transformations` relaxes the checks for rewriting text you supply; Apple's documentation says it applies only to plain-text answers, not structured (schema) output.

## Languages

Reported on the test Mac, 24 locales:

Chinese (Simplified; Traditional for Hong Kong and Taiwan), Danish, Dutch, English (Australia, India, UK, US), French (Canada, France), German, Italian, Japanese, Korean, Norwegian Bokmål, Portuguese (Brazil, Portugal), Spanish (Latin America, Spain, US), Swedish, Turkish, Vietnamese.

Apple's evaluations also cover Arabic, Finnish, Hebrew, Hindi, Indonesian, Malay, Polish, Russian, Thai and Ukrainian, but the framework did not list those on this Mac.

## Context: measured against reported

The framework reports 8,192 tokens. A test placing one code word at the start of the prompt and another at the end found:

| Prompt size (tokens) | Result |
| --- | --- |
| 6,324 | Found both codes |
| 7,298 | Refused |
| 8,068 | Refused |
| 8,138 | `exceeded the model's context size` |

The answer needs room inside the same 8,192, which is why the error appears just below it. Quality drops well before that point. Keep input under about 6,000 tokens.

## Training (Published)

- Data: publicly available, licensed or purchased, open-source, dedicated studies, and synthetic data. Apple says it does not train on users' private personal data or interactions.
- Recipe: large-scale pre-training on cloud TPUs, then supervised fine-tuning and multi-stage reinforcement learning.
- Training data cutoff: not published.

## Quality (Published)

Apple's own human evaluations, not independent:

- General text, AFM 3 Core against the 2025 on-device model: preferred 45.6% vs 23.3%.
- Image understanding, AFM 3 Core against its predecessor: preferred over 61% of the time when raters had a preference.

Apple promised a full technical report with benchmarks "later this summer". It is not linked here yet.

## Private Cloud Compute

The same framework also exposes Apple's server model (Reported on the test Mac):

| | On-device | Private Cloud Compute |
| --- | --- | --- |
| Context window | 8,192 | **32,768** |
| Reasoning mode | No | **Yes** |
| Image input, schema output, tool calling | Yes | Yes |
| Usage quota | None | Yes (test Mac: below limit) |

`fm` on macOS 27.0.1 cannot use it: `-m` accepts only `system`. Apps reach it through the FoundationModels framework, which needs an entitlement from Apple; per Apple's WWDC26 session it is free for developers under two million first-time downloads.

## Not known

Total parameter count as installed, number of experts, quantization bit width, the model files' size on disk, the exact chat template, training cutoff, the list of Macs that get Core Advanced, and independent benchmarks. Corrections with sources are welcome as [issues](../../issues).

## Check your own Mac

```sh
xcode-select --install          # once, if you don't have the Command Line Tools
swiftc -o model-info tools/model-info.swift
./model-info
```

It prints the model name, context size, capabilities and languages for your Mac, plus whether Private Cloud Compute is available to it. It does not send any prompts. The model name follows from the context size (see [Which model you get](#which-model-you-get)), so the context size line is the one to report.

For stronger evidence, send one prompt and look at the files the answer came from:

```sh
fm respond --save-transcript check.json "Say OK." && grep -o 'com\.apple\.fm\.[^"]*' check.json | sort -u
```

On the test Mac every line contained `variant=generic_sparse`, the sparse model, followed by a version number.
