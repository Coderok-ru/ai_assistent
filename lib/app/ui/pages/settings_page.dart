import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import 'package:flutter/cupertino.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController apiKeyController = TextEditingController(text: controller.apiKey.value);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('API-ключ'),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                hintText: 'Введите API-ключ',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF888888), width: 1.2),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.saveApiKey(apiKeyController.text.trim());
                Get.snackbar('Сохранено', 'API-ключ сохранён', snackPosition: SnackPosition.TOP);
              },
              child: const Text('Сохранить'),
            ),
            const SizedBox(height: 32),
            const Text('Тема', style: TextStyle(fontWeight: FontWeight.bold)),
            Obx(() => Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Светлая'),
                      selected: controller.themeMode.value == 'light',
                      onSelected: (_) => controller.setThemeMode('light'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Тёмная'),
                      selected: controller.themeMode.value == 'dark',
                      onSelected: (_) => controller.setThemeMode('dark'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Системная'),
                      selected: controller.themeMode.value == 'system',
                      onSelected: (_) => controller.setThemeMode('system'),
                    ),
                  ],
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Модель', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Obx(() => controller.isLoadingModels.value
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(CupertinoIcons.refresh),
                        tooltip: 'Обновить список моделей',
                        onPressed: controller.fetchModelsFromApi,
                      )),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              final modelsError = controller.modelsError.value;
              final models = controller.visibleModels;
              final selected = controller.selectedModel;
              if (controller.isLoadingModels.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (modelsError.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      modelsError,
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }
              if (models.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Нет доступных моделей',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  selected != null
                    ? GestureDetector(
                        onTap: () async {
                          final result = await Get.to<String>(() => const ModelSelectPage());
                          if (result != null) controller.selectModel(result);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(top: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(selected.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('ID: ${selected.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('Цена (ввод): ${selected.priceInput}/M токенов'),
                                Text('Цена (вывод): ${selected.priceOutput}/M токенов'),
                                Text('Контекст: ${selected.context} токенов'),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListTile(
                        title: const Text('Выбрать модель'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await Get.to<String>(() => const ModelSelectPage());
                          if (result != null) controller.selectModel(result);
                        },
                      ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ModelSelectPage extends GetView<SettingsController> {
  const ModelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RxString query = ''.obs;
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор модели')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по названию...',
                prefixIcon: Icon(CupertinoIcons.search),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF888888), width: 1.2),
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onChanged: (val) => query.value = val.trim().toLowerCase(),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.modelsError.isNotEmpty) {
                return Center(child: Text(controller.modelsError.value, style: const TextStyle(color: Colors.red)));
              }
              if (controller.isLoadingModels.value && controller.models.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.models.isEmpty) {
                return const Center(child: Text('Нет доступных моделей'));
              }
              final filter = query.value;
              final free = filter.isEmpty
                  ? controller.freeModels
                  : controller.freeModels.where((m) => m.name.toLowerCase().contains(filter)).toList();
              final paid = filter.isEmpty
                  ? controller.paidModels
                  : controller.paidModels.where((m) => m.name.toLowerCase().contains(filter)).toList();
              return ListView(
                children: [
                  if (free.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16, bottom: 4),
                      child: Text(
                        'Бесплатные',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ...free.map((m) => ListTile(
                          title: Text(
                            m.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Text('ID: ${m.id}', style: const TextStyle(fontSize: 12)),
                          trailing: controller.selectedModelId.value == m.id
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: () => Get.back(result: m.id),
                          selected: controller.selectedModelId.value == m.id,
                        )),
                  ],
                  if (paid.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, bottom: 4),
                      child: Text(
                        'Платные',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (controller.isDefaultKeyUsed)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Text(
                          'Для доступа к платным моделям введите свой API-ключ',
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                    ...paid.map((m) => ListTile(
                          title: Text(
                            m.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: controller.isDefaultKeyUsed
                                ? const TextStyle(color: Colors.grey)
                                : null,
                          ),
                          subtitle: Text('ID: ${m.id}', style: const TextStyle(fontSize: 12)),
                          trailing: controller.selectedModelId.value == m.id
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: controller.isDefaultKeyUsed
                              ? null
                              : () => Get.back(result: m.id),
                          selected: controller.selectedModelId.value == m.id,
                          enabled: !controller.isDefaultKeyUsed,
                        )),
                  ],
                  if (free.isEmpty && paid.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Совпадений не найдено')),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
} 