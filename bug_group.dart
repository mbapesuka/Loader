import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage> with TickerProviderStateMixin {
  final linkGroupController = TextEditingController();
  static const String baseUrl = "http://kinncloud.sistems.tech:2052";

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  bool _isSending = false;
  int _activeStep = 0;

  // DARK GOLDEN/BLACK THEME - Kuning kehitaman
  final Color _primaryColor = const Color(0xFFD4A017); // Dark Gold
  final Color _secondaryColor = const Color(0xFF8B6914); // Olive Gold
  final Color _accentColor = const Color(0xFFF5B81B); // Bright Gold
  final Color _successColor = const Color(0xFFDAA520); // Goldenrod
  final Color _warningColor = const Color(0xFFB8860B); // Dark Goldenrod
  final Color _darkBg = const Color(0xFF0A0A05); // Almost Black with slight yellow tint
  final Color _darkerBg = const Color(0xFF050502); // Pure Dark
  final Color _surfaceColor = const Color(0xFF111108); // Dark surface
  final Color _cardColor = const Color(0xFF0C0C06); // Card dark
  final Color _glowColor1 = const Color(0xFFF5B81B); // Bright Gold glow
  final Color _glowColor2 = const Color(0xFFD4A017); // Dark Gold glow
  final Color _glowColor3 = const Color(0xFFB8860B); // Darker Gold
  final Color _goldColor = const Color(0xFFF5B81B); // Gold
  final Color _roseColor = const Color(0xFF8B6914); // Olive Gold

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _startAnimations();
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _glowController.repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseController.repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _rotateController.repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _initializeVideoController() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(1);
          }
        }).catchError((error) {
          debugPrint('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    } catch (e) {
      debugPrint('Video controller creation error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  bool _isValidGroupLink(String input) {
    final regex = RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}');
    return regex.hasMatch(input);
  }

  Future<void> _sendGroupBug() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final linkGroup = linkGroupController.text.trim();
    final key = widget.sessionKey;

    if (linkGroup.isEmpty || !_isValidGroupLink(linkGroup)) {
      _showAlert("Invalid Link", "Please enter a valid WhatsApp group link.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/groupBug?key=$key&linkGroup=$linkGroup"));
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("Failed", data["message"] ?? "Failed to send group bug.");
      } else {
        setState(() {
          _activeStep = 2;
        });
        _showSuccessPopup(linkGroup, data);
      }
    } catch (_) {
      _showAlert("Connection Error", "Failed to connect to the server. Please try again.");
    } finally {
      setState(() {
        _isSending = false;
        if (_activeStep != 2) _activeStep = 0;
      });
    }
  }

  void _showSuccessPopup(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GroupBugSuccessDialog(
        linkGroup: linkGroup,
        data: data,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() {
            _activeStep = 0;
          });
        },
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceColor.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: _glowColor1.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
              ),
              child: Icon(title.contains("Error") ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  color: _glowColor1, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            height: 1.6,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text(
              "CLOSE",
              style: TextStyle(
                color: _glowColor1.withOpacity(0.7),
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MODERN UI BUILDERS ====================

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoInitialized && !_videoError)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController)),
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
                        border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
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
                        border: Border.all(color: _glowColor2.withOpacity(0.1), width: 0.8),
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
                Colors.black.withOpacity(0.65),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 12)),
          BoxShadow(color: _glowColor1.withOpacity(0.06), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNeonHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: _glowColor1.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.35 * _glowAnimation.value),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
                color: _cardColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.whatsapp, color: _glowColor1, size: 22),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_glowColor1, _accentColor, _goldColor],
                    ).createShader(bounds),
                    child: const Text(
                      "GROUP BUG",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(FontAwesomeIcons.whatsapp, color: _glowColor1, size: 22),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _successColor.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _successColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _successColor, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "GROUP ATTACK READY",
                style: TextStyle(
                  color: _successColor.withOpacity(0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _surfaceColor,
                          border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.25), blurRadius: 20),
                          ],
                        ),
                        child: Center(
                          child: ClipOval(
  child: Image.asset(
    'assets/images/abc.jpg',
    width: 30,
    height: 30,
    fit: BoxFit.cover,
  ),
),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                        ),
                        child: Text(
                          widget.role.toUpperCase(),
                          style: TextStyle(
                            color: _glowColor1.withOpacity(0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontFamily: 'Rajdhani',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(FontAwesomeIcons.users, "GROUP", "Target", _glowColor1),
                _buildStatChip(FontAwesomeIcons.bolt, "MASS", "Attack", _glowColor2),
                _buildStatChip(Icons.calendar_today, widget.expiredDate, "Until", _goldColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color.withOpacity(0.9), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Rajdhani',
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }

  Widget _buildGroupLinkCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(FontAwesomeIcons.link, color: _glowColor1.withOpacity(0.8), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "TARGET GROUP LINK",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
              ),
              child: TextField(
                controller: linkGroupController,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: "https://chat.whatsapp.com/xxxxxxxxxx",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                  prefixIcon: Icon(FontAwesomeIcons.whatsapp, color: _glowColor2.withOpacity(0.5), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.25), size: 11),
                const SizedBox(width: 6),
                Text(
                  "Enter valid WhatsApp group invite link",
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(FontAwesomeIcons.bolt, "Instant", "Delivery"),
            _buildInfoItem(FontAwesomeIcons.bullseye, "High", "Accuracy"),
            _buildInfoItem(FontAwesomeIcons.lock, "Secure", "Process"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String line1, String line2) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _glowColor1.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: _glowColor1.withOpacity(0.8), size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          line1,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Rajdhani'),
        ),
        Text(
          line2,
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, fontFamily: 'Rajdhani'),
        ),
      ],
    );
  }

  Widget _buildAttackButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTap: _isSending ? null : _sendGroupBug,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_glowColor1, _accentColor, _goldColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.45 * _glowAnimation.value),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSending)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _darkerBg,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(FontAwesomeIcons.skullCrossbones, color: Color(0xFF0A0A05), size: 18),
                  const SizedBox(width: 12),
                  Text(
                    _isSending ? "EXECUTING..." : "LAUNCH GROUP STRIKE",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: _darkerBg,
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

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.15), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText("SECURE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 10),
            _buildFooterText("ENCRYPTED"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "EXP: ${widget.expiredDate} • VANTHRA SECURITY",
          style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 8, letterSpacing: 2.5, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
        ),
        if (_activeStep > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              value: _activeStep / 2,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: _glowColor1,
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
    // Role-based access control
    final allowedRoles = ["vip", "owner", "high admin", "reseller", "founder", "moderator", "dev"];
    if (!allowedRoles.contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: _darkerBg,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.1 + 0.05 * _glowAnimation.value),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _roseColor.withOpacity(0.4 + 0.1 * _glowAnimation.value),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _roseColor.withOpacity(0.2 * _glowAnimation.value),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          FontAwesomeIcons.lock,
                          color: Color(0xFFD4A017),
                          size: 50,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "ACCESS DENIED",
                    style: TextStyle(
                      color: _roseColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      "This feature is only available for VIP, Owner, Reseller, Founder, Moderator users",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildNeonHeader(),
                        const SizedBox(height: 32),
                        _buildUserProfileCard(),
                        const SizedBox(height: 24),
                        _buildGroupLinkCard(),
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 32),
                        _buildAttackButton(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _videoController.dispose();
    linkGroupController.dispose();
    super.dispose();
  }
}

// Custom success dialog for group bug (Dark Gold Version)
class GroupBugSuccessDialog extends StatefulWidget {
  final String linkGroup;
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const GroupBugSuccessDialog({
    super.key,
    required this.linkGroup,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<GroupBugSuccessDialog> createState() => _GroupBugSuccessDialogState();
}

class _GroupBugSuccessDialogState extends State<GroupBugSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showDetails = false;

  // DARK GOLDEN/BLACK THEME
  final Color _glowColor1 = const Color(0xFFF5B81B); // Bright Gold
  final Color _glowColor2 = const Color(0xFFD4A017); // Dark Gold
  final Color _accentColor = const Color(0xFFF5B81B);
  final Color _successColor = const Color(0xFFDAA520);
  final Color _cardColor = const Color(0xFF0C0C06);
  final Color _surfaceColor = const Color(0xFF111108);
  final Color _darkerBg = const Color(0xFF050502);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowController.repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showDetails = true;
        });
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.6;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _surfaceColor.withOpacity(0.96),
                    _cardColor.withOpacity(0.96),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.25), blurRadius: 40, spreadRadius: 4),
                ],
              ),
              child: Stack(
                children: [
                  // Success icon and title
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: _glowColor1.withOpacity(0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _glowColor1.withOpacity(0.5 * _glowAnimation.value),
                                    blurRadius: 35,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                FontAwesomeIcons.skullCrossbones,
                                color: Color(0xFFF5B81B),
                                size: 42,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFFF5B81B), Color(0xFFDAA520), Color(0xFFD4A017)],
                          ).createShader(bounds),
                          child: const Text(
                            "GROUP OBLITERATED",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Rajdhani',
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Attack details
                  if (_showDetails)
                    Positioned(
                      top: 150,
                      left: 20,
                      right: 20,
                      bottom: 90,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _glowColor1.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                                        ),
                                        child: const Icon(Icons.report, color: Color(0xFFF5B81B), size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "EXECUTION REPORT",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Rajdhani',
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _buildDetailRow("Target", widget.linkGroup),
                                  const SizedBox(height: 10),
                                  _buildDetailRow("Status", widget.data["success"] == true ? "FATAL" : "FAILED", 
                                      isSuccess: widget.data["success"] == true),
                                  if (widget.data["canSendMessage"] != null)
                                    _buildDetailRow("Injection", widget.data["canSendMessage"] == true ? "SUCCESS" : "BLOCKED", 
                                        isSuccess: widget.data["canSendMessage"] == true),
                                  if (widget.data["groupInfo"] != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _surfaceColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildDetailRow("Group Name", widget.data["groupInfo"]["subject"]?.toString() ?? "Unknown"),
                                          const SizedBox(height: 8),
                                          _buildDetailRow("Members", widget.data["groupInfo"]["participants"]?.toString() ?? "Unknown"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Close button
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_glowColor1, _accentColor, _goldColor],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.4), blurRadius: 20),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "DISMISS",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Rajdhani',
                              letterSpacing: 3,
                              color: Color(0xFF050502),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSuccess = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              "[$label]",
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isSuccess ? _glowColor1 : const Color(0xFFB8860B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this missing variable
const _goldColor = Color(0xFFF5B81B);