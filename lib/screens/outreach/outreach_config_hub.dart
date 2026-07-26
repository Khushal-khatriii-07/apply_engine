import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:applyengine/controllers/mail_controller.dart';
import 'package:applyengine/utils/app_theme.dart';

class OutreachConfigHub extends StatefulWidget {
  const OutreachConfigHub({Key? key}) : super(key: key);

  @override
  State<OutreachConfigHub> createState() => _OutreachConfigHubState();
}

class _OutreachConfigHubState extends State<OutreachConfigHub> {
  final MailController controller = Get.find<MailController>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final activePlatform = controller.campaignType.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. PREMIUM HEADER BANNER
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 16.0),
            child: Text(
              "Outreach Configuration",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // 2. PREMIUM SEGMENTED SWITCHER (SLIDER PILL DESIGN)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                _buildSegmentButton("Email", activePlatform == "Email", isDark, theme),
                _buildSegmentButton("WhatsApp", activePlatform == "WhatsApp", isDark, theme),
                _buildSegmentButton("LinkedIn", activePlatform == "LinkedIn", isDark, theme),
              ],
            ),
          ),

          // 3. DYNAMIC FORM WITH ANIMATED CROSSFADE
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: activePlatform == "Email"
                  ? _buildEmailConfigForm(theme, isDark)
                  : activePlatform == "WhatsApp"
                      ? _buildWhatsappConfigForm(theme, isDark)
                      : _buildLinkedinConfigForm(theme, isDark),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSegmentButton(String platform, bool isActive, bool isDark, ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (controller.isProcessing.value) {
            Get.snackbar(
              "Campaign Running",
              "Cannot switch platform while an active campaign is running.",
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          controller.campaignType.value = platform;
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
                platform == "Email"
                    ? Icons.mail_outline_rounded
                    : platform == "WhatsApp"
                        ? Icons.phone_iphone_rounded
                        : Icons.link_rounded,
                size: 16,
                color: isActive
                    ? (isDark ? Colors.white : theme.colorScheme.primary)
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                platform,
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

  // --- EMAIL CONFIG FORM ---
  Widget _buildEmailConfigForm(ThemeData theme, bool isDark) {
    final borderSide = BorderSide(
      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      width: 1.5,
    );

    return ListView(
      key: const ValueKey("email_form"),
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 0, bottom: 100.0),
      children: [
        // Premium Setup Header Card with Avatar
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email Setup",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure SMTP settings, subject line templates, and verify connections.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.mark_email_read_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
        ),

        // SMTP Credentials Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "SMTP Configuration", Icons.security_rounded),
                const SizedBox(height: 18),
                _buildCustomTextField(
                  label: "Gmail Address",
                  hint: "j.doe@gmail.com",
                  icon: Icons.alternate_email_rounded,
                  initialValue: controller.senderEmail.value,
                  onChanged: (val) => controller.senderEmail.value = val,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                _buildCustomTextField(
                  label: "Sender Display Name",
                  hint: "e.g. John Doe",
                  icon: Icons.person_outline_rounded,
                  initialValue: controller.senderName.value,
                  onChanged: (val) => controller.senderName.value = val,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                // Obscure App Password Input Field with trailing Show/Hide trigger
                _buildAppPasswordTextField(isDark, theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Template Setup Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "SMTP Settings", Icons.article_rounded),
                const SizedBox(height: 18),
                _buildCustomTextField(
                  label: "Subject Template",
                  hint: "Applying for {Role} role",
                  icon: Icons.subject_rounded,
                  initialValue: controller.subject.value,
                  onChanged: (val) => controller.subject.value = val,
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shared Campaign Parameters
        _buildSharedOutreachParameters(theme, isDark),
        const SizedBox(height: 24),

        // Save and Discard Actions side-by-side
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                  label: const Text("Verify SMTP", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    if (controller.isTestingEmail.value || controller.isProcessing.value) return;
                    controller.sendTestEmail();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF34D399), const Color(0xFF059669)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text("Send 2 Tests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    if (controller.isTestingEmail.value ||
                        controller.isProcessing.value ||
                        controller.leads.isEmpty) return;
                    controller.sendTwoTestEmailsToSelf();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- WHATSAPP CONFIG FORM ---
  Widget _buildWhatsappConfigForm(ThemeData theme, bool isDark) {
    final borderSide = BorderSide(
      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      width: 1.5,
    );

    return ListView(
      key: const ValueKey("whatsapp_form"),
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 0, bottom: 100.0),
      children: [
        // Premium Setup Header Card with Avatar
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WhatsApp Setup",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure accessibility permissions, message body templates, and dispatch test messages.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.phone_iphone_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
        ),

        // Accessibility Automator Service Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Accessibility Service", Icons.settings_accessibility_rounded),
                const SizedBox(height: 12),
                const Text(
                  "Required to auto-click the Send button in WhatsApp and return to dispatcher.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: controller.isAccessibilityActive.value
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isAccessibilityActive.value ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: controller.isAccessibilityActive.value ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isAccessibilityActive.value ? "Status: AUTOMATOR ACTIVE" : "Status: AUTOMATOR DISABLED",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: controller.isAccessibilityActive.value ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.openAccessibilitySettings,
                  icon: const Icon(Icons.settings_accessibility_rounded, size: 16),
                  label: const Text("Configure Accessibility Settings"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Message template
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Message Template", Icons.chat_bubble_outline_rounded),
                const SizedBox(height: 10),
                const Text(
                  "Tags supported: {Recruiter}, {Company}, {Role}.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildCustomTextField(
                  label: "Message Body Template",
                  hint: "Hi {Recruiter}, noticed post for {Role} at {Company}...",
                  icon: Icons.edit_note_rounded,
                  maxLines: 4,
                  initialValue: controller.whatsappBody.value,
                  onChanged: (val) => controller.whatsappBody.value = val,
                  isDark: isDark,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shared Campaign Parameters
        _buildSharedOutreachParameters(theme, isDark),
        const SizedBox(height: 16),

        // WhatsApp test dispatcher
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Test Connection", Icons.send_rounded),
                const SizedBox(height: 16),
                _buildCustomTextField(
                  label: "Test Mobile Number (with country code)",
                  hint: "e.g., 918160047106",
                  icon: Icons.phone_iphone_rounded,
                  initialValue: controller.testMobile.value,
                  onChanged: (val) => controller.testMobile.value = val,
                  isDark: isDark,
                  theme: theme,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                          : [const Color(0xFF818CF8), const Color(0xFF4F46E5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: const Text("Dispatch Test Message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => controller.sendTestWhatsApp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCardHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    required String initialValue,
    required Function(String) onChanged,
    required bool isDark,
    required ThemeData theme,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: initialValue,
          selection: TextSelection.collapsed(offset: initialValue.length),
        ),
      ),
      enabled: !controller.isProcessing.value,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAppPasswordTextField(bool isDark, ThemeData theme) {
    return TextField(
      onChanged: (val) => controller.appPassword.value = val,
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: controller.appPassword.value,
          selection: TextSelection.collapsed(offset: controller.appPassword.value.length),
        ),
      ),
      enabled: !controller.isProcessing.value,
      obscureText: _obscurePassword,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: "App Password",
        hintText: "••••••••••••••••",
        prefixIcon: const Icon(Icons.vpn_key_outlined),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Text(
              _obscurePassword ? "Show" : "Hide",
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // --- SHARED DISPATCH PARAMETERS ---
  Widget _buildSharedOutreachParameters(ThemeData theme, bool isDark) {
    final borderSide = BorderSide(
      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      width: 1.5,
    );
    final isEmail = controller.campaignType.value == "Email";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: borderSide,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(theme, "Campaign Parameters", Icons.tune_rounded),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sending Delay", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  "${controller.delay.value.toStringAsFixed(1)} seconds",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            Slider(
              value: controller.delay.value,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              activeColor: theme.colorScheme.primary,
              onChanged: controller.isProcessing.value ? null : (val) => controller.delay.value = val,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEmail) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Workers (Threads)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: controller.threads.value,
                              isExpanded: true,
                              items: [1, 2, 3, 5].map((t) {
                                return DropdownMenuItem<int>(
                                  value: t,
                                  child: Text("$t Workers", style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: controller.isProcessing.value
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.threads.value = val;
                                      }
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmail
                            ? "Maximum Emails"
                            : controller.campaignType.value == "WhatsApp"
                                ? "Maximum Chat Messages"
                                : "Maximum Connection Requests",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        enabled: !controller.isProcessing.value,
                        onChanged: (val) => controller.maxEmails.value = int.tryParse(val) ?? 1000,
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: controller.maxEmails.value.toString(),
                            selection: TextSelection.collapsed(offset: controller.maxEmails.value.toString().length),
                          ),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedinConfigForm(ThemeData theme, bool isDark) {
    final borderSide = BorderSide(
      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      width: 1.5,
    );

    return ListView(
      key: const ValueKey("linkedin_form"),
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 0, bottom: 100.0),
      children: [
        // Setup Header Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LinkedIn Setup",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Configure accessibility permissions, note templates, and verify connections.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.link_rounded, color: theme.colorScheme.primary, size: 20),
              ),
            ],
          ),
        ),

        // Accessibility Service Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Accessibility Service", Icons.settings_accessibility_rounded),
                const SizedBox(height: 12),
                const Text(
                  "Required to auto-click menu items, type personalize note, and return to dispatcher.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: controller.isAccessibilityActive.value
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isAccessibilityActive.value ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: controller.isAccessibilityActive.value ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isAccessibilityActive.value ? "Status: AUTOMATOR ACTIVE" : "Status: AUTOMATOR DISABLED",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: controller.isAccessibilityActive.value ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.openAccessibilitySettings,
                  icon: const Icon(Icons.settings_accessibility_rounded, size: 16),
                  label: const Text("Configure Accessibility Settings"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Message Template
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Invite Template", Icons.chat_bubble_outline_rounded),
                const SizedBox(height: 10),
                const Text(
                  "Tags supported: {Recruiter}, {Company}, {Role}. Note is capped at 300 characters.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildCustomTextField(
                  label: "Message Body Template (Max 300 chars)",
                  hint: "Hi {Recruiter}, noticed post for {Role} at {Company}...",
                  icon: Icons.edit_note_rounded,
                  maxLines: 4,
                  initialValue: controller.linkedinBody.value,
                  onChanged: (val) {
                    controller.linkedinBody.value = val;
                  },
                  isDark: isDark,
                  theme: theme,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Obx(() {
                    final len = controller.linkedinBody.value.length;
                    final isOverLimit = len > 300;
                    return Text(
                      "Length: $len/300 characters${isOverLimit ? ' (Message will be truncated to 300 characters)' : ''}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverLimit ? Colors.red : Colors.grey,
                        fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shared Campaign Parameters
        _buildSharedOutreachParameters(theme, isDark),
        const SizedBox(height: 16),

        // Test connection card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderSide,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(theme, "Test Connection", Icons.send_rounded),
                const SizedBox(height: 16),
                _buildCustomTextField(
                  label: "Test LinkedIn Profile URL",
                  hint: "e.g., https://www.linkedin.com/in/username/",
                  icon: Icons.link_rounded,
                  initialValue: controller.testLinkedinProfile.value,
                  onChanged: (val) => controller.testLinkedinProfile.value = val,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                          : [const Color(0xFF818CF8), const Color(0xFF4F46E5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: const Text("Dispatch Test Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => controller.sendTestLinkedIn(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
