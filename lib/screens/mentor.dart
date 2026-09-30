import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/store.dart';
import '../mentor/mentor_service.dart';
import 'mentor_chat_screen.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key, this.ai});
  final InferenceController? ai;

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  late final InferenceController _ai;
  late final MentorService _service;
  bool _isServiceInitialized = false;

  // Local mentors directory for Human Mentor section
  final List<Map<String, dynamic>> _availableMentors = [
    {
      'id': 'm1',
      'name': 'Dr. Ramesh Sharma',
      'specialization': 'Science & Mathematics',
      'institution': 'District Education Centre',
      'availability': 'Mon - Fri, 4:00 PM - 6:00 PM',
      'email': 'ramesh.sharma@gramvidya.org',
      'phone': '+91 98765 43210',
      'bio': 'Passionate educator with 15+ years of experience helping students excel in STEM subjects and scholarship applications.',
    },
    {
      'id': 'm2',
      'name': 'Priya Verma',
      'specialization': 'English & Communication Skills',
      'institution': 'Rural Youth Foundation',
      'availability': 'Tue & Thu, 2:00 PM - 5:00 PM',
      'email': 'priya.v@gramvidya.org',
      'phone': '+91 98765 12345',
      'bio': 'Dedicated to building confidence in English speaking, reading comprehension, and interview preparation for rural students.',
    },
    {
      'id': 'm3',
      'name': 'Anand Kulkarni',
      'specialization': 'Digital Literacy & Computer Science',
      'institution': 'Community Skill Hub',
      'availability': 'Sat - Sun, 10:00 AM - 1:00 PM',
      'email': 'anand.k@gramvidya.org',
      'phone': '+91 98765 67890',
      'bio': 'Tech mentor guiding students through basic computer operations, internet safety, coding fundamentals, and digital tools.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ai = widget.ai ?? InferenceController();
    _service = MentorService();
    _service.addListener(_onServiceUpdate);
    _initService();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  Future<void> _initService() async {
    await _service.init();
    _service.syncFromStore();
    if (mounted) {
      setState(() {
        _isServiceInitialized = true;
      });
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('good_morning');
    if (hour < 17) return tr('good_afternoon');
    return tr('good_evening');
  }

  void _openDigitalMentorChat({String? initialQuery}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MentorChatScreen(
          ai: _ai,
          service: _service,
          initialQuery: initialQuery,
        ),
      ),
    ).then((_) {
      // Refresh analytics upon returning from chat session
      _service.syncFromStore();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final humanMentor = Store.mentor;

    if (!_isServiceInitialized) {
      return Scaffold(
        backgroundColor: tok.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: tok.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
        title: Text(tr('mentor_title'), style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DIGITAL MENTOR CARD
              _buildDigitalMentorCard(tok),
              const SizedBox(height: 24),

              // 2. YOUR PROGRESS SECTION
              _buildYourProgressSection(tok),
              const SizedBox(height: 24),

              // 3. NEEDS ATTENTION (WEAK TOPICS)
              _buildNeedsAttentionSection(tok),
              const SizedBox(height: 24),

              // 4. QUICK ACTIONS
              _buildQuickActionsSection(tok),
              const SizedBox(height: 28),

              // 5. HUMAN MENTOR SECTION
              _buildHumanMentorSection(tok, humanMentor),
            ],
          ),
        ),
      ),
    );
  }

  // ──── 1. DIGITAL MENTOR CARD ────
  Widget _buildDigitalMentorCard(SemanticThemeTokens tok) {
    final profile = _service.profile;
    final plan = _service.dailyPlan;
    final timeGreeting = _getTimeGreeting();
    final greeting = '$timeGreeting, ${profile.name.isNotEmpty ? profile.name : "Student"} 👋';
    final progressMsg = _service.generateMentorMessage();

    final goalMinutes = plan?.estimatedMinutes ?? profile.preferredStudyDuration;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tok.primary, tok.primaryPressed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tok.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tok.buttonText.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology, color: tok.buttonText, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('digital_mentor'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tok.buttonText,
                      ),
                    ),
                    Text(
                      tr('digital_mentor_desc'),
                      style: TextStyle(fontSize: 12, color: tok.buttonText.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tok.success.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tok.success.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: tok.buttonText, size: 12),
                    const SizedBox(width: 4),
                    Text(tr('offline_ai_badge'), style: TextStyle(fontSize: 10, color: tok.buttonText, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Personalized Greeting & Message
          Text(
            greeting,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tok.buttonText),
          ),
          const SizedBox(height: 6),
          Text(
            progressMsg,
            style: TextStyle(fontSize: 13, color: tok.buttonText.withValues(alpha: 0.85), height: 1.4),
          ),
          const SizedBox(height: 18),

          // Today's Goal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tok.buttonText.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tok.buttonText.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('todays_goal'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tok.buttonText),
                    ),
                    Text(
                      '${tr("estimated_time")}: $goalMinutes ${tr("mins")}',
                      style: TextStyle(fontSize: 11, color: tok.buttonText.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        profile.currentTopic,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tok.buttonText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(_service.getSubjectProgress(profile.currentSubject) * 100).toInt()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tok.buttonText),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _service.getSubjectProgress(profile.currentSubject),
                    backgroundColor: tok.buttonText.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(tok.buttonText),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDigitalMentorChat(
                    initialQuery: "Let's start today's session on ${profile.currentTopic}.",
                  ),
                  icon: Icon(Icons.play_arrow, size: 18, color: tok.primary),
                  label: Text(tr('start_session'), style: TextStyle(color: tok.primary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tok.buttonText,
                    foregroundColor: tok.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _openDigitalMentorChat(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tok.buttonText),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(tr('ask_mentor'), style: TextStyle(color: tok.buttonText, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _openDigitalMentorChat(
                  initialQuery: "Namaste Mentor, I want to talk to you.",
                ),
                icon: Icon(Icons.mic, color: tok.buttonText),
                style: IconButton.styleFrom(
                  backgroundColor: tok.buttonText.withValues(alpha: 0.2),
                ),
                tooltip: tr('talk_to_mentor'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──── 2. YOUR PROGRESS SECTION ────
  Widget _buildYourProgressSection(SemanticThemeTokens tok) {
    final progressMap = _service.getAllSubjectProgress();
    final hasAnyProgress = progressMap.values.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('your_progress'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: tok.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tok.border),
          ),
          padding: const EdgeInsets.all(16),
          child: hasAnyProgress
              ? Column(
                  children: progressMap.entries.map((entry) {
                    final pct = (entry.value * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tok.textPrimary)),
                              Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tok.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value,
                              backgroundColor: tok.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                entry.value > 0.7 ? tok.success : tok.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  children: [
                    Icon(Icons.info_outline, color: tok.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('no_progress_yet'),
                        style: TextStyle(fontSize: 12, color: tok.textSecondary),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ──── 3. NEEDS ATTENTION (WEAK TOPICS) ────
  Widget _buildNeedsAttentionSection(SemanticThemeTokens tok) {
    final weakTopics = _service.memory.weakTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: tok.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              tr('needs_attention'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (weakTopics.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: tok.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tok.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: tok.success, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('no_weak_topics'),
                    style: TextStyle(fontSize: 12, color: tok.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: weakTopics.map((w) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: tok.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tok.warning.withValues(alpha: 0.35)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: tok.warning, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.topic,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tok.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w.reason,
                            style: TextStyle(fontSize: 12, color: tok.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openDigitalMentorChat(
                        initialQuery: "Please explain and give me practice on ${w.topic}.",
                      ),
                      child: Text(tr('revision'), style: TextStyle(color: tok.primary, fontSize: 13)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ──── 4. QUICK ACTIONS ────
  Widget _buildQuickActionsSection(SemanticThemeTokens tok) {
    final profile = _service.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('quick_actions'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.chat_bubble_outline,
                label: tr('ask_mentor'),
                onTap: () => _openDigitalMentorChat(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.quiz_outlined,
                label: tr('take_quiz'),
                onTap: () => _openDigitalMentorChat(
                  initialQuery: "Give me a quick 5-question quiz on ${profile.currentTopic}.",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.menu_book_outlined,
                label: tr('continue_learning'),
                onTap: () => _openDigitalMentorChat(
                  initialQuery: "Let's continue studying ${profile.currentTopic}.",
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.refresh_outlined,
                label: tr('revision'),
                onTap: () {
                  final weak = _service.memory.weakTopics.isNotEmpty
                      ? _service.memory.weakTopics.first.topic
                      : profile.currentTopic;
                  _openDigitalMentorChat(initialQuery: "Let's revise $weak.");
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    final tok = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: tok.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tok.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: tok.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tok.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──── 5. HUMAN MENTOR SECTION ────
  Widget _buildHumanMentorSection(SemanticThemeTokens tok, Map<String, dynamic>? humanMentor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: tok.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              tr('human_mentor'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (humanMentor != null) ...[
          _buildAssignedHumanMentorCard(tok, humanMentor),
          const SizedBox(height: 16),
          _buildHumanSessionsSection(tok),
        ] else ...[
          _buildUnassignedHumanMentorView(tok),
        ],
      ],
    );
  }

  Widget _buildAssignedHumanMentorCard(SemanticThemeTokens tok, Map<String, dynamic> mentor) {
    final name = mentor['name'] as String? ?? 'Dr. Ramesh Sharma';
    final spec = mentor['specialization'] as String? ?? 'Science & Mathematics';
    final inst = mentor['institution'] as String? ?? '';
    final avail = mentor['availability'] as String? ?? 'Mon - Fri, 4:00 PM - 6:00 PM';
    final email = mentor['email'] as String? ?? 'ramesh.sharma@gramvidya.org';
    final phone = mentor['phone'] as String? ?? '+91 98765 43210';

    return Container(
      decoration: BoxDecoration(
        color: tok.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tok.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: tok.primary.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0] : 'M',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tok.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary)),
                      const SizedBox(height: 2),
                      Text(spec, style: TextStyle(fontSize: 13, color: tok.secondaryAccent)),
                      if (inst.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(inst, style: TextStyle(fontSize: 11, color: tok.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.access_time, tr('mentor_availability'), avail),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, tr('phone'), phone),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.email, tr('email'), email),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBookSessionDialog(name),
                    icon: Icon(Icons.calendar_today, size: 16, color: tok.buttonText),
                    label: Text(tr('mentor_book'), style: TextStyle(color: tok.buttonText)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tok.buttonPrimary,
                      foregroundColor: tok.buttonText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () async {
                    await Store.setMentor(null);
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tok.error,
                    side: BorderSide(color: tok.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final tok = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tok.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tok.textSecondary)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: tok.textPrimary))),
      ],
    );
  }

  Widget _buildHumanSessionsSection(SemanticThemeTokens tok) {
    return Container(
      decoration: BoxDecoration(
        color: tok.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tok.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tok.success,
          radius: 16,
          child: Icon(Icons.check, color: tok.buttonText, size: 16),
        ),
        title: Text('Introduction & Learning Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tok.textPrimary)),
        subtitle: Text('Scheduled via local centre. Offline notes synced.', style: TextStyle(fontSize: 11, color: tok.textMuted)),
        trailing: Chip(
          label: Text(tr('offline'), style: TextStyle(fontSize: 10, color: tok.textPrimary)),
          backgroundColor: tok.success.withValues(alpha: 0.2),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildUnassignedHumanMentorView(SemanticThemeTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tok.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tok.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: tok.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('mentor_not_assigned'),
                      style: TextStyle(color: tok.warning, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('mentor_not_assigned_desc'),
                      style: TextStyle(color: tok.warning.withValues(alpha: 0.85), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._availableMentors.map((m) => _buildAvailableMentorCard(m)),
      ],
    );
  }

  Widget _buildAvailableMentorCard(Map<String, dynamic> m) {
    final tok = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tok.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tok.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: tok.primary.withValues(alpha: 0.15),
                  child: Text(
                    (m['name'] as String)[0],
                    style: TextStyle(fontWeight: FontWeight.bold, color: tok.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: tok.textPrimary)),
                      Text(m['specialization'] as String, style: TextStyle(fontSize: 12, color: tok.secondaryAccent)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Store.setMentor(m);
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Assigned ${m['name']} as your human mentor!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tok.buttonPrimary,
                    foregroundColor: tok.buttonText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(m['bio'] as String, style: TextStyle(fontSize: 12, color: tok.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: tok.textMuted),
                const SizedBox(width: 4),
                Text(m['availability'] as String, style: TextStyle(fontSize: 11, color: tok.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookSessionDialog(String mentorName) {
    final tok = context.tokens;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tok.cardBackground,
        title: Text(tr('mentor_book'), style: TextStyle(color: tok.textPrimary)),
        content: Text('Session request registered for $mentorName. The session will be confirmed when synced with the local centre.', style: TextStyle(color: tok.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('ok'), style: TextStyle(color: tok.primary)),
          ),
        ],
      ),
    );
  }
}
