import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/network/api_config.dart';
import 'package:oma/features/room_3d/presentation/scene_embed.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';

/// Whole-home WebGL; room focus is optional. Backend decides eligible goods.
class Room3dScreen extends StatelessWidget {
  const Room3dScreen({required this.propertyId, this.roomId, super.key});

  final String propertyId;
  final String? roomId;

  @override
  Widget build(BuildContext context) {
    final params = roomId == null
        ? ''
        : '?room_id=' + Uri.encodeComponent(roomId!);
    final url = ApiConfig.baseUrl + ApiConfig.apiPrefix +
        '/scene/view/' + propertyId + params;
    final height =
        (MediaQuery.sizeOf(context).height * .68).clamp(350.0, 690.0);
    return OmaPage(
      header: OmaFlowHeader(
        title: roomId == null ? 'Моё жильё · 3D' : 'Комната · 3D',
        eyebrow: 'Цифровой дом ОМА',
      ),
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SceneEmbed(url: url),
          ),
        ),
        Text(
          'Здесь отображаются только товары из заказов ОМА, '
          'привязанные к комнате. Демо-заказы отмечены отдельно. '
          'Если точные размеры не указаны, геометрия приблизительна.',
          style: OmaType.regular(12, OmaColors.muted),
        ),
        OmaButton(
          label: 'Технический паспорт жилья',
          kind: OmaButtonKind.secondary,
          // A nested StatefulShellRoute cannot safely be pushed on top of
          // this root-level 3D route: Flutter reserves the same Navigator
          // GlobalKeys twice and crashes with !_keyReservation.contains(key).
          // Replace the route stack when crossing into the profile shell.
          onPressed: () =>
              context.go(AppRoutes.propertyPassportPath(propertyId)),
        ),
      ],
    );
  }
}
