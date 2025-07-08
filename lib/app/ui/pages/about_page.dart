import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cupertino_icons/cupertino_icons.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.2';
        final buildNumber = snapshot.data?.buildNumber ?? '3';
        return Scaffold(
          appBar: AppBar(title: const Text('О приложении')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/main.jpg',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Assistent - Coderok',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Версия: $version  |  Сборка: $buildNumber',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'AI Assistent — это современное приложение для общения с искусственным интеллектом на базе OpenRouter. Поддерживает различные роли, быстрый обмен сообщениями, хранение истории и удобный интерфейс.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Возможности:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Общение с ИИ на русском языке\n'
                  '• Мультироли и настройка собственных промтов\n'
                  '• Мультимодели LLM\n'
                  '• Мультичаты: несколько независимых диалогов\n'
                  '• Сохранение и восстановление истории чата\n'
                  '• Переименование и удаление чатов\n'
                  '• Поддержка светлой и тёмной темы\n'
                  '• Подсчёт токенов (отправлено/получено)\n',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Разработчик: Андрей Любиченко\n'
                  'Сайт: coderok.ru\n'
                  'Telegram: @coderok_official',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Помощь по API-ключам',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Для работы приложения необходим API-ключ OpenRouter. Получить и оплатить ключ можно на сайте openrouter.ai.\n'
                  'Если возникли сложности с получением или оплатой ключа — разработчик готов проконсультировать и помочь лично! Просто напишите в Telegram или на сайте.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.paperplane),
                  label: const Text('Написать в Telegram'),
                  onPressed: () async {
                    final url = Uri.parse('https://t.me/coderok_official');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 