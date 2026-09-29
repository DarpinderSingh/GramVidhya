import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../data/auth_service.dart';
import '../data/store.dart';
import '../mentor/mentor_models.dart';
import '../mentor/mentor_service.dart';
import 'auth_screen.dart';
import 'dart:async';
import 'package:gramvidya/main.dart' show appThemeMode, setThemeMode;
import '../data/content_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.ai, required this.auth});
  final InferenceController ai;
  final AuthService auth;
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  int _quoteIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotes = [tr('quote1'), tr('quote2'), tr('quote3')];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(tr('app_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 48, color: Color(0xFF38BDF8)),
                        const SizedBox(height: 8),
                        Text(
                          tr('welcome'),
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('welcome_sub'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Language selector
              DropdownButton<String>(
                dropdownColor: const Color(0xFF1E293B),
                value: appLang.value,
                icon: const Icon(Icons.language, color: Colors.white),
                underline: const SizedBox(),
                items: langNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setLanguage(v!),
              ),
              // Online / Offline Toggle
              ListenableBuilder(
                listenable: ContentRepository(),
                builder: (ctx, _) {
                  final isOnline = ContentRepository().isOnline;
                  return IconButton(
                    tooltip: isOnline ? 'Online Mode (Tap to switch to Offline)' : 'Offline Mode (Tap to switch to Online)',
                    icon: Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? const Color(0xFF10B981) : Colors.amber,
                      size: 22,
                    ),
                    onPressed: () async {
                      await ContentRepository().toggleOnlineMode();
                      if (context.mounted) {
                        final nowOnline = ContentRepository().isOnline;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            backgroundColor: nowOnline ? const Color(0xFF10B981) : Colors.amber.shade900,
                            content: Row(
                              children: [
                                Icon(nowOnline ? Icons.cloud_done : Icons.cloud_off, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(nowOnline ? 'Online Mode: All educational libraries active' : 'Offline Mode: Showing downloaded & cached content'),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              // Theme toggle
              ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeMode,
                builder: (_, mode, __) => IconButton(
                  tooltip: tr('theme'),
                  icon: Icon(
                    mode == ThemeMode.light ? Icons.light_mode
                        : mode == ThemeMode.dark ? Icons.dark_mode
                        : Icons.brightness_auto,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final next = mode == ThemeMode.light ? ThemeMode.dark
                        : mode == ThemeMode.dark ? ThemeMode.system
                        : ThemeMode.light;
                    setThemeMode(next);
                  },
                ),
              ),
              // Profile / Auth button
              IconButton(
                icon: Icon(
                  widget.auth.isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                  color: widget.auth.isLoggedIn ? const Color(0xFF38BDF8) : Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AuthScreen(auth: widget.auth)),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSoftwareInfoCard(theme),
                  const SizedBox(height: 24),
                  Text(tr('how_to_use'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHowToUseSteps(theme),
                  const SizedBox(height: 24),
                  _buildQuotesCarousel(theme, quotes),
                  const SizedBox(height: 24),
                  _buildOfflineAICard(theme),
                  const SizedBox(height: 24),
                  Text(tr('content_library'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...widget.ai.rag.chunks.map((m) => CheckboxListTile(
                    value: Store.done(m.id),
                    title: Text(m.subject),
                    subtitle: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onChanged: (v) async {
                      await Store.setDone(m.id, v!);
                      if (v) {
                        await MentorService().recordEvent(
                          type: LearningEventType.lessonCompleted,
                          subject: m.subject,
                          topic: m.text.split('\n').first,
                          score: 100.0,
                        );
                      } else {
                        MentorService().syncFromStore();
                      }
                      setState(() {});
                    },
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftwareInfoCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('what_is'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr('what_is_desc'),
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToUseSteps(ThemeData theme) {
    return Column(
      children: [
        _buildStepItem(theme, tr('step1'), tr('step1_desc'), Icons.mic),
        _buildStepItem(theme, tr('step2'), tr('step2_desc'), Icons.menu_book),
        _buildStepItem(theme, tr('step3'), tr('step3_desc'), Icons.school),
        _buildStepItem(theme, tr('step4'), tr('step4_desc'), Icons.share),
      ],
    );
  }

  Widget _buildStepItem(ThemeData theme, String step, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                Text(desc, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesCarousel(ThemeData theme, List<String> quotes) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        child: Text(
          '"${quotes[_quoteIndex]}"',
          key: ValueKey<int>(_quoteIndex),
          style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: const Color(0xFFF472B6)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOfflineAICard(ThemeData theme) {
    return AnimatedBuilder(
      animation: widget.ai,
      builder: (context, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF38BDF8),
            child: Icon(Icons.offline_bolt, color: Colors.white),
          ),
          title: Text(tr('offline'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('AI: ${widget.ai.active.name}\n${trf('progress_sync', {'n': Store.pending.toString()})}'),
          isThreeLine: true,
          trailing: widget.ai.isDownloading
              ? const CircularProgressIndicator()
              : widget.ai.active.name.contains('Notes')
                  ? FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: Text(tr('download_ai')),
                      onPressed: () async => await widget.ai.downloadOfflineModel(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
                      onPressed: () async => await widget.ai.refresh(),
                    ),
        ),
      ),
    );
  }
}
