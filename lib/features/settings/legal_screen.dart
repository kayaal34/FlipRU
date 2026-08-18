import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Gizlilik politikası, kullanım şartları ve iletişim.
///
/// Metinler İngilizce: mağaza incelemeleri ve uluslararası kullanıcılar için
/// ortak dil. Arayüzün geri kalanı seçilen dile göre değişiyor, bu belgeler
/// sabit kalıyor.
enum LegalDocument {
  privacy('Privacy Policy'),
  terms('Terms of Service'),
  contact('Contact Us');

  const LegalDocument(this.title);

  final String title;
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final sections = switch (document) {
      LegalDocument.privacy => _privacy,
      LegalDocument.terms => _terms,
      LegalDocument.contact => _contact,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                if (document != LegalDocument.contact) ...[
                  Text(
                    'Last updated: 16 August 2026',
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                  const SizedBox(height: 18),
                ],
                for (final (heading, body) in sections) ...[
                  Text(heading, style: textTheme.titleLarge),
                  const SizedBox(height: 7),
                  Text(body, style: textTheme.bodyMedium),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<(String, String)> _contact = [
    (
      'Write to us',
      'Questions, suggestions and bug reports are welcome at:\n\n'
          'kodmod034@gmail.com\n\n'
          'We read every message, though a reply may take a few days.',
    ),
    (
      'Wrong word or translation?',
      'The fastest way to report a wrong translation or a strange example '
          'sentence is from inside the app: tap "There is a mistake in this '
          'word" under any card. Your reports collect in Settings › Account '
          'and data, and you can send them all at once with a single tap.',
    ),
    (
      'Feature requests',
      'Missing a study mode, a theme or a language pair? Tell us what you '
          'would use it for — that context is what actually shapes the '
          'roadmap.',
    ),
    (
      'Data requests',
      'FlipRU stores nothing on a server, so there is no account to export or '
          'delete. Everything lives on your device and can be erased from '
          'Settings › Account.',
    ),
  ];

  static const List<(String, String)> _privacy = [
    (
      'In short',
      'FlipRU does not ask you to create an account, does not track you, and '
          'never sends your learning data to any server. The app works fully '
          'offline.',
    ),
    (
      'What data is stored',
      'Only the learning data you create: which words you have learned, which '
          'ones you starred, your daily progress, your streak and your app '
          "preferences. All of it stays in your device's own storage.",
    ),
    (
      'Where the data goes',
      'Nowhere. This data never leaves your device. The only exception is when '
          'you deliberately tap "Send to us" to share your word error reports; '
          'in that case you choose which app to send them with.',
    ),
    (
      'Pronunciation',
      "Speech uses your device's own text-to-speech engine. The text being "
          'read is bundled with the app and the audio is produced on device.',
    ),
    (
      'Notifications',
      'If you enable the daily reminder, notifications are scheduled locally '
          'on your device. No server is involved.',
    ),
    (
      'Advertising and analytics',
      'The app contains no advertising networks, analytics or tracking tools.',
    ),
    (
      'Deleting your data',
      'You can reset your progress, stars and preferences at any time from '
          'Settings › Account. Uninstalling the app also erases all data.',
    ),
    (
      'Contact',
      'For questions or data requests, write to kodmod034@gmail.com.',
    ),
  ];

  static const List<(String, String)> _terms = [
    (
      'Scope',
      'FlipRU is a vocabulary app for people who want to expand their Russian '
          'vocabulary. It is provided for personal, non-commercial use.',
    ),
    (
      'About the dictionary content',
      'Word translations and example sentences are compiled automatically '
          'from open dictionaries and corpora (Wiktionary/WikDict, the '
          'Badestrand Russian dictionary, Tatoeba, TED2020, WikiMatrix and '
          'OpenSubtitles) and cross-checked against multiple sources. Errors '
          'are still possible; the content is not an official language '
          'teaching material.',
    ),
    (
      'Error reports',
      'You can report a translation you believe is wrong from inside the app. '
          'Reports are used to correct the content.',
    ),
    (
      'Limitation of liability',
      'The app is provided "as is". No liability is accepted for indirect '
          'damages such as lost time arising from possible errors in the '
          'content.',
    ),
    (
      'Intellectual property',
      'The interface and software belong to their developer. The dictionary '
          'and sentence corpora remain under their own open licences '
          '(CC BY-SA and similar).',
    ),
    (
      'Changes',
      'These terms may be updated from time to time. The current version is '
          'always available on this screen.',
    ),
  ];
}
