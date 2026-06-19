import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;
  String _currentPlayingTitle = '';
  int _currentIndex = -1;
  int _currentPosition = 0;
  int _totalDuration = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration.inSeconds;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position.inSeconds;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = 0;
      });
    });
  }

Future<void> _searchMusic(String query) async {
  if (query.trim().isEmpty) return;

  setState(() {
    _isLoading = true;
    _searchResults = [];
  });

  try {
    final response = await http.get(
      Uri.parse(
        "https://scnario-spotify.hf.space/play?q=${Uri.encodeComponent(query)}", // Ganti pake apikey lagu lu, w ga ada apikey lagu😭😭
      ),
    );
    

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == true && data["result"] != null) {
        final result = data["result"];

        setState(() {
          _searchResults = [
            {
              "title": result["title"] ?? "Unknown",
              "primary_artists": result["author"] ?? "Unknown Artist",
              "image": result["thumbnail"] ?? "",
              "url": result["audio"] is Map
                  ? result["audio"]["url"]
                  : result["audio"],
            }
          ];
        });
      } else {
        _setFallbackTracks();
      }
    } else {
      _setFallbackTracks();
    }
  } catch (e) {
    debugPrint(e.toString());
    _setFallbackTracks();
  }

  setState(() {
    _isLoading = false;
  });
}

void _setFallbackTracks() {
    setState(() {
      _searchResults = [
        {'title': 'Shape of You', 'primary_artists': 'Ed Sheeran', 'image': '', 'url': ''},
        {'title': 'Blinding Lights', 'primary_artists': 'The Weeknd', 'image': '', 'url': ''},
        {'title': 'Dance Monkey', 'primary_artists': 'Tones and I', 'image': '', 'url': ''},
      ];
    });
  }

  Future<void> _playSong(String url, String title, int index) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link lagu tidak tersedia')),
      );
      return;
    }
    
    if (_currentPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
    } else if (_currentPlayingUrl == url && !_isPlaying) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentPlayingUrl = url;
        _currentPlayingTitle = title;
        _currentIndex = index;
        _currentPosition = 0;
      });
    }
  }

  void _stopMusic() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentPlayingUrl = null;
      _currentPosition = 0;
    });
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "MUSIC PLAYER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: "Rajdhani",
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.grey[900]!],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cari lagu...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _searchMusic(value),
            ),
          ),

          if (_currentPlayingUrl != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFFD32F2F)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPlayingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: LinearProgressIndicator(
                                  value: _totalDuration > 0
                                      ? _currentPosition / _totalDuration
                                      : 0,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    onPressed: () => _playSong(_currentPlayingUrl!, _currentPlayingTitle, _currentIndex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    color: Colors.white,
                    onPressed: _stopMusic,
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Cari lagu atau ketik di atas",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontFamily: "Rajdhani",
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final song = _searchResults[index];
                          final title = song['title'] ?? 'Unknown';
                          final artist = song['primary_artists'] ?? 'Unknown Artist';
                          final imageUrl = song['image'] ?? '';
                          final url = song['url'] ?? '';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        imageUrl: imageUrl,
                                        placeholder: (_, __) => Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.music_note, color: Colors.white54),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.music_note, color: Colors.white54),
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  _currentPlayingUrl == url && _isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: const Color(0xFFD32F2F),
                                ),
                                onPressed: () => _playSong(url, title, index),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }
}