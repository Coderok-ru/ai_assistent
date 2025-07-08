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
              final apiKey = controller.apiKey.value;
              final modelsError = controller.modelsError.value;
              if (apiKey.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Введите API-ключ для выбора модели',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }
              if (modelsError.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          modelsError,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: controller.fetchModelsFromApi,
                      child: const Text('Обновить список моделей'),
                    ),
                  ],
                );
              }
              final model = controller.selectedModel;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final selected = await Get.to<String>(() => const ModelSelectPage());
                      if (selected != null) controller.selectModel(selected);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            model?.name ?? 'Выбрать модель',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(CupertinoIcons.right_chevron, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (model != null)
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 8),
                              Text('ID: ${model.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text('Цена (ввод): ${model.priceInput}/M токенов'),
                              Text('Цена (вывод): ${model.priceOutput}/M токенов'),
                              Text('Контекст: ${model.context} токенов'),
                            ],
                          ),
                        ),
                      ),
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
                    const Padding(
                      padding: EdgeInsets.only(top: 8, left: 16, bottom: 4),
                      child: Text('Бесплатные', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Padding(
                      padding: EdgeInsets.only(top: 16, left: 16, bottom: 4),
                      child: Text('Платные', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...paid.map((m) => ListTile(
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