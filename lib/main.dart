import 'package:flutter/material.dart';

void main() {
  runApp(NewsApp());
}

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Новости',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: NewsGridPage(),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String imageUrl;
  final String content;

  NewsItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.content,
  });
}

class NewsGridPage extends StatelessWidget {
  final List<NewsItem> news = [
    NewsItem(
      title: 'Flutter 3.24 выпущен!',
      description: 'Новая версия Flutter уже доступна.',
      imageUrl: 'https://technobrains.io/wp-content/uploads/2021/07/flutter-Featured-Blog-Image2.jpg',
      content:
      'Flutter 3.24 привносит множество улучшений производительности и поддержку новых платформ. '
          'Теперь Flutter ещё более стабилен и готов к производству приложений.',
    ),
    NewsItem(
      title: 'Google представил новый Android 15',
      description: 'Android 15 делает акцент на приватность.',
      imageUrl: 'https://bumper-stickers.ru/49542/android-pisaet-na-apl.jpg',
      content:
      'Android 15 улучшает управление разрешениями, оптимизацию работы приложений и энергоэффективность. '
          'Ожидается, что релиз состоится в конце года.',
    ),
    NewsItem(
      title: 'ИИ помогает писать код',
      description: 'Новые технологии ускоряют разработку.',
      imageUrl: 'https://dknews.kz/storage/news/2024-03/kjWGUGu9BHfpOrFABIg6uEYBlJnlgQFgIxTi1980.jpg',
      content:
      'Современные инструменты на базе искусственного интеллекта помогают программистам писать код быстрее и точнее. '
          'Будущее разработки меняется на глазах.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новости'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: news.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // две новости в ряд
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.8, // пропорции карточки
          ),
          itemBuilder: (context, index) {
            final item = news[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailPage(news: item),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.description,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final NewsItem news;

  const NewsDetailPage({required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(news.imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              news.content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
