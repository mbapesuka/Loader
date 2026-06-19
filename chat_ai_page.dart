// chat_ai_page.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatAIPage extends StatefulWidget {
  final String sessionKey;

  const ChatAIPage({super.key, required this.sessionKey});

  @override
  State<ChatAIPage> createState() => _ChatAIPageState();
}

class _ChatAIPageState extends State<ChatAIPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];
  bool _showSessionList = false;

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
    _loadChatSessions();
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

  Future<void> _loadChatSessions() async {
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/chat/list?key=${widget.sessionKey}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _chatSessions = (data['chatHistoryList'] as List).map((session) => ChatSession.fromJson(session)).toList();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load chat sessions', isError: true);
    }
  }

  Future<void> _createNewSession() async {
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/chat/new-session?key=${widget.sessionKey}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = data['sessionId'];
            _messages.clear();
            _showSessionList = false;
          });
          _loadChatSessions();
          _showSnackBar('New session created');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to create new session', isError: true);
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/chat/history?key=${widget.sessionKey}&session=$sessionId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = sessionId;
            _messages.clear();
            final chatHistory = data['chatHistory'] as List;
            for (var message in chatHistory) {
              _messages.add(ChatMessage(
                text: message['message'],
                isAI: message['isAI'] == true,
                timestamp: DateTime.parse(message['timestamp'])
              ));
            }
            _showSessionList = false;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load chat session', isError: true);
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/chat/delete?key=${widget.sessionKey}&session=$sessionId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _showSnackBar('Chat session deleted');
          _loadChatSessions();
          if (_currentSessionId == sessionId) {
            setState(() {
              _currentSessionId = null;
              _messages.clear();
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('Failed to delete chat session', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _currentSessionId == null) return;
    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isAI: false, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    try {
      final response = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/tools/chat/send?key=${widget.sessionKey}&session=$_currentSessionId&message=${Uri.encodeComponent(userMessage)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _messages.add(ChatMessage(text: data['data']['message'], isAI: true, timestamp: DateTime.now()));
          });
        } else {
          _showSnackBar('Failed to get AI response', isError: true);
        }
      } else {
        _showSnackBar('Failed to connect to AI service', isError: true);
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
                  child: const Icon(FontAwesomeIcons.robot, color: Color(0xFFE0E0F8), size: 22),
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
                          "AI ASSISTANT",
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
                        _currentSessionId != null ? "Session Active" : "No Active Session",
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showSessionList = !_showSessionList),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                        ),
                        child: Icon(_showSessionList ? Icons.chat : Icons.history, color: _glowColor1, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _createNewSession,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFE0E0F8), size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    "CHAT SESSIONS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Rajdhani",
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _createNewSession,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 14, color: Color(0xFFE0E0F8)),
                          const SizedBox(width: 4),
                          Text(
                            "NEW",
                            style: TextStyle(
                              color: _glowColor1,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: "Rajdhani",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _chatSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.comments, color: Colors.white.withOpacity(0.1), size: 50),
                      const SizedBox(height: 16),
                      Text(
                        "No chat sessions found",
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Rajdhani', fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _createNewSession,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 16, color: Color(0xFFE0E0F8)),
                              const SizedBox(width: 6),
                              Text(
                                "Create New Session",
                                style: TextStyle(
                                  color: _glowColor1,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Rajdhani",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chatSessions.length,
                  itemBuilder: (context, index) {
                    final session = _chatSessions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildGlassCard(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.chat_bubble, color: _glowColor1, size: 16),
                          ),
                          title: Text(
                            session.sessionId.length > 30 
                                ? '${session.sessionId.substring(0, 30)}...' 
                                : session.sessionId,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Rajdhani',
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            '${session.messageCount} messages • ${session.preview}',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'Rajdhani'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: GestureDetector(
                            onTap: () => _deleteChatSession(session.sessionId),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _roseColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.delete_outline, color: _roseColor, size: 16),
                            ),
                          ),
                          onTap: () => _loadChatSession(session.sessionId),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: _currentSessionId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cardColor,
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1.5),
                        ),
                        child: Icon(FontAwesomeIcons.robot, size: 48, color: _glowColor1.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Start a new conversation',
                        style: TextStyle(color: _glowColor1.withOpacity(0.7), fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the + button to create a session',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Rajdhani', fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[_messages.length - 1 - index]),
                ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFE0E0F8), strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('AI is thinking...', style: TextStyle(color: _glowColor2.withOpacity(0.7), fontFamily: 'Rajdhani', fontSize: 11)),
              ],
            ),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: !message.isAI ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isAI) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(FontAwesomeIcons.robot, color: Color(0xFFE0E0F8), size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !message.isAI ? _glowColor1.withOpacity(0.15) : _surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isAI ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: message.isAI ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: Border.all(
                  color: !message.isAI ? _glowColor1.withOpacity(0.3) : _glowColor1.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: !message.isAI ? _glowColor1 : Colors.white.withOpacity(0.85),
                  fontWeight: !message.isAI ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (!message.isAI) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(FontAwesomeIcons.user, color: Color(0xFFE0E0F8), size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _glowColor1.withOpacity(0.08), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: _cardColor,
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w600),
                cursorColor: _glowColor1,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontFamily: 'Rajdhani'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Color(0xFF070709), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
            "VANTHRA • AI ASSISTANT",
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 8,
              letterSpacing: 3,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _showSessionList ? _buildSessionList() : _buildChatInterface(),
                  ),
                ),
                if (!_showSessionList && _currentSessionId != null) _buildFooter(),
              ],
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
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isAI; 
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isAI, required this.timestamp});
}

class ChatSession {
  final String sessionId;
  final String username;
  final DateTime lastModified;
  final int messageCount;
  final String preview;
  ChatSession({
    required this.sessionId, 
    required this.username, 
    required this.lastModified, 
    required this.messageCount, 
    required this.preview
  });
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'],
      username: json['username'],
      lastModified: DateTime.parse(json['lastModified']),
      messageCount: json['messageCount'],
      preview: json['preview'],
    );
  }
}