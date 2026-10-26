import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/core/repositories/ai_chat_repository.dart';
import 'package:oma/features/my_home/presentation/widgets/dom_widgets.dart';
import 'package:oma/shared/models/chat_message.dart';
import 'package:oma/shared/models/product.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:oma/widgets/oma_controls.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    required this.propertyId,
    required this.roomId,
    super.key,
  });

  final String propertyId;
  final String roomId;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];
  final _products = <Product>[];
  bool _busy = false;
  int? _sessionId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    final repo = context.read<AiChatRepository>();
    setState(() {
      _busy = true;
      _messages.add(repo.userMessage(text));
      _controller.clear();
    });
    try {
      final result = await repo.chat(
        message: text,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = result.sessionId ?? _sessionId;
        _messages.add(result.reply);
        if (result.products.isNotEmpty) {
          _products
            ..clear()
            ..addAll(result.products);
        }
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(repo.assistantMessage('Не удалось получить ответ: $e'));
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const OmaDomHeader(title: 'ИИ-подбор · Кухня'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DomBreadcrumb('Моя квартира / Кухня'),
                  const SizedBox(height: 12),
                  if (_messages.isEmpty && !_busy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Напишите, что хотите подобрать — например освещение или смеситель для кухни.',
                        textAlign: TextAlign.center,
                        style: OmaType.regular(14, OmaColors.muted),
                      ),
                    ),
                  for (final m in _messages) ...[
                    _Bubble(message: m),
                    const SizedBox(height: 12),
                  ],
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  for (final p in _products) ...[
                    _ProductChatCard(
                      product: p,
                      propertyId: widget.propertyId,
                      roomId: widget.roomId,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_products.isNotEmpty)
                    OmaButton(
                      label: 'Открыть карточку товара',
                      kind: OmaButtonKind.secondary,
                      onPressed: () => context.push(
                        AppRoutes.productPath(_products.first.id),
                      ),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: OmaColors.white,
                border: Border(top: BorderSide(color: OmaColors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: OmaColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Что хотите изменить?',
                          hintStyle: OmaType.regular(14, OmaColors.hint),
                          filled: true,
                          fillColor: OmaColors.searchFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send, color: OmaColors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              mine ? 'Вы' : 'Помощник OMA',
              style: OmaType.medium(12, OmaColors.muted),
            ),
            const SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: mine ? OmaColors.blueSoft : OmaColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OmaColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mine) ...[
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: OmaColors.blue,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        message.text,
                        style: OmaType.regular(14, OmaColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductChatCard extends StatelessWidget {
  const _ProductChatCard({
    required this.product,
    required this.propertyId,
    required this.roomId,
  });

  final Product product;
  final String propertyId;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return DomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DomProductRow(
            imageAsset: product.hasNetworkImage
                ? product.imageUrl!
                : product.imageAsset,
            title: product.name,
            price: product.priceLabel,
            status: 'Цена из бэкенда · ${product.currency}',
          ),
          const SizedBox(height: 12),
          OmaButton(
            label: 'Посмотреть в комнате',
            onPressed: () =>
                context.push(AppRoutes.room3dPath(propertyId, roomId)),
          ),
          DomInstallBlock(
            onAction: () => context.push(AppRoutes.installPath(product.id)),
          ),
        ],
      ),
    );
  }
}
