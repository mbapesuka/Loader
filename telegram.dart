// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TelegramSpamPage extends StatefulWidget {
  final String sessionKey;

  const TelegramSpamPage({super.key, required this.sessionKey});

  @override
  State<TelegramSpamPage> createState() => _TelegramSpamPageState();
}

class _TelegramSpamPageState extends State<TelegramSpamPage>
    with SingleTickerProviderStateMixin {
  // --- Controllers ---
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authController = TextEditingController(); 
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _reportTextController = TextEditingController(
    text: "This account is violating Telegram's terms of service through spam and scam activities.",
  );
  final TextEditingController _reportLinkController = TextEditingController();
  final TextEditingController _reportCountController = TextEditingController(text: "50");

  // Controller untuk password manual di session
  final Map<String, TextEditingController> _sessionPasswordControllers = {};

  // Video Controller
  VideoPlayerController? _videoController;

  // --- State Variables ---
  List<TelegramSession> _sessions = [];
  bool _isLoading = false;
  bool _isLoggingIn = false;
  bool _isRefreshing = false;
  bool _isReporting = false;

  // State untuk login
  String _currentLoginPhone = "";
  String _currentLoginId = "";
  String _loginErrorMessage = "";
  String _currentLoginStep = "wait_code";
  bool _canResendOtp = true;
  int _resendOtpCooldown = 30;

  // Report State
  int _reportProgress = 0;
  int _reportTotal = 0;
  String _reportStatus = "";
  String _currentReportId = "";
  Timer? _statusCheckTimer;
  Timer? _resendOtpTimer;
  Timer? _loginStatusTimer;

  // --- UI Controller ---
  late TabController _tabController;
  int _currentTabIndex = 0;

  // GLOWING GREY THEME (sama dengan file lain)
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

  // Animation
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation != null) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _initializeAnimations();
    _loadSessions();
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

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _resendOtpTimer?.cancel();
    _loginStatusTimer?.cancel();
    _tabController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _phoneController.dispose();
    _authController.dispose();
    _targetController.dispose();
    _reportTextController.dispose();
    _reportLinkController.dispose();
    _reportCountController.dispose();
    _videoController?.dispose();
    for (var controller in _sessionPasswordControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- API Calls (TETAP UTUH) ---
  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/sessions?key=${widget.sessionKey}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _sessions = (data['sessions'] as List)
                .map((session) => TelegramSession.fromJson(session))
                .toList();
            _isLoading = false;
          });

          for (var session in _sessions) {
            _sessionPasswordControllers.putIfAbsent(
                session.phone,
                    () => TextEditingController()
            );
          }
        } else {
          if (mounted) _showSnackBar(data['message'] ?? 'Failed to load sessions', isError: true);
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) _showSnackBar('Server error: ${response.statusCode}', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error loading sessions: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateLogin({bool isResend = false}) async {
    if (!isResend && _phoneController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter a phone number.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      final phone = _currentLoginPhone.isEmpty ? _phoneController.text.trim() : _currentLoginPhone;
      final response = await http.get(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/login?key=${widget.sessionKey}&phone=$phone'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginPhone = phone;
            _currentLoginId = data['loginId'];
            _currentLoginStep = data['step'] ?? 'wait_code';
            _isLoggingIn = false;
          });
          _authController.clear();
          if (isResend) {
            if (mounted) _showSnackBar('OTP code resent');
          } else {
            if (mounted) _showSnackBar('OTP code sent to your phone');
            Navigator.of(context).pop();
            _showAuthDialog();
          }
          _startLoginStatusPolling();
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to initiate login';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  Future<void> _submitAuth() async {
    if (_authController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter the code or password.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/auth?key=${widget.sessionKey}&loginId=$_currentLoginId&input=${_authController.text.trim()}'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginStep = data['step'] ?? 'completed';
            _isLoggingIn = false;
          });

          if (_currentLoginStep == 'wait_password') {
            _authController.clear();
            if (mounted) _showSnackBar('OTP verified. Please enter your 2FA password.');
            return;
          } else if (_currentLoginStep == 'completed') {
            _handleLoginSuccess();
            return;
          }
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to verify';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  void _startLoginStatusPolling() {
    _loginStatusTimer?.cancel();
    _loginStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/status?key=${widget.sessionKey}&loginId=$_currentLoginId'),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['completed'] == true) {
          timer.cancel();
          _handleLoginSuccess();
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  Future<void> _verifySessionPassword(String phone) async {
    final passwordController = _sessionPasswordControllers[phone];
    if (passwordController == null || passwordController.text.trim().isEmpty) {
      _showSnackBar('Please enter 2FA password', isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/verify-session-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'phone': phone,
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        _showSnackBar('Session verified successfully');
        passwordController.clear();
        _loadSessions();
      } else {
        _showSnackBar(data['message'] ?? 'Failed to verify session', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _handleLoginSuccess() {
    _loginStatusTimer?.cancel();
    if (mounted) _showSnackBar('Login successful! Session saved.');
    _phoneController.clear();
    _authController.clear();
    Navigator.of(context).pop();
    _resetLoginState();
    _loadSessions();
  }

  void _resetLoginState() {
    _loginStatusTimer?.cancel();
    setState(() {
      _currentLoginPhone = "";
      _currentLoginId = "";
      _currentLoginStep = "wait_code";
      _isLoggingIn = false;
      _loginErrorMessage = "";
    });
  }

  void _startResendOtpCooldown() {
    setState(() {
      _canResendOtp = false;
    });
    _resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendOtpCooldown--;
      });
      if (_resendOtpCooldown <= 0) {
        timer.cancel();
        setState(() {
          _canResendOtp = true;
          _resendOtpCooldown = 30;
        });
      }
    });
  }

  Future<void> _refreshSessions() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await http.get(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/refresh-sessions?key=${widget.sessionKey}'),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted) _showSnackBar('Sessions refreshed. ${data['inactiveSessions'].length} inactive sessions removed.');
        _loadSessions();
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to refresh sessions', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _deleteSession(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/remove-ses?key=${widget.sessionKey}&phone=$phone'),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted) _showSnackBar('Session deleted');
        _sessionPasswordControllers.remove(phone)?.dispose();
        _loadSessions();
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to delete session', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _startSpamReport() async {
    if (_targetController.text.trim().isEmpty) {
      _showSnackBar('Please enter a target (username or user ID)', isError: true);
      return;
    }
    if (_sessions.isEmpty) {
      _showSnackBar('No active sessions available', isError: true);
      return;
    }

    final reportCount = int.tryParse(_reportCountController.text) ?? 50;
    if (reportCount <= 0 || reportCount > 1000) {
      _showSnackBar('Report count must be between 1 and 1000', isError: true);
      return;
    }

    setState(() {
      _isReporting = true;
      _reportProgress = 0;
      _reportTotal = _sessions.length * 10;
      _reportStatus = "Initializing...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/spam-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'target': _targetController.text.trim(),
          'count': reportCount,
          'message': _reportTextController.text.trim(),
          'link': _reportLinkController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        setState(() => _currentReportId = data['reportId']);
        _startStatusPolling();
        if (mounted) _showSnackBar('Spam report started successfully!');
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to start spam report', isError: true);
        setState(() => _isReporting = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() => _isReporting = false);
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/telegram/report-status?key=${widget.sessionKey}&reportId=$_currentReportId'),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final report = data['report'];
          if (mounted) {
            setState(() {
              _reportProgress = report['progress'] ?? 0;
              _reportTotal = report['total'] ?? 0;
              _reportStatus = report['status'] ?? "Processing...";
            });
          }
          if (report['completed'] == true) {
            timer.cancel();
            setState(() => _isReporting = false);
            if (mounted) _showCompletionDialog(report['status']);
          }
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  // --- UI Helpers ---
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _roseColor.withOpacity(0.9) : _glowColor1.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCompletionDialog(String status) {
    final bool isBanned = status.contains('frozen') || status.contains('banned');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: Icon(isBanned ? Icons.check_circle : Icons.info, color: _glowColor1, size: 22),
            ),
            const SizedBox(width: 14),
            const Text("Report Completed", style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status, style: const TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 13)),
            if (isBanned) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _successColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: _successColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Target successfully frozen!", style: TextStyle(color: _successColor, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani'))),
                  ],
                ),
              ),
            ],
          ],
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
                  child: const Icon(FontAwesomeIcons.telegram, color: Color(0xFFE0E0F8), size: 22),
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
                          "TELEGRAM SPAM",
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
                        "${_sessions.length} Active Sessions",
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
                  onTap: _isRefreshing ? null : _refreshSessions,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: _isRefreshing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE0E0F8)))
                        : Icon(Icons.refresh, color: _glowColor1, size: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _buildGlassCard(
        child: Row(
          children: [
            _buildTabItem("SESSIONS", 0, Icons.phone_android),
            _buildTabItem("REPORT", 1, Icons.report),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _glowColor1.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: _glowColor1.withOpacity(0.3), width: 1) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? _glowColor1 : Colors.white.withOpacity(0.4), size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _glowColor1 : Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showPhoneDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Color(0xFF070709), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        "ADD SESSION",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 2,
                          fontSize: 11,
                          color: Color(0xFF070709),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _glowColor1, strokeWidth: 3))
              : _sessions.isEmpty
              ? _buildEmptyState('No Sessions', 'Add a Telegram account to start spamming', FontAwesomeIcons.telegram)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(TelegramSession session) {
    final isActive = session.isActive;
    final passwordController = _sessionPasswordControllers[session.phone] ?? TextEditingController();
    bool showPasswordInput = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive ? _glowColor1.withOpacity(0.15) : _roseColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(FontAwesomeIcons.telegram, color: isActive ? _glowColor1 : _roseColor, size: 18),
                  ),
                  title: Text(
                    session.phone,
                    style: TextStyle(
                      color: isActive ? Colors.white : _roseColor,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  subtitle: Text(
                    'Last active: ${_formatDate(session.lastModified)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          showPasswordInput ? Icons.keyboard_arrow_up : FontAwesomeIcons.lock,
                          color: _glowColor2.withOpacity(0.6),
                          size: 16,
                        ),
                        onPressed: () => setStateCard(() => showPasswordInput = !showPasswordInput),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: _roseColor.withOpacity(0.7), size: 18),
                        onPressed: () => _deleteSession(session.phone),
                      ),
                    ],
                  ),
                ),
                if (showPasswordInput)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                              color: _cardColor,
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                              cursorColor: _glowColor1,
                              decoration: InputDecoration(
                                hintText: 'Enter 2FA password',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontFamily: 'Rajdhani'),
                                prefixIcon: Icon(Icons.lock, color: _glowColor2.withOpacity(0.5), size: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _verifySessionPassword(session.phone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                              ],
                            ),
                            child: const Text(
                              "VERIFY",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 2,
                                fontSize: 11,
                                color: Color(0xFF070709),
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
        );
      },
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _glowColor1,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "REPORT CONFIGURATION",
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
                  _buildPremiumInputField(
                    icon: Icons.person,
                    label: "Target",
                    hint: "@username or user ID",
                    controller: _targetController,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.message,
                    label: "Report Message",
                    hint: "Optional custom message",
                    controller: _reportTextController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.link,
                    label: "Evidence Link",
                    hint: "Optional evidence link",
                    controller: _reportLinkController,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.numbers,
                    label: "Report Count",
                    hint: "1-1000",
                    controller: _reportCountController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isReporting ? null : _startSpamReport,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 20),
                ],
              ),
              child: Center(
                child: _isReporting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF070709)))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.play, size: 14, color: Color(0xFF070709)),
                          SizedBox(width: 10),
                          Text(
                            "START SPAM REPORT",
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
          if (_isReporting) ...[
            const SizedBox(height: 20),
            _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REPORT PROGRESS",
                      style: TextStyle(
                        color: _glowColor1,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: "Rajdhani",
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _reportTotal > 0 ? _reportProgress / _reportTotal : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        color: _glowColor1,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $_reportProgress / $_reportTotal',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        Flexible(
                          child: Text(
                            _reportStatus,
                            style: TextStyle(color: _glowColor1, fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPremiumInputField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
            border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
            color: _cardColor,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.1), size: 50),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.25), fontFamily: 'Rajdhani', fontSize: 12), textAlign: TextAlign.center),
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
            gradient: LinearGradient(colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent]),
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
          "SPAMS • VANTHRA SECURITY",
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 2.5,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- Dialogs ---
  void _showPhoneDialog() {
    _resetLoginState();
    _phoneController.clear();
    _authController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPhoneDialog(),
    );
  }

  Widget _buildPhoneDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(FontAwesomeIcons.telegram, color: Color(0xFFE0E0F8), size: 22),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_glowColor1, _accentColor, _glowColor2],
                    ).createShader(bounds),
                    child: const Text(
                      "ADD SESSION",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPremiumInputField(
                icon: Icons.phone,
                label: "Phone Number",
                hint: "+628123456789",
                controller: _phoneController,
              ),
              if (_loginErrorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_loginErrorMessage, style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetLoginState();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoggingIn ? null : _initiateLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070709)))
                          : const Text(
                              "SEND OTP",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 2,
                                fontSize: 12,
                                color: Color(0xFF070709),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuthDialog() {
    _loginErrorMessage = "";
    _authController.clear();
    _startResendOtpCooldown();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isPasswordStep = _currentLoginStep == 'wait_password';
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPasswordStep ? _roseColor.withOpacity(0.15) : _glowColor1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (isPasswordStep ? _roseColor : _glowColor1).withOpacity(0.3), width: 1),
                        ),
                        child: Icon(isPasswordStep ? Icons.lock : FontAwesomeIcons.key, color: isPasswordStep ? _roseColor : _glowColor1, size: 20),
                      ),
                      const SizedBox(width: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isPasswordStep ? [_roseColor, _glowColor2] : [_glowColor1, _accentColor],
                        ).createShader(bounds),
                        child: Text(
                          isPasswordStep ? "2FA VERIFICATION" : "OTP VERIFICATION",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Rajdhani',
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isPasswordStep
                        ? '2FA Password Required for $_currentLoginPhone'
                        : 'Code sent to $_currentLoginPhone',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani', fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: isPasswordStep ? Icons.lock : Icons.pin,
                    label: isPasswordStep ? "2FA Password" : "OTP Code",
                    hint: isPasswordStep ? "Enter your 2FA password" : "Enter 5-digit code",
                    controller: _authController,
                  ),
                  if (_loginErrorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_loginErrorMessage, style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isPasswordStep)
                        GestureDetector(
                          onTap: _isLoggingIn || !_canResendOtp ? null : () => _initiateLogin(isResend: true),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                            ),
                            child: _isLoggingIn || !_canResendOtp
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE0E0F8)))
                                : Icon(Icons.refresh, color: _glowColor1, size: 18),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetLoginState();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isLoggingIn ? null : _submitAuth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                            ],
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070709)))
                              : Text(
                                  isPasswordStep ? "LOGIN" : "VERIFY",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Rajdhani',
                                    letterSpacing: 2,
                                    fontSize: 12,
                                    color: Color(0xFF070709),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                _buildCustomTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSessionsTab(),
                      _buildReportTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Data Model ---
class TelegramSession {
  final String phone;
  final DateTime lastModified;
  final bool isActive;

  TelegramSession({required this.phone, required this.lastModified, required this.isActive});

  factory TelegramSession.fromJson(Map<String, dynamic> json) {
    return TelegramSession(
      phone: json['phone'] ?? '',
      lastModified: DateTime.parse(json['lastModified']),
      isActive: json['isActive'] ?? true,
    );
  }
}