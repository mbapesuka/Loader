import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String role;
  final String? message;
  final String? imageUrl;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.role,
    this.message,
    this.imageUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'member',
      message: json['message'],
      imageUrl: json['imageUrl'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class CommunityPage extends StatefulWidget {
  final String username;
  final String role;

  const CommunityPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scroll = ScrollController();
  final ImagePicker picker = ImagePicker();

  List<ChatMessage> messages = [];
  Timer? timer;
  bool sending = false;

  final String baseUrl = "http://nodexwaroy.xwar.my.id:2002";

  @override
  void initState() {
    super.initState();
    load();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => load(),
    );
  }

  // ================= LOAD =================
  Future<void> load() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/chat/messages"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          messages = (data as List)
              .map((e) => ChatMessage.fromJson(e))
              .toList()
              .reversed
              .toList();
        });
      }
    } catch (_) {}
  }

  // ================= SEND =================
  Future<void> send() async {
    if (controller.text.trim().isEmpty || sending) return;

    setState(() => sending = true);

    await http.post(
      Uri.parse("$baseUrl/chat/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": widget.username,
        "username": widget.username,
        "role": widget.role,
        "message": controller.text.trim(),
      }),
    );

    controller.clear();
    load();

    setState(() => sending = false);
  }

  // ================= IMAGE =================
  Future<void> sendImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    var req = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/chat/upload-image"),
    );

    req.files.add(await http.MultipartFile.fromPath("image", img.path));
    req.fields["userId"] = widget.username;
    req.fields["username"] = widget.username;
    req.fields["role"] = widget.role;

    await req.send();
    load();
  }

  // ================= ROLE COLOR =================
  Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case "founder":
        return Colors.redAccent;
      case "moderator":
        return Colors.greenAccent;
      case "high admin":
        return Colors.orangeAccent;
      case "owner":
        return Colors.purpleAccent;
      case "vip":
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1629),
        title: const Text("Community Chat"),
      ),

      body: Column(
        children: [

          // ================= CHAT LIST =================
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: scroll,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isMe = msg.username == widget.username;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMe
                            ? [
                                Colors.blueAccent.withOpacity(0.8),
                                Colors.purpleAccent.withOpacity(0.6),
                              ]
                            : [
                                const Color(0xFF1C2436),
                                const Color(0xFF121826),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // USER + ROLE
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: roleColor(msg.role),
                              child: Text(
                                msg.username.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Text(
                              msg.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor(msg.role),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                msg.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // TEXT
                        if (msg.message != null)
                          Text(
                            msg.message!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),

                        // IMAGE
                        if (msg.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(msg.imageUrl!),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1629),
            ),
            child: Row(
              children: [

                IconButton(
                  onPressed: sendImage,
                  icon: const Icon(Icons.image, color: Colors.white),
                ),

                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFF1C2436),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.purpleAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}