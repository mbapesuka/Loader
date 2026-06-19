import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- VANTHRA Security Theme Constants ---
const Color kPrimaryColor = Color(0xFFB8B8CC); // Glowing Silver
const Color kAccentColor = Colors.redAccent; // Adult Indicator Color
const Color kBackgroundColor = Color(0xFF070709); // Deep Dark
const Color kCardColor = Color(0xFF111118); // Dark Grey Cards
const Color kHighlightColor = Color(0xFF161620); // Shimmer Highlight

class HomeHentaiPage extends StatefulWidget {
  const HomeHentaiPage({super.key});

  @override
  State<HomeHentaiPage> createState() => _HomeHentaiPageState();
}

class _HomeHentaiPageState extends State<HomeHentaiPage> {
  Map<String, dynamic>? contentData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    fetchContentData();
    _loadWatchHistory();
  }

  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('hentai_watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> fetchContentData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          contentData = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> searchContent(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/search/$query'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = jsonData['data']['animeList'] ?? [];
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 3, height: 18,
              decoration: BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: kAccentColor.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'X-HUB',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Rajdhani',
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.2),
              border: Border.all(color: kAccentColor),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Text("18+", style: TextStyle(color: kAccentColor, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
              decoration: InputDecoration(
                hintText: "Search content...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Rajdhani'),
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: kPrimaryColor),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchContent(value);
                } else {
                  setState(() {
                    isSearching = false;
                    searchResults.clear();
                  });
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchContent(value);
                }
              },
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                    ? _buildSearchResults()
                    : contentData == null
                        ? _buildErrorWidget()
                        : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          fetchContentData(),
          _loadWatchHistory(),
        ]);
      },
      color: kPrimaryColor,
      backgroundColor: kCardColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watch History Section
            _buildSectionHeader(Icons.history, "WATCH HISTORY"),
            const SizedBox(height: 12),

            if (_isHistoryLoading)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: kCardColor,
                        highlightColor: kHighlightColor,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_watchHistory.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                ),
                child: const Text(
                  "No watch history yet.\nStart streaming!",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Rajdhani'
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final content = _watchHistory[index];
                    return _buildHistoryCard(content);
                  },
                ),
              ),

            // Quick Access Section
            _buildSectionHeader(Icons.dashboard, "QUICK ACCESS"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    "Tags & Genres",
                    Icons.local_offer,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HentaiGenreListPage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    "Schedule",
                    Icons.schedule,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HentaiSchedulePage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ongoing Section
            _buildSectionHeader(Icons.live_tv, "CURRENTLY AIRING"),
            const SizedBox(height: 12),
            _buildContentGrid(contentData!['ongoing']['animeList'] ?? []),
            const SizedBox(height: 24),

            // Complete Section
            _buildSectionHeader(Icons.check_circle, "COMPLETED SERIES"),
            const SizedBox(height: 12),
            _buildContentGrid(contentData!['completed']['animeList'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Rajdhani',
            color: kPrimaryColor,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> content) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (content['last_watched_episode_slug'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HentaiEpisodePage(
                  episodeSlug: content['last_watched_episode_slug'],
                  contentSlug: content['slug'],
                  contentTitle: content['title'],
                  contentPoster: content['poster'],
                  onHistoryUpdate: refreshHistory, 
                ),
              ),
            ).then((_) => refreshHistory());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HentaiDetailPage(
                  slug: content['slug'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    content['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 120,
                      color: kCardColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: kAccentColor, width: 1),
                    ),
                    child: const Icon(Icons.play_arrow, color: kAccentColor, size: 16),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Text(
                      content['last_watched_episode'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content['title'],
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text("No results found", style: TextStyle(color: Colors.grey, fontFamily: 'Rajdhani', fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final content = searchResults[index];
        return _buildSearchResultCard(content);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> content) {
    final String title = content['title'];
    final String poster = content['poster'];
    final String? status = content['status'];
    final String? score = content['score'];
    final String slug = content['animeId']; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HentaiDetailPage(
                slug: slug,
                onHistoryUpdate: refreshHistory,
              ),
            ),
          ).then((_) => refreshHistory());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  poster,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80, height: 120, color: kHighlightColor,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (score != null && score.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(score, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (status != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.black, fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return kAccentColor; 
      case 'completed':
        return kPrimaryColor; 
      default:
        return Colors.grey;
    }
  }

  Widget _buildContentGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final content = list[index];
        final String title = content['title'];
        final String poster = content['poster'];
        final String? episode = content['episodes']?.toString();
        final String slug = content['animeId'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HentaiDetailPage(
                  slug: slug,
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          },
          child: Container(
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    poster,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170, color: kCardColor,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        episode != null ? "EP $episode" : "-",
                        style: const TextStyle(fontSize: 11, fontFamily: 'Rajdhani', color: kAccentColor, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.play_circle_fill, color: kPrimaryColor, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisExtent: 260, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: kCardColor,
        highlightColor: kHighlightColor,
        child: Container(
          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text("Failed to load data", style: TextStyle(color: Colors.grey, fontFamily: 'Rajdhani', fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Future.wait([fetchContentData(), _loadWatchHistory()]);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.black),
            child: const Text("Try Again", style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class HentaiDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate; 

  const HentaiDetailPage({super.key, required this.slug, this.onHistoryUpdate});

  @override
  State<HentaiDetailPage> createState() => _HentaiDetailPageState();
}

class _HentaiDetailPageState extends State<HentaiDetailPage> {
  Map<String, dynamic>? detail;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          detail = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; isError = true; });
      }
    } catch (e) {
      setState(() { isLoading = false; isError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        title: const Text(
          "CONTENT DETAILS",
          style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Rajdhani', color: Colors.white, letterSpacing: 2),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : isError || detail == null
              ? const Center(child: Text("Failed to load details.", style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani')))
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final content = detail!;
    final List<dynamic> episodes = content['episodeList'] ?? [];
    final List<dynamic> recommendations = content['recommendedAnimeList'] ?? [];
    final List<dynamic> genres = content['genreList'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  content['poster'],
                  height: 220,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(content['score'] ?? '-', style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('Status', content['status']),
                    _buildInfoItem('Episodes', content['episodes']?.toString()),
                    _buildInfoItem('Duration', content['duration']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text("SYNOPSIS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', color: kPrimaryColor, letterSpacing: 2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimaryColor.withOpacity(0.1))),
            child: Text(
              content['synopsis']?['paragraphs']?.join('\n\n') ?? '-',
              style: const TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          if (episodes.isNotEmpty) ...[
            const Text("EPISODES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', color: kPrimaryColor, letterSpacing: 2)),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final ep = episodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimaryColor.withOpacity(0.1))),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(ep['eps'].toString(), style: const TextStyle(color: kPrimaryColor, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold))),
                    ),
                    title: Text(ep['title'], style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani')),
                    trailing: const Icon(Icons.play_circle_fill, color: kAccentColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HentaiEpisodePage(
                            episodeSlug: ep['episodeId'],
                            contentSlug: widget.slug,
                            contentTitle: content['title'],
                            contentPoster: content['poster'],
                            episodes: episodes,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) { if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!(); });
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey, fontFamily: 'Rajdhani', fontSize: 12)),
            TextSpan(text: value ?? '-', style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ---------------- EPISODE / PLAYER PAGE ----------------
class HentaiEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? contentSlug;
  final String? contentTitle;
  final String? contentPoster;
  final List<dynamic>? episodes;
  final List<dynamic>? recommendations;
  final Function()? onHistoryUpdate; 

  const HentaiEpisodePage({
    super.key, required this.episodeSlug, this.contentSlug, this.contentTitle,
    this.contentPoster, this.episodes, this.recommendations, this.onHistoryUpdate,
  });

  @override
  State<HentaiEpisodePage> createState() => _HentaiEpisodePageState();
}

class _HentaiEpisodePageState extends State<HentaiEpisodePage> with WidgetsBindingObserver {
  Map<String, dynamic>? episodeData;
  bool isLoading = true;
  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;
  String? _streamUrl;
  List<dynamic> _qualities = [];
  int _selectedQualityIndex = 0;
  int _selectedServerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEpisodeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> fetchEpisodeData() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          episodeData = jsonData['data'];
          _qualities = episodeData?['server']?['qualities'] ?? [];
        });
        await _fetchStreamUrl();
        _initializeWebView();
        _addToWatchHistory();
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchStreamUrl() async {
    if (_qualities.isEmpty) return;
    final serverId = _qualities[_selectedQualityIndex]['serverList'][_selectedServerIndex]['serverId'];
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/server/$serverId'));
      if (response.statusCode == 200) {
        setState(() => _streamUrl = json.decode(response.body)['data']['url']);
      }
    } catch (e) {
      debugPrint('Stream URL error: $e');
    }
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('hentai_watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson.map((item) => Map<String, dynamic>.from(json.decode(item))).toList();
      final historyItem = {
        'slug': widget.contentSlug,
        'title': widget.contentTitle,
        'poster': widget.contentPoster,
        'last_watched_episode': episodeData?['title'],
        'last_watched_episode_slug': widget.episodeSlug,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      watchHistory.removeWhere((item) => item['slug'] == widget.contentSlug);
      watchHistory.insert(0, historyItem);
      if (watchHistory.length > 20) watchHistory = watchHistory.sublist(0, 20);
      await prefs.setStringList('hentai_watch_history', watchHistory.map((item) => json.encode(item)).toList());
      if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
    } catch (e) {}
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => setState(() => _isWebViewLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(_streamUrl!), headers: {'Referer': 'https://www.sankavollerei.com/'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _isFullScreen ? null : AppBar(
        backgroundColor: Colors.black,
        title: Text(episodeData?['title'] ?? "Streaming", style: const TextStyle(fontFamily: 'Rajdhani', color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: kAccentColor))
          : Column(
              children: [
                Container(
                  height: _isFullScreen ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      if (_streamUrl != null) WebViewWidget(controller: _webViewController),
                      if (_isWebViewLoading) const Center(child: CircularProgressIndicator(color: kAccentColor)),
                    ],
                  ),
                ),
                if (!_isFullScreen) Expanded(
                  child: Container(
                    color: kBackgroundColor,
                    child: Center(
                      child: Text("Enjoy the content.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani')),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}

// ---------------- ADDITIONAL PAGES (GENRE & SCHEDULE) ----------------
class HentaiGenreListPage extends StatefulWidget {
  const HentaiGenreListPage({super.key});
  @override State<HentaiGenreListPage> createState() => _HentaiGenreListPageState();
}

class _HentaiGenreListPageState extends State<HentaiGenreListPage> {
  List<dynamic> genreList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGenreList();
  }

  Future<void> _fetchGenreList() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/genre/'));
      if (response.statusCode == 200) {
        setState(() {
          genreList = json.decode(response.body)['data']['genreList'];
          isLoading = false;
        });
      }
    } catch (_) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, title: const Text("TAGS & GENRES", style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, color: Colors.white))),
      body: isLoading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor)) : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: genreList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 3.0),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: kAccentColor.withOpacity(0.2))),
            alignment: Alignment.center,
            child: Text(genreList[index]['title'], style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}

class HentaiSchedulePage extends StatefulWidget {
  const HentaiSchedulePage({super.key});
  @override State<HentaiSchedulePage> createState() => _HentaiSchedulePageState();
}

class _HentaiSchedulePageState extends State<HentaiSchedulePage> {
  List<dynamic> scheduleData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/schedule'));
      if (response.statusCode == 200) {
        setState(() {
          scheduleData = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (_) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, title: const Text("RELEASE SCHEDULE", style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, color: Colors.white))),
      body: isLoading ? const Center(child: CircularProgressIndicator(color: kPrimaryColor)) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scheduleData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text("${scheduleData[index]['day']} - ${scheduleData[index]['anime_list'].length} Updates", style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 16)),
          );
        },
      ),
    );
  }
}

// Komponen Reusable
Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimaryColor.withOpacity(0.1))),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: kAccentColor, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}