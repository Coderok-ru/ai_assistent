class Message {
  final String text;
  final bool isUser;
  final DateTime createdAt;

  Message({required this.text, required this.isUser, required this.createdAt});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'],
        isUser: json['isUser'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'createdAt': createdAt.toIso8601String(),
      };
} 