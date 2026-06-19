// subdomain_finder_page.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SubdomainFinderPage extends StatefulWidget {
  final String sessionKey;

  const SubdomainFinderPage({super.key, required this.sessionKey});

  @override
  State<SubdomainFinderPage> createState() => _SubdomainFinderPageState();
}

class _SubdomainFinderPageState extends State<SubdomainFinderPage> with TickerProviderStateMixin {
  final TextEditingController _domainController = TextEditingController();
  List<String> _subdomains = [];
  bool _isLoading = false;

  // GLOWING GREY THEME
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

  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  // Video Controller
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initVideoBackground();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          _videoController?.setVolume(0.0);
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
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController!)),
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

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Future<void> _findSubdomains() async {
    if (_domainController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _subdomains = [];
    });
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/subdomain-finder?key=${widget.sessionKey}&domain=${_domainController.text}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            final allSubdomains = <String>{};
            for (var item in data['data']) {
              final subdomainList = item.toString().split('\n');
              for (var subdomain in subdomainList) {
                if (subdomain.isNotEmpty) {
                  allSubdomains.add(subdomain.trim());
                }
              }
            }
            _subdomains = allSubdomains.toList();
            _subdomains.sort();
          });
        } else {
          _showSnackBar('Failed to find subdomains', isError: true);
        }
      } else {
        _showSnackBar('Failed to connect to subdomain service', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
      backgroundColor: isError ? _roseColor.withOpacity(0.9) : _glowColor1.withOpacity(0.92),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
                  child: const Icon(FontAwesomeIcons.globe, color: Color(0xFFE0E0F8), size: 22),
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
                          "SUBDOMAIN FINDER",
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
                        "Discover hidden subdomains",
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "TARGET DOMAIN",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: "Rajdhani",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                color: _cardColor,
              ),
              child: TextField(
                controller: _domainController,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: "example.com",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                  prefixIcon: Icon(FontAwesomeIcons.search, color: _glowColor2.withOpacity(0.5), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _findSubdomains,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor1.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF070709), strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.magnifyingGlass, size: 16, color: Color(0xFF070709)),
                            SizedBox(width: 12),
                            Text(
                              "FIND SUBDOMAINS",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 3,
                                fontSize: 12,
                                color: Color(0xFF070709),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    if (_isLoading) {
      return _buildGlassCard(
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFE0E0F8)),
                SizedBox(height: 16),
                Text(
                  "SCANNING SUBDOMAINS...",
                  style: TextStyle(color: Colors.white54, fontFamily: 'Rajdhani', fontSize: 11, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_subdomains.isEmpty) {
      return _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(FontAwesomeIcons.globe, color: Colors.white.withOpacity(0.1), size: 50),
                const SizedBox(height: 16),
                Text(
                  "NO SUBDOMAINS FOUND",
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try entering a valid domain name",
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontFamily: 'Rajdhani', fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "RESULTS (${_subdomains.length})",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: "Rajdhani",
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final allText = _subdomains.join('\n');
                    Clipboard.setData(ClipboardData(text: allText));
                    _showSnackBar('All subdomains copied to clipboard!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(Icons.copy_all, color: _glowColor1, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _subdomains.length,
            itemBuilder: (context, index) {
              final subdomain = _subdomains[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.link, color: _glowColor1, size: 12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subdomain,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: subdomain));
                        _showSnackBar('Copied to clipboard!');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.copy, color: _glowColor2.withOpacity(0.6), size: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 8),
            _buildFooterText("SECURE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 8),
            _buildFooterText("ENCRYPTED"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "VANTHRA • SUBDOMAIN SCANNER",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildNeonHeader(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildSearchCard(),
                          const SizedBox(height: 20),
                          _buildResultsCard(),
                          const SizedBox(height: 32),
                          _buildFooter(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _videoController?.dispose();
    _domainController.dispose();
    super.dispose();
  }
}