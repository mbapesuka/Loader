// lib/calendar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late PageController _pageController;
  int _currentSlideIndex = 0; // 0-based, hari ke-1 index 0

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // set selected day ke hari ini
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
    });
  }

  String _getImagePath(int day) {
    return 'assets/kalenderFoto/kalen$day.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E), // ungu hitam
      appBar: AppBar(
        title: const Text(
          'Kalender & Galeri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D1B4E),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ========== KALENDER BULAN ==========
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B4E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header bulan & tahun
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 1),
                // Nama hari
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB']
                        .map((day) => Expanded(
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // Grid tanggal
                _buildDaysGrid(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ========== SLIDE PER HARI (1-30) ==========
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hari ${_currentSlideIndex + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Geser ke kiri/kanan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSlideIndex = index;
                      });
                    },
                    itemCount: 30, // 1-30
                    itemBuilder: (context, index) {
                      final dayNumber = index + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            _getImagePath(dayNumber),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple.shade800, Colors.deepPurple.shade900],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: Colors.white.withOpacity(0.5)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Foto hari $dayNumber belum tersedia',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Indikator slide (bulatan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(30, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentSlideIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayWeekday = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;
    // Konversi: Senin=1 ... Minggu=7 -> grid mulai dari Minggu (0)
    final leading = (firstDayWeekday % 7);

    List<Widget> dayWidgets = [];

    // Sel kosong sebelum tanggal 1
    for (int i = 0; i < leading; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Tanggal
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final isToday = DateUtils.isSameDay(date, DateTime.now());
      final isSelected = _selectedDay != null && DateUtils.isSameDay(date, _selectedDay!);
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
              // Geser slide ke hari yang dipilih (jika tanggal <= 30)
              if (date.day <= 30) {
                _pageController.animateToPage(
                  date.day - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _currentSlideIndex = date.day - 1;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.purpleAccent
                  : isToday
                      ? Colors.white24
                      : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.black
                      : isToday
                          ? Colors.white
                          : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: dayWidgets,
    );
  }
}