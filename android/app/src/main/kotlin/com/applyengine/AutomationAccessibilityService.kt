package com.applyengine

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log
import android.content.Intent
import android.os.Bundle

class AutomationAccessibilityService : AccessibilityService() {

    companion object {
        var isAutoSendActive = false
        var campaignType = "WhatsApp" // "WhatsApp" or "LinkedIn"
        var linkedinMessage = ""
        var lastSentSuccess = false       // true = invite sent; false = skipped/timed-out
        var profileOpenTime = 0L          // epoch ms when profile was opened
        const val PROFILE_TIMEOUT_MS = 15_000L  // 15 seconds idle = give up
        var bottomSheetOpened = false     // true after three-dots clicked, waiting for sheet
        var textFilledTime = 0L           // epoch ms when message text was set into EditText
        const val SEND_BUTTON_TIMEOUT_MS = 8_000L  // 8 seconds to find Send button before bailing
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isAutoSendActive) return
        
        val rootNode = rootInActiveWindow
        if (rootNode == null) {
            Log.d("AutomationAccess", "rootInActiveWindow is null, skipping event")
            return
        }
        
        val packageName = rootNode.packageName?.toString() ?: return
        
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED || 
            event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            
            if (packageName == "com.whatsapp" && campaignType == "WhatsApp") {
                handleWhatsAppAutomation(rootNode)
            } else if (packageName == "com.linkedin.android" && campaignType == "LinkedIn") {
                handleLinkedInAutomation(rootNode)
            }
        }
    }

    // --- WHATSAPP AUTOMATION SEQUENCE ---
    private fun handleWhatsAppAutomation(rootNode: AccessibilityNodeInfo) {
        // 1. Find the send button by common ID
        val sendButtons = rootNode.findAccessibilityNodeInfosByViewId("com.whatsapp:id/send")
        if (sendButtons != null && sendButtons.isNotEmpty()) {
            val sendButton = sendButtons[0]
            Log.d("AutomationAccess", "WhatsApp: Found send button by ID: isEnabled=${sendButton.isEnabled}")
            if (sendButton.isEnabled) {
                sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("AutomationAccess", "WhatsApp: Auto-clicked Send Button via ID!")
                Thread.sleep(1000)
                performReturnToApp()
                return
            }
        }

        // Fallback: search recursively by content description or text "Send"
        val clicked = searchAndClickWhatsAppSend(rootNode)
        Log.d("AutomationAccess", "WhatsApp: Recursive search clicked send button: $clicked")
    }

    private fun searchAndClickWhatsAppSend(node: AccessibilityNodeInfo?): Boolean {
        if (node == null) return false
        
        val contentDesc = node.contentDescription
        val text = node.text
        val isSendButton = (contentDesc != null && contentDesc.toString().equals("Send", ignoreCase = true)) ||
                           (text != null && text.toString().equals("Send", ignoreCase = true))

        if (isSendButton) {
            Log.d("AutomationAccess", "WhatsApp: Target node matches Send! contentDesc=$contentDesc, text=$text")
            var targetNode = node
            while (targetNode != null) {
                if (targetNode.isClickable) {
                    targetNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    Log.d("AutomationAccess", "WhatsApp: Auto-clicked Send Button Layout!")
                    Thread.sleep(1000)
                    performReturnToApp()
                    return true
                }
                targetNode = targetNode.parent
            }
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            Log.d("AutomationAccess", "WhatsApp: Auto-clicked Send Button Node directly!")
            Thread.sleep(1000)
            performReturnToApp()
            return true
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (searchAndClickWhatsAppSend(child)) {
                return true
            }
        }
        return false
    }

    // --- LINKEDIN AUTOMATION SEQUENCE ---
    private fun handleLinkedInAutomation(rootNode: AccessibilityNodeInfo) {
        Log.d("AutomationAccess", "LinkedIn: Starting automation check...")

        // Step A: Check if we are on the message composition screen/dialog containing EditText and a Send button
        val editText = findNodeByCriteria(rootNode) { node ->
            node.className?.toString()?.contains("EditText") == true
        }
        
        if (editText != null) {
            Log.d("AutomationAccess", "LinkedIn: Found message composition EditText")
            val currentText = editText.text?.toString() ?: ""
            if (!currentText.equals(linkedinMessage, ignoreCase = false)) {
                Log.d("AutomationAccess", "LinkedIn: Setting invitation text...")
                editText.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
                Thread.sleep(250)
                val arguments = Bundle().apply {
                    putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, linkedinMessage)
                }
                editText.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
                Thread.sleep(600)
                if (textFilledTime == 0L) textFilledTime = System.currentTimeMillis()
            }

            // Find send/done/connect button — broad search
            val sendButton = findNodeByCriteria(rootNode) { node ->
                val text = node.text?.toString()?.lowercase() ?: ""
                val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
                val viewId = node.viewIdResourceName?.lowercase() ?: ""
                val isClickable = node.isClickable || node.parent?.isClickable == true

                isClickable && (
                    text.contains("send") || text == "done" || text.contains("invite") ||
                    text == "connect" || text.contains("connect") ||
                    contentDesc.contains("send") || contentDesc == "done" || contentDesc.contains("invite") ||
                    contentDesc == "connect" || contentDesc.contains("connect") ||
                    viewId.contains("send") || viewId.contains("btn_send") || viewId.contains("action_send") ||
                    viewId.contains("menu_send") || viewId.contains("invitation") || viewId.contains("submit") ||
                    viewId.contains("connect")
                )
            }

            if (sendButton != null) {
                Log.d("AutomationAccess", "LinkedIn: Clicking Send invitation button: text='${sendButton.text}' id='${sendButton.viewIdResourceName}'")
                clickNodeOrParent(sendButton)
                Thread.sleep(1500)
                textFilledTime = 0L
                lastSentSuccess = true
                performReturnToApp()
                return
            } else {
                Log.d("AutomationAccess", "LinkedIn: Message text set, but Send button not found yet")
                // Timeout: if we've been stuck here too long, bail out
                if (textFilledTime > 0L && System.currentTimeMillis() - textFilledTime > SEND_BUTTON_TIMEOUT_MS) {
                    Log.d("AutomationAccess", "LinkedIn: Send button timeout — bailing out as skipped")
                    textFilledTime = 0L
                    lastSentSuccess = false
                    performReturnToApp()
                }
            }
            return
        }

        // Step B: Check if we are on a intermediate dialog containing "Add a note" or "Personalize" button
        val addNoteButton = findNodeByCriteria(rootNode) { node ->
            val text = node.text?.toString()?.lowercase() ?: ""
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
            text.contains("add a note") || text.contains("personalize") ||
            contentDesc.contains("add a note") || contentDesc.contains("personalize")
        }

        if (addNoteButton != null) {
            Log.d("AutomationAccess", "LinkedIn: Found dialog 'Add a note' / 'Personalize' button, clicking it...")
            clickNodeOrParent(addNoteButton)
            Thread.sleep(800)
            return
        }

        // Step C: Check if the popup menu/bottom sheet containing "Personalize invite" or "Connect" options is open
        val menuItem = findNodeByCriteria(rootNode) { node ->
            val text = node.text?.toString()?.lowercase() ?: ""
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
            val viewId = node.viewIdResourceName?.lowercase() ?: ""
            
            text.contains("personalize invite") || text.contains("personalize") || text.contains("add a note") || text == "connect" ||
            contentDesc.contains("personalize invite") || contentDesc.contains("personalize") || contentDesc.contains("add a note") || contentDesc == "connect" ||
            viewId.contains("connect") || viewId.contains("personalize")
        }

        if (menuItem != null) {
            Log.d("AutomationAccess", "LinkedIn: Found popup menu action item: ${menuItem.text ?: menuItem.contentDescription}, clicking it...")
            clickNodeOrParent(menuItem)
            Thread.sleep(800)
            return
        }

        // Step D: We are on the main profile page. Find the "three vertical dots" (More options) button to open the menu.
        val moreButton = findNodeByCriteria(rootNode) { node ->
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
            val viewId = node.viewIdResourceName?.lowercase() ?: ""
            
            contentDesc.contains("more options") ||
            contentDesc.contains("more actions") ||
            contentDesc.contains("other actions") ||
            contentDesc == "more" ||
            contentDesc == "more..." ||
            viewId.contains("overflow") ||
            viewId.contains("more_actions") ||
            viewId.contains("top_card_more")
        }

        if (moreButton != null) {
            Log.d("AutomationAccess", "LinkedIn: Found More options (three dots) button, clicking it...")
            clickNodeOrParent(moreButton)
            bottomSheetOpened = true  // mark that we opened the sheet; next cycle checks for personalize
            Thread.sleep(800)
            return
        }

        // Step E: Bottom sheet is open (we clicked three-dots) but "Personalize invite" was NOT found above.
        // This means the person is already connected, not connected yet with a different flow, etc.
        // Immediately press BACK to dismiss the sheet and return to app as Skipped.
        if (bottomSheetOpened) {
            Log.d("AutomationAccess", "LinkedIn: Bottom sheet open but no Personalize option found. Dismissing and skipping.")
            bottomSheetOpened = false
            lastSentSuccess = false
            performGlobalAction(GLOBAL_ACTION_BACK)  // closes the bottom sheet
            Thread.sleep(500)
            performReturnToApp()
            return
        }

        Log.d("AutomationAccess", "LinkedIn: Profile automation check idle (no matching views)")

        // Timeout: if we have been idle too long since the profile was opened, give up and return
        if (profileOpenTime > 0L) {
            val elapsed = System.currentTimeMillis() - profileOpenTime
            if (elapsed > PROFILE_TIMEOUT_MS) {
                Log.d("AutomationAccess", "LinkedIn: Timeout after ${elapsed}ms — no buttons found. Returning to app as skipped.")
                profileOpenTime = 0L
                lastSentSuccess = false
                performReturnToApp()
            }
        }
    }

    // --- RECURSIVE SEARCH HELPERS ---
    private fun findNodeByCriteria(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (node == null) return null
        if (predicate(node)) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val result = findNodeByCriteria(child, predicate)
            if (result != null) return result
        }
        return null
    }

    private fun clickNodeOrParent(node: AccessibilityNodeInfo?): Boolean {
        var current = node
        while (current != null) {
            if (current.isClickable) {
                current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return true
            }
            current = current.parent
        }
        return false
    }

    // --- RETURN TO DISPATCHER ---
    private fun performReturnToApp() {
        Log.d("AutomationAccess", "performReturnToApp called. Executing return sequence...")
        try {
            // Back action 1
            Log.d("AutomationAccess", "Executing back action 1...")
            performGlobalAction(GLOBAL_ACTION_BACK)
            Thread.sleep(600)
            
            // Back action 2
            Log.d("AutomationAccess", "Executing back action 2...")
            performGlobalAction(GLOBAL_ACTION_BACK)
            Thread.sleep(400)
            
            // Launch JobPilot activity explicitly to foreground
            Log.d("AutomationAccess", "Launching $packageName directly to foreground...")
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                startActivity(launchIntent)
                Log.d("AutomationAccess", "App relaunch intent started!")
            } else {
                Log.e("AutomationAccess", "Launch intent for $packageName is null!")
            }
        } catch (e: Exception) {
            Log.e("AutomationAccess", "Error performing return to app: ${e.message}", e)
        }
    }

    override fun onInterrupt() {
        Log.d("AutomationAccess", "Service Interrupted")
    }
}
