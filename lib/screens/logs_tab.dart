import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:applyengine/controllers/mail_controller.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({Key? key}) : super(key: key);

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  late final ScrollController _logScrollController;
  late final MailController controller;
  dynamic _logsListener;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MailController>();
    _logScrollController = ScrollController();

    // Auto-scroll logs to bottom when updated
    _logsListener = controller.logs.listen((_) {
      if (_logScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    _logsListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Real-time SMTP operations logs.",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 12),
                    label: const Text("Copy", style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: controller.logs.join('\n')),
                      );
                      Get.snackbar(
                        "Logs Copied",
                        "Logs successfully copied to clipboard.",
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 12),
                    label: const Text("Clear", style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.logs.clear(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Obx(() {
                if (controller.logs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No console logs recorded.",
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _logScrollController,
                  itemCount: controller.logs.length,
                  itemBuilder: (context, index) {
                    final log = controller.logs[index];
                    final isErr =
                        log.toLowerCase().contains("failed") ||
                        log.toLowerCase().contains("error");
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: isErr
                              ? Colors.redAccent
                              : const Color(0xFFA7F3D0),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
