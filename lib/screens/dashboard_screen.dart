import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:applyengine/controllers/mail_controller.dart';
import 'package:applyengine/utils/app_theme.dart';
import 'package:applyengine/screens/dashboard/home_tab.dart';
import 'package:applyengine/screens/outreach/outreach_config_hub.dart';
import 'package:applyengine/screens/leads_tab.dart';
import 'package:applyengine/screens/outreach_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MailController controller = Get.put(MailController());
  late PageController _pageController;
  int _currentIndex = 0;
  final _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleTheme(bool isDark) {
    Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
    _storage.write('isDarkMode', !isDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "ApplyEngine",
              style: appTextStyle(
                fallback: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                googleFontBuilder: () => GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          // Persisted Theme Toggle
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
              ),
            ),
            onPressed: () => _toggleTheme(isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildSideDrawer(context, theme, isDark),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(), // Switch only via bottom nav
        children: const [
          HomeTab(),
          OutreachConfigHub(),
          LeadsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent, // Real transparency to see the background content scroll underneath
        child: SafeArea(
          child: WavyFluidNavBar(
            currentIndex: _currentIndex,
            theme: theme,
            isDark: isDark,
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
            },
          ),
        ),
      ),
    );
  }

  // --- PREMIUM LEFT DRAWER (SIDEBAR) ---
  Widget _buildSideDrawer(BuildContext context, ThemeData theme, bool isDark) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (ApplyEngine with v1.4.2 matching premium mockup)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ApplyEngine",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "v1.4.2",
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Drawer Items Scrollable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // SECTION 1: NAVIGATION MENU (Outline design)
                  _buildSectionHeader("NAVIGATION MENU"),
                  const SizedBox(height: 6),
                  _buildDrawerNavItem(
                    title: "Dashboard",
                    icon: Icons.dashboard_outlined,
                    isActive: _currentIndex == 0,
                    onTap: () {
                      Get.back();
                      _pageController.jumpToPage(0);
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildDrawerNavItem(
                    title: "Outreach Config",
                    icon: Icons.rocket_launch_outlined,
                    isActive: _currentIndex == 1,
                    onTap: () {
                      Get.back();
                      _pageController.jumpToPage(1);
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildDrawerNavItem(
                    title: "Leads Database",
                    icon: Icons.storage_rounded,
                    isActive: _currentIndex == 2,
                    onTap: () {
                      Get.back();
                      _pageController.jumpToPage(2);
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildDrawerNavItem(
                    title: "Outreach History",
                    icon: Icons.history_rounded,
                    isActive: false,
                    onTap: () {
                      Get.back();
                      Get.to(() => const OutreachHistoryScreen());
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildDrawerNavItem(
                    title: "System Logs",
                    icon: Icons.terminal_rounded,
                    isActive: false,
                    onTap: () {
                      Get.back();
                      _showLogsBottomSheet(context, isDark);
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2: DATABASE FILES
                  _buildSectionHeader("SHARED WORKSPACE FILES"),
                  const SizedBox(height: 6),
                  Obx(
                    () => _buildFilePickerBox(
                      title: "Excel Database (.xlsx)",
                      filePath: controller.excelPath.value,
                      icon: Icons.table_chart_rounded,
                      color: Colors.green,
                      onPick: controller.isProcessing.value ? null : controller.selectExcel,
                      onClear: controller.isProcessing.value ? null : controller.clearExcel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => _buildFilePickerBox(
                      title: "Resume PDF (.pdf)",
                      filePath: controller.resumePath.value,
                      icon: Icons.picture_as_pdf_rounded,
                      color: Colors.red,
                      onPick: controller.isProcessing.value ? null : controller.selectResume,
                      onClear: controller.isProcessing.value ? null : () => controller.resumePath.value = '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SECTION 3: SUPPORT PLACEHOLDERS
                  _buildSectionHeader("SUPPORT"),
                  const SizedBox(height: 6),
                  _buildDrawerNavItem(
                    title: "Settings",
                    icon: Icons.settings_outlined,
                    isActive: false,
                    onTap: () {
                      Get.back();
                      Get.snackbar("Workspace Settings", "Core parameters are shared automatically in hubs.");
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildDrawerNavItem(
                    title: "Help & Support",
                    icon: Icons.help_outline_rounded,
                    isActive: false,
                    onTap: () {
                      Get.back();
                      Get.snackbar("Help & Support", "Consult system manuals for email dispatcher limits.");
                    },
                    isDark: isDark,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerNavItem({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.primary.withOpacity(0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 18,
          color: isActive ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }

  void _showLogsBottomSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Container(
        height: context.height * 0.75,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "System Console Output",
                  style: GoogleFonts.firaCode(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () => controller.logs.clear(),
                      tooltip: "Clear Logs",
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.logs.isEmpty) {
                  return Center(
                    child: Text(
                      "No console logs loaded.",
                      style: GoogleFonts.firaCode(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: controller.logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        controller.logs[index],
                        style: GoogleFonts.firaCode(fontSize: 11, color: isDark ? Colors.greenAccent : Colors.black87),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFilePickerBox({
    required String title,
    required String filePath,
    required IconData icon,
    required Color color,
    required VoidCallback? onPick,
    required VoidCallback? onClear,
  }) {
    final hasFile = filePath.isNotEmpty;
    final isDark = Get.isDarkMode;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? color.withOpacity(0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? p.basename(filePath) : "No file selected",
                    style: TextStyle(
                      fontSize: 10,
                      color: hasFile ? Get.theme.colorScheme.onSurface : Colors.grey,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile && onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

// --- WHATSAPP OPTION B: WAVY FLUID NAV BAR WIDGET ---
class WavyFluidNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final ThemeData theme;
  final bool isDark;

  const WavyFluidNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.theme,
    required this.isDark,
  }) : super(key: key);

  @override
  State<WavyFluidNavBar> createState() => _WavyFluidNavBarState();
}

class _WavyFluidNavBarState extends State<WavyFluidNavBar> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tabWidth = width / 3;

    // Determine target center X position of active tab index
    final double targetX = (widget.currentIndex * tabWidth) + (tabWidth / 2);

    final dockBgColor = widget.isDark ? const Color(0xFF131926) : Colors.white; // Midnight blue vs clean white
    final strokeColor = widget.isDark
        ? const Color(0xFF4338CA).withOpacity(0.5) // Glowing indigo stroke
        : const Color(0xFFCBD5E1); // Clean slate stroke

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: targetX, end: targetX),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      builder: (context, activeX, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Custom Wavy Clipped Background Container
            ClipPath(
              clipper: WavyDockClipper(activeX: activeX),
              child: Container(
                height: 60,
                color: dockBgColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavIcon(0, Icons.dashboard_outlined, "Home"),
                    _buildNavIcon(1, Icons.rocket_launch_outlined, "Outreach"),
                    _buildNavIcon(2, Icons.storage_rounded, "Leads"),
                  ],
                ),
              ),
            ),

            // Paint a premium top stroke/border following the wavy path curve
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 60,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: WavyDockBorderPainter(activeX: activeX, color: strokeColor),
                ),
              ),
            ),

            // Animated Floating Gradient Active Circle (Precise Curve Alignment)
            Positioned(
              left: activeX - 24, // Center of tab - half bubble width (48/2)
              top: -12,           // Floats perfectly inside the 20px dip curve
              child: GestureDetector(
                onTap: () => widget.onTap(widget.currentIndex),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isDark
                          ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                          : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getActiveIcon(widget.currentIndex),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getActiveIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_rounded;
      case 1:
        return Icons.rocket_launch_rounded;
      case 2:
        return Icons.storage_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  Widget _buildNavIcon(int index, IconData icon, String title) {
    final isActive = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 0.0 : 1.0,
                child: Icon(
                  icon,
                  color: Colors.grey[500],
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isActive ? widget.theme.colorScheme.primary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WAVY DOCK CLIPPER ---
class WavyDockClipper extends CustomClipper<Path> {
  final double activeX;

  WavyDockClipper({required this.activeX});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);

    final dipWidth = 85.0;
    final dipHeight = 20.0;

    final leftX = activeX - (dipWidth / 2);
    final rightX = activeX + (dipWidth / 2);

    path.lineTo(leftX, 0);

    // Smooth cubic bezier curves for fluid transition matching
    path.cubicTo(
      activeX - (dipWidth / 3.0), 0,
      activeX - (dipWidth / 3.0), dipHeight,
      activeX, dipHeight,
    );

    path.cubicTo(
      activeX + (dipWidth / 3.0), dipHeight,
      activeX + (dipWidth / 3.0), 0,
      rightX, 0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WavyDockClipper oldClipper) => oldClipper.activeX != activeX;
}

// --- WAVY DOCK BORDER PAINTER ---
class WavyDockBorderPainter extends CustomPainter {
  final double activeX;
  final Color color;

  WavyDockBorderPainter({required this.activeX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, 0);

    final dipWidth = 85.0;
    final dipHeight = 20.0;

    final leftX = activeX - (dipWidth / 2);
    final rightX = activeX + (dipWidth / 2);

    path.lineTo(leftX, 0);

    path.cubicTo(
      activeX - (dipWidth / 3.0), 0,
      activeX - (dipWidth / 3.0), dipHeight,
      activeX, dipHeight,
    );

    path.cubicTo(
      activeX + (dipWidth / 3.0), dipHeight,
      activeX + (dipWidth / 3.0), 0,
      rightX, 0,
    );

    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavyDockBorderPainter oldDelegate) =>
      oldDelegate.activeX != activeX || oldDelegate.color != color;
}
