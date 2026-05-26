import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../bloc/onboarding/onboarding_bloc.dart';
import '../../../bloc/settings/settings_bloc.dart';
import '../../../core/route/routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _controller;

  static const _ageGroups = ['18-24', '25-34', '35-44', '45+'];
  static const _cycleLengths = [
    '21-25 days',
    '26-28 days',
    '29-32 days',
    '33+ days',
  ];
  static const _symptoms = [
    'Cramps',
    'Headache',
    'Mood swings',
    'Fatigue',
    'Bloating',
    'Acne',
  ];
  static const _goals = [
    'Track period',
    'Predict ovulation',
    'Monitor symptoms',
    'Plan pregnancy',
  ];
  static const _pregnancyStatuses = [
    'Not pregnant',
    'Trying to conceive',
    'Pregnant',
    'Postpartum',
  ];

  @override
  void initState() {
    super.initState();
    final cubit = context.read<OnboardingBloc>()..add(const LoadOnboarding());
    _controller = PageController(initialPage: cubit.state.currentStep);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int currentStep) {
    final cubit = context.read<OnboardingBloc>();
    if (currentStep < OnboardingBloc.totalSteps - 1) {
      final next = currentStep + 1;
      cubit.add(GoToOnboardingStep(step: next));
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      cubit.add(const SubmitOnboarding());
    }
  }

  void _back(int currentStep) {
    if (currentStep == 0) return;
    final prev = currentStep - 1;
    context.read<OnboardingBloc>().add(GoToOnboardingStep(step: prev));
    _controller.animateToPage(
      prev,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) =>
          prev.isComplete != curr.isComplete && curr.isComplete,
      listener: (context, state) {
        context.read<SettingsBloc>().add(const MarkOnboardingComplete());
        context.goNamed(dashboardRoute);
      },
      builder: (context, state) {
        // keep PageController in sync with restored currentStep on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_controller.hasClients) return;
          final page = _controller.page?.round() ?? 0;
          if (page != state.currentStep) {
            _controller.jumpToPage(state.currentStep);
          }
        });

        final canAdvance = state.draft.isStepValid(state.currentStep);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Step ${state.currentStep + 1} of ${OnboardingBloc.totalSteps}',
            ),
            leading: state.currentStep == 0
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _back(state.currentStep),
                  ),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: (state.currentStep + 1) / OnboardingBloc.totalSteps,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SingleSelectStep(
                      title: 'What is your age group?',
                      options: _ageGroups,
                      selected: state.draft.ageGroup,
                      onSelect: (v) => context
                          .read<OnboardingBloc>()
                          .add(UpdateOnboardingAnswers(
                            draft: state.draft.copyWith(ageGroup: v),
                          )),
                    ),
                    _SingleSelectStep(
                      title: 'How long is your typical cycle?',
                      options: _cycleLengths,
                      selected: state.draft.cycleLength,
                      onSelect: (v) => context
                          .read<OnboardingBloc>()
                          .add(UpdateOnboardingAnswers(
                            draft: state.draft.copyWith(cycleLength: v),
                          )),
                    ),
                    _MultiSelectStep(
                      title: 'Which symptoms do you usually experience?',
                      subtitle: 'Pick one or more',
                      options: _symptoms,
                      selected: state.draft.symptoms,
                      onChange: (v) => context
                          .read<OnboardingBloc>()
                          .add(UpdateOnboardingAnswers(
                            draft: state.draft.copyWith(symptoms: v),
                          )),
                    ),
                    _MultiSelectStep(
                      title: 'What do you want to track?',
                      subtitle: 'Pick one or more',
                      options: _goals,
                      selected: state.draft.goals,
                      onChange: (v) => context
                          .read<OnboardingBloc>()
                          .add(UpdateOnboardingAnswers(
                            draft: state.draft.copyWith(goals: v),
                          )),
                    ),
                    _SingleSelectStep(
                      title: 'Pregnancy status',
                      options: _pregnancyStatuses,
                      selected: state.draft.pregnancyStatus,
                      onSelect: (v) => context
                          .read<OnboardingBloc>()
                          .add(UpdateOnboardingAnswers(
                            draft:
                                state.draft.copyWith(pregnancyStatus: v),
                          )),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed:
                        canAdvance ? () => _next(state.currentStep) : null,
                    child: Text(
                      state.currentStep == OnboardingBloc.totalSteps - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SingleSelectStep extends StatelessWidget {
  const _SingleSelectStep({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final opt = options[i];
                final isSelected = opt == selected;
                return _SelectableTile(
                  label: opt,
                  selected: isSelected,
                  onTap: () => onSelect(opt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectStep extends StatelessWidget {
  const _MultiSelectStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onChange,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final isSelected = selected.contains(opt);
                  return FilterChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (_) {
                      final next = List<String>.from(selected);
                      if (isSelected) {
                        next.remove(opt);
                      } else {
                        next.add(opt);
                      }
                      onChange(next);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (selected) Icon(Icons.check, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
