import 'dart:convert';
import 'package:http/http.dart' as http;
import 'course_provider.dart';

/// DIKSHA (National Digital Infrastructure for Teachers) content provider.
///
/// Uses the Sunbird Composite Search API:
///   POST https://diksha.gov.in/api/content/v1/search
///   GET  https://diksha.gov.in/api/collection/v1/hierarchy/{id}
///
/// Security: No private API key. DIKSHA public content search is open.
/// All failures are silently caught so the app stays fully offline-first.
class DikshaContentProvider implements EducationalContentProvider {
  static const _baseUrl = 'https://diksha.gov.in';
  static const _searchPath = '/api/content/v1/search';
  static const _hierarchyPath = '/api/collection/v1/hierarchy/';

  final http.Client _client;
  DikshaContentProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<bool> isAvailable() async {
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl/home'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Course>> fetchCourses() async {
    try {
      final body = jsonEncode({
        'request': {
          'query': '',
          'filters': {
            'contentType': ['Course'],
            'status': ['Live'],
            'medium': ['Hindi', 'English'],
          },
          'limit': 20,
          'fields': [
            'identifier', 'name', 'description', 'subject',
            'medium', 'gradeLevel', 'thumbnail', 'leafNodesCount',
          ],
        }
      });

      final resp = await _client
          .post(
            Uri.parse('$_baseUrl$_searchPath'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = (data['result']?['content']) as List?;
      if (content == null) return [];
      return content
          .map((c) => _mapToCourse(c as Map<String, dynamic>))
          .whereType<Course>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Course?> fetchCourse(String id) async {
    // id format: "diksha_<sourceId>"
    final sourceId = id.startsWith('diksha_') ? id.substring(7) : id;
    try {
      final resp = await _client
          .get(Uri.parse('$_baseUrl$_hierarchyPath$sourceId'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = data['result']?['content'] as Map<String, dynamic>?;
      if (content == null) return null;
      return _mapFullCourse(content);
    } catch (_) {
      return null;
    }
  }

  Course? _mapToCourse(Map<String, dynamic> c) {
    final rawId = c['identifier'] as String?;
    final name = c['name'] as String?;
    if (rawId == null || name == null) return null;
    final subjects = (c['subject'] as List?)?.cast<String>() ?? [];
    final medium = (c['medium'] as List?)?.cast<String>() ?? [];
    final grades = (c['gradeLevel'] as List?)?.cast<String>() ?? [];
    final parts = <String>[
      if (subjects.isNotEmpty) 'Subject: ${subjects.join(', ')}',
      if (grades.isNotEmpty) 'Level: ${grades.join(', ')}',
      if (medium.isNotEmpty) 'Medium: ${medium.join(', ')}',
    ];
    final descExtra = c['description'] as String?;
    final desc = parts.isNotEmpty
        ? parts.join(' · ') + (descExtra != null ? '\n$descExtra' : '')
        : (descExtra ?? 'DIKSHA course');
    return Course(
      id: 'diksha_$rawId',
      title: name,
      description: desc,
      icon: _iconForSubject(subjects.isNotEmpty ? subjects.first : ''),
      lessons: const [],
      provider: 'DIKSHA',
      version: 1,
      sourceId: rawId,
      thumbnailUrl: c['thumbnail'] as String?,
      leafCount: c['leafNodesCount'] as int?,
    );
  }

  Course? _mapFullCourse(Map<String, dynamic> c) {
    final rawId = c['identifier'] as String?;
    final name = c['name'] as String?;
    if (rawId == null || name == null) return null;
    final lessons = <Lesson>[];
    _extractLessons((c['children'] as List?) ?? [], lessons);
    final subjects = (c['subject'] as List?)?.cast<String>() ?? [];
    return Course(
      id: 'diksha_$rawId',
      title: name,
      description: c['description'] as String? ?? 'DIKSHA course',
      icon: _iconForSubject(subjects.isNotEmpty ? subjects.first : ''),
      lessons: lessons,
      provider: 'DIKSHA',
      version: 1,
      sourceId: rawId,
    );
  }

  void _extractLessons(List items, List<Lesson> out) {
    for (final item in items) {
      final m = item as Map<String, dynamic>;
      final contentType = m['contentType'] as String? ?? '';
      final mime = m['mimeType'] as String? ?? '';
      final name = m['name'] as String? ?? 'Untitled';
      final rawId = m['identifier'] as String? ?? name.hashCode.toString();
      if (contentType == 'Resource' || mime.contains('video') || mime.contains('pdf')) {
        out.add(Lesson(
          id: rawId,
          title: name,
          content: m['description'] as String? ??
              'This lesson is part of a DIKSHA course.\n\nOpen the source URL below to view the full content online.',
          videoUrl: m['streamingUrl'] as String? ?? m['artifactUrl'] as String?,
          durationMinutes: _secs(m['duration']),
          sourceUrl: 'https://diksha.gov.in/play/content/$rawId',
        ));
      } else if (m['children'] != null) {
        _extractLessons(m['children'] as List, out);
      }
    }
  }

  String _iconForSubject(String s) {
    final l = s.toLowerCase();
    if (l.contains('math')) return 'calculate';
    if (l.contains('science') || l.contains('physics') || l.contains('chemistry')) return 'science';
    if (l.contains('bio')) return 'eco';
    if (l.contains('english') || l.contains('language')) return 'translate';
    if (l.contains('history') || l.contains('social')) return 'account_balance';
    if (l.contains('computer') || l.contains('digital')) return 'computer';
    if (l.contains('agri')) return 'agriculture';
    if (l.contains('art') || l.contains('music')) return 'palette';
    return 'menu_book';
  }

  int? _secs(dynamic raw) {
    if (raw == null) return null;
    final n = raw is int ? raw : int.tryParse(raw.toString());
    if (n == null) return null;
    return (n / 60).round();
  }
}
