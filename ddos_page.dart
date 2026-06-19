// tools_page.dart - Modified with Dark Yellow/Black theme

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart';
import 'subdomain_finder_page.dart';
import 'anime.dart';
import 'cdrama_page.dart';
import 'hentai.dart';
import 'games.dart';
import 'testfunc.dart';
import 'ai.dart';
import 'calendar.dart';
import 'kalkulator.dart';
import 'tiktok.dart';
import 'iqc.dart';
import 'meme.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;
  final String expiredDate;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
    required this.expiredDate,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with TickerProviderStateMixin {

  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<double> _headerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  late List<Animation<double>> _itemAnimations;

  late VideoPlayerController _videoController;

  // ==================== DARK YELLOW / GOLDEN THEME COLORS ====================
final Color _primaryColor = const Color(0xFF1A0B2E);      // Ungu kehitaman pekat
final Color _secondaryColor = const Color(0xFF2D1B4E);    // Ungu gelap
final Color _accentColor = const Color(0xFF7B2F9D);       // Ungu terang (aksen)

final Color _successColor = const Color(0xFF4A2A6B);
final Color _warningColor = const Color(0xFF6B3A8C);

final Color _darkBg = const Color(0xFF0D0418);            // Hitam ungu pekat
final Color _darkerBg = const Color(0xFF080210);          // Hitam pekat ungu
final Color _surfaceColor = const Color(0xFF140A24);      // Ungu hitam
final Color _cardColor = const Color(0xFF1A0B2E);         // Ungu kehitaman

final Color _glowColor1 = const Color(0xFF9B59B6);        // Ungu glow terang
final Color _glowColor2 = const Color(0xFF6C3483);        // Ungu glow medium
final Color _glowColor3 = const Color(0xFF8E44AD);        // Ungu glow lembut

final Color _goldColor = const Color(0xFF7B2F9D);         // Ungu metalik
final Color _darkGoldColor = const Color(0xFF4A2A6B);      // Ungu tua

final Color primaryDark = const Color(0xFF0D0418);
final Color primaryYellow = const Color(0xFF9B59B6);
final Color accentYellow = const Color(0xFFBB8FCE);
final Color neonYellow = const Color(0xFFD2B4DE);

final Color primaryWhite = Colors.white;
final Color cardDark = const Color(0xFF1A0B2E);
final Color cardDarker = const Color(0xFF140A24);

final Color borderGrey = const Color(0xFF6C3483);          // Ungu gelap untuk border
final Color glowColor = const Color(0x309B59B6);           // Glow ungu transparan

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset('assets/videos/banner.mp4')
          ..initialize().then((_) {
            _videoController.setLooping(true);
            _videoController.setVolume(1.0);
            _videoController.play();
            setState(() {});
          }).catchError((error) {
            debugPrint("Video initialization error: $error");
          });

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
    );

    _glowController.repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _rotateController.repeat();

    _headerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.linear,
      ),
    );
     // BUAT UBAH BERAPA TOOLS NYA X - HUB
    _itemAnimations = List.generate(
      14,
      (index) => Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.08,
            0.6 + (index * 0.08),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _videoController.dispose();

    super.dispose();
  }

  // =========================
  // GAMES
  // =========================

  void _navigateToGame(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const GamesPage(),
    ),
  );
}

  // Fungsi _showGamesMenu dan _showGameRankings masih ada tapi tidak digunakan lagi
  // (bisa dihapus jika ingin, tapi dibiarkan saja tidak masalah)

  void _showGamesMenu(BuildContext context) {
  _showEnhancedModalSheet(
    context,
    "Online Games",
    Icons.gamepad_rounded,
    [
      _buildEnhancedModalOption(
        icon: Icons.grid_3x3_rounded,
        label: "Tic Tac Toe",
        gradient: [
          const Color(0xFFD4A833),
          const Color(0xFFE8C25A),
        ],
        onTap: () {
  Navigator.pop(context);
  _navigateToGame(context);
},
      ),
      _buildEnhancedModalOption(
        icon: Icons.casino_rounded,
        label: "Play Chess",
        gradient: [
          const Color(0xFFB8922A),
          const Color(0xFFD4A833),
        ],
        onTap: () {
  Navigator.pop(context);
  _navigateToGame(context);
},
      ),
      _buildEnhancedModalOption(
        icon: Icons.smartphone_rounded,
        label: "Snake Game",
        gradient: [
          const Color(0xFF10B981),
          const Color(0xFF34D399),
        ],
        onTap: () {
  Navigator.pop(context);
  _navigateToGame(context);
},
      ),
      _buildEnhancedModalOption(
        icon: Icons.memory_rounded,
        label: "Memory Match",
        gradient: [
          const Color(0xFF8B5CF6),
          const Color(0xFFA78BFA),
        ],
          onTap: () {
  Navigator.pop(context);
  _navigateToGame(context);
},
      ),
      _buildEnhancedModalOption(
        icon: Icons.leaderboard_rounded,
        label: "Game Rankings",
        gradient: [
          const Color(0xFFD4A833),
          const Color(0xFFFFD700),
        ],
        onTap: () {
          _showGameRankings(context);
        },
      ),
    ],
  );
}

  void _showGameRankings(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardDark,
                cardDarker,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderGrey.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryYellow,
                      accentYellow,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [

                    Icon(
                      Icons.leaderboard_rounded,
                      color: primaryWhite,
                      size: 28,
                    ),

                    const SizedBox(width: 16),

                    Text(
                      "Game Rankings",
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [

                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Game rankings coming soon!",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Compete Winner !",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryYellow,
                            accentYellow,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GamesPage(),
                            ),
                          );
                        },

                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: primaryWhite,
                        ),

                        label: Text(
                          "PLAY NOW",
                          style: TextStyle(
                            color: primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

  // =========================
  // MODAL SHEET
  // =========================

  void _showEnhancedModalSheet(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> options,
  ) {

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,

      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),

        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,

          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardDark.withOpacity(0.95),
                cardDarker.withOpacity(0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),

            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),

            border: Border.all(
              color: borderGrey.withOpacity(0.3),
            ),
          ),

          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 60,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderGrey.withOpacity(0.3),
                    ),
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryYellow,
                            accentYellow,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),

                        borderRadius: BorderRadius.circular(12),

                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),

                      child: Icon(
                        icon,
                        color: primaryWhite,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Text(
                      title,
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: options,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedModalOption({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: borderGrey.withOpacity(0.3),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },

          borderRadius: BorderRadius.circular(16),

          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),

              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  gradient[0].withOpacity(0.05),
                ],

                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            child: Row(
              children: [

                Container(
                  width: 45,
                  height: 45,

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    borderRadius: BorderRadius.circular(12),

                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),

                  child: Center(
                    child: Icon(
                      icon,
                      color: primaryWhite,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Container(
                  width: 30,
                  height: 30,

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),

                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade500,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // BACKGROUND
  // =========================

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [

        if (_videoController.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,

              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,

                child: Opacity(
                  opacity: 0.18,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          )

        else
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.4),
                radius: 1.6,
                colors: [
                  _glowColor1.withOpacity(0.05),
                  _darkerBg,
                  _darkBg,
                ],
              ),
            ),
          ),
      ],
    );
  
}

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
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
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                      ),
                      child: Icon(Icons.build_circle, color: _glowColor1, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [_glowColor1, _accentColor, _glowColor2],
                          ).createShader(bounds),
                          child: const Text(
                            "UTILITY TOOLS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: "Rajdhani",
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Professional Toolkit",
                          style: TextStyle(
                            color: _glowColor2.withOpacity(0.6),
                            fontSize: 10,
                            fontFamily: "Rajdhani",
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_glowColor1, _glowColor2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 24,
                  child: MarqueeText(
                    text: "select a tool to begin • premium utilities • professional toolkit • ready to use",
                    style: TextStyle(
                      color: _glowColor1.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: "Rajdhani",
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedToolItem({
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradient,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 30),
          child: Opacity(
            opacity: animation.value,
            child: _PremiumToolItem(
              icon: icon,
              label: label,
              description: description,
              gradient: gradient,
              onTap: onTap,
              glowAnimation: _glowAnimation,
              cardColor: _cardColor,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Array tools ditambahin X-Hub dengan warna kuning
    final tools = [
  {
    'icon': FontAwesomeIcons.robot,
    'label': 'Chat AI',
    'description': 'AI Assistant',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.idCard,
    'label': 'NIK Check',
    'description': 'ID Validator',
    'gradient': [_glowColor2, _glowColor3]
  },

  {
    'icon': FontAwesomeIcons.phoneAlt,
    'label': 'Phone Lookup',
    'description': 'Number Info',
    'gradient': [_glowColor3, _glowColor1]
  },
  
  {
    'icon': FontAwesomeIcons.tiktok,
    'label': 'Tiktok Downloader',
    'description': 'Downloader Video Tiktok',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.globe,
    'label': 'Subdomain',
    'description': 'Domain Finder',
    'gradient': [_glowColor2, _accentColor]
  },
  
  {
    'icon': Icons.screenshot_monitor_rounded,
    'label': 'iqc',
    'description': 'Whatsapp Screenshot Fake',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.film,
    'label': 'Anime',
    'description': 'Streaming Hub',
    'gradient': [_glowColor1, _glowColor3]
  },
  
  {
    'icon': Icons.sentiment_very_satisfied,
    'label': 'meme',
    'description': 'Random Meme',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.tv,
    'label': 'C-Drama',
    'description': 'Chinese Drama',
    'gradient': [_glowColor1, _glowColor2]
  },
  
  {
    'icon': Icons.calculate,
    'label': 'Kalkulator',
    'description': 'Kalkulator perhitungan',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.gamepad,
    'label': 'Games',
    'description': 'Online Games',
    'gradient': [_glowColor2, _glowColor3]
  },
  
  {
    'icon': Icons.bolt,
    'label': 'Test Function',
    'description': 'Tes Yor Function',
    'gradient': [_glowColor1, _glowColor2]
  },

  {
    'icon': FontAwesomeIcons.fire,
    'label': 'X-Hub',
    'description': 'Adult Content',
    'gradient': [const Color(0xFFD4A833), _glowColor1]
  },
  
  {
  'icon': Icons.calendar_month,
  'label': 'Kalender',
  'description': 'Kalender & Galeri',
  'gradient': [_glowColor1, _glowColor2]
  }, 
];

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = tools[index];
                        return _buildAnimatedToolItem(
                          icon: tool['icon'] as IconData,
                          label: tool['label'] as String,
                          description: tool['description'] as String,
                          gradient: tool['gradient'] as List<Color>,
                          animation: _itemAnimations[index],
                          onTap: () => _navigateToTool(tool['label'] as String),
                        );
                      },
                      childCount: tools.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildFooter(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText("TOOLS READY"),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor3),
            const SizedBox(width: 10),
            _buildFooterText("SECURE"),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "VANTHRA v3.0 • PROFESSIONAL TOOLKIT",
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

  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'Rajdhani',
      ),
    );
  }

  void _navigateToTool(String toolName) {
    Widget page;

    switch (toolName) {
      case 'Chat AI':
        page = AIPage(username: widget.username, sessionKey: widget.sessionKey);
        break;
        
      case 'Kalender':
  page = const CalendarPage();
  break;

      case 'NIK Check':
        page = NIKCheckPage(sessionKey: widget.sessionKey);
        break;

      case 'Phone Lookup':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
        
        case 'Test Function':
  page = TestFunctionPage(
  username: widget.username,
  sessionKey: widget.sessionKey,
  role: widget.userRole,
  expiredDate: widget.expiredDate,
);
  break;

      case 'Anime':
        page = HomeAnimePage();
        break;
        
        case 'Tiktok Downloader':
        page = TiktokDownloaderPage();
        break;
        
        case 'Games':
      // LANGSUNG KE GAMES PAGE TANPA MODAL
      _navigateToGame(context);
      return;

      case 'Subdomain':
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;

      case 'C-Drama':
        page = const CDramaPage();
        break;
        
        case 'iqc':
        page = const IQCScreen();
        break;
        
        case 'meme':
        page = const MemeGeneratorPage();
        break;
        
        case 'Kalkulator':
        page = const KalkulatorPage();
        break;

      case 'X-Hub':
        page = const HomeHentaiPage();
        break;

      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {

          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },

        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// Marquee Text Widget
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final maxWidth = constraints.maxWidth;
              final textWidth = _measureTextWidth(widget.text, widget.style);
              if (textWidth <= maxWidth) return child!;
              final dx = maxWidth - (_controller.value * (maxWidth + textWidth));
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }
}

// Premium Tool Item dengan Glassmorphism
class _PremiumToolItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Animation<double> glowAnimation;
  final Color cardColor;

  const _PremiumToolItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
    required this.glowAnimation,
    required this.cardColor,
  });

  @override
  State<_PremiumToolItem> createState() => _PremiumToolItemState();
}

class _PremiumToolItemState extends State<_PremiumToolItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _isPressed ? widget.gradient[0].withOpacity(0.08) : widget.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isPressed 
                      ? widget.gradient[0].withOpacity(0.5) 
                      : widget.gradient[0].withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  if (_isPressed)
                    BoxShadow(
                      color: widget.gradient[0].withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  if (_isPressed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.gradient[0].withOpacity(0.1), Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ pakai spaceBetween
                      children: [
                        // Icon
                        AnimatedBuilder(
                          animation: widget.glowAnimation,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.gradient[0].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: widget.gradient[0].withOpacity(0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.gradient[0].withOpacity(0.2 * widget.glowAnimation.value),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(widget.icon, color: widget.gradient[0], size: 24),
                            );
                          },
                        ),
                        // Teks dan row bawah
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: "Rajdhani",
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 10,
                                fontFamily: "Rajdhani",
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: widget.gradient),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _isPressed ? widget.gradient[0] : Colors.white.withOpacity(0.25),
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Tools Hexagon Grid Painter
class ToolsHexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A833).withOpacity(0.05)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const double side = 28;
    const double height = side * 1.732;
    const double width = side * 1.5;

    for (double y = 0; y < size.height + height; y += height) {
      for (double x = 0; x < size.width + width; x += width) {
        final offset = (y / height) % 2 == 0 ? 0.0 : width / 2;
        _drawHexagon(canvas, Offset(x + offset, y), side, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double side, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * pi / 180;
      final x = center.dx + side * cos(angle);
      final y = center.dy + side * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// GridPatternPainter - Dipertahankan untuk kompatibilitas
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A833)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += gridSize) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}