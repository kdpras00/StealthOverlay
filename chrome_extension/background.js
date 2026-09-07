// background.js — Screenshot capture, tab audio capture, note relay, debug relay

// Store the active capture tab ID so we can relay debug logs
var activeCapTabId = null;

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "open_options") {
    chrome.tabs.create({ url: chrome.runtime.getURL("options.html") }, (tab) => {
      if (chrome.runtime.lastError) {
        chrome.runtime.openOptionsPage();
      }
    });
    sendResponse({ status: "ok" });
    return true;
  }

  if (request.action === "capture_screenshot") {
    chrome.tabs.captureVisibleTab(null, { format: "png" }, (dataUrl) => {
      if (chrome.runtime.lastError) {
        sendResponse({ error: chrome.runtime.lastError.message });
      } else {
        sendResponse({ dataUrl: dataUrl });
      }
    });
    return true;
  }

  if (request.action === "send_note") {
    sendNoteToDesktop(request.title, request.content).then(() => {
      sendResponse({ status: "ok" });
    });
    return true;
  }

  // ── TAB AUDIO CAPTURE ──
  if (request.action === "start_tab_capture") {
    handleStartTabCapture(
      request.tabId,
      request.lang,
      request.apiKey,
      request.apiProvider,
      request.apiBaseUrl
    );
    sendResponse({ status: "starting" });
    return true;
  }

  if (request.action === "stop_tab_capture") {
    handleStopTabCapture();
    sendResponse({ status: "stopped" });
    return true;
  }

  // Relay transcript from offscreen → content script
  if (request.action === "tab_transcript") {
    if (request.tabId) {
      chrome.tabs.sendMessage(request.tabId, {
        action: "tab_transcript_result",
        interim: request.interim,
        final: request.final
      }).catch(() => {});
    }
    return false;
  }

  // Capture status from offscreen → content script
  if (request.action === "capture_status") {
    if (request.tabId) {
      chrome.tabs.sendMessage(request.tabId, {
        action: "capture_status_update",
        status: request.status,
        error: request.error,
        detail: request.detail
      }).catch(() => {});
    }
    return false;
  }

  // Debug log relay from offscreen → content script (visible in page console)
  if (request.action === "debug_log") {
    var tabId = request.tabId || activeCapTabId;
    if (tabId) {
      chrome.tabs.sendMessage(tabId, {
        action: "offscreen_debug",
        message: request.message
      }).catch(() => {});
    }
    return false;
  }
});

// ── Tab Audio Capture via Offscreen Document ──
async function handleStartTabCapture(tabId, lang, apiKey, apiProvider, apiBaseUrl) {
  activeCapTabId = tabId;
  try {
    // Create offscreen document if not exists
    const contexts = await chrome.runtime.getContexts({
      contextTypes: ["OFFSCREEN_DOCUMENT"]
    });

    if (contexts.length === 0) {
      await chrome.offscreen.createDocument({
        url: "offscreen.html",
        reasons: ["USER_MEDIA"],
        justification: "Capture tab audio for interview speech recognition"
      });
      // Give offscreen.js time to initialize listeners
      await new Promise((r) => setTimeout(r, 300));
    }

    // Get media stream ID for the target tab
    const streamId = await chrome.tabCapture.getMediaStreamId({
      targetTabId: tabId
    });

    console.log("[StealthOverlay:bg] Got stream ID for tab", tabId);

    // Send stream ID to offscreen document with retry
    await sendToOffscreen({
      target: "offscreen",
      action: "start_capture",
      streamId: streamId,
      tabId: tabId,
      lang: lang || "id-ID",
      apiKey: apiKey || "",
      apiProvider: apiProvider || "groq",
      apiBaseUrl: apiBaseUrl || ""
    });
  } catch (err) {
    console.error("[StealthOverlay:bg] Tab capture error:", err);
    if (tabId) {
      chrome.tabs.sendMessage(tabId, {
        action: "capture_status_update",
        status: "error",
        error: err.message
      }).catch(() => {});
    }
  }
}

async function sendToOffscreen(message, retries = 5) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await chrome.runtime.sendMessage(message);
      if (response && response.status === "ok") return response;
    } catch (e) {
      console.log(`[StealthOverlay:bg] Retry offscreen msg (${i + 1}/${retries})...`);
      await new Promise((r) => setTimeout(r, 200));
    }
  }
  console.warn("[StealthOverlay:bg] Could not reach offscreen document");
}

async function handleStopTabCapture() {
  activeCapTabId = null;
  try {
    await sendToOffscreen({ target: "offscreen", action: "stop_capture" });
    setTimeout(async () => {
      try { await chrome.offscreen.closeDocument(); } catch (e) {}
    }, 500);
  } catch (e) {}
}

async function sendNoteToDesktop(title, content) {
  try {
    await fetch("http://127.0.0.1:8765/api/note", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: title || "Chrome Input", content: content })
    });
  } catch (e) {}
}
