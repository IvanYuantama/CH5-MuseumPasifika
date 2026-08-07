//
//  Qwen25VLModel.swift
//  PainThink
//
//  A standalone "script" that runs a Core ML build of the Qwen2.5-VL
//  vision-language model against an image + text prompt.
//
//  NOTE: This file intentionally does NOT download any model. It expects a
//  precompiled Core ML model (a `Qwen2.5-VL.mlpackage`, which Xcode compiles
//  into a `Qwen2.5-VL.mlmodelc`) to already be added to the app target/bundle.
//  Because the concrete model is not present here, the runner inspects the
//  model's own `MLModelDescription` at load time and adapts to whatever input
//  and output features it exposes, rather than hard-coding a generated wrapper
//  class. The few model-specific details (feature names, tokenizer) are marked
//  with `TODO` and centralized in `Qwen25VLConfiguration`.
//

import CoreML
import CoreGraphics

// MARK: - Errors

enum Qwen25VLError: LocalizedError {
    case modelNotFound(name: String)
    case noImageInput
    case noTextInput
    case tokenizerRequired
    case imageEncodingFailed
    case unexpectedOutput
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "Could not find a compiled Core ML model named \"\(name)\" in the app bundle. Add the Qwen2.5-VL .mlpackage to the target."
        case .noImageInput:
            return "The model does not expose an image input feature."
        case .noTextInput:
            return "The model does not expose a text/token input feature."
        case .tokenizerRequired:
            return "This model expects tokenized input, but no tokenizer was provided."
        case .imageEncodingFailed:
            return "Failed to convert the input image into the model's expected image format."
        case .unexpectedOutput:
            return "The model produced an output that this runner does not know how to decode."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Tokenizer

/// A Qwen2.5-VL Core ML export that takes token IDs (rather than a raw string)
/// needs a tokenizer that matches the model's vocabulary. Supply an
/// implementation backed by the model's `tokenizer.json` / merges files.
protocol Qwen25VLTokenizer: Sendable {
    /// Encode a chat prompt (already formatted with any chat template) into token IDs.
    nonisolated func encode(_ text: String) -> [Int]
    /// Decode generated token IDs back into text.
    nonisolated func decode(_ tokens: [Int]) -> String
}

// MARK: - Configuration

struct Qwen25VLConfiguration: Sendable {
    /// The name of the compiled model in the bundle, without extension.
    var modelName: String = "Qwen2.5-VL"

    /// TODO: Set these to match your export's feature names if the automatic
    /// detection below doesn't pick the right ones. `nil` means "auto-detect".
    var imageInputName: String? = nil
    var textInputName: String? = nil
    var outputName: String? = nil

    /// Maximum number of tokens to generate when the model is autoregressive.
    var maxNewTokens: Int = 256

    /// Compute units to run on (all = CPU + GPU + Neural Engine).
    var computeUnits: MLComputeUnits = .all

    /// Provide a tokenizer if the model consumes/produces token IDs.
    var tokenizer: Qwen25VLTokenizer? = nil

    nonisolated init() {}
}

// MARK: - Runner

/// Loads and runs the Qwen2.5-VL Core ML model. Model access is serialized on a
/// background actor because an `MLModel` instance must be used from one place at
/// a time.
actor Qwen25VLModel {

    private let configuration: Qwen25VLConfiguration
    private var model: MLModel?

    init(configuration: Qwen25VLConfiguration = Qwen25VLConfiguration()) {
        self.configuration = configuration
    }

    /// Loads the compiled model from the app bundle. Safe to call repeatedly.
    func loadIfNeeded() throws {
        guard model == nil else { return }

        let name = configuration.modelName
        // Xcode compiles `.mlpackage` / `.mlmodel` into a `.mlmodelc` at build time.
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: name, withExtension: "mlpackage") else {
            throw Qwen25VLError.modelNotFound(name: name)
        }

        let mlConfig = MLModelConfiguration()
        mlConfig.computeUnits = configuration.computeUnits

        do {
            model = try MLModel(contentsOf: url, configuration: mlConfig)
        } catch {
            throw Qwen25VLError.underlying(error)
        }
    }

    /// Runs the model on an image + text prompt and returns the decoded response.
    ///
    /// - Parameters:
    ///   - image: The input image as a `CGImage` (platform-agnostic).
    ///   - prompt: The user's text prompt. Apply any chat template before calling
    ///             if your export expects one.
    func generate(image: CGImage, prompt: String) async throws -> String {
        try loadIfNeeded()
        guard let model else { throw Qwen25VLError.modelNotFound(name: configuration.modelName) }

        let description = model.modelDescription
        let inputs = description.inputDescriptionsByName

        // Resolve which input feature is the image and which is the text/tokens.
        let imageName = try resolveImageInputName(from: inputs)
        let textName = try resolveTextInputName(from: inputs, excluding: imageName)

        var featureValues: [String: MLFeatureValue] = [:]

        // --- Image feature -------------------------------------------------
        let imageDescription = inputs[imageName]!
        featureValues[imageName] = try imageFeatureValue(for: image, matching: imageDescription)

        // --- Text / token feature -----------------------------------------
        let textDescription = inputs[textName]!
        featureValues[textName] = try textFeatureValue(for: prompt, matching: textDescription)

        // --- Predict -------------------------------------------------------
        let provider = try MLDictionaryFeatureProvider(dictionary: featureValues)
        let output: MLFeatureProvider
        do {
            output = try await model.prediction(from: provider)
        } catch {
            throw Qwen25VLError.underlying(error)
        }

        return try decode(output: output, description: description)
    }

    // MARK: Feature resolution

    private func resolveImageInputName(from inputs: [String: MLFeatureDescription]) throws -> String {
        if let name = configuration.imageInputName { return name }
        if let match = inputs.first(where: { $0.value.type == .image })?.key { return match }
        throw Qwen25VLError.noImageInput
    }

    private func resolveTextInputName(
        from inputs: [String: MLFeatureDescription],
        excluding imageName: String
    ) throws -> String {
        if let name = configuration.textInputName { return name }
        // Prefer a string input; otherwise fall back to the first non-image input
        // (typically a multi-array of token IDs).
        if let stringMatch = inputs.first(where: { $0.value.type == .string })?.key {
            return stringMatch
        }
        if let match = inputs.keys.first(where: { $0 != imageName }) {
            return match
        }
        throw Qwen25VLError.noTextInput
    }

    // MARK: Encoding

    private func imageFeatureValue(
        for image: CGImage,
        matching description: MLFeatureDescription
    ) throws -> MLFeatureValue {
        do {
            if let constraint = description.imageConstraint {
                // Core ML resizes/crops to satisfy the model's image constraint.
                return try MLFeatureValue(cgImage: image, constraint: constraint, options: nil)
            }
            return try MLFeatureValue(
                cgImage: image,
                pixelsWide: image.width,
                pixelsHigh: image.height,
                pixelFormatType: kCVPixelFormatType_32ARGB,
                options: nil
            )
        } catch {
            throw Qwen25VLError.imageEncodingFailed
        }
    }

    private func textFeatureValue(
        for prompt: String,
        matching description: MLFeatureDescription
    ) throws -> MLFeatureValue {
        switch description.type {
        case .string:
            return MLFeatureValue(string: prompt)
        case .multiArray:
            guard let tokenizer = configuration.tokenizer else {
                throw Qwen25VLError.tokenizerRequired
            }
            let tokens = tokenizer.encode(prompt)
            let array = try MLMultiArray(shape: [1, NSNumber(value: tokens.count)], dataType: .int32)
            for (index, token) in tokens.enumerated() {
                array[index] = NSNumber(value: token)
            }
            return MLFeatureValue(multiArray: array)
        default:
            throw Qwen25VLError.noTextInput
        }
    }

    // MARK: Decoding

    private func decode(output: MLFeatureProvider, description: MLModelDescription) throws -> String {
        let outputName = configuration.outputName
            ?? description.predictedFeatureName
            ?? output.featureNames.first

        guard let outputName, let value = output.featureValue(for: outputName) else {
            throw Qwen25VLError.unexpectedOutput
        }

        switch value.type {
        case .string:
            return value.stringValue
        case .multiArray:
            guard let tokenizer = configuration.tokenizer, let array = value.multiArrayValue else {
                throw Qwen25VLError.unexpectedOutput
            }
            let tokens = (0..<array.count).map { Int(truncating: array[$0]) }
            return tokenizer.decode(tokens)
        case .dictionary:
            // e.g. a probability dictionary — return a readable description.
            return "\(value.dictionaryValue)"
        default:
            throw Qwen25VLError.unexpectedOutput
        }
    }
}
