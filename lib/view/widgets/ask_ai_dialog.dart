import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../core/theme/app_theme.dart';

/// Compact bottom-right popup. Two stages:
///   1) chip picker  → pick focus topics + Generate
///   2) live stream  → AI response builds in-place, token-by-token
///
/// Insights strip is untouched. No persistence.
class AskAIDialog extends StatefulWidget {
  const AskAIDialog({super.key});

  @override
  State<AskAIDialog> createState() => _AskAIDialogState();
}

class _AskAIDialogState extends State<AskAIDialog> {
  static const List<_FocusOption> _options = [
    _FocusOption('Cycle', 'cycle', Icons.calendar_month_outlined),
    _FocusOption('PMS', 'pms_forecast', Icons.event_note_outlined),
    _FocusOption('Sleep', 'sleep', Icons.bedtime_outlined),
    _FocusOption('Hydration', 'water', Icons.water_drop_outlined),
    _FocusOption('Symptoms', 'symptoms', Icons.healing_outlined),
    _FocusOption('Mood', 'mood_trend', Icons.sentiment_satisfied_outlined),
    _FocusOption('Recovery', 'recovery', Icons.spa_outlined),
    _FocusOption('Overall', 'wellness_summary', Icons.insights_outlined),
  ];

  final Set<String> _selected = <String>{};

  // Stage 2 state
  StreamSubscription<String>? _sub;
  bool _streaming = false;
  String _buffer = '';
  String? _error;
  bool _hasFirstToken = false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toggle(String v) {
    setState(() {
      if (_selected.contains(v)) {
        _selected.remove(v);
      } else {
        _selected.add(v);
      }
    });
  }

  void _generate() {
    if (_selected.isEmpty || _streaming) return;
    setState(() {
      _streaming = true;
      _buffer = '';
      _error = null;
      _hasFirstToken = false;
    });
    final bloc = context.read<RecommendationBloc>();
    _sub?.cancel();
    _sub = bloc.streamFocusedInsight(_selected.toList()).listen(
      (chunk) {
        if (!mounted) return;
        setState(() {
          _buffer += chunk;
          _hasFirstToken = true;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _streaming = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _streaming = false);
      },
    );
  }

  void _resetToPicker() {
    _sub?.cancel();
    setState(() {
      _streaming = false;
      _buffer = '';
      _error = null;
      _hasFirstToken = false;
    });
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showingResponse =
        _streaming || _buffer.isNotEmpty || _error != null;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      color: scheme.surface,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 460),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: showingResponse
                    ? _ResponseView(
                        buffer: _buffer,
                        error: _error,
                        streaming: _streaming,
                        hasFirstToken: _hasFirstToken,
                        onReset: _resetToPicker,
                      )
                    : _PickerView(
                        options: _options,
                        selected: _selected,
                        onToggle: _toggle,
                        onGenerate: _generate,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.pink.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, color: AppTheme.pink, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask AI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Pick what you want guidance on',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _PickerView extends StatelessWidget {
  const _PickerView({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onGenerate,
  });

  final List<_FocusOption> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((opt) {
              final sel = selected.contains(opt.value);
              return FilterChip(
                label: Text(opt.label),
                avatar: Icon(
                  opt.icon,
                  size: 14,
                  color: sel
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                selected: sel,
                onSelected: (_) => onToggle(opt.value),
                showCheckmark: false,
                selectedColor: scheme.primaryContainer,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.pink,
            ),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate'),
            onPressed: selected.isEmpty ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _ResponseView extends StatelessWidget {
  const _ResponseView({
    required this.buffer,
    required this.error,
    required this.streaming,
    required this.hasFirstToken,
    required this.onReset,
  });

  final String buffer;
  final String? error;
  final bool streaming;
  final bool hasFirstToken;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (!hasFirstToken && streaming)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thinking…',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _StreamingText(
                  text: buffer,
                  showCursor: streaming,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Ask another'),
                onPressed: streaming ? null : onReset,
              ),
              const Spacer(),
              if (streaming)
                Text(
                  'streaming…',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Text that appends a blinking-cursor placeholder while streaming.
class _StreamingText extends StatelessWidget {
  const _StreamingText({required this.text, required this.showCursor});

  final String text;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.4,
        );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text, style: style),
          if (showCursor)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _BlinkingDot(),
            ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Container(
          width: 7,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.pink,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _FocusOption {
  const _FocusOption(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

/// Opens the Ask-AI dialog anchored to the bottom-right of the screen,
/// above the FAB. Tap outside to dismiss.
Future<void> showAskAIDialog(BuildContext context) {
  final rec = context.read<RecommendationBloc>();
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Ask AI',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: Alignment.bottomRight,
        child: SafeArea(
          child: Padding(
            // Sits above the extended FAB (~52h) + a bit of breathing room.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: BlocProvider.value(
              value: rec,
              child: const AskAIDialog(),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final scale = Tween<double>(begin: 0.94, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack));
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: anim.drive(scale).value,
          alignment: Alignment.bottomRight,
          child: child,
        ),
      );
    },
  );
}
