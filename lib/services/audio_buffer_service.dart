import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for circular audio buffer recording.
///
/// Continuously records audio in the background and provides the last 5 seconds
/// when an impact is detected. This ensures we always have context audio for
/// emergency alerts.
class AudioBufferService {
  static final AudioBufferService _instance = AudioBufferService._internal();
  factory AudioBufferService() => _instance;
  AudioBufferService._internal();

  final Record _recorder = Record();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _rotationTimer;
  
  // Buffer rotation: record in chunks and keep only the last 2 chunks (10 seconds total)
  static const Duration _chunkDuration = Duration(seconds: 5);
  static const int _maxChunks = 2; // Keep last 10 seconds
  int _currentChunk = 0;
  final List<String> _chunkPaths = [];

  /// Start continuous audio buffer recording.
  Future<void> startBufferRecording() async {
    if (_isRecording) {
      debugPrint('AudioBufferService: Already recording');
      return;
    }

    try {
      debugPrint('AudioBufferService: Checking recording permission...');
      // Check and request permissions
      final hasPermission = await _recorder.hasPermission();
      debugPrint('AudioBufferService: Permission check result: $hasPermission');
      
      if (!hasPermission) {
        debugPrint('AudioBufferService: No recording permission, requesting...');
        final requested = await _recorder.hasPermission();
        debugPrint('AudioBufferService: Permission request result: $requested');
        
        if (!requested) {
          debugPrint('AudioBufferService: Permission denied, cannot record');
          return;
        }
      }

      // Get temporary directory for audio chunks
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('AudioBufferService: Temp directory: ${tempDir.path}');

      // Start first chunk
      await _recordChunk(tempDir, timestamp, 0);
      _isRecording = true;
      debugPrint('AudioBufferService: Started buffer recording successfully');

      // Start rotation timer
      _rotationTimer = Timer.periodic(_chunkDuration, (_) async {
        if (!_isRecording) return;
        
        final nextChunk = (_currentChunk + 1) % _maxChunks;
        await _recordChunk(tempDir, timestamp, nextChunk);
      });
    } catch (e) {
      debugPrint('AudioBufferService: Error starting recording: $e');
      debugPrint('AudioBufferService: Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _recordChunk(Directory tempDir, int baseTimestamp, int chunkIndex) async {
    try {
      // Stop previous recording if any
      if (_currentRecordingPath != null) {
        await _recorder.stop();
        _chunkPaths.add(_currentRecordingPath!);
        
        // Keep only last _maxChunks
        while (_chunkPaths.length > _maxChunks) {
          final oldPath = _chunkPaths.removeAt(0);
          try {
            await File(oldPath).delete();
          } catch (e) {
            debugPrint('AudioBufferService: Error deleting old chunk: $e');
          }
        }
      }

      // Start new chunk
      final chunkPath = path.join(
        tempDir.path,
        'jepo_audio_${baseTimestamp}_chunk$chunkIndex.m4a',
      );
      
      await _recorder.start(
        path: chunkPath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      _currentRecordingPath = chunkPath;
      _currentChunk = chunkIndex;
      debugPrint('AudioBufferService: Recording chunk $chunkIndex to $chunkPath');
    } catch (e) {
      debugPrint('AudioBufferService: Error recording chunk: $e');
    }
  }

  /// Stop recording and return the last 5 seconds of audio as a file path.
  ///
  /// When an impact is detected, call this to get the audio context.
  Future<String?> getLast5Seconds() async {
    if (!_isRecording) {
      debugPrint('AudioBufferService: Not recording');
      return null;
    }

    try {
      // Stop current recording
      if (_currentRecordingPath != null) {
        await _recorder.stop();
        _chunkPaths.add(_currentRecordingPath!);
      }

      _isRecording = false;
      _rotationTimer?.cancel();

      // Get the most recent chunk (last 5 seconds)
      if (_chunkPaths.isEmpty) {
        debugPrint('AudioBufferService: No audio chunks available');
        return null;
      }

      final lastChunk = _chunkPaths.last;
      debugPrint('AudioBufferService: Returning last 5s from $lastChunk');
      
      // Clean up old chunks
      for (final oldPath in _chunkPaths) {
        if (oldPath != lastChunk) {
          try {
            await File(oldPath).delete();
          } catch (e) {
            debugPrint('AudioBufferService: Error deleting chunk: $e');
          }
        }
      }
      _chunkPaths.clear();

      return lastChunk;
    } catch (e) {
      debugPrint('AudioBufferService: Error getting last 5s: $e');
      return null;
    }
  }

  /// Stop recording without returning audio (for cleanup).
  Future<void> stop() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      _rotationTimer?.cancel();
      _isRecording = false;

      // Clean up all chunks
      for (final chunkPath in _chunkPaths) {
        try {
          await File(chunkPath).delete();
        } catch (e) {
          debugPrint('AudioBufferService: Error deleting chunk: $e');
        }
      }
      _chunkPaths.clear();
      _currentRecordingPath = null;

      debugPrint('AudioBufferService: Stopped and cleaned up');
    } catch (e) {
      debugPrint('AudioBufferService: Error stopping: $e');
    }
  }

  /// Get the last 5 seconds as bytes for upload.
  Future<Uint8List?> getLast5SecondsAsBytes() async {
    final filePath = await getLast5Seconds();
    if (filePath == null) return null;

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Delete the file after reading
      await file.delete();
      
      return bytes;
    } catch (e) {
      debugPrint('AudioBufferService: Error reading bytes: $e');
      return null;
    }
  }

  bool get isRecording => _isRecording;
}
