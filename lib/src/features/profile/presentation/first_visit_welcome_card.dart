import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../branding/presentation/brand_config_provider.dart';
import '../data/profile_storage_service.dart';
import '../domain/member_profile.dart';

/// Calm, skippable prompt for a custom display name after sign-in (#663).
class FirstVisitWelcomeCard extends HookConsumerWidget {
  const FirstVisitWelcomeCard({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);
    final nameController = useTextEditingController();
    final churchController = useTextEditingController();
    final validationError = useState<String?>(null);
    final busy = useState(false);

    final affiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

    Future<void> finishSkip() async {
      if (busy.value) return;
      busy.value = true;
      ProfileStorageService.instance.markFirstVisitSkipped();
      onFinished();
    }

    Future<void> finishSave() async {
      if (busy.value) return;
      final name = nameController.text.trim();
      if (name.isEmpty) {
        validationError.value = 'Add a first name or display name, or tap Skip for now.';
        return;
      }
      final affiliation = churchController.text.trim();
      if (brand.enableFellowshipAffiliationField && affiliation.isEmpty) {
        validationError.value =
            'Please select which ICOC church you attend, or choose "${brand.fellowshipNonMemberOption}".';
        return;
      }
      busy.value = true;
      ref
          .read(memberProfileProvider.notifier)
          .saveCommunityName(
            displayName: name,
            icocChurchAffiliation: affiliation.isEmpty ? null : affiliation,
          );
      onFinished();
    }

    return Scaffold(
      key: const Key('first_visit_welcome_screen'),
      appBar: AppBar(title: const Text('Welcome'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How should we greet you in Start Here and the member directory?',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optional congregation helps fellowship hosts welcome visitors. You can change this anytime in your profile.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (validationError.value != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      validationError.value!,
                      key: const Key('first_visit_validation_error'),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('first_visit_display_name_field'),
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name / first name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (brand.enableFellowshipAffiliationField) ...[
                    const SizedBox(height: 16),
                    Text(
                      brand.fellowshipAffiliationPrompt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('first_visit_church_affiliation_field'),
                      controller: churchController,
                      readOnly: true,
                      onTap: () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: affiliationOptions
                                  .map(
                                    (opt) => ListTile(
                                      title: Text(opt, style: const TextStyle(fontSize: 14)),
                                      onTap: () => Navigator.pop(ctx, opt),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                        if (selected != null) {
                          churchController.text = selected;
                          validationError.value = null;
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: 'Tap to choose congregation (optional on Skip)',
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('first_visit_save_button'),
                    onPressed: busy.value ? null : finishSave,
                    child: const Text('Save & Enter Belong'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('first_visit_skip_button'),
                    onPressed: busy.value ? null : finishSkip,
                    child: const Text('Skip for now'),
                  ),
                  if (profile.email.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Signed in as ${profile.email}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
