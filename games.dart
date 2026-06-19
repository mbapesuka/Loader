import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koleksi Game',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const GamesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  int _selectedIndex = 0;
  final List<Widget> _gameWidgets = const [
    TicTacToeGame(),
    ChessGame(),
    SnakeGame(),
    MemoryMatchGame(),
  ];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.setVolume(0.5);
    await _audioPlayer.play(AssetSource('audio/background.mp3'));
    _audioPlayer.onPlayerComplete.listen((event) {
      _playBackgroundMusic();
    });
    setState(() {
      _isMusicPlaying = true;
    });
  }

  Future<void> _toggleMusic() async {
    if (_isMusicPlaying) {
      await _audioPlayer.pause();
      setState(() => _isMusicPlaying = false);
    } else {
      await _audioPlayer.resume();
      setState(() => _isMusicPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _gameWidgets[_selectedIndex],
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Icon(_isMusicPlaying ? Icons.volume_up : Icons.volume_off,
                color: Colors.white),
              onPressed: _toggleMusic,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3A8A).withOpacity(0.9),
              const Color(0xFF0F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF60A5FA),
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_3x3),
              label: 'Tic Tac Toe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.casino),
              label: 'Catur',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smartphone),
              label: 'Snake',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.memory),
              label: 'Memory',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TIC TAC TOE GAME =================
class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  String _currentPlayer = 'X';
  List<String> _board = List.filled(9, '');
  String? _winner;
  bool _gameOver = false;
  bool _isPlayingVsBot = false;
  String _botLevel = 'medium';
  
  int _playerScore = 0;
  int _botScore = 0;
  int _draws = 0;
  
  int _playerTime = 300;
  int _botTime = 300;
  Timer? _timer;
  bool _isPlayerTurn = true;
  
  final Map<String, double> _botDifficulty = {
    'low': 0.3,
    'medium': 0.6,
    'hard': 0.9,
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
  _timer?.cancel();
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_gameOver || !_isPlayingVsBot) return;
    setState(() {
      if (_isPlayerTurn) {
        if (_playerTime > 0) {
          _playerTime--;
        } else {
          _gameOver = true;
          _winner = 'O';
          _botScore++;
          timer.cancel();
          _showGameOverDialog();
        }
      } else {
        if (_botTime > 0) {
          _botTime--;
        } else {
          _gameOver = true;
          _winner = 'Player';
          _playerScore++;
          timer.cancel();
          _showGameOverDialog();
        }
      }
    });
  });
}

  void _makeMove(int index) {
    if (_gameOver || _board[index] != '' || !_isPlayerTurn) return;
    
    setState(() {
      _board[index] = _currentPlayer;
      final winner = _checkWinner(_board);
      final isDraw = !_board.contains('') && winner == null;
      
      if (winner != null || isDraw) {
        _gameOver = true;
        _winner = winner ?? 'Draw';
        _timer?.cancel();
        
        if (winner == 'X') _playerScore++;
        else if (winner == 'O') _botScore++;
        else _draws++;
        
        Future.delayed(const Duration(milliseconds: 500), () => _showGameOverDialog());
      } else {
        _currentPlayer = 'O';
        _isPlayerTurn = false;
        if (_isPlayingVsBot) {
          Future.delayed(const Duration(milliseconds: 500), () => _makeBotMove());
        }
      }
    });
  }

  void _makeBotMove() {
    if (_gameOver) return;
    
    final emptyIndices = _board.asMap().entries
        .where((entry) => entry.value == '')
        .map((entry) => entry.key)
        .toList();
    if (emptyIndices.isEmpty) return;
    
    int botMoveIndex;
    
    if (_botLevel == 'hard' && Random().nextDouble() < _botDifficulty['hard']!) {
      botMoveIndex = _findBestMove();
    } else if (_botLevel == 'medium' && Random().nextDouble() < _botDifficulty['medium']!) {
      if (Random().nextBool()) botMoveIndex = _findBestMove();
      else botMoveIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
    } else {
      botMoveIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
    }
    
    setState(() {
      _board[botMoveIndex] = 'O';
      final winner = _checkWinner(_board);
      final isDraw = !_board.contains('') && winner == null;
      
      if (winner != null || isDraw) {
        _gameOver = true;
        _winner = winner ?? 'Draw';
        _timer?.cancel();
        if (winner == 'O') _botScore++;
        else if (winner == 'X') _playerScore++;
        else _draws++;
        Future.delayed(const Duration(milliseconds: 500), () => _showGameOverDialog());
      } else {
        _currentPlayer = 'X';
        _isPlayerTurn = true;
      }
    });
  }

  int _findBestMove() {
    for (int i = 0; i < 9; i++) {
      if (_board[i] == '') {
        List<String> tempBoard = List.from(_board);
        tempBoard[i] = 'O';
        if (_checkWinner(tempBoard) == 'O') return i;
      }
    }
    for (int i = 0; i < 9; i++) {
      if (_board[i] == '') {
        List<String> tempBoard = List.from(_board);
        tempBoard[i] = 'X';
        if (_checkWinner(tempBoard) == 'X') return i;
      }
    }
    if (_board[4] == '') return 4;
    List<int> corners = [0, 2, 6, 8]..shuffle();
    for (int corner in corners) if (_board[corner] == '') return corner;
    final emptyIndices = _board.asMap().entries
        .where((entry) => entry.value == '')
        .map((entry) => entry.key)
        .toList();
    return emptyIndices[Random().nextInt(emptyIndices.length)];
  }

  String? _checkWinner(List<String> board) {
    const winningCombinations = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6],
    ];
    for (final combo in winningCombinations) {
      if (board[combo[0]] != '' &&
          board[combo[0]] == board[combo[1]] &&
          board[combo[0]] == board[combo[2]]) {
        return board[combo[0]];
      }
    }
    return null;
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _winner = null;
      _gameOver = false;
      _playerTime = 300;
      _botTime = 300;
      _isPlayerTurn = true;
    });
    _startTimer();
  }

  void _startVsBot(String level) {
    setState(() {
      _isPlayingVsBot = true;
      _botLevel = level;
      _playerScore = 0;
      _botScore = 0;
      _draws = 0;
      _resetGame();
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Center(
          child: Text(
            _winner == 'Draw' ? 'SERI!' : 'MENANG!',
            style: TextStyle(
              color: _winner == 'X' ? const Color(0xFF60A5FA) : 
                     _winner == 'O' ? const Color(0xFF10B981) : 
                     const Color(0xFFF59E0B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Text(
          _winner == 'Draw' ? 'Permainan berakhir seri!' : 
          _winner == 'X' ? 'Anda menang!' : 'Bot menang!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () { Navigator.pop(context); _resetGame(); },
                child: const Text('MAIN LAGI', style: TextStyle(color: Color(0xFF60A5FA))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() { _isPlayingVsBot = false; });
                },
                child: const Text('KELUAR', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2,'0')}:${remaining.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: !_isPlayingVsBot ? _buildMainMenu() : _buildGameScreen(),
    );
  }

  Widget _buildMainMenu() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            children: [
              const Icon(Icons.grid_3x3, size: 64, color: Color(0xFF60A5FA)),
              const SizedBox(height: 16),
              const Text('TIC TAC TOE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Pilih mode permainan', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              const Text('VS BOT', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDifficultyButton('MUDAH', 'low', const Color(0xFF10B981)),
              const SizedBox(height: 12),
              _buildDifficultyButton('SEDANG', 'medium', const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildDifficultyButton('SULIT', 'hard', const Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String text, String level, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _startVsBot(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(level == 'low' ? Icons.arrow_circle_down : level == 'medium' ? Icons.arrow_circle_right : Icons.arrow_circle_up),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LEVEL: ${_botLevel.toUpperCase()}', style: TextStyle(color: _botLevel == 'low' ? Colors.green : _botLevel == 'medium' ? Colors.orange : Colors.red)),
                    Text(_isPlayerTurn ? 'Giliran Anda' : 'Giliran Bot', style: TextStyle(color: _isPlayerTurn ? Colors.green : Colors.red)),
                  ],
                ),
                Text('GILIRAN: $_currentPlayer', style: TextStyle(color: _currentPlayer == 'X' ? const Color(0xFF60A5FA) : const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                IconButton(onPressed: () { setState(() { _isPlayingVsBot = false; }); }, icon: const Icon(Icons.exit_to_app, color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreBoard(),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _makeMove(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _board[index] == 'X' ? const Color(0xFF60A5FA) : _board[index] == 'O' ? const Color(0xFF10B981) : const Color(0xFF334155), width: 2),
                    ),
                    child: Center(
                      child: Text(_board[index], style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _board[index] == 'X' ? const Color(0xFF60A5FA) : const Color(0xFF10B981))),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('ULANGI PERMAINAN'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [const Text('ANDA', style: TextStyle(color: Color(0xFF60A5FA))), Text('$_playerScore', style: const TextStyle(fontSize: 24)), Text(_formatTime(_playerTime), style: TextStyle(color: _isPlayerTurn ? Colors.green : Colors.white70))]),
          Column(children: [const Text('SERI', style: TextStyle(color: Color(0xFFF59E0B))), Text('$_draws', style: const TextStyle(fontSize: 20))]),
          Column(children: [const Text('BOT', style: TextStyle(color: Color(0xFF10B981))), Text('$_botScore', style: const TextStyle(fontSize: 24)), Text(_formatTime(_botTime), style: TextStyle(color: !_isPlayerTurn ? Colors.red : Colors.white70))]),
        ],
      ),
    );
  }
}

// ================= CHESS GAME (CATUR) =================
class ChessGame extends StatefulWidget {
  const ChessGame({super.key});

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends State<ChessGame> {
  String _botLevel = 'medium';
  bool _isPlayingVsBot = false;
  bool _isWhite = true;
  bool _isPlayerTurn = true;
  bool _gameOver = false;
  String _winner = '';
  
  int _playerScore = 0;
  int _botScore = 0;
  int _draws = 0;
  
  int _playerTime = 600;
  int _botTime = 600;
  Timer? _timer;
  
  List<List<String>> _board = [
    ['r','n','b','q','k','b','n','r'],
    ['p','p','p','p','p','p','p','p'],
    ['','','','','','','',''],
    ['','','','','','','',''],
    ['','','','','','','',''],
    ['','','','','','','',''],
    ['P','P','P','P','P','P','P','P'],
    ['R','N','B','Q','K','B','N','R'],
  ];
  List<List<bool>> _possibleMoves = List.generate(8, (_) => List.filled(8, false));
  int? _selectedRow;
  int? _selectedCol;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
  _timer?.cancel();
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_gameOver || !_isPlayingVsBot) return;
    setState(() {
      if (_isPlayerTurn) {
        if (_playerTime > 0) {
          _playerTime--;
        } else {
          _gameOver = true;
          _winner = 'Bot';
          _botScore++;
          timer.cancel();
          _showGameOverDialog();
        }
      } else {
        if (_botTime > 0) {
          _botTime--;
        } else {
          _gameOver = true;
          _winner = 'Player';
          _playerScore++;
          timer.cancel();
          _showGameOverDialog();
        }
      }
    });
  });
}

  void _selectPiece(int row, int col) {
    if (_gameOver || !_isPlayerTurn) return;
    final piece = _board[row][col];
    if (piece.isEmpty) return;
    final isWhitePiece = piece == piece.toUpperCase();
    if ((_isWhite && !isWhitePiece) || (!_isWhite && isWhitePiece)) {
      _showMessage('Bukan bidakmu!');
      return;
    }
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _calculatePossibleMoves(row, col);
    });
  }

  void _calculatePossibleMoves(int row, int col) {
    _possibleMoves = List.generate(8, (_) => List.filled(8, false));
    final piece = _board[row][col].toLowerCase();
    switch (piece) {
      case 'p': // pion
        final direction = _board[row][col] == 'P' ? -1 : 1;
        if (_isInBoard(row+direction, col) && _board[row+direction][col].isEmpty)
          _possibleMoves[row+direction][col] = true;
        if (_isInBoard(row+direction, col-1) && _board[row+direction][col-1].isNotEmpty)
          _possibleMoves[row+direction][col-1] = true;
        if (_isInBoard(row+direction, col+1) && _board[row+direction][col+1].isNotEmpty)
          _possibleMoves[row+direction][col+1] = true;
        break;
      case 'r': _calculateRookMoves(row, col); break;
      case 'n': _calculateKnightMoves(row, col); break;
      case 'b': _calculateBishopMoves(row, col); break;
      case 'q': _calculateRookMoves(row, col); _calculateBishopMoves(row, col); break;
      case 'k': _calculateKingMoves(row, col); break;
    }
  }

  void _calculateRookMoves(int row, int col) {
    const dirs = [[-1,0],[1,0],[0,-1],[0,1]];
    for (final d in dirs) {
      var r = row+d[0], c = col+d[1];
      while (_isInBoard(r,c)) {
        if (_board[r][c].isEmpty) _possibleMoves[r][c] = true;
        else {
          if (_isOpponentPiece(row,col,r,c)) _possibleMoves[r][c] = true;
          break;
        }
        r+=d[0]; c+=d[1];
      }
    }
  }

  void _calculateBishopMoves(int row, int col) {
    const dirs = [[-1,-1],[-1,1],[1,-1],[1,1]];
    for (final d in dirs) {
      var r = row+d[0], c = col+d[1];
      while (_isInBoard(r,c)) {
        if (_board[r][c].isEmpty) _possibleMoves[r][c] = true;
        else {
          if (_isOpponentPiece(row,col,r,c)) _possibleMoves[r][c] = true;
          break;
        }
        r+=d[0]; c+=d[1];
      }
    }
  }

  void _calculateKnightMoves(int row, int col) {
    const moves = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]];
    for (final m in moves) {
      final r = row+m[0], c = col+m[1];
      if (_isInBoard(r,c) && (_board[r][c].isEmpty || _isOpponentPiece(row,col,r,c))) _possibleMoves[r][c] = true;
    }
  }

  void _calculateKingMoves(int row, int col) {
    const moves = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]];
    for (final m in moves) {
      final r = row+m[0], c = col+m[1];
      if (_isInBoard(r,c) && (_board[r][c].isEmpty || _isOpponentPiece(row,col,r,c))) _possibleMoves[r][c] = true;
    }
  }

  bool _isInBoard(int r, int c) => r>=0 && r<8 && c>=0 && c<8;
  bool _isOpponentPiece(int fromR, int fromC, int toR, int toC) {
    final from = _board[fromR][fromC];
    final to = _board[toR][toC];
    if (to.isEmpty) return false;
    return (from == from.toUpperCase()) != (to == to.toUpperCase());
  }

  void _makeMove(int toRow, int toCol) {
    if (_selectedRow==null || !_possibleMoves[toRow][toCol]) return;
    if (_gameOver || !_isPlayerTurn) return;
    setState(() {
      final captured = _board[toRow][toCol];
      if (captured.toLowerCase() == 'k') {
        _gameOver = true;
        _winner = _board[_selectedRow!][_selectedCol!] == _board[_selectedRow!][_selectedCol!].toUpperCase() ? 'Player' : 'Bot';
        if (_winner == 'Player') _playerScore++; else _botScore++;
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () => _showGameOverDialog());
      }
      _board[toRow][toCol] = _board[_selectedRow!][_selectedCol!];
      _board[_selectedRow!][_selectedCol!] = '';
      _selectedRow = null;
      _selectedCol = null;
      _possibleMoves = List.generate(8, (_) => List.filled(8, false));
      if (_isPlayingVsBot) {
        _isPlayerTurn = false;
        Future.delayed(const Duration(milliseconds: 500), () => _makeBotMove());
      }
    });
  }

  void _makeBotMove() {
    if (_gameOver) return;
    List<Map<String,dynamic>> moves = [];
    for (int r=0; r<8; r++) {
      for (int c=0; c<8; c++) {
        final piece = _board[r][c];
        if (piece.isNotEmpty && piece != piece.toUpperCase()) {
          _calculatePossibleMoves(r, c);
          for (int tr=0; tr<8; tr++) {
            for (int tc=0; tc<8; tc++) {
              if (_possibleMoves[tr][tc]) {
                moves.add({'fromR':r,'fromC':c,'toR':tr,'toC':tc,'capture':_board[tr][tc].isNotEmpty});
              }
            }
          }
        }
      }
    }
    if (moves.isEmpty) return;
    Map<String,dynamic> selected;
    if (_botLevel == 'hard') {
      var captures = moves.where((m) => m['capture']).toList();
      if (captures.isNotEmpty) selected = captures[Random().nextInt(captures.length)];
      else selected = moves[Random().nextInt(moves.length)];
    } else if (_botLevel == 'medium') {
      var captures = moves.where((m) => m['capture']).toList();
      if (captures.isNotEmpty && Random().nextBool()) selected = captures[Random().nextInt(captures.length)];
      else selected = moves[Random().nextInt(moves.length)];
    } else {
      selected = moves[Random().nextInt(moves.length)];
    }
    setState(() {
      final captured = _board[selected['toR']][selected['toC']];
      if (captured.toLowerCase() == 'k') {
        _gameOver = true;
        _winner = 'Bot';
        _botScore++;
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () => _showGameOverDialog());
      }
      _board[selected['toR']][selected['toC']] = _board[selected['fromR']][selected['fromC']];
      _board[selected['fromR']][selected['fromC']] = '';
      _isPlayerTurn = true;
    });
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _board = [
        ['r','n','b','q','k','b','n','r'],
        ['p','p','p','p','p','p','p','p'],
        ['','','','','','','',''],
        ['','','','','','','',''],
        ['','','','','','','',''],
        ['','','','','','','',''],
        ['P','P','P','P','P','P','P','P'],
        ['R','N','B','Q','K','B','N','R'],
      ];
      _playerTime = 600;
      _botTime = 600;
      _gameOver = false;
      _winner = '';
      _selectedRow = null;
      _selectedCol = null;
      _possibleMoves = List.generate(8, (_) => List.filled(8, false));
      _isPlayerTurn = true;
    });
    _startTimer();
  }

  void _startVsBot(String level) {
    setState(() {
      _isPlayingVsBot = true;
      _botLevel = level;
      _playerScore = 0;
      _botScore = 0;
      _draws = 0;
      _resetGame();
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(_winner=='Draw'?'SERI!':'CHECKMATE!', style: TextStyle(color: _winner=='Player'?Colors.blue:_winner=='Bot'?Colors.red:Colors.orange)),
        content: Text(_winner=='Draw'?'Seri!':'${_winner} menang!', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _resetGame(); }, child: const Text('MAIN LAGI', style: TextStyle(color: Color(0xFF60A5FA)))),
          TextButton(onPressed: () { Navigator.pop(context); setState(() { _isPlayingVsBot = false; }); }, child: const Text('KELUAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.blue));
  }

  String _formatTime(int seconds) => '${(seconds~/60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}';
  String _getPieceSymbol(String piece) => {'k':'♔','q':'♕','r':'♖','b':'♗','n':'♘','p':'♙'}[piece.toLowerCase()] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: !_isPlayingVsBot ? _buildMainMenu() : _buildGameScreen(),
    );
  }

  Widget _buildMainMenu() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Column(
            children: [
              const Icon(Icons.casino, size: 64, color: Color(0xFFF0D9B5)),
              const SizedBox(height: 16),
              const Text('CATUR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Pilih mode permainan', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              const Text('VS BOT', style: TextStyle(color: Color(0xFFF0D9B5), fontSize: 18)),
              const SizedBox(height: 16),
              _buildDifficultyButton('MUDAH', 'low', const Color(0xFF10B981)),
              const SizedBox(height: 12),
              _buildDifficultyButton('SEDANG', 'medium', const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildDifficultyButton('SULIT', 'hard', const Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String text, String level, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _startVsBot(level),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(level=='low'?Icons.arrow_circle_down:level=='medium'?Icons.arrow_circle_right:Icons.arrow_circle_up),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [Text(_isWhite?'PUTIH':'HITAM', style: const TextStyle(color: Color(0xFFF0D9B5))), Text('$_playerScore', style: const TextStyle(fontSize: 24)), Text(_formatTime(_playerTime), style: TextStyle(color: _isPlayerTurn?Colors.green:Colors.white70))]),
          Column(children: [const Text('SERI', style: TextStyle(color: Color(0xFFF59E0B))), Text('$_draws', style: const TextStyle(fontSize: 20))]),
          Column(children: [const Text('BOT', style: TextStyle(color: Color(0xFFB58863))), Text('$_botScore', style: const TextStyle(fontSize: 24)), Text(_formatTime(_botTime), style: TextStyle(color: !_isPlayerTurn?Colors.red:Colors.white70))]),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LEVEL: ${_botLevel.toUpperCase()}', style: TextStyle(color: _botLevel=='low'?Colors.green:_botLevel=='medium'?Colors.orange:Colors.red)),
                Text(_isPlayerTurn?'Giliran Anda':'Giliran Bot', style: TextStyle(color: _isPlayerTurn?Colors.green:Colors.red)),
                IconButton(onPressed: () { setState(() { _isPlayingVsBot = false; }); }, icon: const Icon(Icons.exit_to_app, color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreBoard(),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemCount: 64,
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                bool isWhite = (row+col)%2==0;
                bool isSelected = row==_selectedRow && col==_selectedCol;
                bool isPossible = _possibleMoves[row][col];
                return GestureDetector(
                  onTap: () {
                    if (_possibleMoves[row][col]) _makeMove(row, col);
                    else _selectPiece(row, col);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.5) : isPossible ? Colors.green.withOpacity(0.3) : isWhite ? const Color(0xFFF0D9B5) : const Color(0xFFB58863),
                      border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                    ),
                    child: Center(
                      child: _board[row][col].isNotEmpty ? Text(_getPieceSymbol(_board[row][col]), style: TextStyle(fontSize: 28, color: _board[row][col]==_board[row][col].toUpperCase()?Colors.white:Colors.black)) : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('ULANGI PERMAINAN'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SNAKE GAME =================
class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 20;
  List<List<int>> _snake = [[10,10]];
  List<int> _food = [15,15];
  String _direction = 'RIGHT';
  String _nextDirection = 'RIGHT';
  bool _gameOver = false;
  int _score = 0;
  int _highScore = 0;
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _snake = [[10,10]];
      _food = [15,15];
      _direction = 'RIGHT';
      _nextDirection = 'RIGHT';
      _gameOver = false;
      _score = 0;
      _isPlaying = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_gameOver && _isPlaying) _moveSnake();
    });
  }

  void _moveSnake() {
    _direction = _nextDirection;
    List<int> newHead = List.from(_snake.first);
    switch (_direction) {
      case 'UP': newHead[1]--; break;
      case 'DOWN': newHead[1]++; break;
      case 'LEFT': newHead[0]--; break;
      case 'RIGHT': newHead[0]++; break;
    }
    if (newHead[0]<0 || newHead[0]>=gridSize || newHead[1]<0 || newHead[1]>=gridSize || _snake.any((s)=>s[0]==newHead[0]&&s[1]==newHead[1])) {
      setState(() { _gameOver = true; _isPlaying = false; if(_score>_highScore) _highScore=_score; });
      _timer?.cancel();
      return;
    }
    setState(() {
      _snake.insert(0, newHead);
      if (newHead[0]==_food[0] && newHead[1]==_food[1]) { _score++; _generateFood(); }
      else _snake.removeLast();
    });
  }

  void _generateFood() {
    Random r = Random();
    do { _food = [r.nextInt(gridSize), r.nextInt(gridSize)]; } while (_snake.any((s)=>s[0]==_food[0]&&s[1]==_food[1]));
  }

  void _resetGame() { _timer?.cancel(); _startGame(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Skor: $_score', style: const TextStyle(color: Colors.white, fontSize: 20)), Text('Terbaik: $_highScore', style: const TextStyle(color: Colors.white70, fontSize: 20))],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.all(20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize, childAspectRatio: 1),
                itemCount: gridSize*gridSize,
                itemBuilder: (_, index) {
                  int row = index ~/ gridSize, col = index % gridSize;
                  bool isSnake = _snake.any((s)=>s[0]==col && s[1]==row);
                  bool isFood = _food[0]==col && _food[1]==row;
                  return Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: isSnake ? const Color(0xFF10B981) : isFood ? Colors.red : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)));
                },
              ),
            ),
            const SizedBox(height: 20),
            if (!_isPlaying)
              ElevatedButton.icon(onPressed: _resetGame, icon: const Icon(Icons.play_arrow), label: const Text('MULAI'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16))),
            if (_isPlaying && !_gameOver)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['UP','LEFT','DOWN','RIGHT'].map((dir) => IconButton(icon: Icon({'UP':Icons.arrow_upward,'DOWN':Icons.arrow_downward,'LEFT':Icons.arrow_back,'RIGHT':Icons.arrow_forward}[dir]!, color: Colors.white, size: 36), onPressed: () {
                    if ((dir=='UP' && _direction!='DOWN')||(dir=='DOWN' && _direction!='UP')||(dir=='LEFT' && _direction!='RIGHT')||(dir=='RIGHT' && _direction!='LEFT')) setState(() => _nextDirection=dir);
                  })).toList(),
                ),
              ),
            if (_gameOver) Column(children: [const Text('GAME OVER', style: TextStyle(color: Colors.red, fontSize: 24)), const SizedBox(height: 10), ElevatedButton(onPressed: _resetGame, child: const Text('MAIN LAGI'))]),
          ],
        ),
      ),
    );
  }
}

// ================= MEMORY MATCH GAME =================
class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const int gridSize = 4;
  List<String> _cards = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstIndex;
  int? _secondIndex;
  bool _isWaiting = false;
  int _moves = 0;
  int _score = 0;

  final List<String> _icons = ['🍎','🍌','🍒','🍇','🍊','🍉','🥝','🥥','🍎','🍌','🍒','🍇','🍊','🍉','🥝','🥥'];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    List<String> shuffled = List.from(_icons)..shuffle();
    setState(() {
      _cards = shuffled;
      _revealed = List.filled(16, false);
      _matched = List.filled(16, false);
      _firstIndex = null;
      _secondIndex = null;
      _isWaiting = false;
      _moves = 0;
      _score = 0;
    });
  }

  void _onCardTap(int index) {
    if (_isWaiting || _matched[index] || _revealed[index]) return;
    if (_firstIndex != null && _secondIndex != null) return;
    setState(() {
      _revealed[index] = true;
      if (_firstIndex == null) _firstIndex = index;
      else { _secondIndex = index; _moves++; _checkMatch(); }
    });
  }

  void _checkMatch() async {
    _isWaiting = true;
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      if (_cards[_firstIndex!] == _cards[_secondIndex!]) {
        _matched[_firstIndex!] = true;
        _matched[_secondIndex!] = true;
        _score += 10;
      } else {
        _revealed[_firstIndex!] = false;
        _revealed[_secondIndex!] = false;
      }
      _firstIndex = null;
      _secondIndex = null;
      _isWaiting = false;
    });
    if (_matched.every((m) => m)) _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('SELESAI!', style: TextStyle(color: Colors.white)),
        content: Text('Skor: $_score\nLangkah: $_moves', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () { Navigator.pop(context); _startNewGame(); }, child: const Text('MAIN LAGI', style: TextStyle(color: Color(0xFF60A5FA))))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [Text('Skor: $_score', style: const TextStyle(color: Colors.white, fontSize: 20)), Text('Langkah: $_moves', style: const TextStyle(color: Colors.white70, fontSize: 20))],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: 16,
              itemBuilder: (context, index) {
                bool show = _revealed[index] || _matched[index];
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _matched[index] ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: show ? const Color(0xFF60A5FA) : Colors.transparent, width: 2),
                    ),
                    child: Center(child: show ? Text(_cards[index], style: const TextStyle(fontSize: 32)) : const Icon(Icons.question_mark, color: Colors.white70, size: 30)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _startNewGame, icon: const Icon(Icons.refresh), label: const Text('RESET GAME'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}