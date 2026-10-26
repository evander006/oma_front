import 'package:flutter/material.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_icon.dart';

/// Centered flow header matching Dom screenshots (back · title · menu).
class OmaDomHeader extends StatelessWidget {
  const OmaDomHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: OmaColors.line)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => omaBack(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: OmaIcon(OmaIcons.chevronLeft, size: 22),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmaType.bold(16, OmaColors.black),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: OmaIcon(OmaIcons.ellipsis, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class DomBreadcrumb extends StatelessWidget {
  const DomBreadcrumb(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: OmaType.medium(13, OmaColors.blue));
  }
}

class DomSoftNote extends StatelessWidget {
  const DomSoftNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: OmaType.regular(12, OmaColors.muted)),
      ),
    );
  }
}

class DomCard extends StatelessWidget {
  const DomCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.selected = false,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? (selected ? OmaColors.blue : OmaColors.line),
      width: selected ? 1.5 : 1,
    );
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.white,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: box,
      ),
    );
  }
}

class DomPill extends StatelessWidget {
  const DomPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: OmaType.medium(11, OmaColors.blue)),
      ),
    );
  }
}

class DomIconTile extends StatelessWidget {
  const DomIconTile({required this.icon, this.size = 44, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OmaColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: OmaColors.blue, size: size * 0.45),
      ),
    );
  }
}

class DomCheckbox extends StatelessWidget {
  const DomCheckbox({required this.value, this.onTap, super.key});

  final bool value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value ? OmaColors.blue : OmaColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: OmaColors.blue, width: 1.5),
        ),
        child: SizedBox(
          width: 22,
          height: 22,
          child: value
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class DomInstallBlock extends StatelessWidget {
  const DomInstallBlock({
    required this.onAction,
    this.actionLabel = 'Добавить установку',
    this.subtitle = 'Платная услуга · Стоимость уточняется',
    this.linkStyle = false,
    super.key,
  });

  final VoidCallback onAction;
  final String actionLabel;
  final String subtitle;
  final bool linkStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24, color: OmaColors.line),
        Row(
          children: [
            Icon(Icons.build_outlined, size: 18, color: OmaColors.blue),
            const SizedBox(width: 8),
            Text('Нужна установка?', style: OmaType.medium(14, OmaColors.ink)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
        const SizedBox(height: 10),
        if (linkStyle)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel, style: OmaType.medium(13, OmaColors.blue)),
          )
        else
          _OutlineButton(label: actionLabel, onPressed: onAction),
      ],
    );
  }
}

class DomProductRow extends StatelessWidget {
  const DomProductRow({
    required this.imageAsset,
    required this.title,
    required this.price,
    this.status,
    this.trailing,
    super.key,
  });

  final String imageAsset;
  final String title;
  final String price;
  final String? status;
  final Widget? trailing;

  Widget _imgFallback() => Container(
        width: 72,
        height: 72,
        color: OmaColors.blueSoft,
        child: const Icon(Icons.image_outlined, color: OmaColors.blue),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: imageAsset.startsWith('http')
              ? Image.network(
                  imageAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                )
              : Image.asset(
                  imageAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: OmaType.medium(13, OmaColors.ink)),
              const SizedBox(height: 6),
              Text(price, style: OmaType.bold(14, OmaColors.black)),
              if (status != null) ...[
                const SizedBox(height: 4),
                Text(status!, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DomStepBar extends StatelessWidget {
  const DomStepBar({required this.step, required this.total, super.key});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Шаг $step из $total', style: OmaType.medium(13, OmaColors.blue)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < step ? OmaColors.blue : OmaColors.line,
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

class DomLabeledField extends StatelessWidget {
  const DomLabeledField({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OmaType.regular(12, OmaColors.muted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class DomTextBox extends StatelessWidget {
  const DomTextBox({
    required this.controller,
    this.hint,
    this.keyboard,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    super.key,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      onTap: onTap,
      style: OmaType.regular(14, OmaColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: OmaType.regular(14, OmaColors.hint),
        filled: true,
        fillColor: OmaColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OmaColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OmaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OmaColors.blue),
        ),
      ),
    );
  }
}

class DomDashedUpload extends StatelessWidget {
  const DomDashedUpload({
    required this.title,
    this.subtitle = 'JPG, PNG или PDF',
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: OmaColors.blue),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.upload_file_outlined, color: OmaColors.blue, size: 28),
                const SizedBox(height: 8),
                Text(title, style: OmaType.medium(14, OmaColors.blue)),
                const SizedBox(height: 4),
                Text(subtitle, style: OmaType.regular(12, OmaColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DomRoomGrid extends StatelessWidget {
  const DomRoomGrid({
    required this.rooms,
    required this.selected,
    this.onSelect,
    this.compact = false,
    super.key,
  });

  final List<String> rooms;
  final String selected;
  final ValueChanged<String>? onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final top = rooms.take(3).toList();
    final bottom = rooms.skip(3).take(3).toList();
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _cell(top[i], compact ? 56 : 86)),
            ],
          ],
        ),
        if (bottom.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < bottom.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _cell(bottom[i], 48)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(String name, double height) {
    final sel = name == selected;
    return Material(
      color: OmaColors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onSelect == null ? null : () => onSelect!(name),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: sel ? OmaColors.blue : OmaColors.line,
              width: sel ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: OmaType.medium(
                12,
                sel ? OmaColors.blue : OmaColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OmaColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OmaColors.blue),
          ),
          child: Center(
            child: Text(label, style: OmaType.semibold(13, OmaColors.blue)),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
