import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/auth_service.dart';
import '../data/store.dart';
import '../mentor/mentor_models.dart';
import '../mentor/mentor_service.dart';
import 'auth_screen.dart';
import 'model_manager_screen.dart';
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
    final tok = context.tokens;
    final quotes = [tr('quote1'), tr('quote2'), tr('quote3')];

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: tok.primary,
            foregroundColor: tok.buttonText,
            title: Text(
              tr('app_title'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tok.buttonText,
                fontSize: 16,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tok.heroGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 40.0, left: 16, right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 48, color: tok.buttonText),
                        const SizedBox(height: 8),
                        Text(
                          tr('welcome'),
                          style: TextStyle(
                            fontSize: 20,
                            color: tok.buttonText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('welcome_sub'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: tok.buttonText.withValues(alpha: 0.8),
                          ),
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
                dropdownColor: tok.cardBackground,
                value: appLang.value,
                icon: Icon(Icons.language, color: tok.buttonText),
                underline: const SizedBox(),
                items: langNames.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: TextStyle(color: tok.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) => setLanguage(v!),
              ),
              // Online / Offline Toggle
              ListenableBuilder(
                listenable: ContentRepository(),
                builder: (ctx, _) {
                  final isOnline = ContentRepository().isOnline;
                  return IconButton(
                    tooltip: isOnline
                        ? 'Online Mode (Tap to switch to Offline)'
                        : 'Offline Mode (Tap to switch to Online)',
                    icon: Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: isOnline ? tok.buttonText : tok.warning,
                      size: 22,
                    ),
                    onPressed: () async {
                      await ContentRepository().toggleOnlineMode();
                      if (context.mounted) {
                        final nowOnline = ContentRepository().isOnline;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            backgroundColor:
                                nowOnline ? tok.success : tok.warning,
                            content: Row(
                              children: [
                                Icon(
                                  nowOnline
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: tok.buttonText,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nowOnline
                                        ? 'Online Mode: All educational libraries active'
                                        : 'Offline Mode: Showing downloaded & cached content',
                                    style: TextStyle(color: tok.buttonText),
                                  ),
                                ),
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
                    mode == ThemeMode.light
                        ? Icons.light_mode
                        : mode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.brightness_auto,
                    color: tok.buttonText,
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
              // Profile / Auth button
              IconButton(
                icon: Icon(
                  widget.auth.isLoggedIn
                      ? Icons.account_circle
                      : Icons.account_circle_outlined,
                  color: tok.buttonText,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AuthScreen(auth: widget.auth)),
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
                  _buildSoftwareInfoCard(tok),
                  const SizedBox(height: 24),
                  Text(
                    tr('how_to_use'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tok.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowToUseSteps(tok),
                  const SizedBox(height: 24),
                  _buildQuotesCarousel(tok, quotes),
                  const SizedBox(height: 24),
                  _buildOfflineAICard(tok),
                  const SizedBox(height: 24),
                  Text(
                    tr('content_library'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tok.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.ai.rag.chunks.map((m) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: tok.border),
                        ),
                        color: tok.cardBackground,
                        child: CheckboxListTile(
                          activeColor: tok.primary,
                          checkColor: tok.buttonText,
                          value: Store.done(m.id),
                          title: Text(
                            m.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: tok.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            m.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: tok.textSecondary),
                          ),
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
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftwareInfoCard(AppThemeTokens tok) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tok.border),
      ),
      color: tok.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: tok.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('what_is'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tok.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr('what_is_desc'),
              style: TextStyle(
                height: 1.5,
                color: tok.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToUseSteps(AppThemeTokens tok) {
    return Column(
      children: [
        _buildStepItem(tok, tr('step1'), tr('step1_desc'), Icons.mic),
        _buildStepItem(tok, tr('step2'), tr('step2_desc'), Icons.menu_book),
        _buildStepItem(tok, tr('step3'), tr('step3_desc'), Icons.school),
        _buildStepItem(tok, tr('step4'), tr('step4_desc'), Icons.share),
      ],
    );
  }

  Widget _buildStepItem(
      AppThemeTokens tok, String step, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tok.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tok.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tok.primary,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 14, color: tok.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesCarousel(AppThemeTokens tok, List<String> quotes) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: tok.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tok.border),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        child: Text(
          '"${quotes[_quoteIndex]}"',
          key: ValueKey<int>(_quoteIndex),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 15,
            color: tok.secondaryAccent,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOfflineAICard(AppThemeTokens tok) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.ai, widget.ai.modelManager]),
      builder: (context, _) {
        final mgr = widget.ai.modelManager;
        String statusText;
        if (mgr.isReady) {
          statusText = '🟢 Ready: On-device GGUF AI active';
        } else if (mgr.isDownloading) {
          statusText = 'Downloading AI model: ${(mgr.progress * 100).toStringAsFixed(0)}%';
        } else if (mgr.isLoading) {
          statusText = 'Preparing on-device offline AI...';
        } else {
          statusText = 'Offline model available (~350 MB)';
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tok.border),
          ),
          color: tok.cardBackground,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ModelManagerScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: tok.primary.withValues(alpha: 0.15),
                    child: Icon(
                      mgr.isReady ? Icons.check_circle_outline : Icons.offline_bolt_rounded,
                      color: mgr.isReady ? tok.success : tok.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline AI Tutor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: tok.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: mgr.isReady ? tok.success : tok.textSecondary,
                            fontWeight: mgr.isReady ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trf('progress_sync', {'n': Store.pending.toString()}),
                          style: TextStyle(fontSize: 11, color: tok.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (mgr.isDownloading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: mgr.progress > 0 ? mgr.progress : null,
                        color: tok.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  else if (!mgr.isReady)
                    FilledButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 15),
                      label: const Text('Get AI', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: tok.primary,
                        foregroundColor: tok.buttonText,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ModelManagerScreen(),
                          ),
                        );
                      },
                    )
                  else
                    Icon(Icons.chevron_right_rounded, color: tok.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
