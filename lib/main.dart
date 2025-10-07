import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

void main() {
  runApp(NewsApp());
}

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Новостной агрегатор',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: NewsHomePage(),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;

  NewsItem({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    this.pubDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NewsItem &&
              runtimeType == other.runtimeType &&
              title == other.title &&
              link == other.link;

  @override
  int get hashCode => title.hashCode ^ link.hashCode;
}

class NewsHomePage extends StatefulWidget {
  @override
  _NewsHomePageState createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final List<String> rssUrls = [
    'https://ria.ru/export/rss2/archive/index.xml',
    'https://lenta.ru/rss',
  ];

  List<NewsItem> allNews = [];
  List<NewsItem> favorites = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAllNews();
  }

  Future<void> fetchAllNews() async {
    setState(() => isLoading = true);
    List<NewsItem> loadedNews = [];

    for (String url in rssUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final feed = RssFeed.parse(response.body);
          for (var item in feed.items!) {
            final imageUrl = _extractImageUrl(item.description ?? '');
            loadedNews.add(NewsItem(
              title: item.title ?? 'Без названия',
              description: item.description ?? '',
              link: item.link ?? '',
              imageUrl: imageUrl,
              pubDate: item.pubDate,
            ));
          }
        }
      } catch (e) {
        print('Ошибка при загрузке $url: $e');
      }
    }

    setState(() {
      allNews = loadedNews;
      isLoading = false;
    });
  }

  String? _extractImageUrl(String html) {
    final regex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = regex.firstMatch(html);
    return match?.group(1);
  }

  void toggleFavorite(NewsItem item) {
    setState(() {
      favorites.contains(item) ? favorites.remove(item) : favorites.add(item);
    });
  }

  // Функция для удаления HTML тегов
  String removeHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(regex, '');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Новостной агрегатор'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.article), text: 'Все'),
            Tab(icon: Icon(Icons.star), text: 'Избранное'),
          ]),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            NewsList(
              news: allNews,
              favorites: favorites,
              onFavoriteToggle: toggleFavorite,
              removeHtmlTags: removeHtmlTags,
            ),
            NewsList(
              news: favorites,
              favorites: favorites,
              onFavoriteToggle: toggleFavorite,
              removeHtmlTags: removeHtmlTags,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: fetchAllNews,
          tooltip: 'Обновить',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class NewsList extends StatelessWidget {
  final List<NewsItem> news;
  final List<NewsItem> favorites;
  final Function(NewsItem) onFavoriteToggle;
  final String Function(String) removeHtmlTags;

  const NewsList({
    required this.news,
    required this.onFavoriteToggle,
    required this.favorites,
    required this.removeHtmlTags,
  });

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const Center(child: Text('Новостей нет'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final item = news[index];
        final isFav = favorites.contains(item);

        return Card(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsDetailPage(
                    newsItem: item,
                    removeHtmlTags: removeHtmlTags,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                if (item.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      height: 180,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(
                          height: 180,
                          child: Center(child: Icon(Icons.broken_image))),
                    ),
                  ),
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    removeHtmlTags(item.description),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(isFav ? Icons.star : Icons.star_border),
                    onPressed: () => onFavoriteToggle(item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final NewsItem newsItem;
  final String Function(String) removeHtmlTags;

  const NewsDetailPage({
    required this.newsItem,
    required this.removeHtmlTags,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Дата неизвестна';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(newsItem.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newsItem.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  newsItem.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 180, child: Center(child: Icon(Icons.broken_image))),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              newsItem.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Опубликовано: ${_formatDate(newsItem.pubDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              removeHtmlTags(newsItem.description),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

