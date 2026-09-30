import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../ai/model_manager.dart';
import '../core/theme.dart';

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  bool _isTesting = false;
  String? _testOutput;

  Future<void> _runTestInference(SemanticThemeTokens tok) async {
    setState(() {
      _isTesting = true;
      _testOutput = '';
    });

    final ai = InferenceController();
    await ai.init();

    try {
      await for (final token in ai.ask("What is photosynthesis?")) {
        if (!mounted) return;
        setState(() {
          _testOutput = (_testOutput ?? '') + token;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOutput = "Test failed: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final mgr = ModelManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline AI Settings',
          style: TextStyle(color: tok.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
      ),
      backgroundColor: tok.backgroundPrimary,
      body: ListenableBuilder(
        listenable: mgr,
        builder: (context, _) {
          final statusStr = _getStatusString(mgr.status);
          final statusColor = _getStatusColor(mgr.status, tok);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tok.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tok.border),
                    boxShadow: [
                      BoxShadow(
                        color: tok.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tok.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.psychology_outlined, color: tok.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ModelManager.defaultModel.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: tok.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Model Version: ${ModelManager.defaultModel.version}',
                                  style: TextStyle(fontSize: 13, color: tok.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Model Status:', style: TextStyle(color: tok.textSecondary, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusStr,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Model Size', '~350 MB (${ModelManager.defaultModel.sizeMB.toStringAsFixed(1)} MB)', tok),
                      _buildDetailRow('Storage Required', '~500 MB', tok),
                      _buildDetailRow('Model Format', 'GGUF (Q4_K_M)', tok),
                      _buildDetailRow('Inference Type', '100% On-Device Neural Network', tok),
                      _buildDetailRow('Local Path', mgr.localModelPath ?? 'Not initialized', tok, isSmallText: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Download / Progress Card
                if (mgr.isDownloading || mgr.isPaused)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tok.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tok.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              mgr.isPaused ? 'Download Paused' : 'Downloading AI Model...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tok.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${(mgr.progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tok.primary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: mgr.progress,
                            minHeight: 10,
                            backgroundColor: tok.border,
                            valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(mgr.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${ModelManager.defaultModel.sizeMB.toStringAsFixed(1)} MB',
                              style: TextStyle(fontSize: 13, color: tok.textSecondary),
                            ),
                            if (!mgr.isPaused && mgr.downloadSpeedMBps > 0)
                              Text(
                                '${mgr.downloadSpeedMBps.toStringAsFixed(1)} MB/s',
                                style: TextStyle(fontSize: 13, color: tok.primary, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: mgr.isPaused ? mgr.resumeDownload : mgr.pauseDownload,
                                icon: Icon(mgr.isPaused ? Icons.play_arrow : Icons.pause),
                                label: Text(mgr.isPaused ? 'Resume' : 'Pause'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: tok.primary,
                                  side: BorderSide(color: tok.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: mgr.cancelDownload,
                                icon: Icon(Icons.close, color: tok.error),
                                label: Text('Cancel', style: TextStyle(color: tok.error)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: tok.error.withValues(alpha: 0.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (mgr.status == ModelStatus.error)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tok.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tok.error.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: tok.error),
                            const SizedBox(width: 8),
                            Text('Download Error', style: TextStyle(color: tok.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mgr.errorMessage ?? 'Failed to prepare the AI model.',
                          style: TextStyle(color: tok.textPrimary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: mgr.resumeDownload,
                          icon: Icon(Icons.refresh, color: tok.buttonText),
                          label: const Text('Retry Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tok.error,
                            foregroundColor: tok.buttonText,
                          ),
                        )
                      ],
                    ),
                  ),

                // Action Buttons
                Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary)),
                const SizedBox(height: 12),

                if (mgr.isNotInstalled)
                  ElevatedButton.icon(
                    onPressed: mgr.startDownload,
                    icon: Icon(Icons.download_rounded, color: tok.buttonText),
                    label: const Text('Download Offline AI (~350 MB)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tok.buttonPrimary,
                      foregroundColor: tok.buttonText,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                if (mgr.isReady) ...[
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : () => _runTestInference(tok),
                    icon: _isTesting
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: tok.buttonText, strokeWidth: 2))
                        : Icon(Icons.science_outlined, color: tok.buttonText),
                    label: Text(_isTesting ? 'Running Offline Inference...' : 'Test Offline AI Model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tok.buttonPrimary,
                      foregroundColor: tok.buttonText,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmDelete(context, mgr);
                    },
                    icon: Icon(Icons.delete_forever, color: tok.error),
                    label: Text('Delete Model (~350 MB)', style: TextStyle(color: tok.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tok.error.withValues(alpha: 0.5)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                // Live Test Output Display
                if (_testOutput != null && _testOutput!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tok.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tok.primary.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: tok.success, size: 18),
                            const SizedBox(width: 8),
                            Text("Test Output (Offline GGUF)", style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _testOutput!,
                          style: TextStyle(fontSize: 13, color: tok.textPrimary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Notice Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tok.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: tok.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy & Offline Guarantee: The model runs locally on your device hardware. Your questions and study activity are never transmitted to external AI servers.',
                          style: TextStyle(color: tok.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, SemanticThemeTokens tok, {bool isSmallText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: tok.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: tok.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isSmallText ? 11 : 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusString(ModelStatus s) {
    switch (s) {
      case ModelStatus.notInstalled:
        return 'Not Installed';
      case ModelStatus.downloading:
        return 'Downloading';
      case ModelStatus.paused:
        return 'Paused';
      case ModelStatus.verifying:
        return 'Verifying';
      case ModelStatus.loading:
        return 'Loading';
      case ModelStatus.ready:
        return 'Ready (Offline AI)';
      case ModelStatus.error:
        return 'Error';
      case ModelStatus.updateAvailable:
        return 'Update Available';
    }
  }

  Color _getStatusColor(ModelStatus s, SemanticThemeTokens tok) {
    switch (s) {
      case ModelStatus.notInstalled:
        return tok.warning;
      case ModelStatus.downloading:
      case ModelStatus.paused:
      case ModelStatus.verifying:
      case ModelStatus.loading:
        return tok.primary;
      case ModelStatus.ready:
        return tok.success;
      case ModelStatus.error:
        return tok.error;
      case ModelStatus.updateAvailable:
        return tok.secondaryAccent;
    }
  }

  void _confirmDelete(BuildContext context, ModelManager mgr) {
    final tok = context.tokens;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: tok.cardBackground,
        title: Text('Delete AI Model (~350 MB)?', style: TextStyle(color: tok.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'This will only remove the offline AI model file to free up ~350 MB of storage.\n\nYour courses, lessons, progress, notes, scholarships, and profile data will NOT be deleted.',
          style: TextStyle(color: tok.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: TextStyle(color: tok.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tok.error,
              foregroundColor: tok.buttonText,
            ),
            onPressed: () {
              Navigator.pop(c);
              mgr.deleteModel();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline AI Model deleted. Storage reclaimed.')),
              );
            },
            child: const Text('Delete Model'),
          ),
        ],
      ),
    );
  }
}
