import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(NewsApp());
}

class NewsApp extends StatefulWidget {
  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    });
  }

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
      themeMode: _themeMode,
      home: NewsHomePage(
        onToggleTheme: toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;
  final String sourceName;

  NewsItem({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    this.pubDate,
    required this.sourceName,
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
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const NewsHomePage({
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  // Список пар (URL, название источника)
  final List<Map<String, String>> rssSources = [
    {
      'url': 'https://ria.ru/export/rss2/archive/index.xml',
      'name': 'RIA',
    },
    {
      'url': 'https://lenta.ru/rss',
      'name': 'Lenta',
    },
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
    setState(() {
      isLoading = true;
    });
    List<NewsItem> loadedNews = [];

    for (var source in rssSources) {
      final url = source['url']!;
      final sourceName = source['name']!;
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final feed = RssFeed.parse(response.body);
          for (var item in feed.items ?? []) {
            final imageUrl = _extractImageUrl(item.description ?? '');
            loadedNews.add(NewsItem(
              title: item.title ?? 'Без названия',
              description: item.description ?? '',
              link: item.link ?? '',
              imageUrl: imageUrl,
              pubDate: item.pubDate,
              sourceName: sourceName,
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
      if (favorites.contains(item)) {
        favorites.remove(item);
      } else {
        favorites.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.themeMode == ThemeMode.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Новостной агрегатор'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
              tooltip: 'Сменить тему',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.article), text: 'Все'),
              Tab(icon: Icon(Icons.star), text: 'Избранное'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            NewsList(
              news: allNews,
              favorites: favorites,
              onFavoriteToggle: toggleFavorite,
            ),
            NewsList(
              news: favorites,
              favorites: favorites,
              onFavoriteToggle: toggleFavorite,
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

  const NewsList({
    required this.news,
    required this.favorites,
    required this.onFavoriteToggle,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return months[month - 1];
  }

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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailPage(newsItem: item),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imageUrl != null)
                    Image.network(
                      item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      item.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Левый блок: дата и источник
                        if (item.pubDate != null)
                          Text(
                            '${_formatDate(item.pubDate)} · ${item.sourceName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => onFavoriteToggle(item),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewsDetailPage extends StatefulWidget {
  final NewsItem newsItem;

  const NewsDetailPage({required this.newsItem});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.newsItem.link));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.newsItem.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = Uri.parse(widget.newsItem.link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
