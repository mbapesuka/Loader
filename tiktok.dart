import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart'; // Tambahkan import ini untuk XFile

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Black & Yellow Theme Colors
  final Color primaryDark = Colors.black;
  final Color primaryYellow = const Color(0xFFFFC107);
  final Color accentYellow = const Color(0xFFFFD54F);
  final Color lightYellow = const Color(0xFFFFE082);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardDark = const Color(0xFF1A1A1A);

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: primaryDark)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = "URL TikTok tidak boleh kosong.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    // TikTok WM API
    final apiUrl = Uri.parse("https://www.tikwm.com/api/?url=$url");

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // TikTok WM API response structure
        if (json['code'] == 0 && json['data'] != null) {
          setState(() => _videoData = json['data']);
          _initializeVideoPlayer();
        } else {
          setState(() => _errorMessage = json['msg'] ?? "Gagal mengambil data TikTok.");
        }
      } else {
        setState(() => _errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Terjadi kesalahan koneksi.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeVideoPlayer() {
    // TikTok WM API returns 'play' for video without watermark
    String? videoUrl = _videoData?['play'];
    if (videoUrl == null) {
      // Fallback to other possible fields
      videoUrl = _videoData?['wmplay'] ?? _videoData?['hdplay'];
    }
    
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              materialProgressColors: ChewieProgressColors(
                playedColor: primaryYellow,
                handleColor: lightYellow,
              ),
            );
          });
        }).catchError((error) {
          setState(() => _errorMessage = "Gagal memuat video: $error");
        });
    } else {
      setState(() => _errorMessage = "URL video tidak ditemukan");
    }
  }

  Future<void> _shareVideo() async {
    String? videoUrl = _videoData?['play'];
    if (videoUrl == null) {
      videoUrl = _videoData?['wmplay'] ?? _videoData?['hdplay'];
    }
    
    if (videoUrl == null || videoUrl.isEmpty) {
      _showSnackBar("URL video tidak tersedia");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: primaryYellow)),
    );

    try {
      final response = await http.get(
        Uri.parse(videoUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tiktok_video.mp4');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) Navigator.pop(context);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Video TikTok: ${_videoData!['title'] ?? ''}',
        );
      } else {
        throw Exception("Server memutus koneksi (${response.statusCode})");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Gagal memproses video: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text('TIKTOK DOWNLOADER', style: TextStyle(color: primaryYellow, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryYellow.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    style: TextStyle(color: primaryWhite),
                    decoration: InputDecoration(
                      hintText: 'Tempel link TikTok di sini...',
                      hintStyle: TextStyle(color: accentGrey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryYellow.withOpacity(0.5))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: lightYellow)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _downloadTiktok,
                      icon: Icon(_isLoading ? Icons.sync : Icons.download, color: primaryDark),
                      label: Text(_isLoading ? 'LOADING...' : 'DOWNLOAD', style: TextStyle(color: primaryDark)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              ),
            if (_videoData != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    if (_chewieController != null && _videoController != null && _videoController!.value.isInitialized)
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      )
                    else if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 200,
                        color: Colors.grey.shade900,
                        child: const Center(child: Text('Video tidak tersedia', style: TextStyle(color: Colors.white))),
                      ),
                    const SizedBox(height: 16),
                    if (_videoData!['title'] != null)
                      Text(
                        _videoData!['title'],
                        style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    if (_videoData!['author'] != null)
                      Text(
                        '@${_videoData!['author']}',
                        style: TextStyle(color: accentYellow, fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _shareVideo,
                        // PERBAIKAN: Hapus 'const' karena menggunakan variabel primaryDark
                        icon: Icon(Icons.share, color: primaryDark),
                        // PERBAIKAN: Hapus 'const' karena menggunakan variabel primaryDark
                        label: Text('SHARE VIDEO', style: TextStyle(color: primaryDark)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentYellow,
                        ),
                      ),
                    ),
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