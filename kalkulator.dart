import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const KalkulatorApp());
}

class KalkulatorApp extends StatelessWidget {
  const KalkulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kalkulator Vanthra',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0A0A0A),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      debugShowCheckedModeBanner: false,
      home: const KalkulatorPage(),
    );
  }
}

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});

  @override
  State<KalkulatorPage> createState() => _KalkulatorPageState();
}

class _KalkulatorPageState extends State<KalkulatorPage> {
  String _display = "0";
  String _expression = "";
  String _lastResult = "";
  bool _isNewCalculation = true;
  
  final List<Map<String, dynamic>> _history = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;
  String _currentTypingResult = "";
  Timer? _typingTimer;
  int _typingIndex = 0;
  
  // Warna tema kuning kehitaman
  final Color primaryDark = const Color(0xFF0A0A0A);
  final Color cardDark = const Color(0xFF1A1A1A);
  final Color accentYellow = const Color(0xFFFFD700); // Kuning emas
  final Color accentDarkYellow = const Color(0xFFFFC107); // Kuning tua
  final Color accentSoftYellow = const Color(0xFFFFF176); // Kuning lembut

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('kalkulator_history');
    if (historyJson != null) {
      setState(() {
        _history.clear();
        for (var json in historyJson) {
          try {
            _history.add(jsonDecode(json));
          } catch (e) {}
        }
      });
    }
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('kalkulator_history', historyJson);
  }

  void _addToHistory(String expression, String result) {
    setState(() {
      _history.insert(0, {
        'expression': expression,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (_history.length > 50) _history.removeLast();
    });
    _saveHistory();
  }

  void _buttonPressed(String value) {
    setState(() {
      if (_isTyping) {
        _typingTimer?.cancel();
        _isTyping = false;
      }
      
      if (_isNewCalculation && _isNumber(value)) {
        _display = value;
        _expression = value;
        _isNewCalculation = false;
      } else if (value == "C") {
        _clear();
      } else if (value == "⌫") {
        _backspace();
      } else if (value == "=") {
        _calculate();
      } else if (value == "±") {
        _toggleSign();
      } else if (value == "%") {
        _percentage();
      } else {
        _addToExpression(value);
      }
    });
  }

  bool _isNumber(String value) {
    return RegExp(r'^[0-9.]$').hasMatch(value);
  }

  void _clear() {
    _display = "0";
    _expression = "";
    _isNewCalculation = true;
    _lastResult = "";
  }

  void _backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _display = _expression.isEmpty ? "0" : _expression;
      _isNewCalculation = false;
    } else if (_display != "0") {
      _display = "0";
      _isNewCalculation = true;
    }
  }

  void _toggleSign() {
    double current = double.parse(_display);
    current = -current;
    if (current == current.toInt()) {
      _display = current.toInt().toString();
    } else {
      _display = current.toString();
    }
    _expression = _display;
    _isNewCalculation = false;
  }

  void _percentage() {
    double current = double.parse(_display);
    current = current / 100;
    if (current == current.toInt()) {
      _display = current.toInt().toString();
    } else {
      _display = current.toString();
    }
    _expression = _display;
    _isNewCalculation = false;
  }

  void _addToExpression(String value) {
    if (_expression.isEmpty && (value == "×" || value == "÷" || value == "+" || value == "-")) {
      return;
    }
    
    _expression += _convertOperator(value);
    _display = _expression;
    _isNewCalculation = false;
  }

  String _convertOperator(String op) {
    switch(op) {
      case "×": return "*";
      case "÷": return "/";
      default: return op;
    }
  }

  String _displayOperator(String op) {
    switch(op) {
      case "*": return "×";
      case "/": return "÷";
      default: return op;
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    
    try {
      String expr = _expression.replaceAll("×", "*").replaceAll("÷", "/");
      
      double result = _evaluateExpression(expr);
      
      String resultStr;
      if (result == result.toInt()) {
        resultStr = result.toInt().toString();
      } else {
        resultStr = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      
      _startTypingAnimation(resultStr);
      _addToHistory(_expression, resultStr);
      
      _lastResult = resultStr;
      _expression = resultStr;
      
    } catch (e) {
      _display = "Error";
      _expression = "";
      _isNewCalculation = true;
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _display = "0";
          });
        }
      });
    }
  }

  double _evaluateExpression(String expression) {
    List<String> tokens = _tokenize(expression);
    List<double> numbers = [];
    List<String> operators = [];
    
    for (var token in tokens) {
      if (token == "+" || token == "-" || token == "*" || token == "/") {
        operators.add(token);
      } else {
        numbers.add(double.parse(token));
      }
    }
    
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == "*" || operators[i] == "/") {
        double result;
        if (operators[i] == "*") {
          result = numbers[i] * numbers[i + 1];
        } else {
          if (numbers[i + 1] == 0) throw Exception("Division by zero");
          result = numbers[i] / numbers[i + 1];
        }
        numbers[i] = result;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
        i--;
      }
    }
    
    double result = numbers[0];
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == "+") {
        result += numbers[i + 1];
      } else if (operators[i] == "-") {
        result -= numbers[i + 1];
      }
    }
    
    return result;
  }

  List<String> _tokenize(String expression) {
    List<String> tokens = [];
    String currentNumber = "";
    
    for (int i = 0; i < expression.length; i++) {
      String char = expression[i];
      if (char == "+" || char == "-" || char == "*" || char == "/") {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = "";
        }
        tokens.add(char);
      } else {
        currentNumber += char;
      }
    }
    
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }
    
    return tokens;
  }

  void _startTypingAnimation(String result) {
    setState(() {
      _isTyping = true;
      _currentTypingResult = "";
      _typingIndex = 0;
    });
    
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_typingIndex < result.length) {
        setState(() {
          _currentTypingResult = result.substring(0, _typingIndex + 1);
          _display = _currentTypingResult;
          _typingIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _display = result;
          _expression = result;
          _isNewCalculation = true;
        });
      }
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to clear all calculation history?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _history.clear();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('kalkulator_history');
            },
            child: Text('Clear', style: TextStyle(color: accentYellow)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentYellow, accentDarkYellow]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('kalkulator Vanthra', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: cardDark,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // Display utama
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardDark, primaryDark],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: accentYellow.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: accentYellow.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expression.isNotEmpty && !_isNewCalculation)
                  Text(
                    _expression.replaceAll("*", "×").replaceAll("/", "÷"),
                    style: TextStyle(
                      fontSize: 24,
                      color: accentYellow.withOpacity(0.7),
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Text(
                  _display,
                  style: TextStyle(
                    fontSize: _display.length > 10 ? 40 : 56,
                    fontWeight: FontWeight.bold,
                    color: accentYellow,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // History panel
          if (_history.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat',
                    style: TextStyle(color: accentYellow.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentYellow.withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['expression'].replaceAll("*", "×").replaceAll("/", "÷"),
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "= ${item['result']}",
                                style: TextStyle(
                                  color: accentYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Tombol kalkulator warna kuning
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildButtonRow(["C", "⌫", "%", "÷"]),
                  _buildButtonRow(["7", "8", "9", "×"]),
                  _buildButtonRow(["4", "5", "6", "-"]),
                  _buildButtonRow(["1", "2", "3", "+"]),
                  _buildButtonRow(["±", "0", ".", "="]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> values) {
    return Expanded(
      child: Row(
        children: values.map((value) {
          return _buildButton(value);
        }).toList(),
      ),
    );
  }

  Widget _buildButton(String text) {
    bool isOperator = text == "+" || text == "-" || text == "×" || text == "÷";
    bool isEqual = text == "=";
    bool isClear = text == "C" || text == "⌫";
    bool isSpecial = text == "%" || text == "±";
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _buttonPressed(text),
            borderRadius: BorderRadius.circular(60),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: isEqual
                    ? LinearGradient(colors: [accentYellow, accentDarkYellow])
                    : null,
                color: isEqual
                    ? null
                    : isOperator || isSpecial
                        ? cardDark
                        : Colors.grey.shade900,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isEqual)
                    BoxShadow(
                      color: accentYellow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isOperator || isEqual ? 28 : 26,
                    fontWeight: isEqual ? FontWeight.bold : FontWeight.w500,
                    color: isOperator || isSpecial
                        ? accentYellow
                        : isClear
                            ? accentSoftYellow
                            : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}