import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:applyengine/controllers/mail_controller.dart';

class OutreachHistoryScreen extends StatefulWidget {
  const OutreachHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OutreachHistoryScreen> createState() => _OutreachHistoryScreenState();
}

class _OutreachHistoryScreenState extends State<OutreachHistoryScreen> {
  final MailController controller = Get.find<MailController>();
  String _activeTab = "Email";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Outreach History",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            tooltip: "Wipe History",
            onPressed: () => _confirmWipeHistory(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final emailList = controller.campaignHistory;
        final whatsappList = controller.whatsappHistory;
        final linkedinList = controller.linkedinHistory;
        final activeHistory = _activeTab == "Email"
            ? emailList
            : _activeTab == "WhatsApp"
                ? whatsappList
                : linkedinList;

        return Column(
          children: [
            // Tab Selection Switcher (Email vs WhatsApp vs LinkedIn)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton("Email", _activeTab == "Email", isDark, theme),
                  _buildTabButton("WhatsApp", _activeTab == "WhatsApp", isDark, theme),
                  _buildTabButton("LinkedIn", _activeTab == "LinkedIn", isDark, theme),
                ],
              ),
            ),

            // Main List timeline or Empty placeholder
            Expanded(
              child: activeHistory.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildTimelineFeed(activeHistory, _activeTab, isDark, theme),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton(String label, bool isActive, bool isDark, ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? theme.colorScheme.primary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive && !isDark
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == "Email"
                    ? Icons.mail_outline_rounded
                    : label == "WhatsApp"
                        ? Icons.phone_iphone_rounded
                        : Icons.link_rounded,
                size: 16,
                color: isActive
                    ? (isDark ? Colors.white : theme.colorScheme.primary)
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                "$label Outreach",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isActive
                      ? (isDark ? Colors.white : theme.colorScheme.primary)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            "No outreach history recorded",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            "Start outreach campaigns to view logs date-wise here.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineFeed(List<Map<String, dynamic>> records, String activeTab, bool isDark, ThemeData theme) {
    // Group records by Date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var r in records) {
      final String date = r['date'] ?? 'Unknown Date';
      grouped.putIfAbsent(date, () => []).add(r);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // Newest first

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final list = grouped[date] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header label (timeline bullet group)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatHeaderDate(date),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Timeline line container holds cards
            Padding(
              padding: const EdgeInsets.only(left: 3.5),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: list.map((record) {
                    final recruiter = record['recruiter'] ?? 'N/A';
                    final company = record['company'] ?? 'N/A';
                    final timestamp = record['timestamp'] ?? '';
                    final timeOnly = timestamp.isNotEmpty && timestamp.length >= 19
                        ? timestamp.substring(11, 16)
                        : '';
                    final initialLetter = recruiter.isNotEmpty ? recruiter[0].toUpperCase() : 'R';
                    final detail = activeTab == "Email"
                        ? (record['email'] ?? 'N/A')
                        : activeTab == "WhatsApp"
                            ? (record['mobile'] ?? 'N/A')
                            : (record['linkedin_link'] ?? 'N/A');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Details: Role & Target parameters
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.business_rounded, size: 13, color: Colors.grey[500]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          company,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        activeTab == "Email"
                                            ? Icons.alternate_email_rounded
                                            : activeTab == "WhatsApp"
                                                ? Icons.phone_iphone_rounded
                                                : Icons.link_rounded,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          detail,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right Details: Avatar, Time and Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        initialLetter,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      recruiter,
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (timeOnly.isNotEmpty) ...[
                                      Text(
                                        timeOnly,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Status Sent
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Sent",
                                            style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatHeaderDate(String rawDate) {
    try {
      final todayStr = DateTime.now().toLocal().toString().split(' ')[0];
      if (rawDate == todayStr) {
        return "Today, $rawDate";
      }
      final yesterday = DateTime.now().toLocal().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toString().split(' ')[0];
      if (rawDate == yesterdayStr) {
        return "Yesterday, $rawDate";
      }
    } catch (_) {}
    return rawDate;
  }

  void _confirmWipeHistory() {
    final title = _activeTab == "Email"
        ? "Clear Email History?"
        : _activeTab == "WhatsApp"
            ? "Clear WhatsApp History?"
            : "Clear LinkedIn History?";
    Get.defaultDialog(
      title: title,
      titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
      middleText: "This action cannot be undone. Wipe all sent records?",
      textConfirm: "Clear",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (_activeTab == "Email") {
          controller.clearEmailHistory();
        } else if (_activeTab == "WhatsApp") {
          controller.clearWhatsappHistory();
        } else {
          controller.clearLinkedinHistory();
        }
        Get.back();
      },
    );
  }
}
