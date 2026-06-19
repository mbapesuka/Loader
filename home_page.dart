import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class AttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const AttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  static const String baseUrl = "http://kinncloud.sistems.tech:2052";

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
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
  String selectedBugId = "";
  bool _isSending = false;
  bool _isSuccess = false;

  // Sender variables
  String _senderType = "private";
  int _globalSenderCount = 3;
  bool _isLoadingSenders = false;

  // DARK YELLOW / GOLDEN BLACK THEME
  final Color _primaryColor = const Color(0xFFD4AF37);      // Gold
  final Color _secondaryColor = const Color(0xFFB8860B);    // Dark Goldenrod
  final Color _accentColor = const Color(0xFFFFD700);       // Bright Gold
  final Color _successColor = const Color(0xFFDAA520);      // Goldenrod
  final Color _warningColor = const Color(0xFFFF8C00);      // Dark Orange
  final Color _darkBg = const Color(0xFF0A0A0A);            // Almost Black
  final Color _darkerBg = const Color(0xFF050505);          // Pure Dark
  final Color _surfaceColor = const Color(0xFF111111);      // Dark Surface
  final Color _cardColor = const Color(0xFF0D0D0D);         // Darker Card
  final Color _glowColor1 = const Color(0xFFFFD700);        // Gold Glow
  final Color _glowColor2 = const Color(0xFFDAA520);        // Goldenrod Glow
  final Color _glowColor3 = const Color(0xFFCD853F);        // Peru/Bronze
  final Color _goldColor = const Color(0xFFFFD700);         // Gold
  final Color _roseColor = const Color(0xFFFFB347);         // Yellow-Orange

  bool get canUseGlobalSender {
    final allowedRoles = ["founder", "vip", "owner", "high admin", "moderator", "high owner", "dev"];
    return allowedRoles.contains(widget.role.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _setDefaultBug();
    _startAnimations();

    if (!canUseGlobalSender) {
      _senderType = "private";
    }

    _fetchGlobalSenderCount();
  }

  Future<void> _fetchGlobalSenderCount() async {
    if (!mounted) return;
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['valid'] == true && data['connections'] != null) {
          final globalList = data['connections']['global'] as List?;
          setState(() {
            _globalSenderCount = globalList?.length ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching global sender count: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingSenders = false);
      }
    }
  }

  void _initializeAnimations() {
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

  void _setDefaultBug() {
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }
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

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("Invalid Number", "Use international format (e.g., 628123456789, not 08xxx).");
      setState(() {
        _isSending = false;
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/sendBug?key=$key&target=$target&bug=$selectedBugId&senderType=$_senderType"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("Cooldown", "Please wait a moment before sending again.");
      } else if (data["senderOn"] == false) {
        _showAlert("Failed", "Failed to send bug. Sender empty, contact seller.");
      } else if (data["valid"] == false) {
        _showAlert("Failed", data["message"] ?? "Invalid session key or access denied.");
      } else if (data["sended"] == false) {
        _showAlert("Failed", "Failed to send bug. Server may be under maintenance.");
      } else {
        setState(() {
          _isSuccess = true;
        });
        _showSuccessPopup(target);
      }
    } catch (_) {
      _showAlert("Connection Error", "Failed to connect to the server. Please try again.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSuccessPopup(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        target: target,
        senderType: _senderType,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() {
            _isSuccess = false;
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
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Colors.white60,
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

  // ==================== UI BUILDERS ====================

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

  Widget _buildGlassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12)),
          BoxShadow(color: _glowColor1.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }

  Widget _buildNeonHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: _glowColor1.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _glowColor1.withOpacity(0.25), blurRadius: 24),
                  ],
                  color: _cardColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: _glowColor1, size: 24),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                      ).createShader(bounds),
                      child: const Text(
                        "CONTACT BUG",
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
                    Icon(Icons.flash_on, color: _glowColor1, size: 24),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _successColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _successColor.withOpacity(0.3), width: 1),
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
                "SYSTEM ONLINE",
                style: TextStyle(
                  color: _successColor.withOpacity(0.85),
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
                          border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 20),
                          ],
                        ),
                        child: ClipOval(
  child: Image.asset(
    'assets/images/abc.jpg',
    width: 64,
    height: 64,
    fit: BoxFit.cover,
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
                          color: _glowColor1.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          widget.role.toUpperCase(),
                          style: TextStyle(
                            color: _glowColor1.withOpacity(0.85),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(FontAwesomeIcons.bug, widget.listBug.length.toString(), "ARSENAL", _glowColor1),
                _buildStatItem(Icons.trending_up, "READY", "STATUS", _glowColor3),
                _buildStatItem(Icons.calendar_today, widget.expiredDate, "UNTIL", _goldColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Icon(icon, color: color.withOpacity(0.8), size: 20),
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

  Widget _buildTargetInputCard() {
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
                    color: _glowColor1.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(Icons.phone_android, color: _glowColor1.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "TARGET NUMBER",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
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
                border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
              ),
              child: TextField(
                controller: targetController,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                keyboardType: TextInputType.phone,
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: "628123456789",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                  prefixIcon: Icon(FontAwesomeIcons.globe, color: _glowColor2.withOpacity(0.5), size: 18),
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
                  "International format without '+'",
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugSelectionCard() {
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
                    color: _glowColor1.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(FontAwesomeIcons.bug, color: Color(0xFFFFD700), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "BUG VANTHRA",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: widget.listBug.isEmpty
                  ? Center(
                      child: Text(
                        "No bugs available",
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.listBug.length,
                      itemBuilder: (ctx, i) {
                        final bug = widget.listBug[i];
                        bool isSelected = selectedBugId == bug['bug_id'];

                        return GestureDetector(
                          onTap: () => setState(() => selectedBugId = bug['bug_id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? _glowColor1.withOpacity(0.08) : _cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? _glowColor1 : _glowColor1.withOpacity(0.12),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: _glowColor1.withOpacity(0.15), blurRadius: 16)]
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _glowColor1.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(FontAwesomeIcons.skull, color: _glowColor1.withOpacity(0.7), size: 18),
                                  ),
                                  const Spacer(),
                                  Text(
                                    bug['bug_name'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      fontFamily: 'Rajdhani',
                                      letterSpacing: 1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "READY",
                                    style: TextStyle(
                                      color: isSelected ? _glowColor1.withOpacity(0.7) : Colors.white.withOpacity(0.3),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Rajdhani',
                                      letterSpacing: 1,
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
        ),
      ),
    );
  }

  Widget _buildSenderSelectionCard() {
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
                    color: _glowColor1.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(FontAwesomeIcons.server, color: _glowColor1.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "DEPLOYMENT MODE",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isLoadingSenders ? null : _fetchGlobalSenderCount,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                    ),
                    child: _isLoadingSenders
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)))
                        : Icon(Icons.refresh, color: _glowColor2.withOpacity(0.5), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildSenderOption(
                    title: "GLOBAL",
                    icon: FontAwesomeIcons.globe,
                    subtitle: "$_globalSenderCount Active",
                    type: "global",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSenderOption(
                    title: "PRIVATE",
                    icon: FontAwesomeIcons.userShield,
                    subtitle: "Your Session",
                    type: "private",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderOption({
    required String title,
    required IconData icon,
    required String subtitle,
    required String type,
  }) {
    bool isActive = _senderType == type;
    bool isDisabled = type == "global" && !canUseGlobalSender;

    return GestureDetector(
      onTap: () {
        if (isDisabled) {
          _showAlert("Access Denied", "Global sender is only available for: Founder, VIP, Owner, High Owner, High Admin, Moderator, Dev");
          return;
        }
        setState(() => _senderType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _glowColor1.withOpacity(0.08) : _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _glowColor1 : Colors.white.withOpacity(0.06),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: _glowColor1.withOpacity(0.1), blurRadius: 12)] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDisabled ? _warningColor.withOpacity(0.5) : (isActive ? _glowColor1 : Colors.white.withOpacity(0.4)),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDisabled ? _warningColor.withOpacity(0.7) : (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                fontWeight: FontWeight.w800,
                fontFamily: 'Rajdhani',
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isActive ? _glowColor2.withOpacity(0.7) : Colors.white.withOpacity(0.3),
                fontSize: 8,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTap: _isSending ? null : _sendBug,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.35 * _glowAnimation.value),
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
                    Icon(
                      _senderType == "global" ? FontAwesomeIcons.rocket : FontAwesomeIcons.skull,
                      color: _darkerBg,
                      size: 18,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    _isSending
                        ? "EXECUTING..."
                        : (_senderType == "global" ? "GLOBAL STRIKE" : "LAUNCH ATTACK"),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: _darkerBg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_isSending)
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _darkerBg,
                      size: 16,
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
            _buildFooterText("SECURE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 10),
            _buildFooterText("ENCRYPTED"),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "VANTHRA v3.0  •  ADVANCED SECURITY PROTOCOL",
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildNeonHeader(),
                        const SizedBox(height: 28),
                        _buildUserProfileCard(),
                        const SizedBox(height: 22),
                        _buildTargetInputCard(),
                        const SizedBox(height: 22),
                        _buildBugSelectionCard(),
                        const SizedBox(height: 22),
                        _buildSenderSelectionCard(),
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
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _videoController.dispose();
    targetController.dispose();
    super.dispose();
  }
}

// Success Dialog
class _SuccessDialog extends StatefulWidget {
  final String target;
  final String senderType;
  final VoidCallback onDismiss;

  const _SuccessDialog({
    required this.target,
    required this.senderType,
    required this.onDismiss,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final Color _glowColor1 = const Color(0xFFFFD700);      // Gold
  final Color _primaryColor = const Color(0xFFD4AF37);     // Gold
  final Color _secondaryColor = const Color(0xFFB8860B);   // Dark Goldenrod
  final Color _successColor = const Color(0xFFDAA520);     // Goldenrod
  final Color _darkerBg = const Color(0xFF050505);         // Pure Dark
  final Color _surfaceColor = const Color(0xFF111111);     // Dark Surface
  final Color _cardColor = const Color(0xFF0D0D0D);        // Darker Card

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

    _fadeController.forward();
    _scaleController.forward();
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
    final dialogWidth = screenSize.width * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(28),
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
                border: Border.all(color: _glowColor1.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, _) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _glowColor1.withOpacity(0.45 * _glowAnimation.value),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.senderType == "global"
                                  ? FontAwesomeIcons.rocket
                                  : FontAwesomeIcons.skullCrossbones,
                              color: _glowColor1,
                              size: 48,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.senderType == "global" ? "GLOBAL STRIKE!" : "ATTACK SUCCESS",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android, color: _glowColor1.withOpacity(0.6), size: 16),
                            const SizedBox(width: 10),
                            Text(
                              widget.target,
                              style: TextStyle(
                                color: _glowColor1.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                        ),
                        child: Text(
                          widget.senderType.toUpperCase(),
                          style: TextStyle(
                            color: _glowColor1.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Rajdhani',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 20),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "CLOSE",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 3,
                                color: Color(0xFF050505),
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
        ),
      ),
    );
  }
}