import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../ai/model_manager.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../voice/voice_service.dart';
import 'model_manager_screen.dart';

class _Msg {
  _Msg(this.text, this.user);
  String text;
  final bool user;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.ai});
  final InferenceController ai;

  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _c = TextEditingController();
  final _v = VoiceService();
  final _scrollController = ScrollController();
  final _msgs = <_Msg>[
    _Msg("Namaste! I am GramVidhya AI Tutor. Ask me anything about your subjects, lessons, or concepts.", false)
  ];
  bool _busy = false, _rec = false;
  bool _useNotesFallbackMode = false;

  final List<String> _suggestions = [
    "What is photosynthesis?",
    "Explain Newton's Laws with everyday examples",
    "How does Binary Search work?",
    "Summarize Operating System fundamentals",
    "Tips for exam preparation",
  ];

  Future<void> _send([String? t]) async {
    final q = (t ?? _c.text).trim();
    if (q.isEmpty || _busy) return;
    _c.clear();
    setState(() {
      _msgs.add(_Msg(q, true));
      _msgs.add(_Msg('', false));
      _busy = true;
    });
    _scrollToBottom();

    try {
      await for (final tok in widget.ai.ask(q)) {
        if (!mounted) return;
        setState(() => _msgs.last.text += tok);
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_msgs.last.text.isEmpty) {
          _msgs.last.text = "Sorry, an error occurred during inference. Please try again.";
        }
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_msgs.last.text.isNotEmpty) {
          _v.speak(_msgs.last.text, appLang.value);
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _mic() async {
    if (_rec) {
      final text = await _v.stop(appLang.value);
      setState(() => _rec = false);
      if (text.isNotEmpty) {
        _send(text);
      }
    } else {
      setState(() => _rec = true);
      await _v.start(appLang.value, (t) => _c.text = t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final mgr = ModelManager.instance;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: tok.primary,
              radius: 18,
              child: Icon(Icons.psychology, color: tok.buttonText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "GramVidhya AI Tutor",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: tok.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mgr.isReady
                              ? tok.success
                              : (mgr.isDownloading || mgr.isLoading ? tok.warning : tok.textMuted),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          mgr.isReady
                              ? "🟢 Offline AI Ready"
                              : (mgr.isDownloading
                                  ? "Downloading AI (${(mgr.progress * 100).toStringAsFixed(0)}%)"
                                  : (mgr.isLoading
                                      ? "Preparing AI..."
                                      : (_useNotesFallbackMode ? "Offline Notes Mode" : "Model Not Installed"))),
                          style: TextStyle(
                            fontSize: 11,
                            color: tok.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: tok.primary),
            tooltip: 'AI Settings & Model Manager',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelManagerScreen()),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: mgr,
        builder: (context, _) {
          // If model is ready or user explicitly selected "Maybe Later / Notes Mode", show chat interface
          if (mgr.isReady || _useNotesFallbackMode) {
            return _buildChatInterface(tok, mgr);
          }

          // State: Downloading or Paused
          if (mgr.isDownloading || mgr.isPaused) {
            return _buildDownloadingView(tok, mgr);
          }

          // State: Verifying or Loading
          if (mgr.isLoading) {
            return _buildLoadingView(tok, mgr);
          }

          // State: Error
          if (mgr.status == ModelStatus.error) {
            return _buildErrorView(tok, mgr);
          }

          // Default State: Not Installed
          return _buildNotInstalledView(tok, mgr);
        },
      ),
    );
  }

  // ── STATE 1: Model Not Installed View ──────────────────────────────────────────
  Widget _buildNotInstalledView(SemanticThemeTokens tok, ModelManager mgr) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: tok.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.offline_bolt_rounded,
                size: 54,
                color: tok.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Ask GramVidhya Offline",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: tok.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Download the offline AI model once while connected to the internet. After installation, you can ask questions without internet.",
              style: TextStyle(
                fontSize: 14,
                color: tok.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Model Specifications Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tok.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tok.border),
                boxShadow: [
                  BoxShadow(
                    color: tok.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSpecRow(Icons.file_download_outlined, "Approximate Model Size", "~350 MB", tok),
                  const Divider(height: 16),
                  _buildSpecRow(Icons.storage_outlined, "Storage Requirement", "~500 MB free space", tok),
                  const Divider(height: 16),
                  _buildSpecRow(Icons.wifi_off_rounded, "Offline Capability", "100% On-Device (Zero Data)", tok),
                  const Divider(height: 16),
                  _buildSpecRow(Icons.info_outline_rounded, "Model Status", "Not Installed", tok, highlightColor: tok.warning),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                _confirmDownloadModal(context, mgr, tok);
              },
              icon: Icon(Icons.download_rounded, color: tok.buttonText, size: 20),
              label: const Text(
                "Download Offline AI (~350 MB)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tok.buttonPrimary,
                foregroundColor: tok.buttonText,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _useNotesFallbackMode = true;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tok.border),
                foregroundColor: tok.textSecondary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Maybe Later (Use Notes Mode)"),
            ),
            const SizedBox(height: 20),
            Text(
              "GramVidhya courses, scholarships, notes, and mentor features remain fully accessible without downloading the AI model.",
              style: TextStyle(fontSize: 12, color: tok.textMuted, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 2: Downloading View ──────────────────────────────────────────────
  Widget _buildDownloadingView(SemanticThemeTokens tok, ModelManager mgr) {
    final percent = (mgr.progress * 100).toStringAsFixed(0);
    final downloadedMB = (mgr.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = ModelManager.defaultModel.sizeMB.toStringAsFixed(0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tok.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mgr.isPaused ? Icons.pause_circle_outline : Icons.cloud_download_rounded,
                size: 52,
                color: tok.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mgr.isPaused ? "Download Paused" : "Downloading Offline AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: tok.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              mgr.isPaused
                  ? "Download is paused. You can resume anytime without losing progress."
                  : "Downloading model files for on-device offline inference...",
              style: TextStyle(fontSize: 14, color: tok.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tok.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tok.border),
                boxShadow: [
                  BoxShadow(
                    color: tok.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Progress",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tok.textPrimary,
                        ),
                      ),
                      Text(
                        "$percent%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tok.primary,
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$downloadedMB MB / $totalMB MB",
                        style: TextStyle(fontSize: 13, color: tok.textSecondary),
                      ),
                      if (!mgr.isPaused && mgr.downloadSpeedMBps > 0)
                        Text(
                          "${mgr.downloadSpeedMBps.toStringAsFixed(1)} MB/s",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: tok.primary,
                          ),
                        ),
                    ],
                  ),
                  if (!mgr.isPaused && mgr.estimatedRemaining.inSeconds > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Estimated time remaining: ${_formatDuration(mgr.estimatedRemaining)}",
                      style: TextStyle(fontSize: 12, color: tok.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: mgr.isPaused ? mgr.resumeDownload : mgr.pauseDownload,
                    icon: Icon(mgr.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: tok.buttonText),
                    label: Text(mgr.isPaused ? "Resume" : "Pause"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tok.buttonPrimary,
                      foregroundColor: tok.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: mgr.cancelDownload,
                    icon: Icon(Icons.close_rounded, color: tok.error),
                    label: Text("Cancel", style: TextStyle(color: tok.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tok.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _useNotesFallbackMode = true);
              },
              child: Text("Continue using Notes Mode in background", style: TextStyle(color: tok.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 3: Loading / Verifying View ──────────────────────────────────────────
  Widget _buildLoadingView(SemanticThemeTokens tok, ModelManager mgr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "Preparing Offline AI...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tok.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Verifying model integrity and loading on-device inference engine. This may take a moment.",
              style: TextStyle(
                fontSize: 14,
                color: tok.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 4: Error View ──────────────────────────────────────────────────────
  Widget _buildErrorView(SemanticThemeTokens tok, ModelManager mgr) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tok.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 52, color: tok.error),
            ),
            const SizedBox(height: 20),
            Text(
              "Offline AI couldn't be started",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tok.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              mgr.errorMessage ?? "An unexpected error occurred while preparing the offline AI model.",
              style: TextStyle(
                fontSize: 14,
                color: tok.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: mgr.resumeDownload,
              icon: Icon(Icons.refresh_rounded, color: tok.buttonText),
              label: const Text("Try Again / Resume Download"),
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
                mgr.cancelDownload();
                mgr.startDownload();
              },
              icon: Icon(Icons.replay_rounded, color: tok.primary),
              label: Text("Re-download Model", style: TextStyle(color: tok.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tok.border),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _useNotesFallbackMode = true);
              },
              child: Text("Use Offline Notes Mode instead", style: TextStyle(color: tok.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 5: Full Chat Interface (When Model is Ready or in Notes Mode) ──────
  Widget _buildChatInterface(SemanticThemeTokens tok, ModelManager mgr) {
    return Column(
      children: [
        // Optional banner if in Notes Mode (model not installed)
        if (!mgr.isReady && _useNotesFallbackMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: tok.cardBackground,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: tok.secondaryAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Using Notes Mode. Download the offline AI model for full AI tutoring.",
                    style: TextStyle(fontSize: 12, color: tok.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() => _useNotesFallbackMode = false);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text("Get AI (~350MB)", style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

        // Chat Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length,
            itemBuilder: (context, i) {
              final m = _msgs[i];
              return Align(
                alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: m.user ? tok.primary : tok.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.user ? 16 : 4),
                      bottomRight: Radius.circular(m.user ? 4 : 16),
                    ),
                    border: m.user ? null : Border.all(color: tok.border),
                    boxShadow: [
                      BoxShadow(
                        color: tok.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    m.text.isEmpty ? 'Typing response…' : m.text,
                    style: TextStyle(
                      color: m.user ? tok.buttonText : tok.textPrimary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick Suggestions Carousel
        if (_msgs.length <= 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _suggestions
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(s, style: TextStyle(color: tok.textPrimary, fontSize: 12)),
                          backgroundColor: tok.cardBackground,
                          side: BorderSide(color: tok.border),
                          onPressed: () => _send(s),
                        ),
                      ))
                  .toList(),
            ),
          ),

        // Input Control Bar
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tok.cardBackground,
              border: Border(top: BorderSide(color: tok.border)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _rec ? tok.error.withValues(alpha: 0.2) : tok.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _mic,
                    icon: Icon(
                      _rec ? Icons.stop : Icons.mic,
                      color: _rec ? tok.error : tok.primary,
                    ),
                    tooltip: 'Voice Input',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _c,
                    onSubmitted: _send,
                    style: TextStyle(color: tok.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Ask GramVidhya AI...",
                      hintStyle: TextStyle(color: tok.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: tok.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _busy ? tok.textMuted : tok.buttonPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _busy ? null : () => _send(),
                    icon: Icon(Icons.send, color: tok.buttonText, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value, SemanticThemeTokens tok, {Color? highlightColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: tok.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: tok.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlightColor ?? tok.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return "${d.inMinutes}m ${d.inSeconds % 60}s";
    }
    return "${d.inSeconds}s";
  }

  void _confirmDownloadModal(BuildContext context, ModelManager mgr, SemanticThemeTokens tok) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tok.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_outlined, color: tok.primary, size: 26),
                const SizedBox(width: 12),
                Text(
                  "Download Offline AI Model",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tok.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "Offline AI model is approximately 350 MB. Connecting to Wi-Fi is recommended to avoid mobile data consumption.",
              style: TextStyle(fontSize: 14, color: tok.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(c);
                mgr.startDownload();
              },
              icon: Icon(Icons.download_rounded, color: tok.buttonText),
              label: const Text("Start Download (~350 MB)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: tok.buttonPrimary,
                foregroundColor: tok.buttonText,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(c),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tok.border),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Cancel", style: TextStyle(color: tok.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
