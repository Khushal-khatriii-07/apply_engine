import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:applyengine/controllers/mail_controller.dart';
import 'package:applyengine/utils/app_theme.dart';

class LeadsTab extends StatefulWidget {
  const LeadsTab({Key? key}) : super(key: key);

  @override
  State<LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<LeadsTab> {
  late final TextEditingController _searchController;
  late final MailController controller;

  // Selected filter chip option
  final List<String> _filterCategories = ['All Leads', 'Sent', 'Ready', 'Failed', 'Skipped', 'Invalid'];

  @override
  void initState() {
    super.initState();
    controller = Get.find<MailController>();
    _searchController = TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _mapChipToFilter(String chip) {
    if (chip == 'All Leads') return 'All';
    return chip;
  }

  String _mapFilterToChip(String filter) {
    if (filter == 'All') return 'All Leads';
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Title banner showing loaded sheets
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                final hasExcel = controller.excelPath.value.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasExcel ? "DATABASE ARCHIVE" : "NO ACTIVE SPREADSHEET",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasExcel
                          ? "${controller.leads.length} leads loaded"
                          : "Load database from side drawer",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasExcel ? theme.colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ],
                );
              }),
              // Deduplication badges
              Obx(() {
                if (controller.leads.isEmpty) return const SizedBox.shrink();
                return Row(
                  children: [
                    if (controller.removeDuplicates.value)
                      _buildMiniBadge("DUP-EMAIL", Colors.orange, isDark),
                    if (controller.detectDuplicateRecruiter.value) ...[
                      const SizedBox(width: 6),
                      _buildMiniBadge("DUP-REC", Colors.teal, isDark),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),

        // Search Bar with filters icon (Premium Outline Border)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => controller.searchQuery.value = val,
                  decoration: InputDecoration(
                    hintText: "Search name, company, email...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.searchQuery.value = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter options button (Premium Outline Border)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _showSortingDialog(context, isDark),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category Filter Chips row (Premium Mockup)
        SizedBox(
          height: 48,
          child: Obx(() {
            final activeFilter = controller.statusFilter.value;
            final activeChip = _mapFilterToChip(activeFilter);

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: _filterCategories.length,
              itemBuilder: (context, index) {
                final chip = _filterCategories[index];
                final isSelected = activeChip.toLowerCase() == chip.toLowerCase();

                return Padding(
                  key: ValueKey(chip),
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      controller.statusFilter.value = _mapChipToFilter(chip);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Deduplication & Mobile Filter Toggle row (Premium Mockup Feature)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: controller.onlyWithMobile.value ? theme.colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Show Only leads with Mobile Numbers",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: controller.onlyWithMobile.value ? theme.colorScheme.primary : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: controller.onlyWithMobile.value,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      controller.onlyWithMobile.value = val;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ListView Contact Grid Cards (Premium Mockup)
        Expanded(
          child: Obx(() {
            final list = controller.filteredLeads;
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty_rounded, size: 40, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      "No database leads found.",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 100),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final lead = list[index];
                final statusCol = AppTheme.getStatusColor(lead.status);
                final initialLetter = lead.recruiter.isNotEmpty ? lead.recruiter[0].toUpperCase() : 'R';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row: Profile Avatar + Name + Status tag
                        Row(
                          children: [
                            // Recruiter Avatar Circle
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                initialLetter,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Recruiter details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.recruiter.isNotEmpty ? lead.recruiter : "(Unnamed Recruiter)",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (lead.role.isNotEmpty)
                                    Text(
                                      lead.role,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Capsule Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusCol.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusCol.withOpacity(0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    lead.status,
                                    style: TextStyle(color: statusCol, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Two-Column Grid Info Panel
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Company & Role details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.business_rounded, "Company", lead.company),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column: Contact details (Email, Phone)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.mail_outline_rounded, "Email", lead.email),
                                  const SizedBox(height: 6),
                                  _buildInfoRow(Icons.phone_iphone_rounded, "Phone", lead.mobile),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bottom Actions Row (Mini visual outlines triggers)
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (lead.email.isNotEmpty)
                              _buildMiniIconButton(
                                icon: Icons.copy_rounded,
                                tooltip: "Copy Email",
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: lead.email));
                                  Get.snackbar("Copied", "Email copied to clipboard.");
                                },
                              ),
                            if (lead.mobile.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildMiniIconButton(
                                icon: Icons.copy_rounded,
                                tooltip: "Copy Mobile",
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: lead.mobile));
                                  Get.snackbar("Copied", "Mobile copied to clipboard.");
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildMiniIconButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                tooltip: "Open WhatsApp",
                                onTap: () async {
                                  String phone = lead.mobile.replaceAll(RegExp(r'\D'), '');
                                  if (!phone.startsWith('+') && phone.length <= 10) {
                                    phone = "91$phone";
                                  }
                                  final uri = Uri.parse("https://wa.me/$phone");
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),

                        // Error block
                        if (lead.reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.1)),
                            ),
                            child: Text(
                              lead.reason,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    final value = val.isNotEmpty ? val : 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniIconButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    final isDark = Get.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSortingDialog(BuildContext context, bool isDark) {
    Get.defaultDialog(
      title: "Sort Leads Database",
      titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        children: [
          Row(
            children: [
              const Text("Sort Column: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButton<String>(
                    value: controller.sortColumn.value,
                    isExpanded: true,
                    items: ['Company', 'Recruiter', 'Status'].map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 12)),
                      ),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.sortColumn.value = val;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SwitchListTile(
              title: const Text("Sort Ascending", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              value: controller.sortAscending.value,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => controller.sortAscending.value = val,
            ),
          ),
        ],
      ),
      textConfirm: "Apply",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }
}
