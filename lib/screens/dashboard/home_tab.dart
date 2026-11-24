import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:applyengine/controllers/mail_controller.dart';
import 'package:applyengine/utils/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<MailController>();

    return Obx(() {
      final total = controller.totalCount.value;
      final sent = controller.sentCount.value;
      final failed = controller.failedCount.value;
      final progress = total > 0 ? (sent + failed) / total : 0.0;
      final percentage = (progress * 100).round();

      return ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
        children: [
          // 1. DYNAMIC GRADIENT CAMPAIGN PROGRESS RING CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF4338CA).withOpacity(0.3) : const Color(0xFFC7D2FE),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.indigo[100]!).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                // Animated Progress Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      "$percentage%",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.indigo[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Status Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${controller.campaignType.value} Outreach".toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.isProcessing.value
                            ? (controller.isPaused.value ? "Outreach Campaign Paused" : "Actively Outreaching...")
                            : "Campaign is Idle",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$sent sent, $failed failed of $total leads",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. AI HUNT QUICK TRIGGER HERO BANNER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Autonomous AI Job Hunter",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                        controller.isHunting.value
                            ? "Hunting live posts..."
                            : "Target: ${controller.huntKeyword.value} (${controller.huntPlatform.value})",
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final isHunting = controller.isHunting.value;
                  return ElevatedButton(
                    onPressed: isHunting ? null : () => controller.runLiveJobHunt(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isHunting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Hunt Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. CAMPAIGN METRICS GRID
          Row(
            children: [
              Expanded(
                child: _buildStateCard(
                  context,
                  title: "Outreach Speed",
                  value: "${controller.emailsPerMinute.value}/min",
                  icon: Icons.speed_rounded,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStateCard(
                  context,
                  title: "Estimated Time",
                  value: controller.estimatedTimeRemaining.value,
                  icon: Icons.hourglass_empty_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. STATS COUNT GRID (2x4 Layout)
          _buildSectionHeader("CAMPAIGN OUTBOX METRICS"),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard("Database Leads", controller.totalCount.value.toString(), Colors.blueGrey, isDark),
              _buildMetricCard("Ready Status", controller.readyCount.value.toString(), AppTheme.statusReady, isDark),
              _buildMetricCard("Outreach Sent", controller.sentCount.value.toString(), AppTheme.statusSent, isDark),
              _buildMetricCard("Failed Delivery", controller.failedCount.value.toString(), AppTheme.statusFailed, isDark),
              _buildMetricCard("Invalid Contacts", controller.invalidCount.value.toString(), AppTheme.statusInvalid, isDark),
              _buildMetricCard("Skipped Rows", controller.skippedCount.value.toString(), AppTheme.statusSkipped, isDark),
              _buildMetricCard("Duplicates", controller.duplicateCount.value.toString(), AppTheme.statusDuplicate, isDark),
            ],
          ),
          const SizedBox(height: 24),

          // 4. CAMPAIGN FLOW CONTROLLERS
          _buildSectionHeader("CAMPAIGN OUTBOX CONTROLLERS"),
          const SizedBox(height: 8),
          _buildCampaignControllers(context, controller, theme),
          const SizedBox(height: 32),
        ],
      );
    });
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

  Widget _buildStateCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignControllers(BuildContext context, MailController controller, ThemeData theme) {
    if (!controller.isProcessing.value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text("Start ${controller.campaignType.value} Campaign"),
            onPressed: controller.leads.isEmpty ? null : () => controller.startSending(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (controller.leads.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Please select and load an Excel database sheet in the side menu first to enable campaigns.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: controller.isPaused.value
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text("Resume"),
                      onPressed: () => controller.resumeSending(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text("Pause"),
                      onPressed: () => controller.pauseSending(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop_rounded),
                label: const Text("Stop"),
                onPressed: () => controller.stopSending(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        // Skip / Mark Failed Actions (For WhatsApp & LinkedIn Campaigns)
        if ((controller.campaignType.value == 'WhatsApp' || controller.campaignType.value == 'LinkedIn') && !controller.isPaused.value) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text("Skip Lead"),
                  onPressed: () {
                    final sendingLead = controller.leads
                        .firstWhereOrNull((l) => l.status == 'SendingText' || l.status == 'SendingPDF' || l.status == 'SendingLinkedIn');
                    if (sendingLead != null) {
                      controller.addLog("Skipped lead: ${sendingLead.recruiter}");
                      final idx = controller.leads.indexOf(sendingLead);
                      controller.leads[idx].status = 'Skipped';
                      controller.leads[idx].reason = 'Skipped by user';
                      if (controller.campaignType.value == 'WhatsApp') {
                        controller.sendWhatsAppNextFromUi();
                      } else {
                        controller.sendLinkedInNextFromUi();
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.error_outline_rounded),
                  label: const Text("Mark Failed"),
                  onPressed: () {
                    final sendingLead = controller.leads
                        .firstWhereOrNull((l) => l.status == 'SendingText' || l.status == 'SendingPDF' || l.status == 'SendingLinkedIn');
                    if (sendingLead != null) {
                      controller.addLog("Marked lead as failed: ${sendingLead.recruiter}");
                      final idx = controller.leads.indexOf(sendingLead);
                      controller.leads[idx].status = 'Failed';
                      controller.leads[idx].reason = 'Marked failed by user';
                      if (controller.campaignType.value == 'WhatsApp') {
                        controller.sendWhatsAppNextFromUi();
                      } else {
                        controller.sendLinkedInNextFromUi();
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),
        // Secondary Actions (Retry, Export)
        if (controller.failedCount.value > 0)
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Retry Failed Only"),
            onPressed: () => controller.retryFailed(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (controller.failedCount.value > 0 || controller.invalidCount.value > 0) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text("Export Invalid & Failed (to edit & re-upload)"),
            onPressed: () => controller.exportInvalidFailed(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[800],
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: Colors.orange[800]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text("Export Report"),
                onPressed: () => controller.exportReport(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: Text(controller.campaignType.value == 'Email'
                    ? "Copy Failed Emails"
                    : controller.campaignType.value == 'WhatsApp'
                        ? "Copy Failed Mobiles"
                        : "Copy Failed LinkedIn Links"),
                onPressed: controller.failedCount.value == 0
                    ? null
                    : () {
                        final list = controller.leads.where((l) => l.status == 'Failed').map((l) {
                          return controller.campaignType.value == 'Email'
                              ? l.email
                              : controller.campaignType.value == 'WhatsApp'
                                  ? l.mobile
                                  : l.linkedinName;
                        }).join(', ');
                        Clipboard.setData(ClipboardData(text: list));
                        Get.snackbar("Copied", "List copied to clipboard.");
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
