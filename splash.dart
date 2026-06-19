import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

// Import ini berisi DashboardPage
import 'loader_page.dart';

class SplashPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _slideController;
  late AnimationController _scanController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scanAnimation;

  // GLOWING GREY PALETTE
  final Color _primaryColor   = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor    = const Color(0xFFD8D8EC);
  final Color _successColor   = const Color(0xFF8899AA);
  final Color _darkBg         = const Color(0xFF0C0C10);
  final Color _darkerBg       = const Color(0xFF070709);
  final Color _surfaceColor   = const Color(0xFF161620);
  final Color _cardColor      = const Color(0xFF111118);
  final Color _glowColor1     = const Color(0xFFE0E0F8);
  final Color _glowColor2     = const Color(0xFF9090B4);
  final Color _glowColor3     = const Color(0xFFBBBBD0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _rotateController.repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _scanController.repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/videos/load.mp4')
      ..initialize().then((_) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        setState(() => _isInitialized = true);
        _controller.play();
        _controller.setVolume(1);
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
        setState(() => _isInitialized = true);
        Future.delayed(const Duration(seconds: 3), _navigateToDashboard);
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    _controller.pause();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: widget.data['username'] ?? '',
            password: widget.data['password'] ?? '',
            role: widget.data['role'] ?? 'user',
            expiredDate: widget.data['expiredDate'] ?? '-',
            sessionKey: widget.data['key'] ?? '',
            listBug: List<Map<String, dynamic>>.from(widget.data['listBug'] ?? []),
            listPayload: List<Map<String, dynamic>>.from(widget.data['listPayload'] ?? []),
            listDDoS: List<Map<String, dynamic>>.from(widget.data['listDDoS'] ?? []),
            news: List<Map<String, dynamic>>.from(widget.data['news'] ?? []),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ─── VIDEO / BASE LAYER ───────────────────────────────────────────────────
  Widget _buildBaseLayer() {
    if (_isInitialized && _controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: Opacity(opacity: 0.25, child: VideoPlayer(_controller)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 1.6,
          colors: [_glowColor1.withOpacity(0.05), _darkerBg, _darkBg],
        ),
      ),
    );
  }

  // ─── ROTATING RING + ORBS ─────────────────────────────────────────────────
  Widget _buildDecorLayer(Size size) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            // Large rotating ring — bottom right
            Positioned(
              bottom: -size.height * 0.18,
              right: -size.width * 0.22,
              child: Transform.rotate(
                angle: _rotateAnimation.value * pi * 2,
                child: Container(
                  width: size.width * 0.72,
                  height: size.width * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _glowColor1.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Medium ring — top left
            Positioned(
              top: -size.height * 0.08,
              left: -size.width * 0.18,
              child: Transform.rotate(
                angle: -_rotateAnimation.value * pi,
                child: Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _glowColor2.withOpacity(0.06),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            // Glow orb top-left
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_glowColor1.withOpacity(0.07), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Glow orb bottom-right
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_glowColor2.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── SCAN LINE ────────────────────────────────────────────────────────────
  Widget _buildScanLine(Size size) {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, _) {
        final top = _scanAnimation.value * size.height;
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _glowColor1.withOpacity(0.12),
                  _glowColor1.withOpacity(0.2),
                  _glowColor1.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── VIGNETTE OVERLAY ────────────────────────────────────────────────────
  Widget _buildVignette() {
    return Container(
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
    );
  }

  // ─── TOP LEFT CORNER TAG ──────────────────────────────────────────────────
  Widget _buildCornerTag() {
    return Positioned(
      top: 52,
      left: 22,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  color: _glowColor1,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.7), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text("VANTHRA SECURITY",
                style: TextStyle(
                  color: _glowColor1.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 3.5,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text("SYSTEM BOOT v3.0",
              style: TextStyle(
                color: Colors.white.withOpacity(0.18),
                fontSize: 8,
                letterSpacing: 2,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SKIP BUTTON (top right) ──────────────────────────────────────────────
  Widget _buildSkipButton() {
    return Positioned(
      top: 52,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: _navigateToDashboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SKIP",
                  style: TextStyle(
                    color: _glowColor1.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, color: _glowColor1.withOpacity(0.4), size: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── MAIN LOGO BLOCK (left-aligned, asymmetric) ───────────────────────────
  Widget _buildLogoBlock() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hexagon icon + title on the same line
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Icon square
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _glowColor1.withOpacity(0.22), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor1.withOpacity(0.2 * _glowAnimation.value),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text("N",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: _glowColor1,
                        fontFamily: 'Rajdhani',
                        shadows: [
                          Shadow(color: _glowColor1.withOpacity(0.6 * _glowAnimation.value), blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Title stacked
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text("VANTHRA",
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 4,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: _glowColor1.withOpacity(0.35 * _glowAnimation.value),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(children: [
                      Container(
                        width: 24, height: 1.2,
                        color: _glowColor2.withOpacity(0.4),
                      ),
                      const SizedBox(width: 8),
                      Text("SECURITY PLATFORM",
                        style: TextStyle(
                          color: _glowColor2.withOpacity(0.6),
                          fontSize: 9,
                          letterSpacing: 3.5,
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Glow progress bar — full width
            _buildGlowBar(),
          ],
        );
      },
    );
  }

  Widget _buildGlowBar() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar track
            Stack(children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _glowAnimation.value,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_glowColor1.withOpacity(0.9), _glowColor2.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: _glowColor1.withOpacity(0.45), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("INITIALIZING SYSTEM",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.55),
                    fontSize: 8,
                    letterSpacing: 3,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text("${(_glowAnimation.value * 100).toInt()}%",
                  style: TextStyle(
                    color: _glowColor1.withOpacity(0.5),
                    fontSize: 9,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─── VERTICAL STATUS TAGS (right side) ───────────────────────────────────
  Widget _buildVerticalTags() {
    final tags = ["SECURE", "ENCRYPTED", "AUDITED", "ACTIVE"];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: tags.asMap().entries.map((e) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + e.key * 120),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) {
            return Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(20 * (1 - v), 0), child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 5)],
                ),
              ),
              const SizedBox(width: 7),
              Text(e.value,
                style: TextStyle(
                  color: _glowColor1.withOpacity(0.55),
                  fontSize: 8,
                  letterSpacing: 2,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ─── STATUS CHIP (boot indicator) ─────────────────────────────────────────
  Widget _buildStatusChip() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: _successColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _successColor.withOpacity(0.7 * _glowAnimation.value),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text("SECURE BOOT  •  ONLINE",
              style: TextStyle(
                color: _successColor.withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                fontFamily: 'Rajdhani',
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        // Thin separator
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(_glowColor3),
            const SizedBox(width: 7),
            _footerLabel("SECURE"),
            const SizedBox(width: 16),
            Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 16),
            _dot(_glowColor2),
            const SizedBox(width: 7),
            _footerLabel("ENCRYPTED"),
            const SizedBox(width: 16),
            Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 16),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
          ],
        ),
        const SizedBox(height: 10),
        Text("VANTHRA v3.0  •  ADVANCED SECURITY",
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 7,
            color: Colors.white.withOpacity(0.1),
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _dot(Color c) => Container(
    width: 4, height: 4,
    decoration: BoxDecoration(
      color: c, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c, blurRadius: 4)],
    ),
  );

  Widget _footerLabel(String t) => Text(t,
    style: TextStyle(
      color: Colors.white.withOpacity(0.25),
      fontSize: 8,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      fontFamily: 'Rajdhani',
    ),
  );

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base video / gradient
          _buildBaseLayer(),

          // 2. Decorative rings & orbs
          _buildDecorLayer(size),

          // 3. Vignette
          _buildVignette(),

          // 4. Scan line
          _buildScanLine(size),

          // 5. Top left corner tag
          _buildCornerTag(),

          // 6. Skip button
          _buildSkipButton(),

          // 7. Main content — asymmetric layout
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: size.height * 0.12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Row: logo block left + vertical tags right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLogoBlock()),
                        const SizedBox(width: 20),
                        _buildVerticalTags(),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Status chip
                    _buildStatusChip(),

                    const SizedBox(height: 28),

                    // Horizontal mini info grid
                    _buildInfoGrid(),
                  ],
                ),
              ),
            ),
          ),

          // 8. Footer
          Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildFooter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    final items = [
      {"label": "PROTOCOL", "value": "AES-256"},
      {"label": "STATUS", "value": "ONLINE"},
      {"label": "BUILD", "value": "V3.0"},
    ];
    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _glowColor1.withOpacity(0.09), width: 1),
            ),
            child: Column(
              children: [
                Text(e.value["value"]!,
                  style: TextStyle(
                    color: _glowColor1.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Rajdhani',
                    letterSpacing: 1,
                    shadows: [Shadow(color: _glowColor1.withOpacity(0.3), blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.value["label"]!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 7,
                    letterSpacing: 2,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
