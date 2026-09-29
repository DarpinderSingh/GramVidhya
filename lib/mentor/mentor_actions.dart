import 'dart:convert';
import 'package:flutter/material.dart';

/// Supported structured mentor actions.
enum MentorActionType {
  startLesson,
  startQuiz,
  startRevision,
  continueLearning,
  openTopic,
  showProgress,
  noAction,
}

/// A validated, safe mentor action received from AI reasoning or suggested UI prompts.
class MentorAction {
  MentorAction({
    required this.type,
    required this.message,
    this.topic,
    this.subject,
    this.lessonId,
  });

  final MentorActionType type;
  final String message;
  final String? topic;
  final String? subject;
  final String? lessonId;

  /// Safe parser for LLM responses.
  /// Handles JSON blocks or regular conversational text.
  static MentorAction parse(String raw) {
    final text = raw.trim();

    // Check if response contains a JSON block
    int start = text.indexOf('{');
    int end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      try {
        final jsonStr = text.substring(start, end + 1);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        final actionStr = (map['action'] as String? ?? 'NO_ACTION').toUpperCase();
        final actionType = _mapStringToType(actionStr);
        final msg = map['message'] as String? ?? text;
        final topic = map['topic'] as String?;
        final subject = map['subject'] as String?;
        final lessonId = map['lessonId'] as String?;

        return MentorAction(
          type: actionType,
          message: msg,
          topic: topic,
          subject: subject,
          lessonId: lessonId,
        );
      } catch (_) {
        // Fall back to plain text
      }
    }

    // Default: Plain text message with no structured action
    return MentorAction(type: MentorActionType.noAction, message: text);
  }

  static MentorActionType _mapStringToType(String s) {
    switch (s) {
      case 'START_LESSON':
        return MentorActionType.startLesson;
      case 'START_QUIZ':
        return MentorActionType.startQuiz;
      case 'START_REVISION':
        return MentorActionType.startRevision;
      case 'CONTINUE_LEARNING':
        return MentorActionType.continueLearning;
      case 'OPEN_TOPIC':
        return MentorActionType.openTopic;
      case 'SHOW_PROGRESS':
        return MentorActionType.showProgress;
      default:
        return MentorActionType.noAction;
    }
  }

  String get actionLabel {
    switch (type) {
      case MentorActionType.startLesson:
        return 'Start Lesson';
      case MentorActionType.startQuiz:
        return 'Take Quiz';
      case MentorActionType.startRevision:
        return 'Revise Topic';
      case MentorActionType.continueLearning:
        return 'Continue Learning';
      case MentorActionType.openTopic:
        return 'Open Topic';
      case MentorActionType.showProgress:
        return 'View Progress';
      case MentorActionType.noAction:
        return '';
    }
  }

  IconData get actionIcon {
    switch (type) {
      case MentorActionType.startLesson:
        return Icons.play_circle_outline;
      case MentorActionType.startQuiz:
        return Icons.quiz_outlined;
      case MentorActionType.startRevision:
        return Icons.refresh_outlined;
      case MentorActionType.continueLearning:
        return Icons.arrow_forward;
      case MentorActionType.openTopic:
        return Icons.menu_book_outlined;
      case MentorActionType.showProgress:
        return Icons.insights;
      case MentorActionType.noAction:
        return Icons.chat_bubble_outline;
    }
  }

  /// Safe execution: runs predefined safe app behaviors only.
  void execute(BuildContext context, {void Function(MentorAction)? onActionHandled}) {
    if (type == MentorActionType.noAction) return;

    if (onActionHandled != null) {
      onActionHandled(this);
      return;
    }

    // Default execution feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionLabel: ${topic ?? subject ?? "Session ready"}'),
        backgroundColor: const Color(0xFF38BDF8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
