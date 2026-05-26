import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/settings/settings_bloc.dart';
import '../../../core/route/routes.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Terms')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'This app stores your data locally on your device first. '
                    'Nothing leaves your phone unless you explicitly enable '
                    'Google Drive backup from the Profile tab.\n\n'
                    'By tapping Continue you confirm you understand:\n\n'
                    '  • All data is stored on this device by default.\n'
                    '  • Optional Drive backup uses your Google account '
                    '    and a hidden Drive folder only this app can read.\n'
                    '  • You can disable backup or delete it at any time '
                    '    from Settings.\n\n'
                    'We never send your data to any third party.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text('I agree to the terms above'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: !_accepted
                    ? null
                    : () {
                        context
                            .read<SettingsBloc>()
                            .add(const AcceptTerms());
                        context.goNamed(onboardingRoute);
                      },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
