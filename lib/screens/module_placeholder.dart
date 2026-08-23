import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import '../widgets/clay.dart';
import '../widgets/decor.dart';

/// Kerangka layar modul bergaya clay. Tiap modul tinggal mengganti isi
/// dengan pemanggilan API (ApiClient.dio.get/post) sesuai [endpointHint].
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
      body: ClayBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // Bar atas clay (tombol kembali + judul + ikon modul).
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(
                  children: [
                    ClayTappable(
                      onTap: () => Navigator.of(context).maybePop(),
                      radius: 100,
                      padding: const EdgeInsets.all(13),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: MoodaTheme.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: MoodaTheme.ink,
                        ),
                      ),
                    ),
                    ClayIconBadge(icon: icon, color: color, size: 44),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/svg/illus-empty.svg', height: 150),
                        const SizedBox(height: 22),
                        ClayBox(
                          radius: MoodaTheme.radiusLg,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 22),
                          child: Column(
                            children: [
                              Text(
                                'Modul $title',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: MoodaTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Siap dihubungkan ke API.',
                                style: TextStyle(color: MoodaTheme.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: MoodaTheme.ink,
                                  borderRadius:
                                      BorderRadius.circular(MoodaTheme.radiusSm),
                                ),
                                child: Text(
                                  endpointHint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF9EC1FF),
                                    fontFamily: 'monospace',
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
