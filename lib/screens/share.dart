import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../p2p/share_service.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.ai});
  final InferenceController ai;

  @override
  State<ShareScreen> createState() => _ShareState();
}

class _ShareState extends State<ShareScreen> {
  final _s = ShareService();
  final _peers = <String, Peer>{};
  StreamSubscription? _sub;
  Peer? _sel;
  List<Map> _files = [];
  bool _hosting = false;
  bool _villageSync = false;
  String _status = 'Connect both devices to the same hotspot or Wi-Fi Direct group.';

  Future<void> _host() async {
    await _s.host(Platform.localHostname);
    final d = await _s.dir();
    setState(() {
      _hosting = true;
      _status = 'Sharing every file in:\n${d.path}';
    });
  }

  Future<void> _enableVillageSync() async {
    await _host();
    setState(() {
      _villageSync = true;
      _status = 'Village Sync Mode Active (Local Server Mode)';
    });
  }

  void _find() {
    _sub?.cancel();
    _sub = _s.discover().listen((p) => setState(() => _peers[p.ip] = p));
    setState(() => _status = 'Looking for nearby devices…');
  }

  Future<void> _open(Peer p) async {
    final f = await _s.manifest(p);
    setState(() {
      _sel = p;
      _files = f;
    });
  }

  Future<void> _get(String name) async {
    setState(() => _status = 'Downloading $name…');
    final f = await _s.download(_sel!, name);
    if (name.endsWith('.json')) widget.ai.rag.addJson(await f.readAsString());
    setState(() => _status = 'Saved $name');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _s.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
        title: Text(
          tr('offline_share_title'),
          style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tok.primary, tok.secondaryAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: tok.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tok.buttonText.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share_rounded, color: tok.buttonText, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('offline_peer_sharing'),
                          style: TextStyle(
                            color: tok.buttonText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('share_desc'),
                          style: TextStyle(
                            color: tok.buttonText.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tok.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tok.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: tok.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(color: tok.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hosting ? null : _host,
                    icon: Icon(Icons.wifi_tethering, color: tok.buttonText),
                    label: Text(_hosting ? 'Sharing Active' : tr('share_my_notes'), style: TextStyle(color: tok.buttonText)),
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
                    onPressed: _find,
                    icon: Icon(Icons.search, color: tok.primary),
                    label: Text(tr('receive_notes'), style: TextStyle(color: tok.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: tok.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _villageSync ? null : _enableVillageSync,
              icon: Icon(Icons.location_city, color: _villageSync ? tok.success : tok.primary),
              label: Text(
                _villageSync ? 'Village Sync Server Active' : 'Village Sync Mode (Server)',
                style: TextStyle(color: _villageSync ? tok.success : tok.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _villageSync ? tok.success : tok.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Peers List
            Text(
              '${tr('nearby_peers')} (${_peers.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
            ),
            const SizedBox(height: 12),

            if (_peers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tok.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tok.border),
                ),
                child: Center(
                  child: Text(
                    'No nearby peers found yet. Tap "Receive Notes" to scan.',
                    style: TextStyle(color: tok.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._peers.values.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: tok.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: tok.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tok.accent.withValues(alpha: 0.15),
                      child: Icon(Icons.devices, color: tok.accent),
                    ),
                    title: Text(p.name, style: TextStyle(color: tok.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(p.ip, style: TextStyle(color: tok.textSecondary, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: tok.textSecondary),
                    onTap: () => _open(p),
                  ),
                ),
              ),

            if (_sel != null) ...[
              const SizedBox(height: 24),
              Text(
                'Available Files from ${_sel!.name}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tok.textPrimary),
              ),
              const SizedBox(height: 12),
              ..._files.map(
                (f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: tok.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: tok.border),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.insert_drive_file, color: tok.accent),
                    title: Text(f['name'], style: TextStyle(color: tok.textPrimary)),
                    subtitle: Text('${(f['size'] / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: tok.textSecondary)),
                    trailing: IconButton(
                      icon: Icon(Icons.download, color: tok.accent),
                      onPressed: () => _get(f['name']),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
