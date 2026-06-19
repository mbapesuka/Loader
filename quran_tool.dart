import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class QuranTool extends StatefulWidget {
  const QuranTool({super.key});

  @override
  State<QuranTool> createState() => _QuranToolState();
}

class _QuranToolState extends State<QuranTool> with TickerProviderStateMixin {
  List<dynamic> _surahs = [];
  List<dynamic> _ayahs = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = "";
  int? _selectedSurah;
  String _translationLang = 'id.indonesian';

  // ========== ANIMATION CONTROLLERS (seperti di ToolsPage) ==========
  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<double> _headerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  late List<Animation<double>> _itemAnimations;

  // Video Controller
  VideoPlayerController? _videoController;

  // GLOWING GREY THEME (dipertahankan)
  final Color _primaryColor = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor = const Color(0xFFD8D8EC);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF161620);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _goldColor = const Color(0xFFCCBB88);
  final Color _roseColor = const Color(0xFFBB8899);

  final Map<String, String> translations = {
    'id.indonesian': 'Bahasa Indonesia',
    'en.asad': 'English',
    'ms.abdullah': 'Melayu',
  };

  // FALLBACK DATA (sama seperti sebelumnya)
  final List<Map<String, dynamic>> _fallbackSurahs = [
    {"number": 1, "name": "Al-Fatihah", "englishName": "The Opener", "ayahs": 7},
    {"number": 2, "name": "Al-Baqarah", "englishName": "The Cow", "ayahs": 286},
    {"number": 3, "name": "Ali 'Imran", "englishName": "Family of Imran", "ayahs": 200},
    {"number": 4, "name": "An-Nisa'", "englishName": "The Women", "ayahs": 176},
    {"number": 5, "name": "Al-Ma'idah", "englishName": "The Table Spread", "ayahs": 120},
    {"number": 6, "name": "Al-An'am", "englishName": "The Cattle", "ayahs": 165},
    {"number": 7, "name": "Al-A'raf", "englishName": "The Heights", "ayahs": 206},
    {"number": 8, "name": "Al-Anfal", "englishName": "The Spoils of War", "ayahs": 75},
    {"number": 9, "name": "At-Tawbah", "englishName": "The Repentance", "ayahs": 129},
    {"number": 10, "name": "Yunus", "englishName": "Jonah", "ayahs": 109},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers(); // <-- animasi baru
    _initVideoBackground(); // video dengan volume 1.0
    _loadSurahsWithFallback();
  }

  void _initControllers() {
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Jumlah item (surah) maksimal 114, kita buat 114 animasi agar semua surah bisa dianimasikan
    _itemAnimations = List.generate(
      114,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.008, // lebih rapat karena jumlah banyak
            0.6 + (index * 0.008),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/QurAn.mp4')
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          _videoController?.setVolume(1.0); // <-- volume 1.0 (bersuara)
          _videoController?.play();
          if (mounted) setState(() {});
        }).catchError((e) {
          debugPrint("Gagal memuat video background: $e");
        });
    } catch (e) {
      debugPrint("Exception saat memuat video: $e");
    }
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: Opacity(opacity: 0.18, child: VideoPlayer(_videoController!)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.4),
                radius: 1.6,
                colors: [_glowColor1.withOpacity(0.05), _darkerBg, _darkBg],
              ),
            ),
          ),

        // Rotating rings
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Stack(
              children: [
                Positioned(
                  bottom: -size.height * 0.15,
                  right: -size.width * 0.2,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * pi * 2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor1.withOpacity(0.05), width: 1),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -size.height * 0.08,
                  left: -size.width * 0.15,
                  child: Transform.rotate(
                    angle: -_rotateAnimation.value * pi,
                    child: Container(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor2.withOpacity(0.06), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ... (fungsi lain: _loadSurahsWithFallback, fetchAyahs, dll. SAMA PERSIS SEPERTI KODE SEBELUMNYA)
  // Agar tidak terlalu panjang, saya asumsikan fungsi-fungsi tersebut tetap sama.
  // Namun untuk memudahkan, saya akan tulis ulang yang penting.

  // ================== FUNGSI SAMA (tidak berubah) ==================
  Future<void> _loadSurahsWithFallback() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = "";
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          setState(() {
            _surahs = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
      _useFallbackData();
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    setState(() {
      _surahs = _fallbackSurahs;
      _isLoading = false;
      _isError = true;
      _errorMessage = "Using offline data. API connection failed.";
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  Future<void> fetchSurahs() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _surahs = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  Future<void> fetchAyahs(int surahNumber) async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final arabic = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber'),
      ).timeout(const Duration(seconds: 10));
      final translation = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/$_translationLang'),
      ).timeout(const Duration(seconds: 10));
      if (arabic.statusCode == 200 && translation.statusCode == 200) {
        final arabicData = jsonDecode(arabic.body);
        final translationData = jsonDecode(translation.body);
        if (arabicData['code'] == 200 && translationData['code'] == 200 &&
            arabicData['data'] != null && translationData['data'] != null) {
          final ayahsList = arabicData['data']['ayahs'];
          final translationList = translationData['data']['ayahs'];
          final ayahs = <Map<String, String>>[];
          for (int i = 0; i < ayahsList.length; i++) {
            ayahs.add({
              'arabic': ayahsList[i]['text'],
              'translation': translationList[i]['text'],
              'number': (i + 1).toString(),
            });
          }
          setState(() {
            _ayahs = ayahs;
            _isLoading = false;
          });
          return;
        }
      }
      _useFallbackAyahs(surahNumber);
    } catch (e) {
      _useFallbackAyahs(surahNumber);
    }
  }

  void _useFallbackAyahs(int surahNumber) {
    final fallbackAyahs = <Map<String, String>>[];
    for (int i = 1; i <= 7; i++) {
      fallbackAyahs.add({
        'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'translation': 'In the name of Allah, the Most Gracious, the Most Merciful.',
        'number': i.toString(),
      });
    }
    setState(() {
      _ayahs = fallbackAyahs;
      _isLoading = false;
      _isError = true;
      _errorMessage = "Using offline ayah data. API connection failed.";
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  // ========== BUILD HEADER dengan GLOW ==========
  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.12 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFFE0E0F8), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_glowColor1, _accentColor, _glowColor2],
                        ).createShader(bounds),
                        child: const Text(
                          "AL-QUR'AN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedSurah == null ? "${_surahs.length} Surahs" : "Read & Reflect",
                        style: TextStyle(
                          color: _glowColor2.withOpacity(0.7),
                          fontSize: 11,
                          fontFamily: "Rajdhani",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_selectedSurah != null) {
                      setState(() => _selectedSurah = null);
                    } else {
                      fetchSurahs();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(_selectedSurah != null ? Icons.arrow_back : Icons.refresh,
                        color: _glowColor1, size: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== BUILD FOOTER ==========
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 8),
            _buildFooterText("BLESSED"),
            const SizedBox(width: 20),
            Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 8),
            _buildFooterText("QUR'AN"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "VANTHRA • AL-QUR'AN DIGITAL",
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 3,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterDot(Color color) => Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 5)]));
  Widget _buildFooterText(String text) => Text(text, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2.5, fontFamily: 'Rajdhani'));

  // ========== SURAH LIST dengan ANIMASI ITEM ==========
  Widget _buildSurahList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0F8), strokeWidth: 3));
    }
    if (_surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: _glowColor1.withOpacity(0.5), size: 50),
            const SizedBox(height: 16),
            Text("Failed to load surahs", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchSurahs,
              style: ElevatedButton.styleFrom(backgroundColor: _glowColor1, foregroundColor: _darkerBg),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _surahs.length,
      itemBuilder: (context, index) {
        final surah = _surahs[index];
        // Menggunakan animasi item dari _itemAnimations
        return AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _itemAnimations[index].value) * 30),
              child: Opacity(
                opacity: _itemAnimations[index].value,
                child: child,
              ),
            );
          },
          child: _buildSurahCard(surah, index),
        );
      },
    );
  }

  Widget _buildSurahCard(dynamic surah, int index) {
    final number = surah['number']?.toString() ?? (index + 1).toString();
    final name = surah['name'] ?? 'Unknown';
    final englishName = surah['englishName'] ?? 'Surah';
    final ayahsCount = surah['ayahs'] ?? 7;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSurah = int.tryParse(number) ?? 1;
            fetchAyahs(_selectedSurah!);
          });
        },
        child: _buildGlassCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
              ),
              child: Center(child: Text(number, style: TextStyle(color: _glowColor1, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: "Rajdhani"))),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: "Rajdhani", fontSize: 15, letterSpacing: 1)),
            subtitle: Text('$englishName • $ayahsCount verses', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontFamily: "Rajdhani", fontWeight: FontWeight.w500)),
            trailing: Text(name, style: TextStyle(color: _glowColor2.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: "Traditional Arabic")),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  // ========== AYAH LIST (tidak diubah banyak) ==========
  Widget _buildAyahList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: Border(bottom: BorderSide(color: _glowColor1.withOpacity(0.1), width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedSurah = null),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(Icons.arrow_back, color: _glowColor1, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Surah $_selectedSurah', style: TextStyle(color: _glowColor2.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: "Rajdhani")),
                    const SizedBox(height: 4),
                    Text(_surahs.firstWhere((s) => s['number'] == _selectedSurah, orElse: () => {'name': 'Loading...'})['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: "Rajdhani", letterSpacing: 1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                ),
                child: DropdownButton<String>(
                  value: _translationLang,
                  dropdownColor: _cardColor,
                  underline: const SizedBox(),
                  icon: Icon(Icons.language, color: _glowColor1, size: 18),
                  style: TextStyle(color: _glowColor1, fontFamily: "Rajdhani", fontSize: 12, fontWeight: FontWeight.w600),
                  onChanged: (String? newValue) {
                    setState(() => _translationLang = newValue!);
                    if (_selectedSurah != null) fetchAyahs(_selectedSurah!);
                  },
                  items: translations.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0F8), strokeWidth: 3))
              : _ayahs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: _glowColor1.withOpacity(0.5), size: 50),
                          const SizedBox(height: 16),
                          Text("Failed to load ayahs", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => fetchAyahs(_selectedSurah!),
                            style: ElevatedButton.styleFrom(backgroundColor: _glowColor1, foregroundColor: _darkerBg),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ayahs.length,
                      itemBuilder: (context, index) {
                        final ayah = _ayahs[index];
                        return _buildAyahCard(ayah);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAyahCard(Map<String, String> ayah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(ayah['arabic']!, style: TextStyle(color: _glowColor1, fontSize: 22, fontFamily: 'Traditional Arabic', height: 1.6), textAlign: TextAlign.right),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: _glowColor1.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1)),
                    child: Center(child: Text(ayah['number']!, style: TextStyle(color: _glowColor1, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: "Rajdhani"))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ayah['translation']!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontFamily: "Rajdhani", fontWeight: FontWeight.w500, height: 1.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNeonHeader(),
                if (_isError && _errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _warningColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _warningColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _warningColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage, style: TextStyle(color: _warningColor, fontSize: 11))),
                      ],
                    ),
                  ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _headerAnimation,
                    builder: (context, child) {
                      return Opacity(opacity: _headerAnimation.value, child: child);
                    },
                    child: _selectedSurah == null ? _buildSurahList() : _buildAyahList(),
                  ),
                ),
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}