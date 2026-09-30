import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/i18n.dart';

/// Voice service error types for UI to handle gracefully.
enum VoiceError {
  permissionDenied,
  micUnavailable,
  recordingFailed,
  whisperMissing,
  whisperModelMissing,
  recognitionFailed,
  emptyTranscription,
  cancelled,
}

class VoiceException implements Exception {
  VoiceException(this.error, [this.message]);
  final VoiceError error;
  final String? message;

  String get localizedMessage {
    switch (error) {
      case VoiceError.permissionDenied: return tr('mic_permission');
      case VoiceError.micUnavailable: return tr('mic_unavailable');
      case VoiceError.recordingFailed: return tr('recording_failed');
      case VoiceError.whisperMissing: return tr('whisper_missing');
      case VoiceError.whisperModelMissing: return tr('whisper_model_missing');
      case VoiceError.recognitionFailed: return tr('voice_error');
      case VoiceError.emptyTranscription: return tr('empty_transcription');
      case VoiceError.cancelled: return '';
    }
  }
}

/// Android/macOS: system recogniser (on-device when the language pack is installed).
/// Windows/Linux: records 16 kHz WAV and runs the whisper.cpp CLI locally.
class VoiceService {
  final _stt = SpeechToText();
  final _rec = AudioRecorder();
  final _tts = FlutterTts();
  String _last = '', _wav = '';
  bool _isRecording = false;
  bool _sttInitialized = false;

  final _bin = Platform.environment['GRAMVIDYA_WHISPER_BIN'] ?? 'whisper-cli';
  final _model = Platform.environment['GRAMVIDYA_WHISPER_MODEL'] ?? 'ggml-base.bin';
  bool get _system => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  bool get isRecording => _isRecording;

  /// Start recording/listening. Throws VoiceException on failure.
  Future<void> start(String code, void Function(String) onText) async {
    if (_system) {
      _last = '';
      // Initialize STT if not already done
      if (!_sttInitialized) {
        _sttInitialized = await _stt.initialize(
          onError: (error) {
            debugPrint('STT error: ${error.errorMsg}');
            _isRecording = false;
          },
          onStatus: (status) {
            debugPrint('STT status: $status');
          },
        );
      }
      if (!_sttInitialized) {
        throw VoiceException(VoiceError.micUnavailable, 'Speech recognition not available on this device');
      }
      _isRecording = true;
      await _stt.listen(
        onResult: (r) {
          _last = r.recognizedWords;
          onText(_last);
        },
        listenOptions: SpeechListenOptions(
          localeId: langLocales[code]?.replaceAll('-', '_'),
          onDevice: true,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } else {
      // Desktop: Validate whisper setup first
      await _validateWhisperSetup();

      // Check microphone permission
      if (!await _rec.hasPermission()) {
        throw VoiceException(VoiceError.permissionDenied);
      }

      // Prepare recording path
      final tmpDir = await getTemporaryDirectory();
      _wav = '${tmpDir.path}/gramvidya_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        await _rec.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 256000,
          ),
          path: _wav,
        );
        _isRecording = true;
      } catch (e) {
        throw VoiceException(VoiceError.recordingFailed, e.toString());
      }
    }
  }

  /// Stop recording and return transcribed text. Throws VoiceException on failure.
  Future<String> stop(String code) async {
    _isRecording = false;

    if (_system) {
      await _stt.stop();
      if (_last.trim().isEmpty) {
        throw VoiceException(VoiceError.emptyTranscription);
      }
      return _last;
    }

    // Desktop: stop recording and run whisper
    final path = await _rec.stop();
    if (path == null || path.isEmpty) {
      throw VoiceException(VoiceError.recordingFailed, 'Recording produced no output');
    }

    // Verify the WAV file exists and has content
    final wavFile = File(_wav);
    if (!await wavFile.exists()) {
      throw VoiceException(VoiceError.recordingFailed, 'Recording file not found');
    }
    final fileSize = await wavFile.length();
    if (fileSize < 1000) {
      try {
        await wavFile.delete();
      } catch (_) {}
      throw VoiceException(VoiceError.emptyTranscription);
    }

    // Run whisper.cpp for transcription
    try {
      final r = await Process.run(
        _bin,
        ['-m', _model, '-f', _wav, '-l', code, '-nt'],
        runInShell: Platform.isWindows,
      ).timeout(const Duration(seconds: 30));

      // Clean up temp file
      try {
        await wavFile.delete();
      } catch (_) {}

      if (r.exitCode != 0) {
        final err = (r.stderr as String).trim();
        if (err.contains('model') || err.contains('Model')) {
          throw VoiceException(VoiceError.whisperModelMissing);
        }
        throw VoiceException(VoiceError.recognitionFailed, err);
      }

      final text = (r.stdout as String).trim();
      if (text.isEmpty || text == '[BLANK_AUDIO]') {
        throw VoiceException(VoiceError.emptyTranscription);
      }

      return text;
    } on VoiceException {
      rethrow;
    } catch (e) {
      throw VoiceException(VoiceError.recognitionFailed, e.toString());
    }
  }

  /// Cancel recording without processing.
  Future<void> cancel() async {
    _isRecording = false;
    if (_system) {
      await _stt.cancel();
    } else {
      await _rec.cancel();
      // Clean up temp file
      if (_wav.isNotEmpty) {
        try {
          await File(_wav).delete();
        } catch (_) {}
      }
    }
  }

  /// Validate whisper.cpp executable and model exist on desktop platforms.
  Future<void> _validateWhisperSetup() async {
    if (_system) return;

    // Check if whisper binary is accessible
    try {
      final result = await Process.run(
        _bin,
        ['--help'],
        runInShell: Platform.isWindows,
      ).timeout(const Duration(seconds: 5));
      // Any exit is fine, we just need it to exist
      if (result.exitCode != 0 && result.exitCode != 1) {
        // Check stderr for hints
        final err = (result.stderr as String).trim();
        if (err.contains('not found') || err.contains('not recognized')) {
          throw VoiceException(VoiceError.whisperMissing);
        }
      }
    } catch (e) {
      if (e is VoiceException) rethrow;
      throw VoiceException(VoiceError.whisperMissing,
          'Cannot find whisper-cli. Set GRAMVIDYA_WHISPER_BIN environment variable or install whisper.cpp.');
    }

    // Check if model file exists
    final modelFile = File(_model);
    if (!await modelFile.exists()) {
      // Try common locations
      final homeDir = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
      final commonPaths = [
        _model,
        '$homeDir/.gramvidya/$_model',
        '$homeDir/models/$_model',
        'models/$_model',
      ];
      bool found = false;
      for (final p in commonPaths) {
        if (await File(p).exists()) {
          found = true;
          break;
        }
      }
      if (!found) {
        throw VoiceException(VoiceError.whisperModelMissing,
            'Cannot find $_model. Set GRAMVIDYA_WHISPER_MODEL environment variable or download the model.');
      }
    }
  }

  /// Speak text aloud using TTS.
  Future<void> speak(String text, String code) async {
    try {
      final locale = langLocales[code];
      if (locale != null) {
        await _tts.setLanguage(locale);
      }
      await _tts.speak(text);
    } catch (_) {
      // TTS failure is non-critical, silently degrade
    }
  }

  /// Stop any ongoing TTS playback.
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
