import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  Widget _bg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7F6FF),
            Color(0xFFF2E9FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2F6BFF), Color(0xFFB14DFF)]),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 10),
        const Text('yashraj', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = const [
      ('English', 'English'),
      ('Bahasa Indonesia', 'Indonesian'),
      ('हिन्दी', 'Hindi'),
      ('తెలుగు', 'Telugu'),
      ('தமிழ்', 'Tamil'),
      ('മലയാളം', 'Malayalam'),
      ('ಕನ್ನಡ', 'Kannada'),
      ('বাংলা', 'Bangla'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          _bg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _logo(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: languages.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final title = languages[i].$1;
                          final subtitle = languages[i].$2;
                          final selected = _selected == title;
                          return ListTile(
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(subtitle),
                            trailing: selected
                                ? Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2F6BFF), Color(0xFFB14DFF)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.check, size: 18, color: Colors.white),
                                  )
                                : null,
                            onTap: () => setState(() => _selected = title),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Color(0xFF2F6BFF)),
                      ),
                      onPressed: () => context.go(RouteNames.permissions),
                      child: const Text('Continue', style: TextStyle(letterSpacing: 1.2, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
