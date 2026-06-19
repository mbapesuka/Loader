import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  // --- State Variables ---
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['vip', 'reseller', 'owner', 'high admin', 'moderator', 'member', 'founder'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 50; 
  bool isLoading = false;

  // GLOWING GREY THEME (sama dengan file lain)
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
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  // Video Controller
  VideoPlayerController? _videoController;

  // --- Controllers ---
  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _initializeAnimations();
    _initVideoBackground();
    _fetchUsers();
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

  // --- API Logic ---
  Future<void> _fetchUsers() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/user/listUsers?key=$sessionKey'));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showSnackBar(data['message'] ?? 'Tidak diizinkan melihat daftar user.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Gagal memuat user list.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser(String username) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://kinncloud.sistems.tech:2052/api/user/deleteUser?key=$sessionKey&username=$username'));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showSnackBar("User '${data['user']['username']}' telah dihapus.");
        _fetchUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Gagal menghapus user.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Tidak dapat menghubungi server.", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showSnackBar("Semua field wajib diisi.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    if (mounted) Navigator.pop(context); 
    try {
      final url = Uri.parse('http://kinncloud.sistems.tech:2052/api/user/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole');
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showSnackBar("Akun '${data['user']['username']}' berhasil dibuat.");
        _fetchUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Gagal menghubungi server.", isError: true);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: isError ? Colors.white : _darkerBg, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _roseColor.withOpacity(0.9) : _glowColor1.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                  child: Icon(FontAwesomeIcons.userShield, color: _glowColor1, size: 22),
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
                          "ADMIN PANEL",
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
                        "User Management System",
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
                GestureDetector(
                  onTap: _fetchUsers,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(Icons.refresh, color: _glowColor1, size: 20),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildPremiumCard(
              title: 'CREATE USER',
              icon: FontAwesomeIcons.userPlus,
              colors: [_glowColor1, _glowColor2],
              onTap: () => _showCreateUserDialog(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPremiumCard(
              title: 'DELETE USER',
              icon: FontAwesomeIcons.userMinus,
              colors: [_glowColor2, _glowColor3],
              onTap: () => _showDeleteUserDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: colors[0], size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: "Rajdhani",
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: roleOptions.map((role) {
            final isSelected = selectedRole == role;
            Color chipColor;
            switch (role.toLowerCase()) {
              case 'vip': chipColor = const Color(0xFFFFD700); break;
              case 'reseller': chipColor = const Color(0xFF2196F3); break;
              case 'owner': chipColor = const Color(0xFF9C27B0); break;
              case 'founder': chipColor = const Color(0xFFE91E63); break;
              case 'high admin': chipColor = const Color(0xFFFF5722); break;
              default: chipColor = _glowColor1;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedRole = role;
                  _filterAndPaginate();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor.withOpacity(0.15) : _cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? chipColor : chipColor.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? chipColor : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.05),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.users, color: _glowColor1, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'USER LIST (${filteredList.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Rajdhani",
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            _buildCompactListView(),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactListView() {
    if (filteredList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_off, color: Colors.white38, size: 40),
              SizedBox(height: 12),
              Text('No users found for this role.', style: TextStyle(color: Colors.white38, fontFamily: 'Rajdhani')),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 420,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _getCurrentPageData().length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withOpacity(0.05),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = _getCurrentPageData()[index];
          final roleColor = _getRoleColor(user['role'] ?? 'member');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(FontAwesomeIcons.user, color: roleColor, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    user['username'] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Rajdhani',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      (user['role'] ?? 'N/A').toUpperCase(),
                      style: TextStyle(color: roleColor, fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Text(
                    user['parent'] ?? 'SYSTEM',
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDeleteConfirmationDialog(user['username']),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _roseColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline, color: _roseColor.withOpacity(0.7), size: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'vip': return const Color(0xFFFFD700);
      case 'reseller': return const Color(0xFF2196F3);
      case 'moderator': return const Color(0xFF00BCD4);
      case 'high admin': return const Color(0xFFFF5722);
      case 'owner': return const Color(0xFF9C27B0);
      case 'founder': return const Color(0xFFE91E63);
      default: return _glowColor1;
    }
  }

  Widget _buildPaginationControls() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentPage > 1 ? _glowColor1.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: currentPage > 1 ? _glowColor1.withOpacity(0.2) : Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Icon(Icons.chevron_left, color: currentPage > 1 ? _glowColor1 : Colors.white38, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: TextStyle(color: _glowColor1, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: currentPage < totalPages ? () => setState(() => currentPage++) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentPage < totalPages ? _glowColor1.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: currentPage < totalPages ? _glowColor1.withOpacity(0.2) : Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Icon(Icons.chevron_right, color: currentPage < totalPages ? _glowColor1 : Colors.white38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        color: _cardColor,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _glowColor2.withOpacity(0.6), fontSize: 11, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    createUsernameController.clear();
    createPasswordController.clear();
    createDayController.clear();
    newUserRole = 'member';

    showDialog(
      context: context,
      builder: (_) => _buildCreateUserDialog(),
    );
  }

  Widget _buildCreateUserDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(FontAwesomeIcons.userPlus, color: _glowColor1, size: 20),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_glowColor1, _accentColor, _glowColor2],
                    ).createShader(bounds),
                    child: const Text(
                      'CREATE USER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPremiumTextField(controller: createUsernameController, label: 'Username', icon: Icons.person),
              const SizedBox(height: 16),
              _buildPremiumTextField(controller: createPasswordController, label: 'Password', icon: Icons.lock, isPassword: true),
              const SizedBox(height: 16),
              _buildPremiumTextField(controller: createDayController, label: 'Duration (days)', icon: Icons.calendar_today, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                ),
                child: DropdownButtonFormField<String>(
                  value: newUserRole,
                  dropdownColor: _cardColor,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontFamily: 'Rajdhani', fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(color: _glowColor2.withOpacity(0.6), fontSize: 11, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
                    prefixIcon: Icon(Icons.admin_panel_settings, color: _glowColor2.withOpacity(0.5), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: roleOptions.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _createAccount,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: const Text(
                        'CREATE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rajdhani',
                          letterSpacing: 2,
                          fontSize: 12,
                          color: Color(0xFF070709),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteUserDialog() {
    deleteController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _roseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(FontAwesomeIcons.userMinus, color: _roseColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'DELETE USER',
                      style: TextStyle(
                        color: _roseColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPremiumTextField(controller: deleteController, label: 'Username', icon: Icons.person),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteUser(deleteController.text.trim());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _roseColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: _roseColor.withOpacity(0.3), blurRadius: 16),
                          ],
                        ),
                        child: const Text(
                          'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Rajdhani',
                            letterSpacing: 2,
                            fontSize: 12,
                            color: Color(0xFF070709),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _roseColor.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _roseColor),
            const SizedBox(width: 12),
            const Text('Confirm Delete', style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ],
        ),
        content: Text('Delete user "$username" permanently?', style: const TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(username);
            },
            child: Text('Delete', style: TextStyle(color: _roseColor, fontWeight: FontWeight.w800, fontFamily: 'Rajdhani')),
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
            "VANTHRA ADMIN PORTAL • ENCRYPTED",
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 8,
              letterSpacing: 2.5,
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
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _glowColor1,
                      strokeWidth: 3,
                    ),
                  )
                : Column(
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 16),
                      _buildActionCards(),
                      const SizedBox(height: 20),
                      _buildFilterChips(),
                      const SizedBox(height: 20),
                      Expanded(child: _buildUserTable()),
                      _buildFooter(),
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
    _rotateController.dispose();
    _videoController?.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }
}