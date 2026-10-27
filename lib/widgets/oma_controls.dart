import 'package:flutter/material.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_icon.dart';

enum OmaButtonKind { primary, secondary, orange }

class OmaButton extends StatelessWidget {
  const OmaButton({
    required this.label,
    required this.onPressed,
    this.kind = OmaButtonKind.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final OmaButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final orange = kind == OmaButtonKind.orange;
    final background = switch (kind) {
      OmaButtonKind.primary => OmaColors.blue,
      OmaButtonKind.secondary => OmaColors.white,
      OmaButtonKind.orange => OmaColors.orange,
    };
    final foreground = switch (kind) {
      OmaButtonKind.primary => OmaColors.white,
      OmaButtonKind.secondary => OmaColors.blue,
      OmaButtonKind.orange => OmaColors.ink,
    };
    final borderColor = orange ? Colors.transparent : OmaColors.blue;

    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            height: orange ? 44 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: orange
                      ? OmaType.bold(14, foreground)
                      : OmaType.semibold(14, foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OmaTextAction extends StatelessWidget {
  const OmaTextAction({
    required this.label,
    required this.onPressed,
    this.centered = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: OmaType.regular(12, OmaColors.blue),
      ),
    );
  }
}

class OmaSectionHeader extends StatelessWidget {
  const OmaSectionHeader({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: OmaType.bold(18, OmaColors.ink)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Text(action!, style: OmaType.semibold(12, OmaColors.blue)),
          ),
      ],
    );
  }
}

class OmaBadge extends StatelessWidget {
  const OmaBadge({
    required this.label,
    this.cream = false,
    super.key,
  });

  final String label;
  final bool cream;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cream ? OmaColors.cream : OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: OmaType.semibold(
            11,
            cream ? OmaColors.blueDark : OmaColors.blue,
          ),
        ),
      ),
    );
  }
}

class OmaInfoNote extends StatelessWidget {
  const OmaInfoNote({
    required this.text,
    this.icon = OmaIcons.info,
    this.cream = false,
    super.key,
  });

  final String text;
  final String icon;
  final bool cream;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cream ? OmaColors.cream : OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OmaIcon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: OmaType.regular(12, OmaColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class OmaChoiceChip extends StatelessWidget {
  const OmaChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? OmaColors.blueSoft : OmaColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? OmaColors.blue : OmaColors.line,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(
            label,
            style: selected
                ? OmaType.semibold(12, OmaColors.blue)
                : OmaType.regular(12, OmaColors.ink),
          ),
        ),
      ),
    );
  }
}

class OmaChoiceWrap extends StatelessWidget {
  const OmaChoiceWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<String> options;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < options.length; i++)
          OmaChoiceChip(
            label: options[i],
            selected: selected.contains(i),
            onTap: () => onToggle(i),
          ),
      ],
    );
  }
}

class OmaField extends StatelessWidget {
  const OmaField({
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final String icon;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmaType.medium(12, OmaColors.muted)),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: OmaColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OmaColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value, style: OmaType.medium(14, OmaColors.ink)),
                  ),
                  const SizedBox(width: 12),
                  OmaIcon(icon, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: OmaType.regular(11, OmaColors.muted)),
        ],
      ],
    );
  }
}

class OmaSearchBar extends StatelessWidget {
  const OmaSearchBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.searchFill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const OmaIcon(OmaIcons.search, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Поиск по названию или категории',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmaType.regular(13, OmaColors.hint),
                  ),
                ),
                const OmaIcon(OmaIcons.scanBarcode, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OmaCategoryChip extends StatelessWidget {
  const OmaCategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: OmaColors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                OmaIcon(icon, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: OmaType.semibold(10, OmaColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OmaDataRow extends StatelessWidget {
  const OmaDataRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    super.key,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle ?? OmaType.regular(13, OmaColors.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: valueStyle ?? OmaType.medium(13, OmaColors.ink),
        ),
      ],
    );
  }
}

class OmaSurfaceCard extends StatelessWidget {
  const OmaSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: OmaColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected ? OmaColors.blue : OmaColors.line,
        width: selected ? 1.5 : 1,
      ),
    );
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

class OmaTaskRow extends StatelessWidget {
  const OmaTaskRow({
    required this.title,
    this.subtitle,
    this.done = false,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: done ? OmaColors.green : OmaColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: done ? OmaColors.green : OmaColors.line,
              width: 1.5,
            ),
          ),
          child: SizedBox(
            width: 22,
            height: 22,
            child: done
                ? const Center(child: OmaIcon(OmaIcons.check, size: 15))
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: OmaType.medium(13, OmaColors.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: OmaType.regular(11, OmaColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(trailing!, style: OmaType.semibold(11, OmaColors.blue)),
        ],
      ],
    );
  }
}

class OmaStepProgress extends StatelessWidget {
  const OmaStepProgress({
    required this.caption,
    required this.stepLabel,
    required this.current,
    required this.total,
    super.key,
  });

  final String caption;
  final String stepLabel;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(caption, style: OmaType.regular(13, OmaColors.muted)),
            ),
            Text(stepLabel, style: OmaType.medium(13, OmaColors.ink)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < current ? OmaColors.blue : OmaColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const SizedBox(height: 4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class OmaQuantity extends StatelessWidget {
  const OmaQuantity({
    required this.label,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? OmaType.semibold(14, OmaColors.ink)
        : OmaType.regular(14, OmaColors.ink);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 7,
          vertical: compact ? 5 : 7,
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Mark(label: '−', onTap: onMinus),
            if (compact) const SizedBox(width: 14),
            Text(label, style: style),
            if (compact) const SizedBox(width: 14),
            _Mark(label: '+', onTap: onPlus),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(label, style: OmaType.regular(14, OmaColors.blue)),
    );
  }
}
