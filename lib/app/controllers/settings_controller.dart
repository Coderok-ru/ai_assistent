import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../data/storage/model_storage.dart';

class AiModelInfo {
  final String id;
  final String name;
  final double priceInput;
  final double priceOutput;
  final int context;

  AiModelInfo({
    required this.id,
    required this.name,
    required this.priceInput,
    required this.priceOutput,
    required this.context,
  });

  bool get isFree => id.contains(':free') || name.toLowerCase().contains('free');
}

class SettingsController extends GetxController {
  final _box = GetStorage();
  final apiKey = ''.obs;
  final themeMode = ''.obs; // 'light', 'dark', 'system'

  final models = <AiModelInfo>[].obs;
  final selectedModelId = ''.obs;
  final isLoadingModels = false.obs;
  final modelsError = ''.obs;

  static const String defaultApiKey = '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';

  bool get isDefaultKeyUsed => apiKey.value.isEmpty;
  String get effectiveApiKey => apiKey.value.isNotEmpty ? apiKey.value : defaultApiKey;

  AiModelInfo? get selectedModel =>
      models.firstWhereOrNull((m) => m.id == selectedModelId.value);

  List<AiModelInfo> get freeModels =>
      models.where((m) => m.isFree).toList()..sort((a, b) => a.name.compareTo(b.name));
  List<AiModelInfo> get paidModels =>
      models.where((m) => !m.isFree).toList()..sort((a, b) => a.name.compareTo(b.name));

  List<AiModelInfo> get visibleModels => isDefaultKeyUsed ? freeModels : models;

  @override
  void onInit() {
    super.onInit();
    apiKey.value = _box.read('apiKey') ?? '';
    themeMode.value = _box.read('themeMode') ?? 'system';
    _initModels();
  }

  Future<void> _initModels() async {
    isLoadingModels.value = true;
    modelsError.value = '';
    try {
      // 1. Пробуем загрузить из SQLite
      final cached = await ModelStorage.loadModels();
      if (cached.isNotEmpty) {
        models.assignAll(_sortModels(cached));
      }
      final selected = await ModelStorage.loadSelectedModel();
      if (selected != null) {
        selectedModelId.value = selected;
      } else if (models.isNotEmpty) {
        selectedModelId.value = models.first.id;
      }
      // 2. Загружаем с OpenRouter API
      await fetchModelsFromApi();
    } catch (e) {
      modelsError.value = 'Ошибка загрузки моделей: $e';
    } finally {
      isLoadingModels.value = false;
    }
  }

  Future<void> fetchModelsFromApi() async {
    final dio = Dio();
    final response = await dio.get(
      'https://openrouter.ai/api/v1/models',
      options: Options(
        headers: {
          if (effectiveApiKey.isNotEmpty) 'Authorization': 'Bearer 27$effectiveApiKey',
        },
      ),
    );
    final data = response.data['data'] as List;
    final loaded = data.map((m) => AiModelInfo(
      id: m['id'],
      name: m['name'] ?? m['id'],
      priceInput: double.tryParse(m['pricing']?['prompt'] ?? '0') ?? 0,
      priceOutput: double.tryParse(m['pricing']?['completion'] ?? '0') ?? 0,
      context: m['context_length'] ?? 0,
    )).toList();
    models.assignAll(_sortModels(loaded));
    await ModelStorage.saveModels(loaded);
    if (selectedModelId.value.isEmpty || !models.any((m) => m.id == selectedModelId.value)) {
      selectedModelId.value = models.isNotEmpty ? models.first.id : '';
      await ModelStorage.saveSelectedModel(selectedModelId.value);
    }
  }

  List<AiModelInfo> _sortModels(List<AiModelInfo> list) {
    final free = list.where((m) => m.isFree).toList()..sort((a, b) => a.name.compareTo(b.name));
    final paid = list.where((m) => !m.isFree).toList()..sort((a, b) => a.name.compareTo(b.name));
    return [...free, ...paid];
  }

  void saveApiKey(String key) {
    apiKey.value = key;
    _box.write('apiKey', key);
    if (key.isEmpty && freeModels.isNotEmpty) {
      selectModel(freeModels.first.id);
    }
  }

  void selectModel(String id) async {
    selectedModelId.value = id;
    await ModelStorage.saveSelectedModel(id);
  }

  void setThemeMode(String mode) {
    themeMode.value = mode;
    _box.write('themeMode', mode);
  }
} 