import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/content_repository.dart';
import '../data/download_manager.dart';
import '../data/models/learning_resource.dart';
import '../data/store.dart';
import '../data/user_store.dart';
import '../data/progress_service.dart';
import '../data/translation_service.dart';
import '../mentor/mentor_service.dart';
import '../ai/inference_controller.dart';
import 'mentor_chat_screen.dart';
import '../main.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> with SingleTickerProviderStateMixin {
  final ContentRepository _repository = ContentRepository();
  final DownloadManager _downloadManager = DownloadManager();
  late TabController _tabController;

  List<LearningResource> _resources = [];
  List<RecentChapter> _recentChapters = [];
  RecentChapter? _continueLearning;
  bool _isLoading = true;

  // Search & Filter state
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedProvider = 'All';
  String _selectedSubject = 'All';
  String _selectedLevel = 'All';
  bool _downloadableOnly = false;

  final List<String> _providersList = [
    'All',
    'NPTEL',
    'OpenStax',
    'MIT OpenCourseWare',
    'SWAYAM',
    'Khan Academy',
    'DIKSHA',
    'GramVidya',
  ];

  final List<String> _subjectsList = [
    'All',
    'Computer Science',
    'Mathematics',
    'Physics',
    'Economics',
    'Environmental Science',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repository.addListener(_onRepoUpdate);
    _downloadManager.addListener(_onDownloadUpdate);
    _initData();
  }

  void _onRepoUpdate() {
    if (mounted) setState(() {});
  }

  void _onDownloadUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _repository.removeListener(_onRepoUpdate);
    _downloadManager.removeListener(_onDownloadUpdate);
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _repository.init();
    await _filterResources();
    _loadRecents();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadRecents() {
    _recentChapters = _repository.getRecentChapters();
    _continueLearning = _repository.getContinueLearning();
  }

  Future<void> _filterResources() async {
    final list = await _repository.searchResources(
      query: _searchCtrl.text,
      provider: _selectedProvider,
      subject: _selectedSubject,
      level: _selectedLevel,
      downloadableOnly: _downloadableOnly,
    );
    if (mounted) {
      setState(() {
        _resources = list;
        _loadRecents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final isOnline = _repository.isOnline;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: tok.backgroundPrimary,
            elevation: 0,
            iconTheme: IconThemeData(color: tok.textPrimary),
            actions: [
              // Online / Offline Toggle Button
              IconButton(
                tooltip: isOnline ? 'Online Mode (Tap to switch to Offline)' : 'Offline Mode (Tap to switch to Online)',
                icon: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? tok.success : tok.warning,
                  size: 22,
                ),
                onPressed: _toggleOnlineOffline,
              ),
              // Light / Dark Mode Toggle
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
                    size: 22,
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
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 54),
              title: Row(
                children: [
                  Text(
                    tr('nav_learn'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: tok.heroTitleColor),
                  ),
                  const SizedBox(width: 8),
                  _buildNetworkBadge(isOnline, tok),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tok.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: tok.primary,
              labelColor: tok.primary,
              unselectedLabelColor: tok.textSecondary,
              tabs: [
                Tab(icon: const Icon(Icons.explore_outlined, size: 18), text: tr('explore_courses')),
                Tab(icon: const Icon(Icons.offline_pin_outlined, size: 18), text: tr('my_library')),
                Tab(icon: const Icon(Icons.downloading_outlined, size: 18), text: tr('downloads_title')),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Subtle offline banner
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: tok.warning.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: tok.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('you_are_offline_banner'),
                        style: TextStyle(fontSize: 12, color: tok.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                    InkWell(
                      onTap: () => _tabController.animateTo(1),
                      child: Text(
                        tr('my_library'),
                        style: TextStyle(
                          fontSize: 12,
                          color: tok.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExploreTab(tok),
                  _buildLibraryTab(tok),
                  _buildDownloadsTab(tok),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(bool isOnline, SemanticThemeTokens tok) {
    final statusColor = isOnline ? tok.success : tok.warning;
    return InkWell(
      onTap: _toggleOnlineOffline,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isOnline ? Icons.cloud_done : Icons.cloud_off, size: 12, color: statusColor),
            const SizedBox(width: 4),
            Text(
              isOnline ? tr('online_mode') : tr('offline_mode'),
              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 3),
            Icon(Icons.swap_horiz, size: 11, color: statusColor),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOnlineOffline() async {
    final tok = context.tokens;
    await _repository.toggleOnlineMode();
    await _filterResources();
    if (mounted) {
      final online = _repository.isOnline;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: online ? tok.success : tok.warning,
          content: Row(
            children: [
              Icon(online ? Icons.cloud_done : Icons.cloud_off, color: tok.buttonText, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  online
                      ? 'Online Mode: All educational content & online providers active'
                      : 'Offline Mode: Showing downloaded & offline-ready content',
                  style: TextStyle(fontWeight: FontWeight.bold, color: tok.buttonText),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: EXPLORE / DISCOVER (Continue Learning + Recent Chapters + Catalog)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildExploreTab(SemanticThemeTokens tok) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: tok.primary));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. CONTINUE LEARNING (Section 2)
        if (_continueLearning != null) ...[
          _buildContinueLearningCard(_continueLearning!, tok),
          const SizedBox(height: 20),
        ],

        // 2. RECENT CHAPTERS (Section 3)
        if (_recentChapters.isNotEmpty) ...[
          _buildRecentChaptersSection(_recentChapters, tok),
          const SizedBox(height: 24),
        ],

        // 3. SEARCH & FILTERS (Section 14)
        _buildSearchAndFilters(tok),
        const SizedBox(height: 16),

        // 4. REAL EDUCATIONAL RESOURCES
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${tr("explore_courses")} (${_resources.length})',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary),
            ),
            if (_selectedProvider != 'All' || _selectedSubject != 'All' || _downloadableOnly)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _selectedProvider = 'All';
                    _selectedSubject = 'All';
                    _selectedLevel = 'All';
                    _downloadableOnly = false;
                  });
                  _filterResources();
                },
                child: Text('Reset Filters', style: TextStyle(fontSize: 12, color: tok.primary)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_resources.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: tok.textMuted),
                const SizedBox(height: 12),
                Text(tr('no_results'), style: TextStyle(color: tok.textMuted)),
              ],
            ),
          )
        else
          ..._resources.map((res) => _buildResourceCard(res, tok)),
      ],
    );
  }

  // ──── Continue Learning Card (Requirement #2) ────
  Widget _buildContinueLearningCard(RecentChapter recent, SemanticThemeTokens tok) {
    final pct = (recent.progress * 100).toInt();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: tok.cardBackground,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tok.border),
          gradient: LinearGradient(
            colors: [tok.primary, tok.primaryPressed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tok.buttonText.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_circle_fill, color: tok.buttonText, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUE LEARNING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: tok.buttonText,
                        ),
                      ),
                      Text(
                        recent.courseName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tok.buttonText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tok.buttonText.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recent.provider,
                    style: TextStyle(
                      fontSize: 11,
                      color: tok.buttonText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recent.chapterName,
              style: TextStyle(
                fontSize: 14,
                color: tok.buttonText.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: recent.progress,
                      minHeight: 6,
                      backgroundColor: tok.buttonText.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(tok.buttonText),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: tok.buttonText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _resumeChapter(recent),
                icon: Icon(Icons.arrow_forward, size: 16, color: tok.primary),
                label: Text('Continue', style: TextStyle(color: tok.primary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tok.buttonText,
                  foregroundColor: tok.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──── Recent Chapters Section (Requirement #3) ────
  Widget _buildRecentChaptersSection(List<RecentChapter> recents, SemanticThemeTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 20, color: tok.primary),
            const SizedBox(width: 8),
            Text(
              tr('recent_chapters'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recents.length,
            itemBuilder: (ctx, i) {
              final r = recents[i];
              final pct = (r.progress * 100).toInt();
              return Container(
                width: 210,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  color: tok.cardBackground,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: tok.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _resumeChapter(r),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tok.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.provider,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tok.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (r.completed)
                                Icon(Icons.check_circle, size: 14, color: tok.success)
                              else
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tok.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            r.chapterName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: tok.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.courseName,
                            style: TextStyle(
                              fontSize: 11,
                              color: tok.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: r.progress,
                              minHeight: 4,
                              backgroundColor: tok.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                r.completed ? tok.success : tok.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──── Search & Filter Bar (Requirement #14) ────
  Widget _buildSearchAndFilters(SemanticThemeTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => _filterResources(),
          style: TextStyle(color: tok.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search courses, textbooks, lectures...',
            hintStyle: TextStyle(color: tok.textSecondary),
            prefixIcon: Icon(Icons.search, color: tok.primary),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: tok.textSecondary),
                    onPressed: () {
                      _searchCtrl.clear();
                      _filterResources();
                    },
                  )
                : null,
            filled: true,
            fillColor: tok.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tok.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tok.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Provider Filter Chips
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _providersList.length,
            itemBuilder: (ctx, i) {
              final p = _providersList[i];
              final sel = _selectedProvider == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(p),
                  selected: sel,
                  onSelected: (val) {
                    setState(() => _selectedProvider = p);
                    _filterResources();
                  },
                  selectedColor: tok.primary.withValues(alpha: 0.18),
                  checkmarkColor: tok.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? tok.primary : tok.textSecondary,
                  ),
                  backgroundColor: tok.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  side: BorderSide(color: sel ? tok.primary : tok.border),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Downloadable Only toggle & Subject dropdown
        Row(
          children: [
            FilterChip(
              avatar: Icon(Icons.download, size: 14, color: _downloadableOnly ? tok.success : tok.textSecondary),
              label: Text(tr('downloadable_only')),
              selected: _downloadableOnly,
              onSelected: (val) {
                setState(() => _downloadableOnly = val);
                _filterResources();
              },
              selectedColor: tok.success.withValues(alpha: 0.18),
              checkmarkColor: tok.success,
              labelStyle: TextStyle(
                fontSize: 11,
                color: _downloadableOnly ? tok.success : tok.textSecondary,
              ),
              backgroundColor: tok.cardBackground,
              side: BorderSide(color: _downloadableOnly ? tok.success : tok.border),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: tok.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tok.border),
              ),
              child: DropdownButton<String>(
                value: _selectedSubject,
                underline: const SizedBox(),
                dropdownColor: tok.cardBackground,
                style: TextStyle(fontSize: 12, color: tok.textPrimary),
                icon: Icon(Icons.arrow_drop_down, color: tok.textSecondary),
                items: _subjectsList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? tr('all_subjects') : s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSubject = val);
                    _filterResources();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──── Resource Card ────
  Widget _buildResourceCard(LearningResource resource, SemanticThemeTokens tok) {
    final isDownloaded = _downloadManager.isDownloaded(resource.id);
    final task = _downloadManager.getTask(resource.id);
    final isDownloading = task?.status == DownloadStatus.downloading || task?.status == DownloadStatus.queued;
    final progress = Store.courseProgress(resource.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: tok.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tok.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openResourceDetail(resource),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDownloaded
                            ? [tok.success, tok.success.withValues(alpha: 0.8)]
                            : [tok.primary, tok.primaryPressed],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resource.type == ResourceType.book ? Icons.menu_book : Icons.school,
                      color: tok.buttonText,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tok.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Source: ${resource.provider}',
                          style: TextStyle(fontSize: 11, color: tok.primary, fontWeight: FontWeight.w600),
                        ),
                        if (resource.instructorOrAuthor != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            resource.instructorOrAuthor!,
                            style: TextStyle(fontSize: 11, color: tok.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                resource.description,
                style: TextStyle(fontSize: 12, color: tok.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(label: resource.subject, tok: tok),
                  const SizedBox(width: 6),
                  _Badge(label: resource.level, tok: tok),
                  const SizedBox(width: 6),
                  _Badge(label: '${resource.lessons.length} lessons', tok: tok),
                  const Spacer(),
                  if (isDownloaded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tok.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tok.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: tok.success),
                          const SizedBox(width: 4),
                          Text(
                            tr('available_offline'),
                            style: TextStyle(fontSize: 10, color: tok.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else if (isDownloading)
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: tok.primary))
                  else if (resource.downloadable)
                    Icon(Icons.download_for_offline_outlined, size: 20, color: tok.primary)
                  else
                    Icon(Icons.open_in_new, size: 18, color: tok.textSecondary),
                ],
              ),
              if (progress > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: tok.border,
                    valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: MY LIBRARY (OFFLINE-READY RESOURCES)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildLibraryTab(SemanticThemeTokens tok) {
    return FutureBuilder<List<LearningResource>>(
      future: _repository.getDownloadedResources(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: tok.primary));
        }
        final downloaded = snap.data!;

        if (downloaded.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_download_outlined, size: 64, color: tok.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    tr('no_downloaded'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tok.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.explore),
                    label: Text(tr('explore_courses')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tok.primary,
                      foregroundColor: tok.buttonText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr("my_library")} (${downloaded.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tok.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tok.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt, size: 14, color: tok.success),
                      const SizedBox(width: 4),
                      Text(
                        '100% Offline Ready',
                        style: TextStyle(fontSize: 11, color: tok.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...downloaded.map((res) => _buildResourceCard(res, tok)),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 3: DOWNLOADS MANAGER (Section 12 & 19)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildDownloadsTab(SemanticThemeTokens tok) {
    final active = _downloadManager.activeDownloads;
    final completed = _downloadManager.completedDownloads;
    final totalUsed = _downloadManager.formatBytes(_downloadManager.getTotalStorageUsedBytes());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Storage Header
        Card(
          color: tok.cardBackground,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: tok.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.storage, color: tok.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('storage_used'), style: TextStyle(fontSize: 12, color: tok.textSecondary)),
                      Text(totalUsed, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tok.textPrimary)),
                    ],
                  ),
                ),
                if (completed.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClearDownloads(),
                    icon: Icon(Icons.delete_outline, size: 16, color: tok.error),
                    label: Text('Clear', style: TextStyle(color: tok.error, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Active Downloads
        if (active.isNotEmpty) ...[
          Text('Downloading (${active.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tok.textPrimary)),
          const SizedBox(height: 10),
          ...active.map((task) => _buildActiveDownloadTile(task, tok)),
          const SizedBox(height: 20),
        ],

        // Downloaded
        Text('Downloaded (${completed.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tok.textPrimary)),
        const SizedBox(height: 10),
        if (completed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No downloaded files yet.', style: TextStyle(color: tok.textSecondary))),
          )
        else
          ...completed.map((task) => _buildCompletedDownloadTile(task, tok)),

        const SizedBox(height: 24),

        // Download Settings (Requirement #19)
        _buildDownloadSettingsCard(tok),
      ],
    );
  }

  Widget _buildActiveDownloadTile(DownloadTask task, SemanticThemeTokens tok) {
    final downloadedStr = _downloadManager.formatBytes(task.downloadedBytes);
    final totalStr = _downloadManager.formatBytes(task.totalBytes);
    final isPaused = task.status == DownloadStatus.paused;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: tok.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tok.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tok.textPrimary)),
                      Text('${task.provider} • ${task.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: tok.primary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20, color: tok.primary),
                  onPressed: () {
                    if (isPaused) {
                      _repository.getResource(task.resourceId).then((r) {
                        if (r != null) _downloadManager.resumeDownload(task.resourceId, r);
                      });
                    } else {
                      _downloadManager.pauseDownload(task.resourceId);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: tok.textSecondary),
                  onPressed: () => _downloadManager.cancelDownload(task.resourceId),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: task.totalBytes > 0 ? (task.downloadedBytes / task.totalBytes).clamp(0.0, 1.0) : null,
                minHeight: 6,
                backgroundColor: tok.border,
                valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text('$downloadedStr / $totalStr', style: TextStyle(fontSize: 10, color: tok.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedDownloadTile(DownloadTask task, SemanticThemeTokens tok) {
    final sizeStr = _downloadManager.formatBytes(task.downloadedBytes);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: tok.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tok.border),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.check_circle, color: tok.success),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: tok.textPrimary)),
        subtitle: Text('${task.provider} • $sizeStr • Available Offline',
            style: TextStyle(fontSize: 11, color: tok.textSecondary)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: tok.textSecondary),
          onPressed: () => _downloadManager.deleteDownload(task.resourceId),
        ),
        onTap: () async {
          final res = await _repository.getResource(task.resourceId);
          if (res != null && mounted) {
            _openResourceDetail(res);
          }
        },
      ),
    );
  }

  Widget _buildDownloadSettingsCard(SemanticThemeTokens tok) {
    return Card(
      color: tok.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tok.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('download_settings'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tok.textPrimary)),
            Divider(height: 20, color: tok.border),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: tok.primary,
              title: Text(tr('wifi_only'), style: TextStyle(fontSize: 13, color: tok.textPrimary)),
              value: _downloadManager.wifiOnly,
              onChanged: (v) => _downloadManager.setWifiOnly(v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: tok.primary,
              title: Text(tr('ask_large'), style: TextStyle(fontSize: 13, color: tok.textPrimary)),
              value: _downloadManager.askBeforeLargeDownloads,
              onChanged: (v) => _downloadManager.setAskBeforeLargeDownloads(v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: tok.primary,
              title: Text(tr('auto_next'), style: TextStyle(fontSize: 13, color: tok.textPrimary)),
              value: _downloadManager.autoDownloadNextLesson,
              onChanged: (v) => _downloadManager.setAutoDownloadNextLesson(v),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearDownloads() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('clear_downloads')),
        content: const Text('Are you sure you want to remove all downloaded courses and textbooks from offline storage?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _downloadManager.clearAllDownloads();
              Navigator.pop(ctx);
            },
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }

  // ──── Navigation Helpers ────

  void _openResourceDetail(LearningResource resource) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResourceDetailScreen(
          resource: resource,
          repository: _repository,
          downloadManager: _downloadManager,
          onUpdate: _filterResources,
        ),
      ),
    ).then((_) => _filterResources());
  }

  void _resumeChapter(RecentChapter recent) async {
    final resource = await _repository.getResource(recent.courseId);
    if (resource != null && resource.lessons.isNotEmpty && mounted) {
      final index = recent.lessonIndex.clamp(0, resource.lessons.length - 1);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChapterReaderScreen(
            resource: resource,
            initialLessonIndex: index,
            repository: _repository,
            onProgressUpdate: _filterResources,
          ),
        ),
      ).then((_) => _filterResources());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESOURCE DETAIL SCREEN (Section 10)
// ═══════════════════════════════════════════════════════════════════════════════

class ResourceDetailScreen extends StatefulWidget {
  final LearningResource resource;
  final ContentRepository repository;
  final DownloadManager downloadManager;
  final VoidCallback onUpdate;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    required this.repository,
    required this.downloadManager,
    required this.onUpdate,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    final res = widget.resource;
    final isDownloaded = widget.downloadManager.isDownloaded(res.id);
    final task = widget.downloadManager.getTask(res.id);
    final isDownloading = task?.status == DownloadStatus.downloading || task?.status == DownloadStatus.queued;
    final courseProgress = Store.courseProgress(res.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(res.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: tok.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing link: ${res.officialUrl}')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Card(
            color: tok.cardBackground,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tok.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [tok.primary, tok.primaryPressed]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(res.type == ResourceType.book ? Icons.menu_book : Icons.school,
                            color: tok.buttonText, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(res.title,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Source: ${res.provider}',
                                style: TextStyle(
                                    fontSize: 13, color: tok.primary, fontWeight: FontWeight.w600)),
                            if (res.institution != null) ...[
                              const SizedBox(height: 2),
                              Text(res.institution!,
                                  style: TextStyle(fontSize: 12, color: tok.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(res.description, style: TextStyle(fontSize: 13, height: 1.5, color: tok.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Badge(label: res.subject, tok: tok),
                      _Badge(label: res.level, tok: tok),
                      if (res.license != null) _Badge(label: res.license!, tok: tok),
                    ],
                  ),
                  Divider(height: 24, color: tok.border),

                  // Open Original Course Button
                  OutlinedButton.icon(
                    onPressed: () => _launchUrl(res.officialUrl),
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: Text(tr('open_original_course')),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tok.primary),
                      foregroundColor: tok.primary,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Download / Offline Status Card (Section 9 & 10)
          _buildDownloadCard(res, isDownloaded, isDownloading, task, tok),
          const SizedBox(height: 20),

          // Chapters & Lessons List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chapters (${res.lessons.length})',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
              ),
              if (courseProgress > 0)
                Text(
                  '${(courseProgress * 100).toInt()}% completed',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tok.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),

          ...res.lessons.asMap().entries.map((entry) {
            final idx = entry.key;
            final lesson = entry.value;
            final isDone = Store.done(lesson.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: tok.cardBackground,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tok.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isDone ? tok.success : tok.border,
                  child: isDone
                      ? Icon(Icons.check, size: 14, color: tok.buttonText)
                      : Text('${idx + 1}', style: TextStyle(fontSize: 11, color: tok.textPrimary)),
                ),
                title: Text(lesson.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tok.textPrimary)),
                subtitle: lesson.durationMinutes != null
                    ? Text('${lesson.durationMinutes} min', style: TextStyle(fontSize: 11, color: tok.textSecondary))
                    : null,
                trailing: isDownloaded
                    ? Icon(Icons.offline_pin, size: 18, color: tok.success)
                    : Icon(Icons.arrow_forward_ios, size: 12, color: tok.textSecondary),
                onTap: () => _openLessonReader(idx),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(LearningResource res, bool isDownloaded, bool isDownloading, DownloadTask? task, SemanticThemeTokens tok) {
    if (isDownloaded) {
      final sizeStr = task != null ? widget.downloadManager.formatBytes(task.downloadedBytes) : '';
      return Card(
        color: tok.success.withValues(alpha: 0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tok.success.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.offline_pin, color: tok.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('available_offline'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: tok.success)),
                    Text('Ready for airplane mode • $sizeStr',
                        style: TextStyle(fontSize: 11, color: tok.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: tok.error),
                onPressed: () async {
                  await widget.downloadManager.deleteDownload(res.id);
                  setState(() {});
                  widget.onUpdate();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (isDownloading) {
      final pct = task?.percentage ?? 0;
      return Card(
        color: tok.cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tok.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Downloading: ${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: tok.primary)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: tok.textSecondary),
                    onPressed: () {
                      widget.downloadManager.cancelDownload(res.id);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: tok.border,
                  valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (res.downloadable) {
      return Card(
        color: tok.cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tok.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.download_for_offline, color: tok.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Download for Offline Use',
                        style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary)),
                    Text(
                      res.fileSizeBytes != null
                          ? 'Permitted OER package • ${widget.downloadManager.formatBytes(res.fileSizeBytes!)}'
                          : 'Permitted OER package',
                      style: TextStyle(fontSize: 11, color: tok.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await widget.downloadManager.startDownload(res);
                    setState(() {});
                    widget.onUpdate();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: FilledButton.styleFrom(
                  backgroundColor: tok.primary,
                  foregroundColor: tok.buttonText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not downloadable (Rule #9 & #17)
    return Card(
      color: tok.warning.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tok.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: tok.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('available_online'), style: TextStyle(fontWeight: FontWeight.bold, color: tok.warning)),
                  const SizedBox(height: 2),
                  Text('This resource must be accessed from the original provider.',
                      style: TextStyle(fontSize: 11, color: tok.textSecondary)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _launchUrl(res.officialUrl),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tok.warning),
                foregroundColor: tok.warning,
              ),
              child: Text(tr('open_resource'), style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _openLessonReader(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterReaderScreen(
          resource: widget.resource,
          initialLessonIndex: index,
          repository: widget.repository,
          onProgressUpdate: () {
            setState(() {});
            widget.onUpdate();
          },
        ),
      ),
    ).then((_) {
      setState(() {});
      widget.onUpdate();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OFFLINE CHAPTER / LESSON READER SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ChapterReaderScreen extends StatefulWidget {
  final LearningResource resource;
  final int initialLessonIndex;
  final ContentRepository repository;
  final VoidCallback onProgressUpdate;

  const ChapterReaderScreen({
    super.key,
    required this.resource,
    this.initialLessonIndex = 0,
    required this.repository,
    required this.onProgressUpdate,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late int _currentIndex;
  late List<ChapterLesson> _lessons;
  double _fontSize = 15.0;

  @override
  void initState() {
    super.initState();
    _lessons = widget.resource.lessons;
    _currentIndex = _lessons.isEmpty ? 0 : widget.initialLessonIndex.clamp(0, _lessons.length - 1);
    _recordActivity();
  }

  Future<void> _recordActivity() async {
    if (_lessons.isEmpty) return;
    final cur = _lessons[_currentIndex];

    // User-scoped progress calculation via ProgressService
    final completedCount = _lessons.where((l) => UserScopedStore.done(l.id)).length;
    final progress = (completedCount / _lessons.length).clamp(0.0, 1.0);

    // Save to user-scoped recent chapters
    await widget.repository.recordChapterAccess(
      courseId: widget.resource.id,
      courseName: widget.resource.title,
      chapterId: cur.id,
      chapterName: cur.title,
      progress: progress,
      completed: completedCount == _lessons.length,
      provider: widget.resource.provider,
      lessonIndex: _currentIndex,
      totalLessons: _lessons.length,
    );

    widget.onProgressUpdate();
    if (mounted) setState(() {});
  }

  Future<void> _toggleDone() async {
    if (_lessons.isEmpty) return;
    final cur = _lessons[_currentIndex];
    final wasDone = UserScopedStore.done(cur.id);
    final tok = context.tokens;

    if (wasDone) {
      await ProgressService().markLessonIncomplete(
        courseId: widget.resource.id,
        lessonId: cur.id,
        allLessons: _lessons,
      );
    } else {
      await ProgressService().markLessonCompleted(
        courseId: widget.resource.id,
        lessonId: cur.id,
        courseTitle: widget.resource.title,
        lessonTitle: cur.title,
        allLessons: _lessons,
      );
    }

    final completedCount = _lessons.where((l) => UserScopedStore.done(l.id)).length;
    final progress = (completedCount / _lessons.length).clamp(0.0, 1.0);

    await widget.repository.recordChapterAccess(
      courseId: widget.resource.id,
      courseName: widget.resource.title,
      chapterId: cur.id,
      chapterName: cur.title,
      progress: progress,
      completed: completedCount == _lessons.length,
      provider: widget.resource.provider,
      lessonIndex: _currentIndex,
      totalLessons: _lessons.length,
    );

    widget.onProgressUpdate();
    if (mounted) {
      setState(() {});
      if (!wasDone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed "${cur.title}"!'),
            backgroundColor: tok.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _recordActivity();
  }

  void _askMentor(String lessonTitle) {
    final service = MentorService();
    service.saveProfile(service.profile.copyWith(
      currentSubject: MentorService.cleanSubject(widget.resource.title),
      currentTopic: lessonTitle,
    ));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MentorChatScreen(
          ai: InferenceController(),
          service: service,
          initialQuery:
              "Can you explain the main concepts of '$lessonTitle' from ${widget.resource.title} in simple words?",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;

    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.resource.title, style: TextStyle(color: tok.textPrimary))),
        body: Center(child: Text(tr('no_lessons_available'), style: TextStyle(color: tok.textSecondary))),
      );
    }

    final cur = _lessons[_currentIndex];
    final isDone = UserScopedStore.done(cur.id);

    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (_, currentLang, __) {
        final translation = TranslationService.getTranslation(
          lessonId: cur.id,
          languageCode: currentLang,
          originalTitle: cur.title,
          originalContent: cur.content,
        );

        final displayTitle = translation.title;
        final displayContent = translation.content;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: tok.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.resource.provider} • Chapter ${_currentIndex + 1} of ${_lessons.length}',
                  style: TextStyle(fontSize: 11, color: tok.textSecondary),
                ),
              ],
            ),
            actions: [
              // Language Switcher Toggle
              TextButton.icon(
                icon: Icon(Icons.translate, size: 16, color: tok.primary),
                label: Text(
                  currentLang == 'hi' ? 'हिंदी' : 'English',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: tok.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  final nextLang = currentLang == 'hi' ? 'en' : 'hi';
                  setLanguage(nextLang);
                },
              ),
              // Font size toggle
              IconButton(
                tooltip: 'Adjust text size',
                icon: Icon(Icons.format_size, size: 20, color: tok.textPrimary),
                onPressed: () {
                  setState(() {
                    if (_fontSize == 15.0) {
                      _fontSize = 17.5;
                    } else if (_fontSize == 17.5) {
                      _fontSize = 20.0;
                    } else {
                      _fontSize = 15.0;
                    }
                  });
                },
              ),
              // Ask Mentor quick button
              IconButton(
                tooltip: 'Ask Digital Mentor',
                icon: Icon(Icons.psychology, color: tok.primary),
                onPressed: () => _askMentor(displayTitle),
              ),
            ],
          ),
          body: Column(
            children: [
              // Reading progress bar
              LinearProgressIndicator(
                value: ((_currentIndex + 1) / _lessons.length).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: tok.border,
                valueColor: AlwaysStoppedAnimation<Color>(tok.primary),
              ),

              // Lesson Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter header card with status toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tok.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tok.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tok.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'CHAPTER ${_currentIndex + 1} OF ${_lessons.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tok.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (cur.durationMinutes != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.schedule, size: 14, color: tok.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cur.durationMinutes} min read',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: tok.textSecondary,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                FilledButton.tonalIcon(
                                  onPressed: _toggleDone,
                                  icon: Icon(
                                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: isDone ? tok.success : tok.textSecondary,
                                  ),
                                  label: Text(
                                    isDone ? tr('completed') : tr('mark_complete'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDone ? tok.success : tok.textPrimary,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDone
                                        ? tok.success.withValues(alpha: 0.15)
                                        : tok.chipBackground,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayTitle,
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: tok.textPrimary,
                              ),
                            ),
                            // Translation Source Attribution Badge
                            if (translation.languageCode == 'hi') ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tok.secondaryAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: tok.secondaryAccent.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 13, color: tok.secondaryAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      translation.translationSource == 'translated_for_gramvidya'
                                          ? 'Translated for GramVidya • Hindi'
                                          : 'Hindi Content (Official / Reviewed)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tok.secondaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ask Mentor Callout Banner
                      InkWell(
                        onTap: () => _askMentor(displayTitle),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: tok.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tok.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, color: tok.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentLang == 'hi'
                                      ? 'इस पाठ के बारे में संदेह है? अपने एआई डिजिटल मेंटर से मार्गदर्शन प्राप्त करें।'
                                      : 'Have doubts about this lesson? Ask your AI Digital Mentor for guidance.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tok.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 12, color: tok.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Rich Educational Content Body
                      _RichLessonReader(
                        content: displayContent,
                        fontSize: _fontSize,
                        tok: tok,
                      ),

                      // External Link if present
                      if (cur.officialUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.tryParse(cur.officialUrl!);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text('Open on ${widget.resource.provider}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tok.primary,
                              side: BorderSide(color: tok.primary),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom navigation bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tok.cardBackground,
                  border: Border(
                    top: BorderSide(color: tok.border),
                  ),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(tr('back')),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1} / ${_lessons.length}',
                      style: TextStyle(
                        color: tok.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _currentIndex < _lessons.length - 1
                          ? () => _goTo(_currentIndex + 1)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 ${widget.resource.title} ${tr("completed")}!'),
                                  backgroundColor: tok.success,
                                ),
                              );
                              Navigator.pop(context);
                            },
                      icon: Icon(
                        _currentIndex < _lessons.length - 1 ? Icons.arrow_forward : Icons.check,
                        size: 16,
                      ),
                      label: Text(_currentIndex < _lessons.length - 1 ? tr('next') : tr('done')),
                      style: FilledButton.styleFrom(
                        backgroundColor: tok.primary,
                        foregroundColor: tok.buttonText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Rich educational lesson renderer that structures markdown text,
/// code blocks, section titles, tables, bullet points, and exercises into clean widgets.
class _RichLessonReader extends StatelessWidget {
  final String content;
  final double fontSize;
  final SemanticThemeTokens tok;

  const _RichLessonReader({
    required this.content,
    required this.fontSize,
    required this.tok,
  });

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      // Empty line spacer
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        i++;
        continue;
      }

      // Code Block (``` ... ```)
      if (line.startsWith('```')) {
        final lang = line.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing ```
        widgets.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tok.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tok.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lang.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    lang.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: tok.secondaryAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  codeLines.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFFF4EFE6),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Blockquote (> ...)
      if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: tok.primary, width: 3)),
            color: tok.cardBackground,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: fontSize,
              color: tok.textSecondary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // Title (# Heading 1)
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontSize: fontSize + 6,
              fontWeight: FontWeight.bold,
              color: tok.primary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // Section (## Heading 2)
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: fontSize + 2,
                decoration: BoxDecoration(
                  color: tok.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.substring(3),
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: tok.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // Subsection (### Heading 3)
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            line.substring(4),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: tok.success,
            ),
          ),
        ));
        i++;
        continue;
      }

      // Markdown Table (| ... |)
      if (line.startsWith('|') && line.endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        widgets.add(_buildTable(tableLines));
        continue;
      }

      // Bullet List (- or • or *)
      if (line.startsWith('- ') || line.startsWith('• ') || line.startsWith('* ')) {
        final itemText = line.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 6, color: tok.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  itemText,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.55,
                    color: tok.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ));
        i++;
        continue;
      }

      // Callout box / Common Mistake / Example
      if (line.startsWith('❌') || line.startsWith('✅') || line.startsWith('⚠️')) {
        final isCheck = line.startsWith('✅');
        final calloutColor = isCheck ? tok.success : tok.error;
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: calloutColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: calloutColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            line,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: tok.textPrimary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // Standard text paragraph
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          line,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.65,
            color: tok.textPrimary,
          ),
        ),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTable(List<String> tableLines) {
    if (tableLines.length < 2) return const SizedBox();

    List<String> parseRow(String row) =>
        row.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final headerCols = parseRow(tableLines[0]);
    final dataRows = <List<String>>[];

    for (int k = 1; k < tableLines.length; k++) {
      final line = tableLines[k];
      if (line.contains('---')) continue; // divider row
      final cols = parseRow(line);
      if (cols.isNotEmpty) dataRows.add(cols);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: tok.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tok.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: tok.border),
        ),
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              color: tok.chipBackground,
            ),
            children: headerCols
                .map((h) => Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.bold,
                          color: tok.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Data Rows
          ...dataRows.map(
            (row) => TableRow(
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          cell,
                          style: TextStyle(
                            fontSize: fontSize - 1,
                            color: tok.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ──── Small Utility Badge ────
class _Badge extends StatelessWidget {
  final String label;
  final SemanticThemeTokens tok;

  const _Badge({required this.label, required this.tok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tok.chipBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tok.border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: tok.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}
