import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../voice/voice_service.dart';
import 'mentor_actions.dart';
import 'mentor_models.dart';
import 'mentor_prompt.dart';
import 'mentor_service.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class MentorChatMessage {
  MentorChatMessage({
    required this.text,
    required this.isUser,
    this.action,
    this.sourceAttribution,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String text;
  final bool isUser;
  MentorAction? action;
  String? sourceAttribution; // 'PROGRESS DATA', 'COURSE CONTENT', 'LOCAL AI', 'ONLINE AI'
  final DateTime timestamp;
}

class MentorController extends ChangeNotifier {
  MentorController({
    required this.ai,
    required this.service,
    VoiceService? voiceService,
  }) : _voice = voiceService ?? VoiceService();

  final InferenceController ai;
  final MentorService service;
  final VoiceService _voice;

  final List<MentorChatMessage> _messages = [];
  bool _isBusy = false;
  VoiceState _voiceState = VoiceState.idle;
  String _errorMessage = '';

  List<MentorChatMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _isBusy;
  VoiceState get voiceState => _voiceState;
  String get errorMessage => _errorMessage;

  void init() {
    if (_messages.isEmpty) {
      final greeting = service.generateMentorMessage();
      _messages.add(MentorChatMessage(
        text: greeting,
        isUser: false,
        sourceAttribution: 'PROGRESS DATA',
      ));
    }
  }

  /// Sends a message from the student to the digital mentor.
  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isBusy) return;

    _errorMessage = '';
    _messages.add(MentorChatMessage(text: query, isUser: true));
    
    // Add empty placeholder for mentor streaming response
    final mentorMsg = MentorChatMessage(text: '', isUser: false);
    _messages.add(mentorMsg);
    _isBusy = true;
    notifyListeners();

    // Record user question in student history
    await service.recordEvent(
      type: LearningEventType.topicAsked,
      subject: service.profile.currentSubject,
      topic: service.profile.currentTopic,
      metadata: {'query': query},
    );

    final lowerQuery = query.toLowerCase();

    // ── HIERARCHY 1: Progress & Learning History Questions ─────────────────
    if (_isProgressQuestion(lowerQuery)) {
      final responseText = _answerProgressQuestion(lowerQuery);
      mentorMsg.text = responseText;
      mentorMsg.sourceAttribution = 'PROGRESS DATA';
      _isBusy = false;
      notifyListeners();
      return;
    }

    // ── HIERARCHY 2 & 3: Course Content / Local AI / Offline Fallback ─────
    try {
      final searchHits = ai.rag.search(query, k: 3);
      final retrievedContent = searchHits.map((c) => '• [${c.subject}] ${c.text}').join('\n');

      final isLlmActive = await ai.active.available() && ai.active.name != 'GramVidya (Offline Notes)';

      if (isLlmActive) {
        // Query active LLM
        mentorMsg.sourceAttribution = 'LOCAL AI';
        final systemPrompt = MentorPromptBuilder.buildSystemPrompt(
          profile: service.profile,
          memory: service.memory,
          retrievedContent: retrievedContent,
        );

        final stream = ai.active.generate(systemPrompt, query, context: retrievedContent);
        final fullResponseBuffer = StringBuffer();
        await for (final token in stream) {
          fullResponseBuffer.write(token);
          mentorMsg.text = fullResponseBuffer.toString();
          notifyListeners();
        }

        final fullText = fullResponseBuffer.toString();
        final parsedAction = MentorAction.parse(fullText);
        if (parsedAction.type != MentorActionType.noAction) {
          mentorMsg.action = parsedAction;
          mentorMsg.text = parsedAction.message;
        }
      } else {
        // Fallback to deterministic course content retrieval without LLM
        mentorMsg.sourceAttribution = 'COURSE CONTENT';
        if (retrievedContent.isNotEmpty) {
          mentorMsg.text = "Based on your downloaded course content:\n\n"
              "$retrievedContent\n\n"
              "You can open the course module to read the full chapter.";
        } else {
          mentorMsg.text = "Based on your downloaded course content:\n\n"
              "No specific downloaded notes were found for '$query'. "
              "Try searching for topics like Machine Learning, Linear Regression, or Operating Systems.";
        }
      }

      if (_voiceState == VoiceState.processing) {
        _speakResponse(mentorMsg.text);
      }
    } catch (e) {
      // Deterministic course content fallback on exception
      mentorMsg.sourceAttribution = 'COURSE CONTENT';
      mentorMsg.text = "Based on your downloaded course content:\n\n"
          "The offline AI engine is adjusting, but you can continue reading your downloaded lessons directly.";
      _errorMessage = e.toString();
    } finally {
      _isBusy = false;
      if (_voiceState != VoiceState.speaking) {
        _voiceState = VoiceState.idle;
      }
      notifyListeners();
    }
  }

  bool _isProgressQuestion(String q) {
    return q.contains('what should i study') ||
        q.contains('next lesson') ||
        q.contains('how much have i completed') ||
        q.contains('completion') ||
        q.contains('recent activity') ||
        q.contains('what did i study') ||
        q.contains('my progress') ||
        q.contains('weak topics') ||
        q.contains('lessons completed');
  }

  String _answerProgressQuestion(String q) {
    final ctx = service.getMentorContext();
    if (q.contains('what should i study') || q.contains('next lesson')) {
      if (ctx.recommendedNextLessons.isNotEmpty) {
        final next = ctx.recommendedNextLessons.first;
        final title = next['title'] ?? 'Next Chapter';
        final course = next['courseTitle'] ?? '';
        return "Based on your learning progress:\n\n"
            "I recommend starting: **$title** ${course.isNotEmpty ? '($course)' : ''}.\n\n"
            "Keep up the consistent momentum!";
      } else {
        return "Based on your learning progress:\n\n"
            "You have no pending incomplete lessons. Select a new course from the Learn section!";
      }
    }

    if (q.contains('how much have i completed') || q.contains('completion') || q.contains('my progress') || q.contains('lessons completed')) {
      final overall = (ctx.overallProgress * 100).round();
      return "Based on your learning progress:\n\n"
          "• Overall Completion: $overall%\n"
          "• Lessons Completed: ${ctx.completedLessons.length}\n"
          "• Lessons In Progress: ${ctx.incompleteLessons.length}\n"
          "• Active Courses: ${ctx.recentCourses.length}";
    }

    if (q.contains('weak topics') || q.contains('struggling')) {
      if (ctx.strugglingTopics.isNotEmpty) {
        final list = ctx.strugglingTopics.map((t) => "• ${t.topic} (${t.reason})").join('\n');
        return "Based on your learning analysis:\n\n"
            "Here are topics that need attention:\n$list";
      } else {
        return "Based on your learning analysis:\n\n"
            "Great news! No weak or struggling topics detected in your recent learning activity.";
      }
    }

    // Default recent learning summary
    if (ctx.recentLessons.isNotEmpty) {
      final top = ctx.recentLessons.take(3).map((l) => "• ${l['lessonTitle']} (${l['courseTitle']})").join('\n');
      return "Based on your recent activity:\n\n"
          "Here is what you studied recently:\n$top";
    }

    return "Based on your learning progress:\n\n"
        "No learning history recorded yet. Start reading lessons in the Learn section to track your progress!";
  }

  // ──── Voice Interactions ────

  Future<void> toggleVoice(void Function(String) onRecognizedText) async {
    if (_voiceState == VoiceState.listening) {
      // Stop recording and process
      _voiceState = VoiceState.processing;
      notifyListeners();

      try {
        final text = await _voice.stop(appLang.value);
        if (text.isNotEmpty) {
          onRecognizedText(text);
          await sendMessage(text);
        } else {
          _voiceState = VoiceState.idle;
          notifyListeners();
        }
      } catch (e) {
        _voiceState = VoiceState.error;
        _errorMessage = e is VoiceException ? e.localizedMessage : e.toString();
        notifyListeners();
      }
    } else {
      // Start listening
      _voiceState = VoiceState.listening;
      _errorMessage = '';
      notifyListeners();

      try {
        await _voice.start(appLang.value, (partial) {
          onRecognizedText(partial);
        });
      } catch (e) {
        _voiceState = VoiceState.error;
        _errorMessage = e is VoiceException ? e.localizedMessage : e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> _speakResponse(String text) async {
    _voiceState = VoiceState.speaking;
    notifyListeners();
    try {
      await _voice.speak(text, appLang.value);
    } catch (_) {}
    _voiceState = VoiceState.idle;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _voice.stopSpeaking();
    _voiceState = VoiceState.idle;
    notifyListeners();
  }
}
