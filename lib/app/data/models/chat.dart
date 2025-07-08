import 'message.dart';

class Chat {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Message> messages;
  final String roleName;
  final String rolePrompt;
  final String modelId;
  final String modelName;
  final int? sentTokens;
  final int? receivedTokens;

  Chat({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.messages,
    required this.roleName,
    required this.rolePrompt,
    required this.modelId,
    required this.modelName,
    this.sentTokens,
    this.receivedTokens,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    messages: (json['messages'] as List).map((e) => Message.fromJson(e)).toList(),
    roleName: json['roleName'],
    rolePrompt: json['rolePrompt'],
    modelId: json['modelId'],
    modelName: json['modelName'],
    sentTokens: json['sentTokens'],
    receivedTokens: json['receivedTokens'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((e) => e.toJson()).toList(),
    'roleName': roleName,
    'rolePrompt': rolePrompt,
    'modelId': modelId,
    'modelName': modelName,
    'sentTokens': sentTokens,
    'receivedTokens': receivedTokens,
  };
} 