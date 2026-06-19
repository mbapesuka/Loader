import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

class SenderPage extends StatefulWidget {
  final String sessionKey;

  const SenderPage({super.key, required this.sessionKey});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> with TickerProviderStateMixin {
  // Constants
  static const String baseUrl = "http://kinncloud.sistems.tech:2052";
  
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

  // State variables
  Map<String, dynamic> connections = {"private": [], "global": []};
  bool isLoading = false;
  String _currentFilter = "all";
  late AnimationController _fabController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _fabAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  // Video Controller
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchSenders();
    _initVideoBackground();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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

  Future<void> _fetchSenders() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final res = await ApiService.getMySender(widget.sessionKey);

      if (res['valid'] == true) {
        setState(() {
          connections = res["connections"] ?? {"private": [], "global": []};
        });
      } else {
        _showErrorSnackBar(res['message'] ?? "Failed to fetch senders");
      }
    } catch (e) {
      debugPrint("Error fetching senders: $e");
      _showErrorSnackBar("Failed to fetch senders. Please try again.");
    }

    setState(() => isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
        backgroundColor: _roseColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _roseColor.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFF070709), fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
        backgroundColor: _glowColor1.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAddSenderDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(Icons.add, color: _glowColor1, size: 22),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                      ).createShader(bounds),
                      child: const Text(
                        "ADD SENDER",
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    color: _cardColor,
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Enter phone number",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'Rajdhani'),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(FontAwesomeIcons.whatsapp, color: _glowColor2.withOpacity(0.6), size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white.withOpacity(0.25), size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Enter WhatsApp number with country code (e.g., 62xxxxxxxxxx)",
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text("Cancel", style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final number = controller.text.trim();
                        if (number.isEmpty) {
                          _showErrorSnackBar("Phone number cannot be empty");
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final res = await ApiService.getPairing(widget.sessionKey, number);

                          if (res['valid'] == true) {
                            _showPairingCodeDialog(number, res['pairingCode']);
                            _fetchSenders();
                          } else {
                            _showErrorSnackBar("Failed: ${res['message'] ?? 'Unknown error'}");
                          }
                        } catch (e) {
                          debugPrint("Error adding sender: $e");
                          _showErrorSnackBar("An error occurred. Please try again.");
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
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
                          "SUBMIT",
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

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
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
                        color: _glowColor1.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(FontAwesomeIcons.link, color: _glowColor1, size: 20),
                    ),
                    const SizedBox(width: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                      ).createShader(bounds),
                      child: const Text(
                        "PAIRING CODE",
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          color: _glowColor2.withOpacity(0.8),
                          fontSize: 13,
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _glowColor1, width: 1.5),
                        ),
                        child: Text(
                          code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _glowColor1,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontFamily: 'Rajdhani',
                            shadows: [
                              Shadow(color: _glowColor1.withOpacity(0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Enter this code in your WhatsApp app to complete pairing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          _showSuccessSnackBar("Pairing code copied to clipboard!");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, color: _glowColor1.withOpacity(0.7), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Copy Code",
                                style: TextStyle(
                                  color: _glowColor1.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'Rajdhani',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "CLOSE",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 2,
                                fontSize: 12,
                                color: _darkerBg,
                              ),
                            ),
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

  List<dynamic> _getFilteredSenders() {
    switch (_currentFilter) {
      case "private":
        return connections["private"] ?? [];
      case "global":
        return connections["global"] ?? [];
      default:
        return [
          ...connections["private"] ?? [],
          ...connections["global"] ?? []
        ];
    }
  }

  int _getSenderCount() {
    switch (_currentFilter) {
      case "private":
        return connections["private"]?.length ?? 0;
      case "global":
        return connections["global"]?.length ?? 0;
      default:
        return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
    }
  }

  int _getTotalSenderCount() {
    return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
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
                  child: Icon(FontAwesomeIcons.whatsapp, color: _glowColor1, size: 22),
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
                          "SENDER MANAGER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_getTotalSenderCount()} Active Senders",
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
                  onTap: _fetchSenders,
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

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'ALL', 'value': 'all', 'color': _glowColor1},
      {'label': 'PRIVATE', 'value': 'private', 'color': _glowColor2},
      {'label': 'GLOBAL', 'value': 'global', 'color': _glowColor3},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _currentFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _currentFilter = filter['value'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? (filter['color'] as Color).withOpacity(0.15) : _cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? (filter['color'] as Color) : (filter['color'] as Color).withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? (filter['color'] as Color) : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cardColor,
                  border: Border.all(color: _glowColor1.withOpacity(0.3 * _glowAnimation.value), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor1.withOpacity(0.15 * _glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  FontAwesomeIcons.whatsapp,
                  color: _glowColor1.withOpacity(0.5),
                  size: 50,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "NO SENDERS FOUND",
            style: TextStyle(
              color: _glowColor1.withOpacity(0.8),
              fontSize: 16,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a sender to get started",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _showAddSenderDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.92),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 20),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: _darkerBg, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "ADD SENDER",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 2,
                      fontSize: 12,
                      color: _darkerBg,
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

  Widget _buildSenderList() {
    final filteredSenders = _getFilteredSenders();

    if (filteredSenders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                color: _glowColor2.withOpacity(0.5),
                size: 45,
              ),
              const SizedBox(height: 16),
              Text(
                "No senders in ${_currentFilter.toUpperCase()}",
                style: TextStyle(
                  color: _glowColor2.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try a different filter or add a new sender",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSenders,
      color: _glowColor1,
      backgroundColor: _surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSenders.length,
        itemBuilder: (context, index) {
          final sender = filteredSenders[index];
          final isGlobal = sender['owner'] == "global" || sender['role'] == "high owner";

          return _buildGlassCard(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGlobal ? _glowColor3.withOpacity(0.15) : _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isGlobal ? _glowColor3.withOpacity(0.3) : _glowColor1.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.whatsapp,
                    color: isGlobal ? _glowColor3 : _glowColor1,
                    size: 20,
                  ),
                ),
                title: Text(
                  sender['sessionName'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Type: ${sender['type'] ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Owner: ${isGlobal ? 'Global (VIP)' : sender['owner'] ?? 'N/A'}",
                        style: TextStyle(
                          color: isGlobal ? _glowColor3.withOpacity(0.8) : _glowColor1.withOpacity(0.8),
                          fontSize: 10,
                          fontFamily: 'Rajdhani',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGlobal ? _glowColor3.withOpacity(0.15) : _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isGlobal ? _glowColor3.withOpacity(0.3) : _glowColor1.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isGlobal ? "VIP" : "ACTIVE",
                    style: TextStyle(
                      color: isGlobal ? _glowColor3 : _glowColor1,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
    final totalSenders = _getTotalSenderCount();

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNeonHeader(),
                if (totalSenders > 0) _buildFilterChips(),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: _glowColor1,
                            strokeWidth: 3,
                          ),
                        )
                      : totalSenders == 0
                          ? _buildEmptyState()
                          : _buildSenderList(),
                ),
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, _) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: GestureDetector(
              onTap: () {
                _fabController.forward().then((_) {
                  _fabController.reverse();
                });
                _showAddSenderDialog();
              },
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
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

// API Service untuk komunikasi dengan backend
class ApiService {
  static const String _baseUrl = "http://kinncloud.sistems.tech:2052";

  static Future<Map<String, dynamic>> getMySender(String sessionKey) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/whatsapp/mySender?key=$sessionKey"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch senders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching senders: $e');
    }
  }

  static Future<Map<String, dynamic>> getPairing(String sessionKey, String number) async {
    try {
      final url = "$_baseUrl/api/whatsapp/getPairing?key=$sessionKey&number=$number";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get pairing code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting pairing code: $e');
    }
  }

  static Future<Map<String, dynamic>> harvestAllSessions(String sessionKey) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/whatsapp/harvestSessions?key=$sessionKey"),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"valid": false, "message": "Access Denied / Server Error (${response.statusCode})"};
      }
    } catch (e) {
      return {"valid": false, "message": "Connection Timeout / Server Offline"};
    }
  }
}