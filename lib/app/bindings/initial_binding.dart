import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/settings_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
} 