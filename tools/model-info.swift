// Prints what macOS reports about its Apple Foundation Models.
// Build and run: swiftc -o model-info model-info.swift && ./model-info
// Needs macOS 27 and the Xcode Command Line Tools (xcode-select --install).

import Foundation
import FoundationModels

func caps(_ c: LanguageModelCapabilities) -> String {
    var out: [String] = []
    if c.contains(.vision) { out.append("vision") }
    if c.contains(.guidedGeneration) { out.append("guidedGeneration") }
    if c.contains(.reasoning) { out.append("reasoning") }
    if c.contains(.toolCalling) { out.append("toolCalling") }
    return out.joined(separator: ", ")
}

let m = SystemLanguageModel.default
print("== SystemLanguageModel.default")
print("availability:", m.availability)
// The framework derives variant from contextSize alone (8192 → Core Advanced), not from the model files.
print("variant:", m.variant)
print("contextSize:", m.contextSize)
print("capabilities:", caps(m.capabilities))
let langs = m.supportedLanguages.map { $0.maximalIdentifier }.sorted()
print("supportedLanguages (\(langs.count)):", langs.joined(separator: " "))
print("supports current locale:", m.supportsLocale())
let tag = SystemLanguageModel(useCase: .contentTagging)
print("contentTagging variant:", tag.variant, "contextSize:", tag.contextSize)

print("== PrivateCloudComputeLanguageModel")
let p = PrivateCloudComputeLanguageModel()
print("availability:", p.availability)
print("capabilities:", caps(p.capabilities))
do { print("contextSize:", try await p.contextSize) } catch { print("contextSize error:", error) }
do { let l = try await p.supportedLanguages; print("languages:", l.count) } catch { print("languages error:", error) }
print("quota:", p.quotaUsage.status, "reset:", p.quotaUsage.resetDate as Any)
