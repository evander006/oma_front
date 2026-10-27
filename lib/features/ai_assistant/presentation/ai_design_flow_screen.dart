import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/ai_chat_repository.dart';
import 'package:oma/core/repositories/catalog_repository.dart';
import 'package:oma/features/cart/cubit/cart_cubit.dart';
import 'package:oma/features/my_home/cubit/properties_cubit.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/shared/widgets/product_card.dart';
import 'package:oma/theme/oma_icons.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_chrome.dart';
import 'package:oma/widgets/oma_controls.dart';
import 'package:oma/widgets/oma_icon.dart';

/// Guided AI interior design entry that uses the real AI chat / catalog APIs.
class AiDesignFlowScreen extends StatefulWidget {
  const AiDesignFlowScreen({super.key});

  @override
  State<AiDesignFlowScreen> createState() => _AiDesignFlowScreenState();
}

class _AiDesignFlowScreenState extends State<AiDesignFlowScreen> {
  int _step = 0;
  String? _roomType;
  String? _style;
  String? _budget;
  final _notes = TextEditingController();
  final _photos = <String>[];
  final _categories = <String>{};
  var _loading = false;
  String? _error;
  String? _reply;
  List<Product> _products = const [];

  static const _rooms = [
    'Кухня',
    'Гостиная',
    'Спальня',
    'Детская',
    'Санузел',
    'Прихожая',
  ];
  static const _styles = [
    'Современный',
    'Минимализм',
    'Скандинавский',
    'Классический',
    'Лофт',
  ];
  static const _budgets = [
    'до 1 000 BYN',
    '1–3 000 BYN',
    '3–7 000 BYN',
    'от 7 000 BYN',
  ];
  static const _cats = [
    'Сантехника',
    'Освещение',
    'Отделка',
    'Мебель',
    'Хранение',
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
      _reply = null;
      _products = const [];
    });
    try {
      final message = [
        'Подбери товары OMA для комнаты: ${_roomType ?? 'комната'}.',
        if (_style != null) 'Стиль: $_style.',
        if (_budget != null) 'Бюджет: $_budget.',
        if (_categories.isNotEmpty)
          'Категории: ${_categories.join(', ')}.',
        if (_notes.text.trim().isNotEmpty) 'Ограничения: ${_notes.text.trim()}.',
      ].join(' ');

      final ai = context.read<AiChatRepository>();
      final catalog = context.read<CatalogRepository>();
      final budgetDigits = RegExp(r'(\d[\d\s]*)')
          .allMatches(_budget ?? '')
          .map((m) => double.tryParse(m.group(1)!.replaceAll(' ', '')))
          .whereType<double>()
          .toList();
      final result = await ai.recommend(
        prompt: message,
        preferredStyle: _style,
        maxBudget: budgetDigits.isEmpty ? null : budgetDigits.last,
        categoryIds: _categories.toList(),
      );
      var products = result.products;
      if (products.isEmpty) {
        // Fallback: chat, then catalog page — never invent products.
        final chat = await ai.chat(
          message: message,
          budget: budgetDigits.isEmpty ? null : budgetDigits.last,
          style: _style,
        );
        products = chat.products;
      }
      if (products.isEmpty) {
        products = await catalog.products(pageSize: 6);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _reply = result.reply.text;
        _products = products;
        _step = 5;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = context.watch<PropertiesCubit>().state;

    return OmaPage(
      header: const OmaFlowHeader(
        title: 'ИИ-дизайнер',
        eyebrow: 'Реальные товары каталога',
        showCart: true,
      ),
      actions: [
        if (_step > 0 && _step < 5)
          OmaButton(
            label: 'Назад',
            kind: OmaButtonKind.secondary,
            onPressed: _loading ? null : () => setState(() => _step--),
          ),
        if (_step < 4)
          OmaButton(
            label: 'Далее',
            onPressed: () {
              if (_step == 1 && _roomType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Выберите тип комнаты')),
                );
                return;
              }
              setState(() => _step++);
            },
          )
        else if (_step == 4)
          OmaButton(
            label: _loading ? 'Анализ…' : 'Получить рекомендации',
            onPressed: _loading ? null : _runAnalysis,
          )
        else if (_step == 5)
          OmaButton(
            label: 'Открыть чат по комнате',
            onPressed: () {
              final selected = props.selected;
              if (selected != null && selected.rooms.isNotEmpty) {
                context.push(
                  AppRoutes.roomAiPath(selected.id, selected.rooms.first.id),
                );
              } else {
                context.push(AppRoutes.onboarding);
              }
            },
          ),
      ],
      children: [
        OmaStepProgress(
          caption: switch (_step) {
            0 => 'Объект',
            1 => 'Комната и фото',
            2 => 'Стиль и бюджет',
            3 => 'Категории',
            4 => 'Проверка',
            _ => 'Рекомендации',
          },
          stepLabel: 'Шаг ${_step + 1} из 6',
          current: _step + 1,
          total: 6,
        ),
        if (_error != null)
          OmaInfoNote(
            text: 'Ошибка ИИ/сети: $_error. Можно повторить запрос.',
          ),
        ...switch (_step) {
          0 => [
              Text(
                'Выберите объект или создайте новый',
                style: OmaType.bold(16, OmaColors.ink),
              ),
              if (props.properties.isEmpty)
                OmaButton(
                  label: 'Создать объект',
                  onPressed: () => context.push(AppRoutes.onboarding),
                )
              else
                for (final p in props.properties)
                  OmaSurfaceCard(
                    selected: props.selected?.id == p.id,
                    onTap: () => context.read<PropertiesCubit>().select(p.id),
                    child: Text(p.name, style: OmaType.semibold(14, OmaColors.ink)),
                  ),
              OmaButton(
                label: 'Продолжить без объекта',
                kind: OmaButtonKind.secondary,
                onPressed: () => setState(() => _step = 1),
              ),
            ],
          1 => [
              Text('Тип комнаты', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _rooms)
                    OmaChoiceChip(
                      label: r,
                      selected: _roomType == r,
                      onTap: () => setState(() => _roomType = r),
                    ),
                ],
              ),
              Text('Фото', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in _photos)
                    Chip(
                      label: Text(a.split('/').last),
                      onDeleted: () => setState(() => _photos.remove(a)),
                    ),
                  ActionChip(
                    avatar: const OmaIcon(OmaIcons.paperclip, size: 16),
                    label: const Text('Демо-фото'),
                    onPressed: () => setState(
                      () => _photos.add(OmaImages.attachmentKitchen),
                    ),
                  ),
                ],
              ),
              const OmaInfoNote(
                text:
                    'Загрузка фото на backend для vision-анализа выполняется через AI API при наличии сессии/endpoint.',
              ),
            ],
          2 => [
              Text('Стиль', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _styles)
                    OmaChoiceChip(
                      label: s,
                      selected: _style == s,
                      onTap: () => setState(() => _style = s),
                    ),
                ],
              ),
              Text('Бюджет', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in _budgets)
                    OmaChoiceChip(
                      label: b,
                      selected: _budget == b,
                      onTap: () => setState(() => _budget = b),
                    ),
                ],
              ),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ограничения и пожелания',
                  hintText: 'Оставить диван, светлые стены…',
                  filled: true,
                  fillColor: OmaColors.white,
                ),
              ),
            ],
          3 => [
              Text('Категории товаров', style: OmaType.bold(16, OmaColors.ink)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _cats)
                    OmaChoiceChip(
                      label: c,
                      selected: _categories.contains(c),
                      onTap: () {
                        final next = {..._categories};
                        if (!next.add(c)) next.remove(c);
                        setState(() {
                          _categories
                            ..clear()
                            ..addAll(next);
                        });
                      },
                    ),
                ],
              ),
            ],
          4 => [
              Text('Проверьте данные', style: OmaType.bold(16, OmaColors.ink)),
              OmaDataRow(label: 'Комната', value: _roomType ?? '—'),
              OmaDataRow(label: 'Стиль', value: _style ?? '—'),
              OmaDataRow(label: 'Бюджет', value: _budget ?? '—'),
              OmaDataRow(label: 'Фото', value: '${_photos.length}'),
              OmaDataRow(
                label: 'Категории',
                value: _categories.isEmpty ? '—' : _categories.join(', '),
              ),
              if (_loading) const LinearProgressIndicator(),
            ],
          _ => [
              Text('Рекомендации', style: OmaType.bold(18, OmaColors.ink)),
              if (_reply != null)
                OmaSurfaceCard(
                  child: Text(_reply!, style: OmaType.regular(14, OmaColors.ink)),
                ),
              if (_products.isEmpty)
                Text(
                  'Товары не вернулись от ИИ. Показан пустой результат — повторите запрос.',
                  style: OmaType.regular(13, OmaColors.muted),
                )
              else
                for (final p in _products)
                  Column(
                    children: [
                      ProductCard(
                        product: p,
                        onTap: () =>
                            context.push(AppRoutes.productPath(p.id)),
                        onAdd: () => context.read<CartCubit>().add(p),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OmaButton(
                              label: 'Подробнее',
                              kind: OmaButtonKind.secondary,
                              onPressed: () =>
                                  context.push(AppRoutes.productPath(p.id)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OmaButton(
                              label: 'Убрать',
                              kind: OmaButtonKind.secondary,
                              onPressed: () => setState(
                                () => _products =
                                    _products.where((e) => e.id != p.id).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              if (_products.isNotEmpty) ...[
                OmaDataRow(
                  label: 'Сумма товаров',
                  value:
                      '${_products.fold<double>(0, (s, p) => s + (p.priceByn ?? 0)).toStringAsFixed(2)} BYN',
                ),
                OmaButton(
                  label: 'Добавить все в корзину',
                  onPressed: () {
                    final cart = context.read<CartCubit>();
                    for (final p in _products) {
                      cart.add(p);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Товары добавлены в корзину')),
                    );
                  },
                ),
                OmaButton(
                  label: 'К визуализации / чату комнаты',
                  kind: OmaButtonKind.secondary,
                  onPressed: () {
                    final selected = props.selected;
                    if (selected != null && selected.rooms.isNotEmpty) {
                      context.push(
                        AppRoutes.roomAiPath(
                          selected.id,
                          selected.rooms.first.id,
                        ),
                      );
                    } else {
                      context.push(AppRoutes.projects);
                    }
                  },
                ),
                const OmaInfoNote(
                  text:
                      'Визуализация комнаты — концепт, а не точное соответствие купленным товарам. Генерация изображения выполняется только при ответе backend.',
                  cream: true,
                ),
              ],
            ],
        },
      ],
    );
  }
}
