import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../mentor/mentor_actions.dart';
import '../mentor/mentor_controller.dart';
import '../mentor/mentor_service.dart';

import '../main.dart';

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({
    super.key,
    required this.ai,
    required this.service,
    this.initialQuery,
  });

  final InferenceController ai;
  final MentorService service;
  final String? initialQuery;

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  late final MentorController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'Explain this topic to me',
    'What should I study today?',
    'Test me on this topic',
    "I don't understand this question",
    'Revise my weak topics',
  ];

  @override
  void initState() {
    super.initState();
    _controller = MentorController(ai: widget.ai, service: widget.service);
    _controller.init();
    _controller.addListener(_onControllerUpdate);

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.sendMessage(widget.initialQuery!);
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend([String? text]) {
    final query = (text ?? _textController.text).trim();
    if (query.isEmpty) return;
    _textController.clear();
    _controller.sendMessage(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.service.profile;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('digital_mentor'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              '${profile.name} • ${profile.currentSubject}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (_, mode, __) => IconButton(
              tooltip: tr('theme'),
              icon: Icon(
                mode == ThemeMode.light
                    ? Icons.light_mode
                    : mode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.brightness_auto,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                final next = mode == ThemeMode.light
                    ? ThemeMode.dark
                    : mode == ThemeMode.dark
                        ? ThemeMode.system
                        : ThemeMode.light;
                setThemeMode(next);
              },
            ),
          ),
          // Offline AI Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
                Text(
                  tr('offline_ai_badge'),
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Suggestions Bar
          _buildSuggestionsBar(),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _controller.messages.length,
              itemBuilder: (ctx, i) {
                final msg = _controller.messages[i];
                return _buildMessageBubble(msg, theme);
              },
            ),
          ),

          // Loading / Streaming indicator
          if (_controller.isBusy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr('typing'),
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),

          // Voice Status Feedback
          if (_controller.voiceState != VoiceState.idle)
            _buildVoiceStatusBanner(),

          // Input Bar
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final prompt = _suggestedPrompts[i];
          return ActionChip(
            label: Text(prompt, style: const TextStyle(fontSize: 12)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            onPressed: () => _handleSend(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(MentorChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    final tok = context.tokens;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? tok.accent
              : tok.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(
            color: tok.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 14, color: tok.accent),
                      const SizedBox(width: 6),
                      Text(
                        tr('digital_mentor'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tok.accent),
                      ),
                    ],
                  ),
                  if (msg.sourceAttribution != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tok.chipBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        msg.sourceAttribution!,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tok.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : tok.textPrimary,
                height: 1.4,
              ),
            ),
            if (msg.action != null && msg.action!.type != MentorActionType.noAction) ...[
              const SizedBox(height: 12),
              _buildStructuredActionButton(msg.action!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredActionButton(MentorAction action) {
    return ElevatedButton.icon(
      onPressed: () => action.execute(context),
      icon: Icon(action.actionIcon, size: 16),
      label: Text(action.actionLabel),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildVoiceStatusBanner() {
    String text = '';
    Color color = const Color(0xFF38BDF8);
    IconData icon = Icons.mic;

    switch (_controller.voiceState) {
      case VoiceState.listening:
        text = tr('listening_state');
        color = Colors.redAccent;
        icon = Icons.mic;
        break;
      case VoiceState.processing:
        text = 'Processing voice audio...';
        color = Colors.amber;
        icon = Icons.hourglass_top;
        break;
      case VoiceState.speaking:
        text = tr('speaking_state');
        color = const Color(0xFF10B981);
        icon = Icons.volume_up;
        break;
      case VoiceState.error:
        text = _controller.errorMessage.isNotEmpty ? _controller.errorMessage : 'Voice error';
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      case VoiceState.idle:
        return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: color.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    final isListening = _controller.voiceState == VoiceState.listening;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Microphone Button
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Colors.redAccent : const Color(0xFF38BDF8),
              ),
              onPressed: () => _controller.toggleVoice((t) => _textController.text = t),
            ),
            const SizedBox(width: 4),

            // Text Field
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _handleSend(),
                decoration: InputDecoration(
                  hintText: tr('hint'),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Send Button
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
              onPressed: () => _handleSend(),
            ),
          ],
        ),
      ),
    );
  }
}
