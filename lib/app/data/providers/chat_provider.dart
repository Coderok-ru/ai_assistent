import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../models/message.dart';
import '../../controllers/settings_controller.dart';
import 'package:get/get.dart';

class ChatProvider {
  final Dio _dio = Dio();
  final _box = GetStorage();
  final SettingsController _settingsController =
      Get.isRegistered<SettingsController>() ? Get.find<SettingsController>() : Get.put(SettingsController());

  Future<Message> sendMessage({
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? systemPrompt,
    String model = 'openai/gpt-4o',
    List<Message>? history,
  }) async {
    final apiKey = _settingsController.effectiveApiKey;
    final hasAttachment = (imageUrl != null && imageUrl.isNotEmpty) || (fileUrl != null && fileUrl.isNotEmpty);
    final List<Map<String, dynamic>> messages = [];

    // Добавляем системное сообщение, если есть промпт
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });
    }

    // Добавляем историю сообщений
    if (history != null && history.isNotEmpty) {
      for (final msg in history) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    }

    final List<Map<String, dynamic>> content = [];

    if (text.isNotEmpty) {
      content.add({'type': 'text', 'text': text});
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      content.add({'type': 'image_url', 'image_url': {'url': imageUrl}});
    }
    if (fileUrl != null && fileUrl.isNotEmpty) {
      content.add({'type': 'file_url', 'file_url': {'url': fileUrl}});
    }

    final userMessage = {
      'role': 'user',
      'content': hasAttachment ? content : text,
    };

    messages.add(userMessage);

    final requestBody = {
      'model': model,
      'messages': messages,
    };

    print('Request: \\${jsonEncode(requestBody)}');

    final response = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: requestBody,
    );

    print('AI response: \\${response.data}');

    if (response.data is Map && response.data['choices'] is List && response.data['choices'].isNotEmpty) {
      final dynamic aiContent = response.data['choices'][0]['message']['content'];
      String aiText;
      if (aiContent is List && aiContent.isNotEmpty && aiContent[0]['type'] == 'text') {
        aiText = aiContent[0]['text'];
      } else if (aiContent is String) {
        aiText = aiContent;
      } else {
        aiText = 'Ответ не распознан';
      }
      return Message(text: aiText, isUser: false, createdAt: DateTime.now());
    } else if (response.data is Map && response.data['error'] != null) {
      return Message(
        text: 'Ошибка: \\${response.data['error']['message'] ?? response.data['error']}',
        isUser: false,
        createdAt: DateTime.now(),
      );
    } else {
      return Message(
        text: 'Ошибка: неожиданный ответ от сервера',
        isUser: false,
        createdAt: DateTime.now(),
      );
    }
  }
} 