import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.at,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime at;

  bool get isUser => role == ChatRole.user;

  @override
  List<Object?> get props => [id, role, text, at];
}
