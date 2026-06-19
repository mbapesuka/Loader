import 'package:flutter/material.dart';
import 'dart:ui';

class LaranganPenggunaPage extends StatelessWidget {
  const LaranganPenggunaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "LARANGAN & SANKSI",
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
          onPressed: () {
            // Kembali ke halaman sebelumnya dengan aman
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback: jika tidak bisa pop, tutup halaman
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0000),
                Colors.black,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0000),
              Colors.black,
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD32F2F), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Peraturan Wajib bagi Seluruh Pengguna",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Rajdhani",
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle("🚫 LARANGAN", Icons.gpp_maybe),
                const SizedBox(height: 12),
                _buildRuleCard(
                  number: "01",
                  title: "MEMBAJAK AKUN ORANG LAIN",
                  description: "Dilarang melakukan pembajakan akun WhatsApp, Telegram, atau media sosial lainnya milik pengguna lain.",
                  icon: Icons.handshake,
                ),
                _buildRuleCard(
                  number: "02",
                  title: "PENYALAHGUNAAN TOOLS SPAM",
                  description: "Spam berlebihan yang mengganggu ketenangan publik (virtex, bomb text, dll) tanpa izin.",
                  icon: Icons.warning,
                ),
                _buildRuleCard(
                  number: "03",
                  title: "MEMPERJUALBELIKAN SCRIPT",
                  description: "Dilarang menjual kembali script/bot yang didapat dari grup ini tanpa izin reseller.",
                  icon: Icons.sell,
                ),
                _buildRuleCard(
                  number: "04",
                  title: "MENYEBABKAN KERUSAKAN SERVER",
                  description: "Melakukan serangan DDOS atau aktivitas yang merusak infrastruktur server bersama.",
                  icon: Icons.device_hub,
                ),
                _buildRuleCard(
                  number: "05",
                  title: "MENYEBAR KONTEN ILEGAL",
                  description: "Menyebarkan materi pornografi, SARA, ujaran kebencian, atau konten terlarang lainnya.",
                  icon: Icons.content_paste,
                ),
                _buildRuleCard(
                  number: "06",
                  title: "DOXING & PELANGGARAN PRIVASI",
                  description: "Menyebarkan data pribadi (doxing) atau melakukan intimidasi/threatening.",
                  icon: Icons.privacy_tip,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle("⚖️ SANKSI", Icons.gavel),
                const SizedBox(height: 12),
                _buildSanctionCard(
                  level: "RINGAN",
                  color: Color(0xFFFFB300),
                  punishment: "Peringatan tertulis + Nonaktif fitur tertentu selama 3 hari.",
                ),
                _buildSanctionCard(
                  level: "SEDANG",
                  color: Color(0xFFFF6D00),
                  punishment: "Banned sementara (7-30 hari) + semua sesi direset.",
                ),
                _buildSanctionCard(
                  level: "BERAT",
                  color: Color(0xFFD32F2F),
                  punishment: "Banned permanen + blacklist device + laporan ke otoritas jika perlu.",
                ),
                _buildSanctionCard(
                  level: "PALING BERAT",
                  color: Color(0xFFB71C1C),
                  punishment: "Hapus akun permanen, ban IP, dan tidak bisa register ulang.",
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.security, color: Colors.white54, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        "Segala pelanggaran dicatat dalam log sistem.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: "Rajdhani",
                        ),
                      ),
                      Text(
                        "Keputusan admin bersifat mutlak.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: "Rajdhani",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: "Rajdhani",
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          color: const Color(0xFFD32F2F).withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildRuleCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B0000).withOpacity(0.1),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD32F2F).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: "Rajdhani",
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFFFF5252), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Rajdhani",
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: "Rajdhani",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionCard({
    required String level,
    required Color color,
    required String punishment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Rajdhani",
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  punishment,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: "Rajdhani",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}