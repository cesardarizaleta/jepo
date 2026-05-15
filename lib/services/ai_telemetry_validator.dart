import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Validates whether a sequence of sensor readings represents a real fall
/// using a TensorFlow Lite Deep CNN model trained for Human Activity Recognition.
///
/// Model input:  [1, 50, 6]  — 50 timesteps × 6 channels (ax, ay, az, gx, gy, gz)
/// Model output: [1, 3]      — probabilities for [caida, actividad, normal]
///
/// Classes:
///   0 = caida
///   1 = actividad
///   2 = normal
class AiTelemetryValidator {
  static const String _modelAsset = 'assets/models/jepo_model.tflite';

  /// Number of timesteps the model expects per inference window.
  static const int windowSize = 50;

  /// Number of sensor channels (ax, ay, az, gx, gy, gz).
  static const int nFeatures = 6;

  /// Number of output classes.
  static const int nClasses = 3;

  /// Index of the "caida" class in the output tensor.
  static const int fallClassIndex = 0;

  /// Default minimum confidence threshold to consider a prediction as a real fall.
  static const double defaultConfidenceThreshold = 0.80;

  Interpreter? _interpreter;
  bool _isReady = false;

  /// Whether the interpreter has been loaded successfully.
  bool get isReady => _isReady;

  /// Loads the TFLite model from assets. Call once during service initialization.
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      _isReady = true;
      debugPrint('AiTelemetryValidator: Model loaded successfully.');
    } catch (e) {
      _isReady = false;
      debugPrint('AiTelemetryValidator: Failed to load model: $e');
    }
  }

  /// Runs inference on a buffer of sensor readings and determines if the
  /// sequence represents a real fall.
  ///
  /// [sensorBuffer] must contain exactly [windowSize] (50) entries.
  /// Each entry is a map with keys: 'ax', 'ay', 'az', 'gx', 'gy', 'gz'.
  ///
  /// [confidenceThreshold] controls how strict the detection is. Lower values
  /// make it more sensitive (more detections), higher values more conservative.
  ///
  /// Returns `true` only if:
  ///   - The predicted class is "caida" (index 0)
  ///   - Its confidence exceeds [confidenceThreshold]
  ///   - No other class has equal or higher confidence
  Future<bool> isRealFall(
    List<Map<String, double>> sensorBuffer, {
    double confidenceThreshold = defaultConfidenceThreshold,
  }) async {
    if (!_isReady || _interpreter == null) return false;
    if (sensorBuffer.length != windowSize) return false;

    // Build input tensor [1, 50, 6].
    final input = Float32List(1 * windowSize * nFeatures);
    for (int t = 0; t < windowSize; t++) {
      final sample = sensorBuffer[t];
      final offset = t * nFeatures;
      input[offset + 0] = sample['ax'] ?? 0.0;
      input[offset + 1] = sample['ay'] ?? 0.0;
      input[offset + 2] = sample['az'] ?? 0.0;
      input[offset + 3] = sample['gx'] ?? 0.0;
      input[offset + 4] = sample['gy'] ?? 0.0;
      input[offset + 5] = sample['gz'] ?? 0.0;
    }

    final inputTensor = input.reshape([1, windowSize, nFeatures]);

    // Output tensor [1, 3].
    final output = List<List<double>>.generate(
      1, (_) => List<double>.filled(nClasses, 0.0),
    );

    // Run inference.
    try {
      _interpreter!.run(inputTensor, output);
    } catch (e) {
      debugPrint('AiTelemetryValidator: Inference error: $e');
      return false;
    }

    // Extract probabilities.
    final probabilities = output[0];
    final fallConfidence = probabilities[fallClassIndex];

    // Only confirm fall if class 0 (caída) confidence exceeds threshold
    // AND no other class has equal or higher probability.
    if (fallConfidence < confidenceThreshold) return false;
    if (probabilities[1] >= fallConfidence) return false;
    if (probabilities[2] >= fallConfidence) return false;
    return true;
  }

  /// Releases interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isReady = false;
  }
}
