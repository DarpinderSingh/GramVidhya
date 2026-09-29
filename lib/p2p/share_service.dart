import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class Peer {
  Peer(this.name, this.ip, this.port);
  final String name, ip;
  final int port;
}

/// Serverless sharing on any shared network: a phone hotspot, Wi-Fi Direct group, or LAN.
/// UDP broadcast for discovery, plain HTTP for transfer. No internet involved.
class ShareService {
  static const discoveryPort = 45454, httpPort = 45455;
  HttpServer? _srv;
  Timer? _beacon;
  RawDatagramSocket? _tx, _rx;

  Future<Directory> dir() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/share').create(recursive: true);

  Future<void> host(String deviceName) async {
    final d = await dir();
    _srv = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);
    _srv!.listen((req) async {
      final p = req.uri.path;
      if (p == '/manifest') {
        final files = d.listSync().whereType<File>().map((f) => {'name': f.uri.pathSegments.last, 'size': f.lengthSync()}).toList();
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(files));
      } else if (p.startsWith('/f/')) {
        final f = File('${d.path}/${Uri.decodeComponent(p.substring(3))}');
        if (f.parent.path == d.path && await f.exists()) {
          await req.response.addStream(f.openRead());
        } else {
          req.response.statusCode = 404;
        }
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
    _tx = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..broadcastEnabled = true;
    _beacon = Timer.periodic(const Duration(seconds: 2), (_) {
      _tx!.send(utf8.encode(jsonEncode({'app': 'gramvidya', 'name': deviceName, 'port': httpPort})),
          InternetAddress('255.255.255.255'), discoveryPort);
    });
  }

  Stream<Peer> discover() async* {
    _rx = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort, reuseAddress: true);
    await for (final e in _rx!) {
      if (e != RawSocketEvent.read) continue;
      final d = _rx!.receive();
      if (d == null) continue;
      try {
        final j = jsonDecode(utf8.decode(d.data));
        if (j['app'] == 'gramvidya') yield Peer(j['name'], d.address.address, j['port']);
      } catch (_) {}
    }
  }

  Future<List<Map>> manifest(Peer p) async =>
      (jsonDecode((await http.get(Uri.parse('http://${p.ip}:${p.port}/manifest'))).body) as List).cast<Map>();

  Future<File> download(Peer p, String name) async {
    final res = await http.Client().send(http.Request('GET', Uri.parse('http://${p.ip}:${p.port}/f/${Uri.encodeComponent(name)}')));
    final f = File('${(await dir()).path}/$name');
    await res.stream.pipe(f.openWrite());
    return f;
  }

  void stop() {
    _beacon?.cancel();
    _srv?.close();
    _tx?.close();
    _rx?.close();
  }
}
