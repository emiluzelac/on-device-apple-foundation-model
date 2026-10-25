# Model card: the model behind `fm`

Unofficial. Each fact is marked with where it came from:

- **Measured**: run on our test Mac.
- **Reported**: printed by Apple's FoundationModels framework on that Mac, using [`tools/model-info.swift`](tools/model-info.swift).
- **Published**: Apple's June 8, 2026 post, [Introducing the third generation of Apple Foundation Models](https://machinelearning.apple.com/research/introducing-third-generation-of-apple-foundation-models).

Test Mac: Apple M4 iMac, 32 GB memory, macOS 27.0.1 (26A434), October 24, 2026.

## At a glance

| | Value | Source |
| --- | --- | --- |
| Model | **AFM 3 Core Advanced** | Reported |
| Size | 20B parameters in total, 1–4B active per request (sparse) | Published |
| Context window | **8,192 tokens** (prompt, instructions, history and answer combined) | Reported; hard error measured at 8,138 |
| Capabilities | Image input, schema-guided output, tool calling | Reported |
| Reasoning mode | **No** | Reported |
| Languages | 24 locales (listed below) | Reported |
| Speed | ~37 tokens/s on a ~500-token answer; ~0.5 s for a one-line reply | Measured |
| Runs | Entirely on the Mac, offline after the model downloads | Published |
| Cost | Free | — |

## Which model you get

Apple ships two on-device models, and the framework picks one based on the hardware:

| Model | Design | Who gets it |
| --- | --- | --- |
| AFM 3 Core | 3B parameters, dense | Macs that can run Apple Intelligence |
| AFM 3 Core Advanced | 20B parameters, sparse, 1–4B active | Apple's "most capable Apple silicon systems" (no device list published) |

The M4 iMac got **Core Advanced**. Apple has not published which Macs qualify. Run `tools/model-info.swift` to see which one yours uses, and please [report it](../../issues) with your chip and memory.

How Core Advanced fits on a Mac (Published): the full model is stored on the SSD. For each prompt, a router picks a set of "experts" and loads them into memory, alongside shared experts that stay loaded, and it re-picks them during generation. The model was compressed with quantization-aware training; Apple has not given the bit width.

Using `--use-case content-tagging` did not change the model or the context size; both stayed AFM 3 Core Advanced with 8,192 tokens (Reported).

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

Exact parameter count active per request, quantization bit width, training cutoff, the list of Macs that get Core Advanced, and independent benchmarks. Corrections with sources are welcome as [issues](../../issues).

## Check your own Mac

```sh
xcode-select --install          # once, if you don't have the Command Line Tools
swiftc -o model-info tools/model-info.swift
./model-info
```

It prints the model name, context size, capabilities and languages for your Mac, plus whether Private Cloud Compute is available to it. It does not send any prompts.
