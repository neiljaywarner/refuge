import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material button shapes [AsyncActionButton] can render.
enum AsyncButtonVariant { filled, elevated, outlined, text, icon, filledIcon }

/// A button for work that takes time (saving, sending, signing in).
///
/// While the [onPressed] future is pending the button is disabled, its label
/// or icon is swapped for a small spinner of the same footprint (no layout
/// jump), extra taps are ignored, and screen readers hear [busyLabel]. It
/// re-enables when the future completes or throws; errors are reported via
/// [FlutterError.reportError] rather than swallowed (#977).
class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.onPressed,
    this.child = const SizedBox.shrink(),
    this.variant = AsyncButtonVariant.filled,
    this.icon,
    this.busyLabel = 'Working',
    this.isBusy = false,
    this.style,
    this.tooltip,
    this.iconSize,
  });

  /// The async action. `null` disables the button.
  final Future<void> Function()? onPressed;

  /// Label for text variants. Ignored by [AsyncButtonVariant.icon] and
  /// [AsyncButtonVariant.filledIcon], which show [icon] only.
  final Widget child;

  final AsyncButtonVariant variant;

  /// Leading icon for text variants; the whole content for icon variants.
  final Widget? icon;

  /// What assistive tech announces while the action runs, e.g. 'Sending'.
  final String busyLabel;

  /// When true, show the spinner and ignore taps even if this button did not
  /// start the work (a keyboard submit, or a parent still waiting after this
  /// widget was recreated).
  final bool isBusy;

  final ButtonStyle? style;
  final String? tooltip;
  final double? iconSize;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _busy = false;

  bool get _isIconVariant =>
      widget.variant == AsyncButtonVariant.icon || widget.variant == AsyncButtonVariant.filledIcon;

  bool get _showBusy => _busy || widget.isBusy;

  Future<void> _run() async {
    final action = widget.onPressed;
    if (_showBusy || action == null) return;
    _busy = true; // synchronous: a second tap before rebuild is ignored
    setState(() {});
    try {
      await action();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'async_action_button',
          context: ErrorDescription('while running an AsyncActionButton action'),
        ),
      );
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  Widget _withSpinner(Widget content, {required double maxSpinner}) {
    final scaled = MediaQuery.textScalerOf(context).scale(16).clamp(12.0, 40.0);
    final size = math.min(scaled, maxSpinner);
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: !_showBusy,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: content,
        ),
        if (_showBusy)
          Positioned.fill(
            child: Center(
              child: SizedBox.square(
                dimension: size,
                child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: widget.busyLabel),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _showBusy ? null : _run;

    if (_isIconVariant) {
      final iconSize = widget.iconSize ?? 24;
      final content = _withSpinner(
        widget.icon ?? widget.child,
        maxSpinner: math.max(iconSize - 4, 12),
      );
      return widget.variant == AsyncButtonVariant.filledIcon
          ? IconButton.filled(
              style: widget.style,
              tooltip: widget.tooltip,
              iconSize: widget.iconSize,
              onPressed: onPressed,
              icon: content,
            )
          : IconButton(
              style: widget.style,
              tooltip: widget.tooltip,
              iconSize: widget.iconSize,
              onPressed: onPressed,
              icon: content,
            );
    }

    final label = widget.icon == null
        ? widget.child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon!,
              const SizedBox(width: 8),
              Flexible(child: widget.child),
            ],
          );
    final content = _withSpinner(label, maxSpinner: double.infinity);
    final button = switch (widget.variant) {
      AsyncButtonVariant.elevated => ElevatedButton(
        style: widget.style,
        onPressed: onPressed,
        child: content,
      ),
      AsyncButtonVariant.outlined => OutlinedButton(
        style: widget.style,
        onPressed: onPressed,
        child: content,
      ),
      AsyncButtonVariant.text => TextButton(
        style: widget.style,
        onPressed: onPressed,
        child: content,
      ),
      _ => FilledButton(style: widget.style, onPressed: onPressed, child: content),
    };
    final tooltip = widget.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
