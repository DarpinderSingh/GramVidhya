import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
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
    // Village sync logic here
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GramVidya Share', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub, size: 40, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nearby Sharing Dashboard", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Share courses, models, and notes without internet.", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: _villageSync ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _villageSync ? Colors.greenAccent : Colors.transparent)),
            child: SwitchListTile(
              title: const Text('Village Sync Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Become a local server for students to connect.'),
              value: _villageSync,
              onChanged: (val) {
                if (val) {
                  _enableVillageSync();
                } else {
                  setState(() {
                    _villageSync = false;
                    _hosting = false;
                    _status = 'Disconnected from Village Sync.';
                    _s.stop();
                  });
                }
              },
              activeColor: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text("Status", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Text(_status, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _hosting ? null : _host,
                  icon: const Icon(Icons.upload),
                  label: const Text('Share Files'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _find,
                  icon: const Icon(Icons.radar),
                  label: const Text('Find Nearby'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_peers.isNotEmpty) ...[
            Text("Nearby Devices", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._peers.values.map((p) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF38BDF8), child: Icon(Icons.devices, color: Colors.white)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.ip),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(p),
              ),
            )),
          ],
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text("Available Files", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._files.map((f) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(f['name']),
                subtitle: Text('${((f['size'] as int) / 1e6).toStringAsFixed(1)} MB'),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF38BDF8)),
                  onPressed: () => _get(f['name']),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
