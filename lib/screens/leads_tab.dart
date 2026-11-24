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
              // Deduplication badges & AI Hunter Action
              Row(
                children: [
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
                        const SizedBox(width: 8),
                      ],
                    );
                  }),
                  // AI Job Hunter Trigger Button
                  InkWell(
                    onTap: () => _showJobHunterModal(context, isDark),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "AI Job Hunter",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

        // AI Match Filtering & Scoring Action Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Obx(() {
            final isRunning = controller.isMatchingRunning.value;
            final filterActive = controller.filterByMatchScore.value;
            final minScore = controller.minMatchScore.value;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF4338CA).withOpacity(0.3) : const Color(0xFFC7D2FE),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 8),
                          Text(
                            "Filter Match >= $minScore%",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF312E81),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!isRunning)
                            InkWell(
                              onTap: () => controller.scoreAllLeadsWithGemini(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "Score with AI",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: filterActive,
                              activeColor: const Color(0xFF8B5CF6),
                              onChanged: (val) {
                                controller.filterByMatchScore.value = val;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: controller.matchingProgress.value,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        color: const Color(0xFF8B5CF6),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),

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
                            // AI Match Badge or Quick Score Trigger
                            if (lead.matchScore > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lead.matchScore >= 75
                                      ? const Color(0xFF10B981).withOpacity(0.15)
                                      : (lead.matchScore >= 50
                                          ? Colors.amber.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: lead.matchScore >= 75
                                        ? const Color(0xFF10B981)
                                        : (lead.matchScore >= 50 ? Colors.amber : Colors.grey),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 10,
                                      color: lead.matchScore >= 75 ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${lead.matchScore}% Match",
                                      style: TextStyle(
                                        color: lead.matchScore >= 75
                                            ? const Color(0xFF10B981)
                                            : (lead.matchScore >= 50 ? Colors.amber[800] : Colors.grey),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => controller.scoreSingleLead(lead),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.auto_awesome_rounded, size: 9, color: Color(0xFF8B5CF6)),
                                      SizedBox(width: 3),
                                      Text("AI Score", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

                        // AI Match Highlights & Custom Cold Pitch Box (if available)
                        if (lead.matchReasons.isNotEmpty || lead.customPitch.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (lead.matchReasons.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          lead.matchReasons.first,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (lead.missingSkills.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: lead.missingSkills.map((skill) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Gap: $skill",
                                        style: const TextStyle(fontSize: 8, color: Colors.redAccent),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                                if (lead.customPitch.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tailored AI Cold Pitch:",
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lead.customPitch,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

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
                            if (lead.customPitch.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildMiniIconButton(
                                icon: Icons.auto_awesome_rounded,
                                tooltip: "Copy AI Cold Pitch",
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: lead.customPitch));
                                  Get.snackbar("Pitch Copied", "Tailored cold pitch copied to clipboard.");
                                },
                              ),
                            ],
                            if (lead.applyUrl.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildMiniIconButton(
                                icon: Icons.open_in_new_rounded,
                                tooltip: "1-Click Direct Apply",
                                onTap: () async {
                                  final uri = Uri.parse(lead.applyUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
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
                    items: ['Company', 'Recruiter', 'Status', 'Match Score'].map(
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

  void _showJobHunterModal(BuildContext context, bool isDark) {
    final rawTextController = TextEditingController();
    int activeTab = 0; // 0 = Live Hunt, 1 = Raw Feed Paste

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: context.height * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: ListView(
              children: [
                // Modal Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Autonomous Job Hunter",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              "Find live hiring posts without manual Excel sheets",
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mode Tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 0 ? (isDark ? const Color(0xFF6366F1) : Colors.white) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: activeTab == 0 && !isDark
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: const Text("⚡ Live AI Hunt", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 1 ? (isDark ? const Color(0xFF6366F1) : Colors.white) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: activeTab == 1 && !isDark
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: const Text("📋 Paste Feed Dump", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Common Search Fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Target Role / Keyword", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: controller.huntKeyword.value,
                      onChanged: (val) => controller.huntKeyword.value = val,
                      decoration: InputDecoration(
                        hintText: "e.g. Flutter Developer, Mobile Engineer",
                        prefixIcon: const Icon(Icons.work_outline_rounded, size: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Target Location", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: controller.huntLocation.value,
                      onChanged: (val) => controller.huntLocation.value = val,
                      decoration: InputDecoration(
                        hintText: "e.g. India, Bengaluru, Remote",
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Target Platform", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Obx(
                      () => Row(
                        children: ['LinkedIn', 'Naukri', 'Indeed'].map((plat) {
                          final isSel = controller.huntPlatform.value == plat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(plat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : null)),
                              selected: isSel,
                              selectedColor: const Color(0xFF6366F1),
                              onSelected: (_) => controller.huntPlatform.value = plat,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (activeTab == 0) ...[
                  // Live Hunt Info & Trigger
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "How Live Hunt Works:",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• Gemini Pro searches live Google Grounding for fresh LinkedIn hiring announcements.\n"
                          "• Evaluates each recruiter's requirements against your cached resume.\n"
                          "• Pre-calculates 0-100% Match Scores & custom pitches and saves them directly to your leads pipeline.",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final isBusy = controller.isHunting.value;
                    return ElevatedButton.icon(
                      icon: isBusy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(isBusy ? "Hunting Live Posts..." : "Launch Autonomous Hunt"),
                      onPressed: isBusy
                          ? null
                          : () async {
                              await controller.runLiveJobHunt();
                              if (context.mounted && !controller.isHunting.value) {
                                Get.back();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  }),
                ] else ...[
                  // Paste Feed Dump Area
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Paste Copied Posts / Search Text", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: rawTextController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: "Copy text directly from LinkedIn search results, feed, or emails and paste here...",
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final isBusy = controller.isHunting.value;
                        return ElevatedButton.icon(
                          icon: isBusy
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(isBusy ? "Extracting Leads with AI..." : "Extract Leads & Compute Match Scores"),
                          onPressed: isBusy
                              ? null
                              : () async {
                                  await controller.importRawFeedDump(rawTextController.text);
                                  if (context.mounted && !controller.isHunting.value) {
                                    Get.back();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
