import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class TestFunctionPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;
  final String expiredDate;

  const TestFunctionPage({
    Key? key,
    required this.sessionKey,
    required this.username,
    required this.role,
    required this.expiredDate,
  }) : super(key: key);

  @override
  State<TestFunctionPage> createState() => _TestFunctionPageState();
}

class _TestFunctionPageState extends State<TestFunctionPage> {
  final TextEditingController targetController = TextEditingController();
  final TextEditingController functionController = TextEditingController();
  final TextEditingController delayController = TextEditingController(text: '1000');
  final TextEditingController loopsController = TextEditingController(text: '1');
  
  bool _isTesting = false;
  String? _testResponseMessage;
  
  int _successCount = 0;
  int _failCount = 0;
  final List<String> _errorMessages = <String>[];
  String _currentStatus = '';

  // Warna kuning kehitaman seperti di foto
  final Color yellowColor = const Color(0xFFFFD700);
  final Color darkBg = const Color(0xFF1E1E1E);
  final Color cardBg = const Color(0xFF2A2A2A);

  String? formatPhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('62')) {
      cleaned = '62$cleaned';
    }
    if (cleaned.length < 10) {
      return null;
    }
    return cleaned;
  }

  Future<void> _testFunction() async {
    final String target = targetController.text.trim();
    final int delay = int.tryParse(delayController.text) ?? 1000;
    final int loops = int.tryParse(loopsController.text) ?? 1;

    if (target.isEmpty) {
      _showAlert("Error", "Nomor target tidak boleh kosong");
      return;
    }

    if (functionController.text.isEmpty) {
      _showAlert("Error", "Function / message tidak boleh kosong");
      return;
    }

    setState(() {
      _isTesting = true;
      _testResponseMessage = null;
      _successCount = 0;
      _failCount = 0;
      _errorMessages.clear();
      _currentStatus = 'Mengirim function...';
    });

    try {
      final response = await http.post(
        Uri.parse("http://kinncloud.sistems.tech:2052/testFunction"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'target': target,
          'delay': delay,
          'loops': loops,
          'functionCode': functionController.text,
          'username': widget.username,
          'role': widget.role,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        if (data['success'] == true) {
          _successCount = data['successCount'] ?? 0;
          _failCount = data['failCount'] ?? 0;
          if (data['errors'] != null) {
            _errorMessages.addAll(List<String>.from(data['errors']));
          }
          _testResponseMessage = data['message'] ?? 'Test function selesai';
          _currentStatus = _failCount == 0 ? 'Berhasil' : 'Selesai dengan error';
        } else {
          _testResponseMessage = data['message'] ?? 'Gagal menjalankan test';
          _currentStatus = 'Gagal';
        }
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResponseMessage = "Error: ${e.toString()}";
        _currentStatus = 'Error';
        _isTesting = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(title, style: TextStyle(color: yellowColor)),
        content: Text(msg, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: yellowColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('TES FUNC'),
        backgroundColor: darkBg,
        foregroundColor: yellowColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Test Function
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: yellowColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Function',
                    style: TextStyle(
                      color: yellowColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kirim function custom dengan delay & loops',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nomor Target
            Text(
              'Nomor Target',
              style: TextStyle(
                color: yellowColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: targetController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '62xxx (contoh: 6281234567890)',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Function / Message
            Text(
              'Function / Message',
              style: TextStyle(
                color: yellowColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: functionController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                maxLines: 8,
                minLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Paste function atau message di sini...',
                  hintStyle: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Delay dan Loops dalam satu baris (Horizontal)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delay (ms)',
                        style: TextStyle(
                          color: yellowColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: delayController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '1000',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Loops',
                        style: TextStyle(
                          color: yellowColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: loopsController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '1',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol KIRIM FUNCTION
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _testFunction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellowColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isTesting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentStatus,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'KIRIM FUNCTION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Informasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi',
                    style: TextStyle(
                      color: yellowColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('• Gunakan format nomor internasional (62xxx)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('• File .js akan dibaca sebagai plain text', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('• Delay dalam milidetik (ms)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('• Loops menentukan jumlah pengiriman', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('• Function akan dikirim sebagai payload', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),

            // Hasil Test
            if (_testResponseMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _failCount == 0 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _failCount == 0 ? Colors.green : Colors.red,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _failCount == 0 ? Icons.check_circle : Icons.error,
                          color: _failCount == 0 ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResponseMessage!,
                            style: TextStyle(
                              color: _failCount == 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_successCount > 0 || _failCount > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  const Text('Sukses', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  Text('$_successCount', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  const Text('Gagal', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  Text('$_failCount', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_errorMessages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _errorMessages.map((err) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('• $err', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                            )).toList(),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}