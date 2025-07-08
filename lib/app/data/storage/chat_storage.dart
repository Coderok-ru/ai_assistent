import 'package:get_storage/get_storage.dart';
import '../models/chat.dart';

class ChatStorage {
  final _box = GetStorage();
  final _key = 'chats';

  List<Chat> loadChats() {
    final raw = _box.read(_key) as List?;
    if (raw == null) return [];
    return raw.map((e) => Chat.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  void saveChats(List<Chat> chats) {
    _box.write(_key, chats.map((e) => e.toJson()).toList());
  }
} 