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
    final tok = context.tokens;
    final profile = widget.service.profile;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('digital_mentor'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: tok.textPrimary)),
            Text(
              '${profile.name} • ${profile.currentSubject}',
              style: TextStyle(fontSize: 12, color: tok.textSecondary),
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
                color: tok.textPrimary,
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
              color: tok.success.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tok.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: tok.success, size: 14),
                const SizedBox(width: 4),
                Text(
                  tr('offline_ai_badge'),
                  style: TextStyle(color: tok.success, fontSize: 11, fontWeight: FontWeight.bold),
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
          _buildSuggestionsBar(tok),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _controller.messages.length,
              itemBuilder: (ctx, i) {
                final msg = _controller.messages[i];
                return _buildMessageBubble(msg, tok);
              },
            ),
          ),

          // Loading / Streaming indicator
          if (_controller.isBusy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: tok.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr('typing'),
                    style: TextStyle(fontSize: 12, color: tok.textSecondary),
                  ),
                ],
              ),
            ),

          // Voice Status Feedback
          if (_controller.voiceState != VoiceState.idle)
            _buildVoiceStatusBanner(tok),

          // Input Bar
          _buildInputBar(tok),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBar(SemanticThemeTokens tok) {
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
            label: Text(prompt, style: TextStyle(fontSize: 12, color: tok.textPrimary)),
            backgroundColor: tok.cardBackground,
            side: BorderSide(color: tok.border),
            onPressed: () => _handleSend(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(MentorChatMessage msg, SemanticThemeTokens tok) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? tok.primary
              : tok.cardBackground,
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
                      Icon(Icons.school, size: 14, color: tok.primary),
                      const SizedBox(width: 6),
                      Text(
                        tr('digital_mentor'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tok.primary),
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
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tok.primary),
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
                color: isUser ? tok.buttonText : tok.textPrimary,
                height: 1.4,
              ),
            ),
            if (msg.action != null && msg.action!.type != MentorActionType.noAction) ...[
              const SizedBox(height: 12),
              _buildStructuredActionButton(msg.action!, tok),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredActionButton(MentorAction action, SemanticThemeTokens tok) {
    return ElevatedButton.icon(
      onPressed: () => action.execute(context),
      icon: Icon(action.actionIcon, size: 16, color: tok.buttonText),
      label: Text(action.actionLabel, style: TextStyle(color: tok.buttonText)),
      style: ElevatedButton.styleFrom(
        backgroundColor: tok.buttonPrimary,
        foregroundColor: tok.buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildVoiceStatusBanner(SemanticThemeTokens tok) {
    String text = '';
    Color color = tok.primary;
    IconData icon = Icons.mic;

    switch (_controller.voiceState) {
      case VoiceState.listening:
        text = tr('listening_state');
        color = tok.error;
        icon = Icons.mic;
        break;
      case VoiceState.processing:
        text = 'Processing voice audio...';
        color = tok.warning;
        icon = Icons.hourglass_top;
        break;
      case VoiceState.speaking:
        text = tr('speaking_state');
        color = tok.success;
        icon = Icons.volume_up;
        break;
      case VoiceState.error:
        text = _controller.errorMessage.isNotEmpty ? _controller.errorMessage : 'Voice error';
        color = tok.error;
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

  Widget _buildInputBar(SemanticThemeTokens tok) {
    final isListening = _controller.voiceState == VoiceState.listening;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tok.cardBackground,
        border: Border(top: BorderSide(color: tok.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Microphone Button
            IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? tok.error : tok.primary,
              ),
              onPressed: () => _controller.toggleVoice((t) => _textController.text = t),
            ),
            const SizedBox(width: 4),

            // Text Field
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: tok.textPrimary, fontSize: 14),
                onSubmitted: (v) => _handleSend(),
                decoration: InputDecoration(
                  hintText: tr('hint'),
                  hintStyle: TextStyle(
                    color: tok.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: tok.backgroundSecondary,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Send Button
            IconButton(
              icon: Icon(Icons.send, color: tok.primary),
              onPressed: () => _handleSend(),
            ),
          ],
        ),
      ),
    );
  }
}
