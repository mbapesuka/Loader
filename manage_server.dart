// manage_server_page.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ManageServerPage extends StatefulWidget {
  final String sessionKey;

  const ManageServerPage({super.key, required this.sessionKey});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> with TickerProviderStateMixin {
  static const String baseUrl = "http://kinncloud.sistems.tech:2052/api/vps";
  
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

  bool _isLoading = true;
  List<Map<String, dynamic>> _servers = [];

  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initVideoBackground();
    _fetchServers();
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Future<void> _fetchServers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/myServer?key=${widget.sessionKey}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['servers'] != null) {
          setState(() {
            _servers = List<Map<String, dynamic>>.from(data['servers']);
          });
        }
      } else {
        _showMessage("Failed to load servers.", isError: true);
      }
    } catch (e) {
      _showMessage("Error fetching servers: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addServer() async {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage("All fields are required.", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/addServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server added successfully!");
        _hostController.clear();
        _usernameController.clear();
        _passwordController.clear();
        if (mounted) Navigator.pop(context);
        _fetchServers();
      } else {
        _showMessage(data['error'] ?? "Failed to add server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error adding server: $e", isError: true);
    }
  }

  Future<void> _deleteServer(String host) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server deleted successfully!");
        _fetchServers();
      } else {
        _showMessage(data['error'] ?? "Failed to delete server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error deleting server: $e", isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _roseColor.withOpacity(0.9) : _glowColor1.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddServerDialog() {
    _hostController.clear();
    _usernameController.clear();
    _passwordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                        color: _glowColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                      ),
                      child: const Icon(Icons.computer, color: Color(0xFFE0E0F8), size: 22),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                      ).createShader(bounds),
                      child: const Text(
                        "ADD NEW SERVER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: "Rajdhani",
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _hostController,
                  label: "Host IP",
                  hint: "Enter server IP address",
                  icon: Icons.dns,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _usernameController,
                  label: "SSH Username",
                  hint: "Enter SSH username",
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _passwordController,
                  label: "SSH Password",
                  hint: "Enter SSH password",
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addServer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                          ],
                        ),
                        child: const Text(
                          "ADD",
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    bool _obscure = isPassword;
    
    return StatefulBuilder(
      builder: (context, setStateField) {
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
                obscureText: _obscure,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontFamily: 'Rajdhani'),
                  prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 18),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: _glowColor2.withOpacity(0.5),
                            size: 18,
                          ),
                          onPressed: () => setStateField(() => _obscure = !_obscure),
                        )
                      : null,
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
      },
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
                  child: const Icon(Icons.dns, color: Color(0xFFE0E0F8), size: 22),
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
                          "MANAGE SERVERS",
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
                        "${_servers.length} Servers Connected",
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
                  onTap: _fetchServers,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(Icons.refresh, color: _glowColor1, size: 20),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServerCard(Map<String, dynamic> server, int index) {
    final host = server['host'] ?? 'Unknown Host';
    final username = server['username'] ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _buildGlassCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.computer, color: _glowColor1, size: 20),
          ),
          title: Text(
            host,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFamily: "Rajdhani",
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          subtitle: Text(
            "User: $username",
            style: TextStyle(
              color: _glowColor2.withOpacity(0.6),
              fontSize: 11,
              fontFamily: "Rajdhani",
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _surfaceColor.withOpacity(0.98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: _roseColor.withOpacity(0.4), width: 1),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFBB8899), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Confirm Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    "Are you sure you want to delete server $host?",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteServer(host);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          "DELETE",
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
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _roseColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: _roseColor, size: 18),
            ),
          ),
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
          "VANTHRA • SERVER MANAGEMENT",
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
            child: Column(
              children: [
                _buildNeonHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0F8), strokeWidth: 3))
                      : _servers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dns_outlined, size: 50, color: Colors.white.withOpacity(0.1)),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No servers found",
                                    style: TextStyle(color: _glowColor2.withOpacity(0.5), fontSize: 16, fontFamily: 'Rajdhani', fontWeight: FontWeight.w800, letterSpacing: 2),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add your first VPS to get started",
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'Rajdhani'),
                                  ),
                                ],
                              ),
                            )
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _servers.length,
                                itemBuilder: (context, index) {
                                  final server = _servers[index];
                                  return _buildServerCard(server, index);
                                },
                              ),
                            ),
                ),
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return GestureDetector(
            onTap: _showAddServerDialog,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Color(0xFF070709), size: 28),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _videoController?.dispose();
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}