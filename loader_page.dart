// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

import 'telegram.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'ddos_page.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';
import 'ddos_panel.dart';
import 'sender_page.dart';
import 'spams_page.dart';
import 'public_page.dart';
import 'device_dashboard.dart';
import 'anime.dart';
import 'quran_tool.dart';
import 'tqto.dart';
import 'public_page.dart';
import 'testfunc.dart';
import 'larangan_pengguna.dart';
import 'music_player.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  WebSocketChannel? channel;

  VideoPlayerController? _videoController;
  VideoPlayerController? _statsVideoController;
  VideoPlayerController? _otaxVideoController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _backgroundMusicUrl = "https://k.top4top.io/m_375871wig1.m4a";

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listPayload;
  late List<Map<String, dynamic>> listDDoS;
  late List<dynamic> newsList;
  List<Map<String, String>> _governmentNews = [];
  bool _isLoadingGovernmentNews = false;
  String androidId = "unknown";

  int _onlineUsers = 0;
  int _activeConnections = 0;
  bool _hasServerStats = false;
  Timer? _statsTimer;

  int _selectedIndex = 0;
  Widget _selectedPage = const Placeholder();

  final GlobalKey _bugButtonKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentNewsIndex = 0;

  final PageController _actionPageController = PageController(viewportFraction: 0.92);
  int _currentActionIndex = 0;
  double _currentActionPage = 0.0;
  double _currentNewsPage = 0.0;

  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivityLogs = false;
  bool _hasActivityLogsError = false;

  Offset _assistiveTouchPosition = const Offset(20, 150);
  bool _isAssistiveMenuOpen = false;

  bool _isBugToolsExpanded = false;
  String _activePage = 'home';

  bool _showBottomNav = true;
  bool _showAssistiveTouch = true;
  bool _isMusicOn = false;

  // Data Anime dari API
  Map<String, dynamic>? animeData;
  bool _isLoadingAnime = true;
  
  // DATA JADWAL SHOLAT
  Map<String, Map<String, String>> _sholatTimes = {};
  bool _isLoadingSholat = false;
  String _nextPrayerName = "";
  String _nextPrayerTime = "";
  String _timeToNextPrayer = "";
  
  // ========== TAMBAHAN UNTUK CUACA & JAM ==========
List<Map<String, dynamic>> _weatherForecast = [];
bool _isLoadingWeather = false;
String _currentTime = "";



  Timer? _clockTimer;
  Timer? _countdownTimer;
  Timer? _hourlySholatTimer;

final Color _primaryPurple = const Color(0xFFD32F2F);
final Color _glowLight = const Color(0xFF00BFFF);
final Color _darkBg = const Color(0xFF0A0A0A);
final Color _darkerBg = const Color(0xFF050505);
final Color _surfaceColor = const Color(0xFF1A1A1A);
final Color _cardColor = const Color(0xFF111111);   
final Color _textWhite = const Color(0xFFFFFFFF);         
final Color _textGrey = const Color(0xFF888888);          
final Color _primaryColor = const Color(0xFFD32F2F);      
final Color _secondaryColor = const Color(0xFF00BFFF);    
final Color _accentColor = const Color(0xFFD32F2F);      
final Color _successColor = const Color(0xFF00BFFF);      
final Color _warningColor = const Color(0xFFD32F2F);      
final Color _glowColor1 = const Color(0xFFD32F2F);        
final Color _glowColor2 = const Color(0xFF00BFFF);        
final Color _glowColor3 = const Color(0xFFD32F2F);        
final Color _goldColor = const Color(0xFFD32F2F);         
final Color _roseColor = const Color(0xFF00BFFF);         


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listPayload = widget.listPayload;
    listDDoS = widget.listDDoS;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
    _fetchActivityLogs();
    _initVideoBackground();
    _initAudioPlayer();
    _fetchAnimeData();
    _fetchGovernmentNews();
    _fetchSholatTimes();

    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchServerStats());
    _hourlySholatTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted) _fetchSholatTimes();
    });
    _startCountdownTimer();
    _fetchWeather();
    _startClock();

    _pageController.addListener(() {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? _currentNewsPage;
      final nextIndex = page.round();
      if ((page - _currentNewsPage).abs() > 0.01 || nextIndex != _currentNewsIndex) {
        setState(() {
          _currentNewsPage = page;
          _currentNewsIndex = nextIndex;
        });
      }
    });

    _actionPageController.addListener(() {
      if (!mounted || !_actionPageController.hasClients) return;
      final page = _actionPageController.page ?? _currentActionPage;
      final nextIndex = page.round();
      if ((page - _currentActionPage).abs() > 0.01 || nextIndex != _currentActionIndex) {
        setState(() {
          _currentActionPage = page;
          _currentActionIndex = nextIndex;
        });
      }
    });
  }
  
  
  
  Future<void> _fetchSholatTimes() async {
  setState(() => _isLoadingSholat = true);
  try {
    final response = await http.get(
      Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Jakarta&country=Indonesia&method=11'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timings = data['data']['timings'];
      setState(() {
        _sholatTimes = {
          "Subuh": {"time": timings['Fajr'], "arabic": "الفجر"},
          "Dzuhur": {"time": timings['Dhuhr'], "arabic": "الظهر"},
          "Ashar": {"time": timings['Asr'], "arabic": "العصر"},
          "Maghrib": {"time": timings['Maghrib'], "arabic": "المغرب"},
          "Isya": {"time": timings['Isha'], "arabic": "العشاء"},
        };
      });
      _calculateNextPrayer();
    } else {
      _setDefaultSholatTimes();
    }
  } catch (e) {
    _setDefaultSholatTimes();
  }
  if (mounted) setState(() => _isLoadingSholat = false);
}

Future<void> _fetchWeather() async {
  setState(() => _isLoadingWeather = true);
  try {
    // API GRATIS dari wttr.in (no API key required)
    final response = await http.get(
      Uri.parse('https://wttr.in/Jakarta?format=j1'),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Ambil data 5 hari dari wttr.in
      final List<dynamic> weatherList = data['weather'];
      final List<Map<String, dynamic>> forecast = [];
      
      for (int i = 0; i < (weatherList.length > 5 ? 5 : weatherList.length); i++) {
        final day = weatherList[i];
        final date = day['date'];
        final temp = day['avgtempC'];
        final condition = day['hourly'][0]['weatherDesc'][0]['value'];
        final iconCode = day['hourly'][0]['weatherCode'];
        
        forecast.add({
          'date': date,
          'temp': temp,
          'condition': condition,
          'iconCode': iconCode,
          'day': _getDayName(date),
        });
      }
      
      setState(() {
        _weatherForecast = forecast;
        _isLoadingWeather = false;
      });
    } else {
      // Fallback ke dummy data jika API gagal
      _setDummyWeather();
    }
  } catch (e) {
    print('Error fetching weather: $e');
    _setDummyWeather();
  }
}

String _getDayName(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  } catch (e) {
    return '';
  }
}

void _startClock() {
  _clockTimer?.cancel(); // Hentikan timer lama jika ada
  _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // WIB = UTC+7
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final second = now.second.toString().padLeft(2, '0');
      final timeString = "$hour:$minute:$second";
      
      if (_currentTime != timeString) {
        setState(() {
          _currentTime = timeString;
        });
      }
    }
  });
}

void _setDummyWeather() {
  setState(() {
    _weatherForecast = [
      {'day': 'Sen', 'temp': 30, 'condition': 'Cerah', 'iconCode': '113'},
      {'day': 'Sel', 'temp': 28, 'condition': 'Berawan', 'iconCode': '116'},
      {'day': 'Rab', 'temp': 29, 'condition': 'Hujan Ringan', 'iconCode': '296'},
      {'day': 'Kam', 'temp': 27, 'condition': 'Hujan', 'iconCode': '299'},
      {'day': 'Jum', 'temp': 31, 'condition': 'Cerah', 'iconCode': '113'},
    ];
    _isLoadingWeather = false;
  });
}

void _setDefaultSholatTimes() {
  setState(() {
    _sholatTimes = {
      "Subuh": {"time": "--:--", "arabic": "الفجر"},
      "Dzuhur": {"time": "--:--", "arabic": "الظهر"},
      "Ashar": {"time": "--:--", "arabic": "العصر"},
      "Maghrib": {"time": "--:--", "arabic": "المغرب"},
      "Isya": {"time": "--:--", "arabic": "العشاء"},
    };
  });
}

void _calculateNextPrayer() {
  final now = DateTime.now();
  for (var entry in _sholatTimes.entries) {
    final prayerTime = entry.value["time"]!;
    if (prayerTime == "--:--") continue;
    final parts = prayerTime.split(":");
    final prayerDateTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    if (prayerDateTime.isAfter(now)) {
      setState(() {
        _nextPrayerName = entry.key;
        _nextPrayerTime = prayerTime;
      });
      _updateTimeToNextPrayer();
      return;
    }
  }
  final subuh = _sholatTimes["Subuh"]?["time"] ?? "04:20";
  setState(() {
    _nextPrayerName = "Subuh";
    _nextPrayerTime = subuh;
  });
  _updateTimeToNextPrayer(isTomorrow: true);
}

void _updateTimeToNextPrayer({bool isTomorrow = false}) {
  final now = DateTime.now();
  final parts = _nextPrayerTime.split(":");
  DateTime nextPrayer = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  if (isTomorrow) nextPrayer = nextPrayer.add(const Duration(days: 1));
  final difference = nextPrayer.difference(now);
  setState(() {
    _timeToNextPrayer = "${difference.inHours}j ${difference.inMinutes % 60}m";
  });
}

void _startCountdownTimer() {
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) _calculateNextPrayer();
  });
}




Future<void> _fetchGovernmentNews() async {
  if (!mounted) return;
  setState(() => _isLoadingGovernmentNews = true);

  final feeds = <String>[
    'https://www.komdigi.go.id/berita/rss',
    'https://kemkes.go.id/id/rss/article/rilis-berita',
  ];

  final collected = <Map<String, String>>[];

  for (final feed in feeds) {
    try {
      final response = await http.get(Uri.parse(feed)).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) continue;

      final xml = utf8.decode(response.bodyBytes);
      final items = RegExp(r'<item[\s\S]*?</item>', caseSensitive: false).allMatches(xml);

      for (final match in items.take(10)) {
        final block = match.group(0) ?? '';
        String pick(String tag) {
          final value = RegExp('<$tag(?:\\s[^>]*)?>([\\s\\S]*?)</$tag>', caseSensitive: false).firstMatch(block)?.group(1) ?? '';
          return _cleanRssText(value);
        }

        final enclosure = RegExp(
          "<enclosure[^>]+url=[\"']([^\"']+)[\"']",
          caseSensitive: false,
        ).firstMatch(block);

        final media = RegExp(
          "<media:content[^>]+url=[\"']([^\"']+)[\"']",
          caseSensitive: false,
        ).firstMatch(block);

        final title = pick('title');
        final link = pick('link');
        final desc = pick('description');
        final date = pick('pubDate');
        final image = enclosure?.group(1) ?? media?.group(1) ?? '';

        if (title.isEmpty || link.isEmpty) continue;
        collected.add({
          'title': title,
          'desc': desc,
          'link': link,
          'date': date,
          'image': image,
          'source': Uri.tryParse(feed)?.host.replaceFirst('www.', '') ?? 'pemerintah',
        });
      }

      if (collected.length >= 31) break;
    } catch (e) {
      debugPrint('Error fetching government news from $feed: $e');
    }
  }

  if (mounted) {
    setState(() {
      _governmentNews = collected.take(31).toList();
      _isLoadingGovernmentNews = false;
    });
  }
}

String _cleanRssText(String value) {
  return value
      .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

Future<void> _fetchAnimeData() async {
  try {
    final response = await http.get(
      Uri.parse('https://www.sankavollerei.com/anime/home'),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (mounted) {
        setState(() {
          animeData = jsonData['data'];
          _isLoadingAnime = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingAnime = false);
    }
  } catch (e) {
    debugPrint('Error fetching anime: $e');
    if (mounted) setState(() => _isLoadingAnime = false);
  }
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _videoController?.play();
    _statsVideoController?.play();
    _otaxVideoController?.play();
  }
}

void _initAudioPlayer() {
  _audioPlayer.setReleaseMode(ReleaseMode.loop);
}

void _toggleBackgroundMusic(bool isPlaying) async {
  setState(() => _isMusicOn = isPlaying);
  if (isPlaying) {
    await _audioPlayer.play(UrlSource(_backgroundMusicUrl), volume: 1);
    _videoController?.setVolume(1);
    _statsVideoController?.setVolume(1);
    _otaxVideoController?.setVolume(1.0);
  } else {
    await _audioPlayer.pause();
  }
}

Future<void> _initVideoBackground() async {
  try {
    _videoController = VideoPlayerController.asset('assets/videos/landing.mp4');
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(1.0);
    await _videoController!.play();

    _statsVideoController = VideoPlayerController.asset('assets/videos/landing.mp4');
    await _statsVideoController!.initialize();
    _statsVideoController!.setLooping(true);
    _statsVideoController!.setVolume(1.0);
    await _statsVideoController!.play();

    _otaxVideoController = VideoPlayerController.asset('assets/videos/landing.mp4');
    await _otaxVideoController!.initialize();
    _otaxVideoController!.setLooping(true);
    _otaxVideoController!.setVolume(1.0);
    await _otaxVideoController!.play();

    if (mounted) setState(() {});
  } catch (e) {
    debugPrint("Gagal memuat video background: $e");
  }
}

void _toggleStatsVideo() {
  setState(() {
    if (_statsVideoController != null) {
      if (_statsVideoController!.value.isPlaying) {
        _statsVideoController!.pause();
      } else {
        _statsVideoController!.play();
      }
    }
  });
}

Future<void> _initAndroidIdAndConnect() async {
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  if (mounted) setState(() => androidId = deviceInfo.id);
  _connectToWebSocket();
}

int? _readIntFromMap(Map data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

void _requestStats() {
  _fetchServerStats();
}

Future<void> _fetchServerStats() async {
  try {
    final response = await http
        .get(Uri.parse('http://kinncloud.sistems.tech:2052/api/stats'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return;

    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      _applyStats(decoded);
    }
  } catch (e) {
    debugPrint('Error fetching server stats: $e');
  }
}

void _applyStats(Map data) {
  final mapsToCheck = <Map>[data];
  for (final key in ['data', 'stats', 'payload', 'result']) {
    final nested = data[key];
    if (nested is Map) mapsToCheck.add(nested);
  }

  int? online;
  int? connections;

  for (final map in mapsToCheck) {
    online ??= _readIntFromMap(map, [
      'onlineUsers',
      'online_users',
      'online',
      'usersOnline',
      'activeUsers',
      'totalOnline',
      'totalUsers',
      'users',
    ]);
    connections ??= _readIntFromMap(map, [
      'activeConnections',
      'active_connections',
      'connections',
      'activeClients',
      'clients',
      'connected',
      'socketCount',
    ]);
  }

  if (!mounted || (online == null && connections == null)) return;
  setState(() {
    _hasServerStats = true;
    if (online != null) _onlineUsers = online!;
    if (connections != null) _activeConnections = connections!;
  });
}

void _connectToWebSocket() {
  _fetchServerStats();
}

Future<void> _fetchActivityLogs() async {
  if (!mounted) return;
  setState(() { _isLoadingActivityLogs = true; _hasActivityLogsError = false; });
  try {
    final response = await http.get(
      Uri.parse('http://kinncloud.sistems.tech:2052/api/user/getActivityLogs?key=$sessionKey'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['valid'] == true && data['logs'] != null) {
        if (mounted) setState(() { _activityLogs = List<Map<String, dynamic>>.from(data['logs']); _isLoadingActivityLogs = false; });
      } else {
        if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
      }
    } else {
      if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
    }
  } catch (e) {
    print('Error fetching activity logs: $e');
    if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
  }
}

void _handleInvalidSession(String message) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (!mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: _surfaceColor.withOpacity(0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _roseColor.withOpacity(0.4), width: 1),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _roseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
            ),
            child: Icon(Icons.warning_amber_rounded, color: _roseColor, size: 22),
          ),
          const SizedBox(width: 14),
          const Text("Session Expired",
              style: TextStyle(color: Colors.white, fontFamily: "Rajdhani", fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
        ],
      ),
      content: Text(message,
          style: const TextStyle(color: Colors.white60, fontFamily: "Rajdhani", fontWeight: FontWeight.w500, fontSize: 13, height: 1.5)),
      actions: [
        Container(
          decoration: BoxDecoration(
            color: _primaryPurple.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Text("OK",
                style: TextStyle(
                  color: _darkerBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: "Rajdhani",
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void _openSettingsPage() {
  setState(() {
    _activePage = 'settings';
    _selectedPage = _buildSettingsPage();
    _controller.reset();
    _controller.forward();
  });
}



void _selectFromDrawer(String page) {
  // Special pages that don't follow the nextWidget pattern
  if (page == 'account') {
    setState(() {
      _isAssistiveMenuOpen = false;
      _isBugToolsExpanded = false;
    });
    _showAccountMenu();
    return;
  }
  if (page == 'rat') {
    setState(() {
      _isAssistiveMenuOpen = false;
      _isBugToolsExpanded = false;
      _activePage = 'rat';
      _selectedPage = DeviceDashboardPage(username: username);
    });
    _controller.reset();
    _controller.forward();
    return;
  }
  if (page == 'anime') {
    setState(() {
      _isAssistiveMenuOpen = false;
      _activePage = 'anime';
      _selectedPage = const HomeAnimePage();
    });
    _controller.reset();
    _controller.forward();
    return;
  }
  if (page == 'quran') {
    setState(() {
      _isAssistiveMenuOpen = false;
      _activePage = 'quran';
      _selectedPage = const QuranTool();
    });
    _controller.reset();
    _controller.forward();
    return;
  }

  // For other pages, close assistive menu and set active page
  setState(() {
    _isAssistiveMenuOpen = false;
    _activePage = page;
  });

  Widget nextWidget = _buildNewsPage();

  if (page == 'home') {
    _selectedIndex = 0;
    nextWidget = _buildNewsPage();
  } else if (page == 'settings') {
    nextWidget = _buildSettingsPage();
  } else if (page == 'bug') {
    nextWidget = AttackPage(
      username: username,
      password: password,
      listBug: listBug,
      role: role,
      expiredDate: expiredDate,
      sessionKey: sessionKey,
    );
  } else if (page == 'custom_bug') {
    nextWidget = CustomAttackPage(
      username: username,
      password: password,
      listPayload: listPayload,
      role: role,
      expiredDate: expiredDate,
      sessionKey: sessionKey,
    );
  } else if (page == 'group_bug') {
    nextWidget = GroupBugPage(
      username: username,
      password: password,
      role: role,
      expiredDate: expiredDate,
      sessionKey: sessionKey,
    );
  } else if (page == 'telegram') {
  nextWidget = TelegramSpamPage(sessionKey: sessionKey);
   } else if (page == 'larangan') {
    setState(() {
      _activePage = 'larangan';
      _selectedPage = const LaranganPenggunaPage();
    });
    _controller.reset();
    _controller.forward();
    return;
  } else if (page == 'ddos') {
    nextWidget = AttackPanel(sessionKey: sessionKey, listDDoS: listDDoS);
  } else if (page == 'tools') {
    nextWidget = ToolsPage(
      sessionKey: sessionKey,
      userRole: role,
      username: username,
      expiredDate: expiredDate,
    );
  } else if (page == 'reseller') {
    nextWidget = SellerPage(keyToken: sessionKey);
  } else if (page == 'admin') {
    nextWidget = AdminPage(sessionKey: sessionKey);
  } else if (page == 'sender') {
    nextWidget = SenderPage(sessionKey: sessionKey);
  }

  // For pages that use nextWidget (not already returned)
  setState(() {
    _selectedPage = nextWidget;
    _controller.reset();
    _controller.forward();
  });
}

void _showMoreMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceColor.withOpacity(0.97),
              border: Border.all(color: _primaryPurple.withOpacity(0.12), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 44, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 20),
                Text("MORE OPTIONS",
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16,
                    fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 4)),
                const SizedBox(height: 20),
                _buildMoreOption(
                  icon: Icons.menu_book,
                  title: "AL-QUR'AN",
                  subtitle: "Read Holy Qur'an",
                  color: _primaryPurple,
                  onTap: () {
                    Navigator.pop(context);
                    _selectFromDrawer('quran');
                  },
                ),
                const SizedBox(height: 12),
                _buildMoreOption(
                  icon: Icons.settings,
                  title: "SETTINGS",
                  subtitle: "App preferences",
                  color: _glowLight,
                  onTap: () {
                    Navigator.pop(context);
                    _openSettingsPage();
                  },
                ),
                const SizedBox(height: 12),
                _buildMoreOption(
                  icon: Icons.person,
                  title: "PROFILE",
                  subtitle: "Account information",
                  color: _primaryPurple,
                  onTap: () {
                    Navigator.pop(context);
                    _showAccountMenu();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildMoreOption({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: "Rajdhani",
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontFamily: "Rajdhani",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
        ],
      ),
    ),
  );
}


Widget _buildLaranganButton() {
  return Positioned(
    bottom: 80,
    left: 0,
    right: 0,
    child: Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaranganPenggunaPage()),
          ).then((_) {
            setState(() {});
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFF8B0000), Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
        ),
      ),
    ),
  );
}


// INFORMASI DEVELOPER
Widget _buildApiNewsList() {
  final displayNews = _governmentNews.isNotEmpty
      ? _governmentNews
      : newsList.map<Map<String, String>>((item) {
          final map = item is Map ? item : <String, dynamic>{};
          return {
            'title': '${map['title'] ?? 'INFORMASI APK'}',
            'desc': '${map['desc'] ?? map['description'] ?? ''}',
            'image': '${map['image'] ?? map['thumbnail'] ?? ''}',
            'link': '${map['link'] ?? map['url'] ?? ''}',
            'date': '${map['date'] ?? map['createdAt'] ?? ''}',
            'source': '${map['source'] ?? 'server'}',
          };
        }).toList();

  if (_isLoadingGovernmentNews && displayNews.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(child: CircularProgressIndicator(color: _glowColor1, strokeWidth: 2)),
      ),
    );
  }

  if (displayNews.isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Center(
        child: Text(
          'Berita belum tersedia',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(Icons.newspaper_rounded, 'INFORMASI APK'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _glowColor1.withOpacity(0.15)),
              ),
              child: Text(
                '${displayNews.length} Berita',
                style: TextStyle(color: _glowColor1.withOpacity(0.76), fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'Rajdhani'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 155,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: displayNews.length,
          itemBuilder: (context, index) {
            final item = displayNews[index];
            final image = item['image'] ?? '';
            final link = item['link'] ?? '';
            return GestureDetector(
              onTap: link.isEmpty ? null : () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
              child: Container(
                width: 335,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _glowColor1.withOpacity(0.10), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _surfaceColor,
                                  child: Center(child: Icon(Icons.newspaper_rounded, color: _glowColor1.withOpacity(0.18), size: 40)),
                                ),
                              )
                            : Container(
                                color: _surfaceColor,
                                child: Center(child: Icon(Icons.newspaper_rounded, color: _glowColor1.withOpacity(0.18), size: 42)),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, _darkerBg.withOpacity(0.92)],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _darkerBg.withOpacity(0.58),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _glowColor1.withOpacity(0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, color: _glowColor1.withOpacity(0.72), size: 11),
                              const SizedBox(width: 4),
                              Text('BACA', style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 8, fontFamily: 'Rajdhani', fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['title'] ?? 'Berita Terkini',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Rajdhani', letterSpacing: 0.4),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['desc'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
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
        ),
      ),
    ],
  );
}

// CUACA 5 HARI (horizontal scroll)
Widget _buildWeather5Day() {
  if (_isLoadingWeather) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(color: Color(0xFFD500F9), strokeWidth: 2)),
    );
  }
  
  if (_weatherForecast.isEmpty) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text("Tidak ada data cuaca", style: TextStyle(color: Colors.white.withOpacity(0.5)))),
    );
  }

  return SizedBox(
    height: 110,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _weatherForecast.length,
      itemBuilder: (context, index) {
        final weather = _weatherForecast[index];
        return Container(
          width: 90,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryPurple.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weather['day'], style: TextStyle(color: _primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _getWeatherEmoji(weather['condition']),
              const SizedBox(height: 4),
              Text("${weather['temp']}°C", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    ),
  );
}

// HAPUS method _getWeatherImage, GANTI dengan ini:
Widget _getWeatherEmoji(String condition) {
  final conditionLower = condition.toLowerCase();
  
  if (conditionLower.contains('cerah') || conditionLower.contains('clear') || conditionLower.contains('sunny')) {
    return const Text('☀️', style: TextStyle(fontSize: 28));
  } else if (conditionLower.contains('berawan') || conditionLower.contains('cloud') || conditionLower.contains('overcast')) {
    return const Text('☁️', style: TextStyle(fontSize: 28));
  } else if (conditionLower.contains('hujan') || conditionLower.contains('rain')) {
    if (conditionLower.contains('ringan') || conditionLower.contains('light')) {
      return const Text('🌦️', style: TextStyle(fontSize: 28));
    }
    return const Text('🌧️', style: TextStyle(fontSize: 28));
  } else if (conditionLower.contains('petir') || conditionLower.contains('thunder')) {
    return const Text('⛈️', style: TextStyle(fontSize: 28));
  } else if (conditionLower.contains('kabut') || conditionLower.contains('mist') || conditionLower.contains('fog')) {
    return const Text('🌫️', style: TextStyle(fontSize: 28));
  } else if (conditionLower.contains('salju') || conditionLower.contains('snow')) {
    return const Text('❄️', style: TextStyle(fontSize: 28));
  } else {
    return const Text('☀️', style: TextStyle(fontSize: 28));
  }
}


Widget _buildSettingsPage() {
  return Container(
    color: _darkerBg,
    child: SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 22,
                        decoration: BoxDecoration(color: _primaryPurple, borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.7), blurRadius: 8)]),
                      ),
                      const SizedBox(width: 12),
                      Text("PREFERENCES",
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 20,
                          fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text("Customize your experience",
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11,
                        fontFamily: "Rajdhani", fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 32),
                  _buildModernSettingCard(
                    icon: Icons.navigation_outlined, title: "NAVIGATION BAR",
                    subtitle: "Show/Hide bottom navigation menu", value: _showBottomNav,
                    onChanged: (val) { setState(() => _showBottomNav = val); _openSettingsPage(); },
                    glowColor: _primaryPurple,
                  ),
                  const SizedBox(height: 14),
                  _buildModernSettingCard(
                    icon: Icons.ads_click, title: "FLOATING MENU",
                    subtitle: "Assistive touch shortcut button", value: _showAssistiveTouch,
                    onChanged: (val) {
                      setState(() { _showAssistiveTouch = val; if (!val) _isAssistiveMenuOpen = false; });
                      _openSettingsPage();
                    },
                    glowColor: _glowLight,
                  ),
                  const SizedBox(height: 14),
                  _buildModernSettingCard(
                    icon: _isMusicOn ? Icons.music_note : Icons.music_off,
                    title: "BACKGROUND MUSIC", subtitle: "Play online ambient music",
                    value: _isMusicOn,
                    onChanged: (val) { _toggleBackgroundMusic(val); _openSettingsPage(); },
                    glowColor: _primaryPurple,
                  ),
                  const SizedBox(height: 44),
                  GestureDetector(
                    onTap: () => _selectFromDrawer('home'),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, color: _darkerBg, size: 18),
                          const SizedBox(width: 12),
                          Text("BACK TO HOME",
                            style: TextStyle(color: _darkerBg, fontWeight: FontWeight.w900,
                              fontSize: 13, letterSpacing: 4, fontFamily: "Rajdhani")),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildModernSettingCard({
  required IconData icon, required String title, required String subtitle,
  required bool value, required Function(bool) onChanged, required Color glowColor,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: glowColor.withOpacity(value ? 0.25 : 0.08), width: 1),
      boxShadow: value ? [BoxShadow(color: glowColor.withOpacity(0.08), blurRadius: 20)] : null,
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: glowColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: glowColor.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: glowColor.withOpacity(0.8), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 10, fontFamily: "Rajdhani", fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: _darkerBg,
          activeTrackColor: glowColor,
          inactiveThumbColor: Colors.grey.shade700,
          inactiveTrackColor: Colors.white.withOpacity(0.08),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}




Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 10,
      bottom: 10,
      left: 18,
      right: 18,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_darkerBg.withOpacity(0.97), Colors.transparent],
      ),
    ),
    child: Row(
      children: [
        _buildHeaderBtn(
          icon: Icons.menu_rounded,
          onTap: () => setState(() => _isAssistiveMenuOpen = !_isAssistiveMenuOpen),
          isActive: _isAssistiveMenuOpen,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryPurple, _glowLight],
                ).createShader(bounds),
                child: const Text("VANTHRA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Rajdhani",
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Text("DASHBOARD",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontFamily: "Rajdhani",
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderBtn(icon: Icons.person_outline, onTap: _showAccountMenu), // ← perbaikan
        const SizedBox(width: 10),
        _buildHeaderBtn(
          icon: Icons.settings_outlined,
          onTap: _openSettingsPage,
          isActive: _activePage == 'settings',
        ),
        _buildHeaderBtn(
          icon: Icons.chat,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicChatPage(username: username),
              ),
            );
          },
        ),
        _buildHeaderBtn(
          icon: Icons.music_note,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MusicPlayerPage(),
              ),
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildHeaderBtn({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: isActive ? _primaryPurple.withOpacity(0.12) : _cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isActive ? _primaryPurple.withOpacity(0.4) : Colors.white.withOpacity(0.07),
          width: 1,
        ),
        boxShadow: isActive ? [BoxShadow(color: _primaryPurple.withOpacity(0.15), blurRadius: 12)] : null,
      ),
      child: Icon(icon, color: isActive ? _primaryPurple : Colors.white.withOpacity(0.6), size: 20),
    ),
  );
}

// -------------------------LARANGAN PENGGUNA -------------
Widget _buildNotifMenuItem(IconData icon, String title, String page) {
  bool isActive = _activePage == page;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white.withOpacity(0.04),
      onTap: () => _selectFromDrawer(page),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF8B0000).withOpacity(0.25) 
              : const Color(0xFF1A0000), // hitam kemerahan
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.7), width: 1.2),
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? const Color(0xFFFF5252) : Colors.white, size: 18),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(
            color: isActive ? const Color(0xFFFF5252) : Colors.white,
            fontSize: 13, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontFamily: "Rajdhani", letterSpacing: 1))),
          if (isActive)
            Container(width: 7, height: 7,
              decoration: BoxDecoration(color: const Color(0xFFD32F2F), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.5), blurRadius: 6)])),
        ]),
      ),
    ),
  );
}

// ─────────────────────────── ACCOUNT STATS CARD (Neon Purple) ─────────────────
Widget _buildAccountStatsCard() {
  final onlineText = _hasServerStats ? '$_onlineUsers' : '...';
  final connectionText = _hasServerStats ? '$_activeConnections' : '...';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardColor, _surfaceColor, _primaryPurple.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _primaryPurple.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.42), blurRadius: 24, offset: const Offset(0, 10)),
          BoxShadow(color: _primaryPurple.withOpacity(0.1), blurRadius: 22),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ========== AVATAR FOTO (GANTI DENGAN GAMBAR) ==========
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.3), blurRadius: 24)],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/avatar.jpg', // Ganti dengan file foto Tuan
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback jika gambar tidak ada
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primaryPurple, _glowLight],
                          ),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 40),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahlan Wa Sahlan!!,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 13,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primaryPurple.withOpacity(0.3)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: _primaryPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryPurple.withOpacity(0.10),
                  boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.12), blurRadius: 20)],
                ),
                child: Icon(Icons.timer_rounded, color: _primaryPurple.withOpacity(0.75), size: 26),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.11)),
            ),
            child: Text(
              'VANTHRA DASHBOARD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryPurple,
                fontSize: 12,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildWelcomeStatItem(
                  icon: Icons.groups_rounded,
                  color: Colors.greenAccent,
                  value: onlineText,
                  label: 'Online Users',
                  badge: 'LIVE',
                ),
              ),
              Expanded(
                child: _buildWelcomeStatItem(
                  icon: Icons.link_rounded,
                  color: Colors.cyanAccent,
                  value: connectionText,
                  label: 'Active Connections',
                ),
              ),
              Expanded(
                child: _buildWelcomeStatItem(
                  icon: Icons.calendar_month_rounded,
                  color: Colors.orangeAccent,
                  value: expiredDate,
                  label: 'Expiration',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildWelcomeStatItem({
  required IconData icon,
  required Color color,
  required String value,
  required String label,
  String? badge,
}) {
  return Column(
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 18)],
        ),
        child: Icon(icon, color: color.withOpacity(0.72), size: 24),
      ),
      const SizedBox(height: 10),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.48),
          fontSize: 10,
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
        ),
      ),
      if (badge != null) ...[
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: Colors.greenAccent.withOpacity(0.95),
              fontSize: 8,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ],
  );
}




// ─────────────────────────── LATEST ANIME SECTION ─────────────────────────
Widget _buildLatestAnimeSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _buildSectionHeader(Icons.live_tv, "LATEST ANIME"),
      ),
      const SizedBox(height: 12),
      if (_isLoadingAnime)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFD500F9)),
            ),
          ),
        )
      else if (animeData != null && animeData!['ongoing'] != null)
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: (animeData!['ongoing']['animeList'] as List).length > 10
                ? 10
                : (animeData!['ongoing']['animeList'] as List).length,
            itemBuilder: (context, index) {
              final anime = animeData!['ongoing']['animeList'][index];
              final String title = anime['title'];
              final String poster = anime['poster'];
              final String episode = anime['episodes']?.toString() ?? '?';
              final String slug = anime['animeId'];
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeDetailPage(slug: slug),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          poster,
                          height: 160,
                          width: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            width: 130,
                            color: _surfaceColor,
                            child: const Icon(Icons.image_not_supported, color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          color: _primaryPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: "Rajdhani",
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$episode Episode",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 9,
                          fontFamily: "Rajdhani",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: GestureDetector(
          onTap: () => _selectFromDrawer('anime'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.centerRight,
            child: Text(
              "See All →",
              style: TextStyle(
                color: _primaryPurple.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: "Rajdhani",
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────── API NEWS LIST (SLIDER HORIZONTAL) ────────────

// ─────────────────────────── WHATSAPP BANNER ──────────────────────────────
Widget _buildWhatsAppCrashBanner() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366), // Hijau WhatsApp asli (muda)
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
  FontAwesomeIcons.whatsapp,
  size: 50,
  color: Color(0xFF25D366),
),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("WhatsApp Crash",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Advanced payload injection",
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 24),
        ],
      ),
    ),
  );
}





// ─────────────────────────── QUICK ACTIONS ────────────────────────────────
Widget _buildActionSliderCard(Map<String, dynamic> action) {
  final Color color = action['color'];

  return GestureDetector(
    onTap: action['onTap'],
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.85),
            _cardColor.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background circle decoration
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: action.containsKey('imagePath')
                        ? Image.asset(
                            action['imagePath'],
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, color: Colors.white, size: 28);
                            },
                          )
                        : Icon(action['icon'], color: Colors.white, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "OPEN →",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontFamily: "Rajdhani",
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                action['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: "Rajdhani",
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action['subtitle'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontFamily: "Rajdhani",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuickActions() {
  final List<Map<String, dynamic>> quickActions = [
    {
  "title": "Sender Manager",
  "subtitle": "Pairing & Config",
  "icon": FontAwesomeIcons.whatsapp,
  "color": const Color(0xFF25D366), // Hijau WhatsApp
  "onTap": () => _selectFromDrawer('sender'),
},
{
  "title": "Join Channel",
  "subtitle": "Get updates",
  "icon": FontAwesomeIcons.telegramPlane,
  "color": const Color(0xFF0088CC), // Biru Telegram asli
  "onTap": () async {
    final url = Uri.parse('https://t.me/nocurech');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
},
{
  "title": "Telegram Spam",
  "subtitle": "Mass sender",
  "icon": FontAwesomeIcons.paperPlane,
  "color": const Color(0xFFE53935), // Merah (peringatan/aksi spam)
  "onTap": () => _selectFromDrawer('telegram'),
},
{
  "title": "Security",
  "subtitle": "Change password",
  "icon": Icons.lock_reset,
  "color": const Color(0xFFFFB300), // Kuning/amber (keamanan/perhatian)
  "onTap": () {
    setState(() {
      _activePage = 'change_password';
      _selectedPage = ChangePasswordPage(
        username: username,
        sessionKey: sessionKey,
      );
      _controller.reset();
      _controller.forward();
    });
  },
},
    {
  "title": "Test Function",
  "subtitle": "Test Your Function",
  "icon": Icons.bug_report,
  "color": const Color(0xFFE65100), // Oranye (warning/testing)
  "onTap": () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestFunctionPage(
          sessionKey: sessionKey,
          role: role,
          username: username,
          expiredDate: expiredDate,
        ),
      ),
    );
  },
},
{
  "title": "CHAT PUBLIC",
  "subtitle": "Room chat community",
  "icon": Icons.chat_bubble,
  "color": const Color(0xFF0288D1), // Biru cerah (chat)
  "onTap": () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicChatPage(
          username: username,
        ),
      ),
    );
  },
},
{
  "title": "TOOLS",
  "subtitle": "Open tools page",
  "icon": Icons.build,
  "color": const Color(0xFF607D8B), // Biru keabuan (tools/netral)
  "onTap": () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          username: username,
          expiredDate: expiredDate,
        ),
      ),
    );
  },
},
{
  "title": "THANKS TO",
  "subtitle": "Special contributors",
  "icon": Icons.diversity_1,
  "color": const Color(0xFF4CAF50), // Hijau (apresiasi/terima kasih)
  "onTap": () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThanksToPage(),
      ),
    );
  },
},
];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(Icons.bolt, "QUICK ACCESS"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(  // <-- GRADIENT AGAR WARNA MERATA
                  colors: [_primaryPurple, _glowLight],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.4), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    "READY",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFamily: "Rajdhani",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        height: 180,
        child: PageView.builder(
          controller: _actionPageController,
          itemCount: quickActions.length,
          onPageChanged: (index) {
            setState(() {
              _currentActionIndex = index;
              _currentActionPage = index.toDouble();
            });
          },
          itemBuilder: (context, index) {
            return _buildActionSliderCard(quickActions[index]);
          },
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          quickActions.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 5,
            width: (1 - (_currentActionPage - index).abs()).clamp(0.0, 1.0) > 0.5 ? 24 : 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: (1 - (_currentActionPage - index).abs()).clamp(0.0, 1.0) > 0.5
                  ? _primaryPurple.withOpacity(0.7)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────── RECENT ACTIVITY ──────────────────────────────
Widget _buildRecentActivity() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.history, "ACTIVITY LOG"),
        const SizedBox(height: 18),
        if (_isLoadingActivityLogs)
          _buildGlassPlaceholder(child: CircularProgressIndicator(color: _primaryPurple, strokeWidth: 2))
        else if (_hasActivityLogsError)
          _buildGlassPlaceholder(child: Text("Failed to load logs",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: "Rajdhani")))
        else if (_activityLogs.isEmpty)
          _buildGlassPlaceholder(child: Text("No activity logs",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: "Rajdhani")))
        else
          ..._activityLogs.take(5).map((log) {
            final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
            final formattedTime = _formatDateTime(timestamp);
            String activityText = log['activity'] ?? 'Unknown Activity';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications, color: _primaryPurple, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(activityText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(formattedTime,
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                ])),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
              ]),
            );
          }).toList(),
      ],
    ),
  );
}

Widget _buildGlassPlaceholder({required Widget child}) {
  return Container(
    height: 120,
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Center(child: child),
  );
}

String _formatDateTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}


  // ─────────────────────────── ACCOUNT MENU ─────────────────────────────────
  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.97),
                border: Border.all(color: _primaryPurple.withOpacity(0.15), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 24),
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _cardColor,
                      border: Border.all(color: _primaryPurple.withOpacity(0.25), width: 1.5),
                      boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : "U",
                        style: TextStyle(color: _primaryPurple, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: "Rajdhani"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text("PROFILE", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18,
                    fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 4)),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.person, "USERNAME", username),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today, "EXPIRES", expiredDate),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.security, "ROLE", role),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _buildMenuButton(
                      icon: Icons.lock_reset, label: "CHANGE PW",
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _activePage = 'change_password';
                          _selectedPage = ChangePasswordPage(username: username, sessionKey: sessionKey);
                          _controller.reset(); _controller.forward();
                        });
                      },
                      color: Colors.amber,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMenuButton(
                      icon: Icons.logout, label: "EXIT",
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                      },
                      color: Colors.red,
                    )),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(children: [
        Icon(icon, color: _primaryPurple.withOpacity(0.5), size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w700,
          fontSize: 12, fontFamily: "Rajdhani", letterSpacing: 1)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani",
          fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w800,
            fontSize: 12, letterSpacing: 2, fontFamily: "Rajdhani")),
        ]),
      ),
    );
  }

  // ─────────────────────────── ASSISTIVE MENU ───────────────────────────────
  Widget _buildAssistiveMenu() {
    final String currentRole = role.toLowerCase();
    final bool canAccessAdmin = ['founder', 'moderator', 'high admin', 'owner'].contains(currentRole);
    final bool canAccessSeller = ['founder', 'moderator', 'high admin', 'owner', 'reseller'].contains(currentRole);
    final bool canAccessAllBugs = ['founder', 'moderator', 'high admin', 'owner'].contains(currentRole);
    final bool canAccessResellerBugs = ['reseller'].contains(currentRole);
    final bool isMember = !canAccessAllBugs && !canAccessResellerBugs;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryPurple.withOpacity(0.12), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                _buildMenuItem(Icons.home, "HOME", 'home'),
                _buildMenuItem(Icons.movie, "ANIME", 'anime'),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: FaIcon(FontAwesomeIcons.whatsapp, color: _primaryPurple.withOpacity(0.7), size: 18),
                    title: Text("BUG TOOLS", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13,
                      fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
                    trailing: Icon(_isBugToolsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.4), size: 20),
                    onExpansionChanged: (bool expanded) {
                      setState(() => _isBugToolsExpanded = expanded);
                      if (isMember && expanded) { setState(() => _isBugToolsExpanded = false); _selectFromDrawer('bug'); }
                    },
                    children: [
                      if (!isMember)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (canAccessAllBugs || canAccessResellerBugs) ...[
                              _buildSubMenuItem(FontAwesomeIcons.usersSlash, "GROUP BUG", 'group_bug'),
                              const SizedBox(height: 4),
                            ],
                            if (canAccessAllBugs) ...[
                              _buildSubMenuItem(Icons.terminal, "CUSTOM BUG", 'custom_bug'),
                              const SizedBox(height: 4),
                            ],
                            _buildSubMenuItem(Icons.bolt, "BASIC BUG", 'bug'),
                          ]),
                        ),
                    ],
                  ),
                ),
                _buildMenuItem(FontAwesomeIcons.paperPlane, "SPAM", 'telegram'),
                _buildMenuItem(Icons.phone_android, "RAT", 'rat'),
                _buildMenuItem(FontAwesomeIcons.screwdriverWrench, "TOOLS", 'tools'),
                _buildMenuItem(Icons.security, "DDOS", 'ddos'),
                Divider(color: Colors.white.withOpacity(0.06), height: 20, thickness: 1),
                _buildMenuItem(Icons.person, "ACCOUNT", 'account'),
                if (canAccessSeller) _buildMenuItem(Icons.store, "SELLER", 'reseller'),
                if (canAccessAdmin) _buildMenuItem(Icons.admin_panel_settings, "ADMIN", 'admin'),
                _buildMenuItem(FontAwesomeIcons.whatsapp, "SENDER", 'sender'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String page) {
    bool isActive = _activePage == page;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.04),
        onTap: () => _selectFromDrawer(page),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: isActive
              ? BoxDecoration(
                  color: _primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryPurple.withOpacity(0.2), width: 1),
                )
              : null,
          child: Row(children: [
            Icon(icon, color: isActive ? _primaryPurple.withOpacity(0.85) : Colors.white.withOpacity(0.45), size: 18),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(
              color: isActive ? _primaryPurple.withOpacity(0.9) : Colors.white.withOpacity(0.75),
              fontSize: 13, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontFamily: "Rajdhani", letterSpacing: 1))),
            if (isActive)
              Container(width: 7, height: 7,
                decoration: BoxDecoration(color: _primaryPurple.withOpacity(0.7), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.5), blurRadius: 6)])),
          ]),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String title, String page) {
    bool isActive = _activePage == page;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectFromDrawer(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isActive ? _primaryPurple.withOpacity(0.12) : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? _primaryPurple.withOpacity(0.8) : Colors.white.withOpacity(0.4), size: 13),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isActive ? _primaryPurple.withOpacity(0.85) : Colors.white.withOpacity(0.5),
              fontSize: 12, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontFamily: "Rajdhani", letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────── BOTTOM NAV ───────────────────────────────────
  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _primaryPurple.withOpacity(0.1), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_filled, "HOME", 'home'),
                _buildNavItem(FontAwesomeIcons.whatsapp, "BUG", 'bug'),
                _buildNavItem(FontAwesomeIcons.paperPlane, "SPAM", 'telegram'),
                _buildNavItem(Icons.android, "RAT", 'rat'),
                _buildNavItem(Icons.menu, "MENU", 'more'),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildNavItem(IconData icon, String label, String page) {
  bool isActive = _activePage == page ||
      (page == 'bug' && (_activePage == 'group_bug' || _activePage == 'custom_bug'));
  return GestureDetector(
    onTap: () {
      if (page == 'more') {
        _showMoreMenu();
      } else if (page == 'bug') {
        _showBugOptionsSheet();
      } else {
        _selectFromDrawer(page);
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: isActive
          ? BoxDecoration(
              color: _primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryPurple.withOpacity(0.25), width: 1),
            )
          : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
          color: isActive ? _primaryPurple.withOpacity(0.9) : Colors.white.withOpacity(0.35),
          size: 22),
        if (isActive) ...[
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: _primaryPurple, fontSize: 9,
            fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
        ],
      ]),
    ),
  );
}

  void _showBugOptionsSheet() {
    final String currentRole = role.toLowerCase();
    final List<String> allowedGroupRoles = ['founder', 'moderator', 'high admin', 'owner', 'reseller', 'vip'];
    final bool canAccessGroup = allowedGroupRoles.contains(currentRole);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.97),
                border: Border.all(color: _primaryPurple.withOpacity(0.12), width: 1),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 20),
                Text("SELECT BUG TYPE",
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16,
                    fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 4)),
                const SizedBox(height: 24),
                _buildBugOption(Icons.person_outline, "CONTACT BUG", () { Navigator.pop(context); _selectFromDrawer('bug'); }),
                if (canAccessGroup) ...[
                  const SizedBox(height: 12),
                  _buildBugOption(FontAwesomeIcons.usersSlash, "GROUP BUG", () { Navigator.pop(context); _selectFromDrawer('group_bug'); }),
                ],
                const SizedBox(height: 12),
                _buildBugOption(Icons.code, "CUSTOM BUG", () { Navigator.pop(context); _selectFromDrawer('custom_bug'); }),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBugOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryPurple.withOpacity(0.1), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primaryPurple, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
        ]),
      ),
    );
  }

  // ─────────────────────────── BUILD ────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(width: 3, height: 18,
          decoration: BoxDecoration(color: _primaryPurple, borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.5), blurRadius: 6)])),
        const SizedBox(width: 10),
        Icon(icon, color: _primaryPurple, size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14,
          fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 3)),
      ],
    );
  }

  // ─────────────────────────── MODERN NEWS CAROUSEL ────────────────────────────────
  Widget _buildModernNewsCarousel() {
    final List<Map<String, dynamic>> dummyNews = [
      {"title": "SYSTEM UPDATE V3.0", "date": "2026-04-21", "image": "assets/images/news1.jpg", "isNew": true},
      {"title": "SECURITY PATCH", "date": "2026-05-08", "image": "assets/images/news2.jpg", "isNew": true},
      {"title": "NEW FEATURE", "date": "2026-05-05", "image": "assets/images/news3.jpg", "isNew": true},
      {"title": "GLOBAL UPDATE", "date": "2026-05-02", "image": "assets/images/news4.jpg", "isNew": true},
      {"title": "RAT TOOLS", "date": "2026-04-28", "image": "assets/images/news5.jpg", "isNew": true},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildSectionHeader(Icons.newspaper, "LATEST"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryPurple.withOpacity(0.15), width: 1),
              ),
              child: Text("${dummyNews.length} Updates",
                style: TextStyle(color: _primaryPurple, fontSize: 9,
                  fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: dummyNews.length,
            onPageChanged: (index) => setState(() { _currentNewsIndex = index; _currentNewsPage = index.toDouble(); }),
            itemBuilder: (context, index) {
              final item = dummyNews[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item['image'], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: _cardColor,
                          child: const Center(child: Icon(Icons.image, color: Colors.white12, size: 50)))),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _darkerBg.withOpacity(0.95)],
                            stops: const [0.4, 1.0]),
                        ),
                      ),
                      if (item['isNew'])
                        Positioned(
                          top: 14, right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _primaryPurple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _primaryPurple.withOpacity(0.3), width: 1),
                            ),
                            child: Text("NEW",
                              style: TextStyle(color: _primaryPurple, fontSize: 9,
                                fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
                          ),
                        ),
                      Positioned(
                        bottom: 20, left: 20, right: 20,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.access_time, color: Colors.white.withOpacity(0.4), size: 12),
                            const SizedBox(width: 6),
                            Text(item['date'],
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11,
                                fontFamily: "Rajdhani", fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text("DETAILS",
                                style: TextStyle(color: Colors.white70, fontSize: 9,
                                  fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
                            ),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (dummyNews.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(dummyNews.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 5, width: (1 - (_currentNewsPage - index).abs()).clamp(0.0, 1.0) > 0.5 ? 24 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: (1 - (_currentNewsPage - index).abs()).clamp(0.0, 1.0) > 0.5 ? _primaryPurple.withOpacity(0.7) : Colors.white.withOpacity(0.15),
                ),
              )),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────── NEWS PAGE (HOME) ─────────────────────────────
  Widget _buildNewsPage() {
  return Container(
    color: _darkerBg,
    child: RefreshIndicator(
      color: _primaryPurple,
      backgroundColor: _surfaceColor,
      onRefresh: () async {
        await _fetchActivityLogs();
        await _fetchAnimeData();
        await _fetchGovernmentNews();
        await _fetchWeather();
        _requestStats();
        await _fetchSholatTimes();
        setState(() {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 80)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWhatsAppCrashBanner(),
                const SizedBox(height: 20),
                // HANYA SATU _buildApiNewsList (yang untuk info developer)
                _buildApiNewsList(),
                const SizedBox(height: 20),
                Padding(
  padding: const EdgeInsets.symmetric(horizontal: 18),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("PRAKIRAAN CUACA 5 HARI",
        style: TextStyle(color: _primaryPurple, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      _buildWeather5Day(),
    ],
  ),
),
                const SizedBox(height: 24),
                _buildLatestAnimeSection(),
                const SizedBox(height: 28),
                _buildAccountStatsCard(),
                const SizedBox(height: 24),
                _buildWaktuSholatSection(),
                const SizedBox(height: 32),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildModernNewsCarousel(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildWaktuSholatSection() {
  if (_sholatTimes.isEmpty) {
    return const SizedBox.shrink();
  }

  final prayers = _sholatTimes.entries.toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _buildSectionHeader(Icons.mosque_rounded, "WAKTU SHOLAT"),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final item = prayers[index];
            final isNext = item.key == _nextPrayerName;
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryPurple.withOpacity(isNext ? 0.4 : 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.key,
                    style: TextStyle(color: isNext ? _primaryPurple : Colors.white70, fontWeight: FontWeight.bold)),
                  Text(item.value["arabic"]!,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  const SizedBox(height: 8),
                  Text(item.value["time"]!,
                    style: TextStyle(color: isNext ? _primaryPurple : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isNext)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_timeToNextPrayer,
                        style: TextStyle(color: _primaryPurple, fontSize: 8)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

  // ─────────────────────────── MAIN BUILD ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isRightSide = _assistiveTouchPosition.dx > (screenSize.width / 2);
    final bool isBottomSide = _assistiveTouchPosition.dy > (screenSize.height / 2);

    return WillPopScope(
      onWillPop: () async {
        if (_activePage != 'home') { _selectFromDrawer('home'); return false; }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _darkerBg,
        body: Stack(
          children: [
            // Background video/color
            if (_videoController != null && _videoController!.value.isInitialized)
              Opacity(opacity: 0.03, child: VideoPlayer(_videoController!))
            else
              Container(color: _darkerBg),

            SafeArea(
              top: false, bottom: false,
              child: FadeTransition(
                opacity: _animation,
                child: _activePage == 'home' ? _buildNewsPage() : _selectedPage,
              ),
            ),

            if (_activePage == 'home' || _activePage == 'settings')
              Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            if (_showAssistiveTouch) ...[
              if (_isAssistiveMenuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() { _isAssistiveMenuOpen = false; _isBugToolsExpanded = false; }),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                left: isRightSide ? _assistiveTouchPosition.dx - 290 : _assistiveTouchPosition.dx + 72,
                top: isBottomSide ? _assistiveTouchPosition.dy - 420 : _assistiveTouchPosition.dy,
                child: AnimatedScale(
                  scale: _isAssistiveMenuOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  alignment: isRightSide
                      ? (isBottomSide ? Alignment.bottomRight : Alignment.topRight)
                      : (isBottomSide ? Alignment.bottomLeft : Alignment.topLeft),
                  child: _buildAssistiveMenu(),
                ),
              ),
              Positioned(
                left: _assistiveTouchPosition.dx,
                top: _assistiveTouchPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      if (_isAssistiveMenuOpen) { _isAssistiveMenuOpen = false; _isBugToolsExpanded = false; }
                      double newX = (_assistiveTouchPosition.dx + details.delta.dx).clamp(0.0, screenSize.width - 62.0);
                      double newY = (_assistiveTouchPosition.dy + details.delta.dy).clamp(0.0, screenSize.height - 128.0);
                      _assistiveTouchPosition = Offset(newX, newY);
                    });
                  },
                  onTap: () => setState(() {
                    _isAssistiveMenuOpen = !_isAssistiveMenuOpen;
                    if (!_isAssistiveMenuOpen) _isBugToolsExpanded = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAssistiveMenuOpen ? _primaryPurple.withOpacity(0.15) : _cardColor,
                      border: Border.all(
                        color: _isAssistiveMenuOpen ? _primaryPurple.withOpacity(0.45) : _primaryPurple.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
                        if (_isAssistiveMenuOpen)
                          BoxShadow(color: _primaryPurple.withOpacity(0.2), blurRadius: 24),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_showBottomNav) _buildBottomNavBar(),
if (_activePage == 'home') _buildLaranganButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    channel?.sink.close(status.goingAway);
    _controller.dispose();
    _pageController.dispose();
    _actionPageController.dispose();
    _videoController?.dispose();
    _statsVideoController?.dispose();
    _otaxVideoController?.dispose();
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    _hourlySholatTimer?.cancel();
    _statsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

// ─── NEWS MEDIA WIDGET ────────────────────────────────────────────────────────
class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(1.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") || url.endsWith(".webm") || url.endsWith(".mov") || url.endsWith(".mkv");

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!));
      } else {
        return Center(child: CircularProgressIndicator(color: const Color(0xFFD500F9).withOpacity(0.6), strokeWidth: 2));
      }
    } else {
      return Image.network(
        widget.url, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF111118),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white12, size: 36))),
      );
    }
  }
}