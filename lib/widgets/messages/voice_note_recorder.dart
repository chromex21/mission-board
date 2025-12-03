import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordingPath;

  static const int maxDuration = 60; // 60 seconds max

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String? filePath;
        
        // Web doesn't support file system paths the same way
        if (!kIsWeb) {
          final tempDir = Directory.systemTemp;
          filePath = '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000,
          ),
          path: filePath, // null for web, which stores in memory
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });

          // Auto-stop at max duration
          if (_recordDuration >= maxDuration) {
            _stopRecording();
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
        widget.onRecordComplete(path, _recordDuration);
      } else {
        widget.onCancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording too short (min 1 second)'),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
      }
    } catch (e) {
      widget.onCancel();
      if (mounted) {
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

    widget.onCancel();
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(top: BorderSide(color: AppTheme.grey700)),
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.errorRed),
            onPressed: _cancelRecording,
            tooltip: 'Cancel',
          ),

          const SizedBox(width: 12),

          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          // Progress and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recording...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_recordDuration),
                      style: TextStyle(
                        color: isNearMax
                            ? AppTheme.warningOrange
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.grey700,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isNearMax
                          ? AppTheme.warningOrange
                          : AppTheme.primaryPurple,
                    ),
                    minHeight: 4,
                  ),
                ),
                if (isNearMax)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Max ${maxDuration}s',
                      style: TextStyle(
                        color: AppTheme.warningOrange,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _recordDuration >= 1 ? _stopRecording : null,
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
