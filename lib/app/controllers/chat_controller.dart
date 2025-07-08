import 'package:get/get.dart';
import '../data/models/message.dart';
import '../data/models/chat.dart';
import '../data/providers/chat_provider.dart';
import '../data/storage/chat_storage.dart';
import '../data/storage/prompt_storage.dart';
import 'settings_controller.dart';

class ChatController extends GetxController {
  final chats = <Chat>[].obs;
  final currentChat = Rxn<Chat>();
  final isLoading = false.obs;
  final roles = <PromptRole>[].obs;
  final selectedRole = Rxn<PromptRole>();

  final ChatProvider _provider = ChatProvider();
  final ChatStorage _storage = ChatStorage();
  late final SettingsController _settingsController;

  bool _resetHistoryForNextMessage = false;

  @override
  void onInit() {
    super.onInit();
    _settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    _initStartup();
  }

  Future<void> _initStartup() async {
    await _loadRoles();
    chats.assignAll(_storage.loadChats());
    if (roles.isNotEmpty && selectedRole.value == null) {
      selectedRole.value = roles.first;
    }
    if (chats.isNotEmpty) {
      currentChat.value = chats.first;
    } else {
      if (_settingsController.effectiveApiKey.isEmpty) {
        Get.snackbar('Ошибка', 'Не удалось получить API-ключ', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4));
      } else {
        final PromptRole usedRole = roles.isNotEmpty ? roles.first : PromptRole(name: 'Без роли', prompt: '', isActive: false, isSystem: false);
        selectedRole.value = usedRole;
        final String usedModelName = _settingsController.selectedModel?.name ?? _settingsController.selectedModelId.value;
        Get.snackbar('Модель: $usedModelName', 'Роль: ${usedRole.name}', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4));
        createChat();
      }
    }
  }

  void createChat({String? name, PromptRole? role, String? modelId, String? modelName}) {
    if ((_settingsController.effectiveApiKey.isEmpty)) {
      Get.snackbar('Ошибка', 'Не удалось получить API-ключ', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4));
      return;
    }
    PromptRole usedRole;
    if (role != null) {
      usedRole = role;
    } else if (selectedRole.value != null) {
      usedRole = selectedRole.value!;
    } else if (roles.isNotEmpty) {
      usedRole = roles.first;
    } else {
      usedRole = PromptRole(name: 'Без роли', prompt: '', isActive: false, isSystem: false);
    }
    final String usedName = name ?? usedRole.name;
    final String usedModelId = modelId ?? _settingsController.selectedModel?.id ?? _settingsController.selectedModelId.value;
    final String usedModelName = modelName ?? _settingsController.selectedModel?.name ?? _settingsController.selectedModelId.value;
    final newChat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: usedName,
      createdAt: DateTime.now(),
      messages: [],
      roleName: usedRole.name,
      rolePrompt: usedRole.prompt,
      modelId: usedModelId,
      modelName: usedModelName,
      sentTokens: 0,
      receivedTokens: 0,
    );
    chats.insert(0, newChat);
    currentChat.value = newChat;
    _storage.saveChats(chats);
    Get.snackbar('Создан новый чат', 'Роль: ${newChat.roleName}, Модель: ${newChat.modelName}', snackPosition: SnackPosition.TOP);
  }

  void deleteChat(String chatId) {
    chats.removeWhere((c) => c.id == chatId);
    if (chats.isNotEmpty) {
      currentChat.value = chats.first;
    } else {
      currentChat.value = null;
    }
    _storage.saveChats(chats);
    Get.snackbar('Чат удалён', '', snackPosition: SnackPosition.TOP);
  }

  void selectChat(String chatId) {
    final chat = chats.firstWhereOrNull((c) => c.id == chatId);
    if (chat != null) {
      currentChat.value = chat;
      Get.snackbar(
        'Выбран чат',
        'Роль: ${chat.roleName}, Модель: ${chat.modelName}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  List<Message> get messages => currentChat.value?.messages ?? [];

  Future<void> _loadRoles() async {
    final rolesList = await PromptStorage.loadPrompts();
    roles.assignAll(rolesList);
    
    // Загружаем активную роль
    final activeRole = await PromptStorage.getActivePrompt();
    if (activeRole != null) {
      selectedRole.value = activeRole;
    } else if (roles.isNotEmpty) {
      // Если нет активной роли, выбираем первую
      selectedRole.value = roles.first;
    }
  }

  Future<void> selectRole(PromptRole role) async {
    await PromptStorage.setActivePrompt(role.id!);
    selectedRole.value = role;
  }

  Future<void> sendMessage({
    required String text,
    String? imageUrl,
    String? fileUrl,
  }) async {
    if (_settingsController.effectiveApiKey.isEmpty) {
      Get.snackbar('Ошибка', 'Не удалось получить API-ключ', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4));
      return;
    }
    if (currentChat.value == null) {
      createChat();
    }
    if (currentChat.value == null) return;
    if (text.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty) && (fileUrl == null || fileUrl.isNotEmpty)) return;
    final userMsg = Message(text: text, isUser: true, createdAt: DateTime.now());
    currentChat.value!.messages.add(userMsg);
    final idx = chats.indexWhere((c) => c.id == currentChat.value!.id);
    if (idx != -1) {
      final chat = chats[idx];
      final sent = (chat.sentTokens ?? 0) + text.length;
      chats[idx] = Chat(
        id: chat.id,
        name: chat.name,
        createdAt: chat.createdAt,
        messages: chat.messages,
        roleName: chat.roleName,
        rolePrompt: chat.rolePrompt,
        modelId: chat.modelId,
        modelName: chat.modelName,
        sentTokens: sent,
        receivedTokens: chat.receivedTokens,
      );
      if (currentChat.value?.id == chat.id) {
        currentChat.value = chats[idx];
      }
    }
    _storage.saveChats(chats);
    update();
    isLoading.value = true;
    
    try {
      final aiMsg = await _provider.sendMessage(
        text: text,
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        systemPrompt: currentChat.value!.rolePrompt,
        model: currentChat.value!.modelId,
        history: _resetHistoryForNextMessage ? [] : currentChat.value!.messages.where((m) => !m.isUser || m != userMsg).toList(),
      );
      _resetHistoryForNextMessage = false;
      currentChat.value!.messages.add(aiMsg);
      final idx2 = chats.indexWhere((c) => c.id == currentChat.value!.id);
      if (idx2 != -1) {
        final chat = chats[idx2];
        final received = (chat.receivedTokens ?? 0) + aiMsg.text.length;
        chats[idx2] = Chat(
          id: chat.id,
          name: chat.name,
          createdAt: chat.createdAt,
          messages: chat.messages,
          roleName: chat.roleName,
          rolePrompt: chat.rolePrompt,
          modelId: chat.modelId,
          modelName: chat.modelName,
          sentTokens: chat.sentTokens,
          receivedTokens: received,
        );
        if (currentChat.value?.id == chat.id) {
          currentChat.value = chats[idx2];
        }
      }
      _storage.saveChats(chats);
      update();
    } finally {
      isLoading.value = false;
    }
  }

  void refreshRoles() {
    _loadRoles();
  }

  Future<void> clearChat() async {
    if (currentChat.value == null) return;
    currentChat.value!.messages.clear();
    currentChat.value!.messages.add(Message(
      text: '**Модель:** ${currentChat.value!.modelName}\n**Роль:** ${currentChat.value!.roleName}\n\nНачните новый диалог!',
      isUser: false,
      createdAt: DateTime.now(),
    ));
    _storage.saveChats(chats);
    isLoading.value = false;
  }

  Future<void> setChatRole(PromptRole role) async {
    if (currentChat.value == null) return;
    final model = _settingsController.selectedModel;
    currentChat.value = Chat(
      id: currentChat.value!.id,
      name: currentChat.value!.name,
      createdAt: currentChat.value!.createdAt,
      messages: currentChat.value!.messages,
      roleName: role.name,
      rolePrompt: role.prompt,
      modelId: model?.id ?? _settingsController.selectedModelId.value,
      modelName: model?.name ?? _settingsController.selectedModelId.value,
    );
    // Обновляем в списке чатов
    final idx = chats.indexWhere((c) => c.id == currentChat.value!.id);
    if (idx != -1) {
      chats[idx] = currentChat.value!;
      _storage.saveChats(chats);
      update();
    }
    // Флаг для отправки следующего сообщения без истории
    _resetHistoryForNextMessage = true;
  }

  void renameChat(String chatId, String newName) {
    final idx = chats.indexWhere((c) => c.id == chatId);
    if (idx != -1 && newName.trim().isNotEmpty) {
      final chat = chats[idx];
      chats[idx] = Chat(
        id: chat.id,
        name: newName.trim(),
        createdAt: chat.createdAt,
        messages: chat.messages,
        roleName: chat.roleName,
        rolePrompt: chat.rolePrompt,
        modelId: chat.modelId,
        modelName: chat.modelName,
      );
      if (currentChat.value?.id == chatId) {
        currentChat.value = chats[idx];
      }
      _storage.saveChats(chats);
      update();
    }
  }
} 