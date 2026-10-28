import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/theme/oma_theme.dart';

/// A presentation-only introduction shown once per new app process.
/// Do not persist a completion flag: returning from the background must
/// preserve the current GoRouter location instead of restarting this flow.
class LaunchIntroScreen extends StatefulWidget {
  const LaunchIntroScreen({super.key});

  @override
  State<LaunchIntroScreen> createState() => _LaunchIntroScreenState();
}

class _IntroSlide {
  const _IntroSlide(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

class _LaunchIntroScreenState extends State<LaunchIntroScreen> {
  static const _slides = <_IntroSlide>[
    _IntroSlide(
      'Всё о вашем доме — в одном месте',
      'Сохраняйте сведения о комнатах, оборудовании и покупках, '
          'чтобы нужная информация о жилье всегда была под рукой.',
      Icons.home_outlined,
    ),
    _IntroSlide(
      'Представьте свой дом в 3D',
      'Просматривайте 3D-модель вашего жилья и планируйте изменения '
          'с учётом сведений о комнатах.',
      Icons.view_in_ar_outlined,
    ),
    _IntroSlide(
      'Нашли идею? Найдите товар',
      'Добавьте фото комнаты, чтобы получить идеи оформления '
          'и перейти к подбору подходящих товаров ОМА.',
      Icons.photo_camera_outlined,
    ),
    _IntroSlide(
      'Помощь специалиста — рядом',
      'Выбирайте мастеров для ремонта, монтажа и других задач по дому.',
      Icons.handyman_outlined,
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;
  bool _completed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    context.go(AppRoutes.home);
  }

  void _advance() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmaColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('ОМА. Дом',
                              style: OmaType.bold(20, OmaColors.blue)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _finish,
                        child: Text('Пропустить',
                            style: OmaType.medium(14, OmaColors.muted)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (context, index) =>
                          _IntroPage(slide: _slides[index]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? OmaColors.blue
                                : OmaColors.line,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _advance,
                      style: FilledButton.styleFrom(
                        backgroundColor: OmaColors.blue,
                        foregroundColor: OmaColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _page == _slides.length - 1 ? 'Начать' : 'Далее',
                          key: ValueKey(_page == _slides.length - 1),
                          style: OmaType.semibold(16, OmaColors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: OmaColors.blueSoft,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(slide.icon, size: 68, color: OmaColors.blue),
                ),
                const SizedBox(height: 32),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: OmaType.bold(26, OmaColors.ink).copyWith(height: 1.2),
                ),
                const SizedBox(height: 18),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style:
                      OmaType.regular(16, OmaColors.muted).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
