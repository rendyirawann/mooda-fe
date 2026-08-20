import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Kerangka layar modul. Tiap modul tinggal mengganti [body] dengan
/// pemanggilan API (ApiClient.dio.get/post) sesuai [endpointHint].
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.endpointHint,
    required this.color,
    required this.icon,
  });

  final String title;
  final String endpointHint;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: MoodaTheme.ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Layar modul siap dihubungkan ke API.',
                style: TextStyle(color: MoodaTheme.muted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  endpointHint,
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
