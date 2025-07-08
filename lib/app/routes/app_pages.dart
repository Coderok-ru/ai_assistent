import 'package:get/get.dart';
import '../ui/pages/chat_page.dart';
import '../ui/pages/settings_page.dart';
import '../controllers/settings_controller.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.chat;

  static final pages = [
    GetPage(
      name: Routes.chat,
      page: () => const ChatPage(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController());
      }),
    ),
  ];
} 