// Yalnizca ikon setlerini karsilastirmak icin gecici bir giris noktasi.
//
// Uygulamaya dahil degil; `flutter run -t lib/main_icon_preview.dart` ile
// acilip karar verildikten sonra silinecek.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() => runApp(const IconPreviewApp());

const _canvas = Color(0xFFF4F4F7);
const _surface = Color(0xFFFFFFFF);
const _separator = Color(0xFFE4E4EB);
const _textPrimary = Color(0xFF0B0B0F);
const _textTertiary = Color(0xFF6F6F7B);
const _accent = Color(0xFF5E5CE6);
const _accentSoft = Color(0xFFEDEDFE);
const _learned = Color(0xFF16A34A);
const _review = Color(0xFFE5342A);
const _star = Color(0xFFEFA818);

/// Uygulamada gercekten kullanilan ikonlar; her set icin ayni sirayla.
const _labels = [
  'Ana ekran',
  'Pratik',
  'Ayarlar',
  'Seri',
  'Yildiz',
  'Ogrenildi',
  'Yazma',
  'Ceviri',
  'Ses',
  'Istatistik',
  'Alfabe',
  'Joker',
];

const _tints = [
  _accent,
  _accent,
  _accent,
  _star,
  _star,
  _learned,
  _star,
  _review,
  _accent,
  _accent,
  _accent,
  _star,
];

const _material = [
  Icons.home_rounded,
  Icons.school_rounded,
  Icons.settings_rounded,
  Icons.local_fire_department_rounded,
  Icons.star_rounded,
  Icons.check_circle_rounded,
  Icons.keyboard_rounded,
  Icons.translate_rounded,
  Icons.volume_up_rounded,
  Icons.insights_rounded,
  Icons.abc_rounded,
  Icons.lightbulb_rounded,
];

const _phosphorRegular = [
  PhosphorIconsRegular.house,
  PhosphorIconsRegular.graduationCap,
  PhosphorIconsRegular.gearSix,
  PhosphorIconsRegular.fire,
  PhosphorIconsRegular.star,
  PhosphorIconsRegular.checkCircle,
  PhosphorIconsRegular.keyboard,
  PhosphorIconsRegular.translate,
  PhosphorIconsRegular.speakerHigh,
  PhosphorIconsRegular.chartBar,
  PhosphorIconsRegular.textAa,
  PhosphorIconsRegular.lightbulb,
];

const _phosphorDuotone = [
  PhosphorIconsDuotone.house,
  PhosphorIconsDuotone.graduationCap,
  PhosphorIconsDuotone.gearSix,
  PhosphorIconsDuotone.fire,
  PhosphorIconsDuotone.star,
  PhosphorIconsDuotone.checkCircle,
  PhosphorIconsDuotone.keyboard,
  PhosphorIconsDuotone.translate,
  PhosphorIconsDuotone.speakerHigh,
  PhosphorIconsDuotone.chartBar,
  PhosphorIconsDuotone.textAa,
  PhosphorIconsDuotone.lightbulb,
];

const _phosphorFill = [
  PhosphorIconsFill.house,
  PhosphorIconsFill.graduationCap,
  PhosphorIconsFill.gearSix,
  PhosphorIconsFill.fire,
  PhosphorIconsFill.star,
  PhosphorIconsFill.checkCircle,
  PhosphorIconsFill.keyboard,
  PhosphorIconsFill.translate,
  PhosphorIconsFill.speakerHigh,
  PhosphorIconsFill.chartBar,
  PhosphorIconsFill.textAa,
  PhosphorIconsFill.lightbulb,
];

const _lucide = [
  LucideIcons.home,
  LucideIcons.graduationCap,
  LucideIcons.settings,
  LucideIcons.flame,
  LucideIcons.star,
  LucideIcons.checkCircle,
  LucideIcons.keyboard,
  LucideIcons.languages,
  LucideIcons.volume2,
  LucideIcons.barChart2,
  LucideIcons.type,
  LucideIcons.lightbulb,
];

class IconPreviewApp extends StatelessWidget {
  const IconPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        fontFamily: 'Manrope',
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _canvas,
          title: const Text(
            'Ikon setleri',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: const [
            _SetBlock(
              name: '1 — Material Rounded',
              note: 'Su anki set. Dolgun, yuvarlak, tanidik.',
              icons: _material,
            ),
            _SetBlock(
              name: '2 — Phosphor Regular',
              note: 'Ince cizgi, esit kalinlik. Sakin ve pahali durur.',
              icons: _phosphorRegular,
            ),
            _SetBlock(
              name: '3 — Phosphor Duotone',
              note: 'Cizgi + soluk dolgu. Renk kullanan ekranlarda zengin.',
              icons: _phosphorDuotone,
            ),
            _SetBlock(
              name: '4 — Phosphor Fill',
              note: 'Tamamen dolu. Material setine yakin ama daha yumusak.',
              icons: _phosphorFill,
            ),
            _SetBlock(
              name: '5 — Lucide',
              note: 'Feather mirasi, 2px cizgi. En minimal olani.',
              icons: _lucide,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir setin hem kutucuk hem de alt menu gorunumu.
///
/// Ikonlari cizelgede yan yana gormek yetmiyor: karar, kartin icinde ve alt
/// menude nasil durduguna gore veriliyor.
class _SetBlock extends StatelessWidget {
  const _SetBlock({
    required this.name,
    required this.note,
    required this.icons,
  });

  final String name;
  final String note;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: const TextStyle(color: _textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _separator),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < icons.length; i++)
                      SizedBox(
                        width: 62,
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tints[i].withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              // PhosphorIcon her IconData ile calisiyor; yalnizca duotone
// veride ikinci katmani da ciziyor. Duz Icon kullaninca 3.
// set 2. setin aynisi gibi gorunuyordu.
child: PhosphorIcon(icons[i], color: _tints[i], size: 22),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textTertiary,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: _separator, height: 1),
                const SizedBox(height: 12),
                // Alt menu provasi: secili sekme hapin icinde.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0 ? _accentSoft : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PhosphorIcon(
                              icons[i],
                              size: 26,
                              color: i == 0 ? _accent : _textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: i == 0 ? _accent : _textTertiary,
                              fontWeight: i == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
