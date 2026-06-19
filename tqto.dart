import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ThanksToPage extends StatefulWidget {
  const ThanksToPage({Key? key}) : super(key: key);

  @override
  State<ThanksToPage> createState() => _ThanksToPageState();
}

class _ThanksToPageState extends State<ThanksToPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> thanksToList = [];
  bool isLoading = true;
  bool hasError = false;
  int currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Color Palette - Konsisten dan refined
  final Color _primaryDark = const Color(0xFF0A0A0A);
  final Color _cardDark = const Color(0xFF1A1A1A);
  final Color _cardDarker = const Color(0xFF141414);
  final Color _primaryRed = const Color(0xFF8B0000);
  final Color _accentRed = const Color(0xFFDC143C);
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = const Color(0xFFB0B0B0);
  final Color _borderColor = const Color(0xFF2A2A2A);

  // Gradients
  final LinearGradient _cardGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF141414),
    ],
    stops: [0.0, 1.0],
  );

  final LinearGradient _selectedCardGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF1A1A1A),
    ],
    stops: [0.0, 1.0],
  );

  // Animations
  final Duration _pageAnimationDuration = const Duration(milliseconds: 500);
  final Curve _pageAnimationCurve = Curves.easeInOut;
  final Duration _scaleAnimationDuration = const Duration(milliseconds: 300);
  final Curve _scaleAnimationCurve = Curves.easeOut;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    fetchThanksTo();
  }

  void _initializeControllers() {
    _pageController = PageController(viewportFraction: 0.82);
    _animationController = AnimationController(
      vsync: this,
      duration: _scaleAnimationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _scaleAnimationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchThanksTo() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response =
          await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/tq'));
      await Future.delayed(const Duration(milliseconds: 800)); // Untuk UX yang lebih smooth

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['result'] is List) {
          setState(() {
            thanksToList = List<Map<String, dynamic>>.from(data['result']);
            isLoading = false;
          });
          _animationController.forward();
        } else {
          _handleError();
        }
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() {
      hasError = true;
      isLoading = false;
    });
  }

  Future<void> launchContact(String url) async {
    String formattedUrl = url;

    if (!formattedUrl.startsWith('http')) {
      formattedUrl = formattedUrl.startsWith('t.me/')
          ? 'https://$formattedUrl'
          : 'https://t.me/$formattedUrl';
    }

    if (await canLaunch(formattedUrl)) {
      await launch(formattedUrl);
    } else {
      _showSnackBar('Cannot open: ${Uri.parse(formattedUrl).host}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> person, bool isCenter) {
    final hasImage = person['ppUrl'] != null &&
        person['ppUrl'].toString().isNotEmpty;

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _accentRed.withOpacity(isCenter ? 0.8 : 0.4),
          width: isCenter ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(isCenter ? 0.25 : 0.15),
            blurRadius: isCenter ? 30 : 20,
            spreadRadius: isCenter ? 3 : 2,
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: person['ppUrl'].toString(),
                placeholder: (context, url) => _buildPlaceholderImage(),
                errorWidget: (context, url, error) => _buildPlaceholderImage(),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryRed.withOpacity(0.15),
            _accentRed.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: _accentRed.withOpacity(0.4),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> person, int index) {
    final isCenter = index == currentIndex;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double scale = 1.0;
        double opacity = isCenter ? 1.0 : 0.7;

        if (_pageController.position.haveDimensions) {
          final double page = _pageController.page!;
          final double diff = (page - index).abs();
          scale = (1 - (diff * 0.35)).clamp(0.65, 1.0);
          opacity = (1 - (diff * 0.6)).clamp(0.4, 1.0);
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _pageController.animateToPage(
          index,
          duration: _pageAnimationDuration,
          curve: _pageAnimationCurve,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: isCenter ? _selectedCardGradient : _cardGradient,
            boxShadow: [
              BoxShadow(
                color: isCenter
                    ? _accentRed.withOpacity(0.35)
                    : Colors.black.withOpacity(0.4),
                blurRadius: isCenter ? 32 : 20,
                spreadRadius: isCenter ? 3 : 1,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: isCenter
                  ? _accentRed.withOpacity(0.5)
                  : _borderColor.withOpacity(0.8),
              width: isCenter ? 1.8 : 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProfileImage(person, isCenter),
                const SizedBox(height: 28),
                _buildNameSection(person, isCenter),
                const SizedBox(height: 12),
                _buildStatusBadge(person),
                const SizedBox(height: 24),
                if (person['contac'] != null &&
                    person['contac'].toString().isNotEmpty &&
                    isCenter)
                  _buildContactButton(person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection(Map<String, dynamic> person, bool isCenter) {
    return Text(
      person['name']?.toString() ?? 'Unknown',
      style: TextStyle(
        color: _textPrimary,
        fontSize: isCenter ? 24 : 22,
        fontWeight: isCenter ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> person) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _accentRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentRed.withOpacity(0.3)),
      ),
      child: Text(
        person['status']?.toString() ?? 'No Status',
        style: TextStyle(
          color: _accentRed,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContactButton(Map<String, dynamic> person) {
    return ElevatedButton(
      onPressed: () => launchContact(person['contac'].toString()),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 6,
        shadowColor: _accentRed.withOpacity(0.5),
        animationDuration: const Duration(milliseconds: 200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.telegram, size: 20),
          const SizedBox(width: 12),
          Text(
            'Contact on Telegram',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          thanksToList.length,
          (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: currentIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? _accentRed
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
                boxShadow: currentIndex == index
                    ? [
                        BoxShadow(
                          color: _accentRed.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentRed),
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading Profiles",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please wait a moment",
            style: TextStyle(
              color: _textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _accentRed.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC143C),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Connection Error",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Unable to load profiles. Please check your internet connection.",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: fetchThanksTo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                elevation: 4,
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.group_outlined,
              color: _textSecondary,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Profiles Available",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for updates",
            style: TextStyle(
              color: _textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              "Special Thanks",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) return _buildLoadingState();
    if (hasError) return _buildErrorState();
    if (thanksToList.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: thanksToList.length,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildProfileCard(thanksToList[index], index);
              },
              clipBehavior: Clip.none,
              padEnds: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPageIndicator(),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}