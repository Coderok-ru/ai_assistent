import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../data/storage/prompt_storage.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  double? credits;
  double? usage;
  String? error;
  List<PromptRole> prompts = [];
  int? activePromptId;
  bool loadingPrompts = true;
  bool loadingCredits = true;

  @override
  void initState() {
    super.initState();
    _loadCredits();
    _loadPrompts();
  }

  SettingsController get settingsController {
    if (Get.isRegistered<SettingsController>()) {
      return Get.find<SettingsController>();
    } else {
      return Get.put(SettingsController());
    }
  }

  Future<void> _loadCredits() async {
    setState(() { loadingCredits = true; error = null; });
    try {
      final apiKey = settingsController.apiKey.value;
      final dio = Dio();
      final response = await dio.get(
        'https://openrouter.ai/api/v1/credits',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      final data = response.data['data'];
      setState(() {
        credits = (data['total_credits'] as num?)?.toDouble();
        usage = (data['total_usage'] as num?)?.toDouble();
        loadingCredits = false;
      });
    } catch (e) {
      setState(() {
        error = 'Ошибка загрузки баланса: $e';
        loadingCredits = false;
      });
    }
  }

  Future<void> _loadPrompts() async {
    setState(() { loadingPrompts = true; });
    final list = await PromptStorage.loadPrompts();
    final active = await PromptStorage.getActivePrompt();
    setState(() {
      prompts = list;
      activePromptId = active?.id;
      loadingPrompts = false;
    });
  }

  Future<void> _addOrEditPrompt([PromptRole? prompt]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PromptEditPage(prompt: prompt)),
    );
    if (result == true) {
      _loadPrompts();
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().refreshRoles();
      }
    }
  }

  Future<void> _deletePrompt(int id) async {
    await PromptStorage.deletePrompt(id);
    _loadPrompts();
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().refreshRoles();
    }
  }

  Future<void> _setActivePrompt(int id) async {
    await PromptStorage.setActivePrompt(id);
    _loadPrompts();
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().refreshRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? remaining = (credits != null && usage != null) ? (credits! - usage!) : null;
    final apiKey = settingsController.apiKey.value;
    final showBalance = apiKey.isNotEmpty && error == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.person_crop_circle, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: loadingCredits
                    ? const LinearProgressIndicator()
                    : error != null || apiKey.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Всего: ${credits != null ? credits!.toStringAsFixed(2) + ' \$' : '--'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Израсходовано: ${usage != null ? usage!.toStringAsFixed(2) + ' \$' : '--'}'),
                              Text('Остаток: ${remaining != null ? remaining.toStringAsFixed(2) + ' \$' : '--'}'),
                            ],
                          ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.refresh),
                onPressed: _loadCredits,
                tooltip: 'Обновить баланс',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Промты и роли', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.add),
                tooltip: 'Добавить промт',
                onPressed: () => _addOrEditPrompt(),
              ),
            ],
          ),
          loadingPrompts
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              : prompts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Нет сохранённых промтов'),
                    )
                  : Column(
                      children: prompts.map((p) => Card(
                        color: p.id == activePromptId
                            ? (isDark ? const Color(0xFF162033) : Colors.blue[50])
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Row(
                                  children: [
                                    if (p.isSystem)
                                      const Icon(CupertinoIcons.shield, color: Colors.blue, size: 18),
                                    if (p.isSystem)
                                      const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: TextStyle(
                                          color: p.isSystem ? Colors.blue : Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.prompt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (p.role != null && p.role!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Роль: ${p.role}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (p.id != null && p.id != activePromptId)
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.check_mark),
                                        tooltip: 'Сделать активным',
                                        onPressed: () => _setActivePrompt(p.id!),
                                      ),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.pencil),
                                      tooltip: 'Редактировать',
                                      onPressed: () => _addOrEditPrompt(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.doc_on_doc),
                                      tooltip: 'Копировать',
                                      onPressed: () async {
                                        await PromptStorage.savePrompt(PromptRole(
                                          name: p.name + ' (копия)',
                                          prompt: p.prompt,
                                          role: p.role,
                                          isActive: false,
                                        ));
                                        _loadPrompts();
                                        if (Get.isRegistered<ChatController>()) {
                                          Get.find<ChatController>().refreshRoles();
                                        }
                                      },
                                    ),
                                    if (p.id != null)
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.delete),
                                        tooltip: 'Удалить',
                                        onPressed: () => _deletePrompt(p.id!),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
        ],
      ),
    );
  }
}

class PromptEditPage extends StatefulWidget {
  final PromptRole? prompt;
  const PromptEditPage({super.key, this.prompt});

  @override
  State<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends State<PromptEditPage> {
  late final TextEditingController nameController;
  late final TextEditingController promptController;
  late final TextEditingController roleController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.prompt?.name ?? '');
    promptController = TextEditingController(text: widget.prompt?.prompt ?? '');
    roleController = TextEditingController(text: widget.prompt?.role ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    promptController.dispose();
    roleController.dispose();
    super.dispose();
  }

  InputDecoration getInputDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF888888), width: 1.2),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.prompt == null ? 'Создать промт' : 'Редактировать промт')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: getInputDecoration('Название'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: promptController,
              decoration: getInputDecoration('Промт'),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: roleController,
              decoration: getInputDecoration('Роль (опционально)'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || promptController.text.trim().isEmpty) return;
                await PromptStorage.savePrompt(PromptRole(
                  id: widget.prompt?.id,
                  name: nameController.text.trim(),
                  prompt: promptController.text.trim(),
                  role: roleController.text.trim().isEmpty ? null : roleController.text.trim(),
                  isActive: widget.prompt?.isActive ?? false,
                ));
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
} 