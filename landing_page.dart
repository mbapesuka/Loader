import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> pulseAnimation;
  late final VideoPlayerController _videoController;

  final Color _yellow = const Color(0xFFFFFFFF);      // putih
final Color _yellowSoft = const Color(0xFFF0F0F0); // abu-abu sangat terang
final Color _darkBg = const Color(0xFF000000);      // hitam pekat
final Color _card = const Color(0xFF1A1A1A);        // hitam keabu-abuan (card gelap)
final Color _card2 = const Color(0xFF2A2A2A);       // abu-abu gelap
final Color _border = const Color(0xFF555555);      // abu-abu medium

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, .12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    pulseAnimation = Tween<double>(begin: .92, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _videoController = VideoPlayerController.asset('assets/videos/animek.mp4')
      ..initialize().then((_) {
        _videoController
          ..setLooping(true)
          ..setVolume(1.0)
          ..play();
        if (mounted) setState(() {});
      }).catchError((error) {
        debugPrint('Video initialization error: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Error launching $uri');
    }
  }

  Widget _glass({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _card.withOpacity(.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border.withOpacity(.95), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.65),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: _yellow.withOpacity(.08),
                blurRadius: 40,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 1.35,
              colors: [
                _yellow.withOpacity(.10),
                const Color(0xFF17130A),
                _darkBg,
              ],
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -110,
          child: _orb(250, .13),
        ),
        Positioned(
          bottom: 110,
          right: -120,
          child: _orb(300, .09),
        ),
        CustomPaint(size: Size.infinite, painter: _DotPainter(_yellow)),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(.75)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_yellow.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }

  Widget _topLogoCard() {
    return Center(
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: _card2.withOpacity(.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border.withOpacity(.8)),
          boxShadow: [
            BoxShadow(color: _yellow.withOpacity(.10), blurRadius: 35),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _yellow.withOpacity(.35), width: 1.2),
                boxShadow: [
                  BoxShadow(color: _yellow.withOpacity(.10), blurRadius: 24),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black.withOpacity(.35),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: _yellow.withOpacity(.75),
                          size: 38,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BASE BUG',
              style: TextStyle(
                color: Colors.white.withOpacity(.92),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Rajdhani',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, _yellow, _yellowSoft],
          ).createShader(bounds),
          child: const Text(
            'BASE BUG',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 47,
              fontWeight: FontWeight.w900,
              fontFamily: 'Rajdhani',
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniLine(),
            const SizedBox(width: 10),
            Text(
              'SPYWARE • BUG • STABIL',
              style: TextStyle(
                color: _yellow.withOpacity(.65),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
                letterSpacing: 5,
              ),
            ),
            const SizedBox(width: 10),
            _miniLine(),
          ],
        ),
      ],
    );
  }

  Widget _miniLine() => Container(
        width: 38,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, _yellow.withOpacity(.75)],
          ),
        ),
      );

  Widget _infoCard() {
    return _glass(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _yellow.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _yellow.withOpacity(.35)),
            ),
            child: Icon(Icons.shield_outlined, color: _yellow, size: 26),
          ),
          const SizedBox(height: 22),
          Text(
            'BASE BUG',
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Rajdhani',
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi dengan design elegant dan fitur terbaru. Pengembangan langsung oleh TEAM BASE.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.46),
              fontSize: 13,
              height: 1.7,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }


  Widget _videoCard() {
    return _glass(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: _videoController.value.isInitialized
              ? _videoController.value.aspectRatio
              : 16 / 9,
          child: _videoController.value.isInitialized
              ? VideoPlayer(_videoController)
              : Container(
                  color: Colors.black.withOpacity(.45),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _yellow,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _baseMenuCard() {
    final items = [
      _MenuItem(FontAwesomeIcons.bug, 'CRASH WA', 'Real time bug system'),
      _MenuItem(FontAwesomeIcons.eye, 'SPYWARE', 'Device monitoring panel'),
      _MenuItem(FontAwesomeIcons.locationDot, 'TRACKING', 'Live target location'),
      _MenuItem(FontAwesomeIcons.userShield, 'ADMIN ACCESS', 'Protected base control'),
      _MenuItem(FontAwesomeIcons.clock, '24/7 ACTIVE', 'Server always online'),
      _MenuItem(FontAwesomeIcons.lock, 'ANTI KENON', 'Stabil dan private'),
    ];

    return _glass(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: _yellow, size: 18),
              const SizedBox(width: 10),
              Text(
                'BASE MENU',
                style: TextStyle(
                  color: Colors.white.withOpacity(.86),
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _yellow.withOpacity(.22)),
                ),
                child: Text(
                  'ONLINE',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Rajdhani',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.62,
            ),
            itemBuilder: (context, index) => _menuTile(items[index]),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(_MenuItem item) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C08).withOpacity(.92),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _yellow.withOpacity(.18)),
        boxShadow: [BoxShadow(color: _yellow.withOpacity(.04), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _yellow.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _yellow.withOpacity(.22)),
            ),
            child: Center(
              child: FaIcon(item.icon, color: _yellow.withOpacity(.92), size: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.86),
                    fontSize: 11,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.35),
                    fontSize: 8,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _yellow.withOpacity(.20 * pulseAnimation.value),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
            settings: const RouteSettings(name: '/login'),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _yellow.withOpacity(.75), width: 1.3),
            gradient: LinearGradient(
              colors: [_yellow.withOpacity(.10), _yellow.withOpacity(.03)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.rocket, color: _yellow, size: 17),
              const SizedBox(width: 14),
              Text(
                'LOGIN TO BASE',
                style: TextStyle(
                  color: _yellow,
                  fontSize: 13,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supportButton() {
    return GestureDetector(
      onTap: () => _openUrl('https://t.me/aboutmeyuji'),
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: _card.withOpacity(.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.headset, color: Colors.white.withOpacity(.45), size: 16),
            const SizedBox(width: 14),
            Text(
              'CONTACT SUPPORT',
              style: TextStyle(
                color: Colors.white.withOpacity(.48),
                fontSize: 12,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialCard() {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Text(
            'HUBUNGI KAMI',
            style: TextStyle(
              color: Colors.white.withOpacity(.30),
              fontSize: 10,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _social(FontAwesomeIcons.telegram, 'Telegram OTA', 'https://t.me/aboutmeyuji'),
              const SizedBox(width: 26),
              _social(FontAwesomeIcons.telegram, 'Telegram Xrelly', 'https://t.me/aboutmeyuji'),
              const SizedBox(width: 26),
              _social(FontAwesomeIcons.tiktok, 'TikTok', 'https://tiktok.com'),
            ],
          ),
          const SizedBox(height: 22),
          Divider(color: Colors.white.withOpacity(.07)),
          const SizedBox(height: 14),
          Text(
            '© 2026 BASE BUG. All in For You',
            style: TextStyle(
              color: Colors.white.withOpacity(.20),
              fontSize: 10,
              fontFamily: 'Rajdhani',
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _social(IconData icon, String label, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _yellow.withOpacity(.07),
              shape: BoxShape.circle,
              border: Border.all(color: _yellow.withOpacity(.18)),
              boxShadow: [BoxShadow(color: _yellow.withOpacity(.08), blurRadius: 22)],
            ),
            child: Center(child: FaIcon(icon, color: _yellow.withOpacity(.78), size: 21)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.45),
              fontSize: 10,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
                  child: Column(
                    children: [
                      _topLogoCard(),
                      const SizedBox(height: 36),
                      _titleBlock(),
                      const SizedBox(height: 34),
                      _infoCard(),
                      const SizedBox(height: 22),
                      _videoCard(),
                      const SizedBox(height: 22),
                      _baseMenuCard(), // menu SPYWARE dll sengaja dipasang di atas login
                      const SizedBox(height: 22),
                      _loginButton(),
                      const SizedBox(height: 16),
                      _supportButton(),
                      const SizedBox(height: 34),
                      _socialCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MenuItem(this.icon, this.title, this.subtitle);
}

class _DotPainter extends CustomPainter {
  final Color color;

  _DotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(.055);
    for (double y = 0; y < size.height; y += 22) {
      for (double x = 0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), .8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
