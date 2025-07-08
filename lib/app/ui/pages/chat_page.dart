import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../controllers/chat_controller.dart';
import '../../../main.dart';
import 'profile_page.dart';
import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import 'about_page.dart';
import '../../data/models/chat.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:markdown/markdown.dart' as md;

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final FocusNode messageFocusNode = FocusNode();
    String? imageUrl;
    String? fileUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void showAttachmentDialog() {
      showDialog(
        context: context,
        builder: (context) {
          String? selectedType = 'image';
          urlController.clear();
          return AlertDialog(
            title: const Text('Добавить вложение'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('Изображение (URL)')),
                    DropdownMenuItem(value: 'file', child: Text('Файл (PDF, URL)')),
                  ],
                  onChanged: (val) {
                    selectedType = val;
                    (context as Element).markNeedsBuild();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: selectedType == 'image' ? 'URL изображения' : 'URL файла',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedType == 'image') {
                    imageUrl = urlController.text.trim();
                    fileUrl = null;
                  } else {
                    fileUrl = urlController.text.trim();
                    imageUrl = null;
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      );
    }

    return Obx(() =>
      GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                if (controller.selectedRole.value != null)
                  Text(
                    controller.selectedRole.value!.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            centerTitle: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(CupertinoIcons.chat_bubble),
                tooltip: 'Чаты',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              Obx(() {
                final chat = controller.currentChat.value;
                return IconButton(
                  icon: const Icon(CupertinoIcons.person),
                  tooltip: chat != null ? 'Роль: ${chat.roleName}' : 'Роль',
                  onPressed: () {
                    _showRoleSelector(context);
                  },
                );
              }),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(CupertinoIcons.ellipsis_vertical),
                  tooltip: 'Меню',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Obx(() => ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = controller.messages[controller.messages.length - 1 - index];
                          final isUser = msg.isUser;
                          final userBubbleColor = isDark ? AppColors.darkUserBubble : AppColors.lightUserBubble;
                          final aiBubbleColor = isDark ? AppColors.darkAiBubble : AppColors.lightAiBubble;
                          final userTextColor = isDark ? Colors.white : Colors.black87;
                          final aiTextColor = isDark ? Colors.white : Colors.black87;
                          final msgText = msg.text ?? '';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: !isUser && msgText.isNotEmpty
                                  ? () => _showMessageMenu(context, msgText)
                                  : null,
                              onTap: !isUser && msgText.isNotEmpty
                                  ? () => _showMessageMenu(context, msgText)
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isUser ? userBubbleColor : aiBubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(22),
                                    topRight: const Radius.circular(22),
                                    bottomLeft: Radius.circular(isUser ? 22 : 6),
                                    bottomRight: Radius.circular(isUser ? 6 : 22),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isUser
                                    ? Text(
                                        msgText,
                                        style: TextStyle(
                                          color: userTextColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : MarkdownBody(
                                        data: msgText,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            color: aiTextColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          code: TextStyle(
                                            backgroundColor: Colors.transparent,
                                            color: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF222222),
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.2,
                                          ),
                                          codeblockDecoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF23272F) : const Color(0xFFF5F5F7),
                                            borderRadius: BorderRadius.circular(7),
                                            border: Border.all(color: isDark ? const Color(0xFF444B5A) : const Color(0xFFE0E0E0)),
                                          ),
                                          codeblockPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      )),
                ),
                Obx(() => controller.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: TypingIndicator(),
                      )
                    : const SizedBox.shrink()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkUserBubble : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(CupertinoIcons.paperclip, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                          onPressed: showAttachmentDialog,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: textController,
                            focusNode: messageFocusNode,
                            minLines: 1,
                            maxLines: 4,
                            autofocus: false,
                            decoration: const InputDecoration(
                              hintText: 'Введите сообщение...',
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
                            onSubmitted: (value) {
                              _send(controller, textController, imageUrl, fileUrl);
                              messageFocusNode.unfocus();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.white),
                          onPressed: () {
                            _send(controller, textController, imageUrl, fileUrl);
                            messageFocusNode.unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Obx(() => Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAppBar : AppColors.lightAppBar,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(32),
                        bottomLeft: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Мои чаты',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Всего: ${controller.chats.length}',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.add_circled),
                          tooltip: 'Создать чат',
                          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          onPressed: () {
                            Navigator.of(context).pop();
                            controller.createChat();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: controller.chats.length,
                      separatorBuilder: (_, __) => _buildDivider(isDark),
                      itemBuilder: (context, index) {
                        final chat = controller.chats[index];
                        final isSelected = controller.currentChat.value?.id == chat.id;
                        return _ChatDrawerListItem(
                          chat: chat,
                          isSelected: isSelected,
                          onRename: (newName) => controller.renameChat(chat.id, newName),
                          onDelete: () => controller.deleteChat(chat.id),
                          onTap: () {
                            Navigator.pop(context);
                            controller.selectChat(chat.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              )),
            ),
          ),
          endDrawer: Drawer(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAppBar : AppColors.lightAppBar,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage('assets/main.jpg'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Assistent',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'coderok.ru',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.person_crop_circle,
                    text: 'Профиль',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const ProfilePage());
                    },
                  ),
                  _buildDivider(isDark),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.delete,
                    text: 'Очистить чат',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Удалить весь чат?',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Вы действительно хотите удалить все сообщения? Это действие необратимо.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Отмена'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          controller.clearChat();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Удалить', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.settings,
                    text: 'Настройки',
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed('/settings');
                    },
                  ),
                  _buildDivider(isDark),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.info,
                    text: 'О приложении',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const AboutPage());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  void _showRoleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, _) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Выберите роль',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.roles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Нет доступных ролей'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(CupertinoIcons.add),
                            label: const Text('Добавить'),
                            onPressed: () async {
                              Navigator.pop(context); // Закрываем диалог
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PromptEditPage()),
                              );
                              if (result == true) {
                                controller.refreshRoles();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final localScrollController = ScrollController();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: localScrollController,
                        itemCount: controller.roles.length + 1,
                        itemBuilder: (context, index) {
                          if (index < controller.roles.length) {
                            final role = controller.roles[index];
                            final isSelected = controller.selectedRole.value?.id == role.id;
                            return ListTile(
                              leading: Icon(
                                isSelected ? CupertinoIcons.check_mark_circled : CupertinoIcons.person,
                                color: isSelected ? Colors.green : Colors.grey,
                              ),
                              title: Text(role.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.prompt,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (role.role != null && role.role!.isNotEmpty)
                                    Text(
                                      'Роль: ${role.role}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                await controller.setChatRole(role);
                                controller.selectRole(role);
                                Navigator.pop(context);
                                Get.snackbar(
                                  'Роль выбрана',
                                  role.name,
                                  snackPosition: SnackPosition.TOP,
                                  margin: const EdgeInsets.all(16),
                                  backgroundColor: Colors.blue[50],
                                  colorText: Colors.black87,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              selected: isSelected,
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(CupertinoIcons.add),
                                  label: const Text('Создать роль'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Get.to(() => const ProfilePage());
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _send(ChatController controller, TextEditingController textController, String? imageUrl, String? fileUrl) {
    final text = textController.text.trim();
    if (text.isNotEmpty || (imageUrl != null && imageUrl.isNotEmpty) || (fileUrl != null && fileUrl.isNotEmpty)) {
      controller.sendMessage(text: text, imageUrl: imageUrl, fileUrl: fileUrl);
      textController.clear();
      imageUrl = null;
      fileUrl = null;
    }
  }

  void _showMessageMenu(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.doc_on_doc),
              title: const Text('Копировать'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                Get.snackbar(
                  'Скопировано',
                  'Текст скопирован в буфер обмена',
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  backgroundColor: Colors.green[50],
                  colorText: Colors.black87,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, Color? iconColor, Color? textColor, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? (isDark ? AppColors.darkAccent : AppColors.lightAccent)),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? (isDark ? AppColors.darkText : AppColors.lightText),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: (isDark ? AppColors.darkAiBubble : AppColors.lightAiBubble).withOpacity(0.2),
      splashColor: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  Widget _buildDivider(bool isDark) => Divider(
    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.08),
    height: 0,
    thickness: 1,
    indent: 16,
    endIndent: 16,
  );
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pencilAnimation;
  late Animation<double> _dotsAnimation;

  Color _accent(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    return accent.withOpacity(0.7);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _pencilAnimation = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _dotsAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDots(BuildContext context) {
    int dot = ((3 * _dotsAnimation.value) % 3).floor();
    final color = _accent(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) =>
        AnimatedOpacity(
          opacity: i <= dot ? 1.0 : 0.2,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Text(
              '.',
              style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          AnimatedBuilder(
            animation: _pencilAnimation,
            builder: (context, child) {
              return Baseline(
                baseline: 24,
                baselineType: TextBaseline.alphabetic,
                child: Transform.translate(
                  offset: Offset(_pencilAnimation.value, 0),
                  child: child,
                ),
              );
            },
            child: Icon(CupertinoIcons.pencil, color: accent, size: 28),
          ),
          const SizedBox(width: 10),
          Text(
            'Печатает',
            style: TextStyle(fontSize: 16, color: accent, fontWeight: FontWeight.w500),
          ),
          AnimatedBuilder(
            animation: _dotsAnimation,
            builder: (context, child) => _buildDots(context),
          ),
        ],
      ),
    );
  }
}

class _ChatDrawerListItem extends StatefulWidget {
  final Chat chat;
  final bool isSelected;
  final Function(String) onRename;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ChatDrawerListItem({
    required this.chat,
    required this.isSelected,
    required this.onRename,
    required this.onDelete,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<_ChatDrawerListItem> createState() => _ChatDrawerListItemState();
}

class _ChatDrawerListItemState extends State<_ChatDrawerListItem> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.chat.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getShortModelName(Chat chat) {
    if (chat.modelId.isNotEmpty && chat.modelId.contains('/')) {
      return chat.modelId.split('/').last;
    }
    return chat.modelId.isNotEmpty ? chat.modelId : chat.modelName;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String getChatTitle(Chat chat) {
      final firstUserMsg = chat.messages.firstWhereOrNull((m) => m.isUser && m.text.trim().isNotEmpty);
      if (firstUserMsg != null) {
        final text = firstUserMsg.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        return text.length > 40 ? text.substring(0, 40) + '…' : text;
      }
      return chat.roleName;
    }
    return ListTile(
      title: isEditing
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) widget.onRename(value.trim());
                      setState(() => isEditing = false);
                    },
                    onEditingComplete: () {
                      if (_controller.text.trim().isNotEmpty) widget.onRename(_controller.text.trim());
                      setState(() => isEditing = false);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.check_mark),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) widget.onRename(_controller.text.trim());
                    setState(() => isEditing = false);
                  },
                ),
              ],
            )
          : Text(getChatTitle(widget.chat), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Роль: ${widget.chat.roleName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          Text('Модель: ${getShortModelName(widget.chat)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          if ((widget.chat.sentTokens ?? 0) > 0)
            Text('Отправлено ${widget.chat.sentTokens ?? 0} токенов', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if ((widget.chat.receivedTokens ?? 0) > 0)
            Text('Получено ${widget.chat.receivedTokens ?? 0} токенов', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: isEditing
          ? null
          : PopupMenuButton<String>(
              icon: const Icon(CupertinoIcons.ellipsis_vertical),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'rename') {
                  setState(() => isEditing = true);
                } else if (value == 'delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
              ],
            ),
      selected: widget.isSelected,
      onTap: widget.onTap,
    );
  }
} 