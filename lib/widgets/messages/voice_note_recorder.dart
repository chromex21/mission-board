import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';

class VoiceNoteRecorder extends StatefulWidget {
  final Function(String path, int duration) onRecordComplete;
  final VoidCallback onCancel;

  const VoiceNoteRecorder({
    super.key,
    required this.onRecordComplete,
    required this.onCancel,
  });

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  late AudioRecorder _audioRecorder;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordingPath;
  bool _isRecording = false;
  bool _isSupported = true;
  String _errorMessage = '';

  static const int maxDuration = 60; // 60 seconds max

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      _audioRecorder = AudioRecorder();
      _startRecording();
    } catch (e) {
      setState(() {
        _isSupported = false;
        _errorMessage = 'Failed to initialize recorder: ${e.toString()}';
      });
      if (mounted) {
        widget.onCancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopRecording();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!_isSupported) {
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        String filePath;

        // Android: use system temp directory
        final tempDir = Directory.systemTemp;
        filePath =
            '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000,
          ),
          path: filePath,
        );

        setState(() {
          _recordingPath = filePath;
          _isRecording = true;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });

            // Auto-stop at max duration
            if (_recordDuration >= maxDuration) {
              _stopRecording();
            }
          }
        });
      } else {
        if (mounted) {
          widget.onCancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onCancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();

      if (path != null && _recordDuration >= 1) {
        // Minimum 1 second recording
        if (mounted) {
          widget.onRecordComplete(path, _recordDuration);
        }
      } else {
        if (mounted) {
          widget.onCancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording too short (min 1 second)'),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onCancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await _audioRecorder.stop();

    // Delete the temporary file
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore deletion errors
      }
    }

    if (mounted) {
      widget.onCancel();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _recordDuration / maxDuration;
    final isNearMax = _recordDuration >= maxDuration - 5;

    // Compact WhatsApp-style bubble
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryPurple, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing red dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(
                    alpha: 0.3 + (value * 0.7),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(width: 10),

          // Time display
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              color: isNearMax ? AppTheme.warningOrange : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(width: 12),

          // Minimal progress bar
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.grey700,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isNearMax
                      ? AppTheme.warningOrange
                      : AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Cancel button (compact)
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: AppTheme.errorRed, size: 16),
            ),
          ),

          const SizedBox(width: 8),

          // Send button (compact)
          GestureDetector(
            onTap: _recordDuration >= 1 ? _stopRecording : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _recordDuration >= 1
                    ? AppTheme.successGreen
                    : AppTheme.grey700,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
