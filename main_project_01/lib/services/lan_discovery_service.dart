
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

class LanPeer {
  final int userId;
  final String host;
  final int port;
  final String name;

  const LanPeer({
    required this.userId,
    required this.host,
    required this.port,
    required this.name,
  });
}

class LanDiscoveryService {
  static const String serviceType = '_hybridchat._tcp';

  Registration? _registration;
  Discovery? _discovery;

  final Map<int, LanPeer> _peers = {};

  Map<int, LanPeer> get peers =>
      Map<int, LanPeer>.unmodifiable(_peers);

  VoidCallback? onPeersChanged;

  Future<void> start({int? userId}) async {
    if (_discovery != null || _registration != null) {
      return;
    }

    try {
      _discovery = await startDiscovery(
        serviceType,
        ipLookupType: IpLookupType.any,
      );

      _discovery!.addServiceListener((service, status) {
        final name = service.name;

        if (name == null) return;

        // Only recognize services that advertise a user ID.
        final match = RegExp(
          r'^hybridchat-user-(\d+)$',
        ).firstMatch(name);

        if (match == null) return;

        final discoveredUserId =
        int.tryParse(match.group(1)!);

        if (discoveredUserId == null) return;

        if (status == ServiceStatus.found) {
          final host = service.host;
          final port = service.port;

          if (host == null || port == null) return;

          // Ignore our own advertised identity.
          if (userId != null &&
              discoveredUserId == userId) {
            return;
          }

          _peers[discoveredUserId] = LanPeer(
            userId: discoveredUserId,
            host: host,
            port: port,
            name: name,
          );

          debugPrint(
            'LAN peer found: user=$discoveredUserId '
                'host=$host port=$port',
          );

          onPeersChanged?.call();
        } else if (status == ServiceStatus.lost) {
          if (_peers.remove(discoveredUserId) != null) {
            debugPrint(
              'LAN peer lost: user=$discoveredUserId',
            );
            onPeersChanged?.call();
          }
        }
      });

      final serviceName = userId == null
          ? 'hybridchat-user-0'
          : 'hybridchat-user-$userId';

      _registration = await register(
        Service(
          name: serviceName,
          type: serviceType,
          port: 4040,
        ),
      );

      debugPrint('LAN discovery started');
      debugPrint('LAN service registered: $serviceName');
    } catch (e) {
      debugPrint('LAN discovery error: $e');
    }
  }

  Future<void> stop() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }

    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }

    _peers.clear();
    onPeersChanged?.call();

    debugPrint('LAN discovery stopped');
  }
}
