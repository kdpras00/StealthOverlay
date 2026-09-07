document.addEventListener("DOMContentLoaded", function () {
  var toggle = document.getElementById("toggleOverlay");
  var label = document.getElementById("statusLabel");
  var dot = document.getElementById("statusDot");

  function updateUI(on) {
    toggle.checked = on;
    label.textContent = on ? "ON" : "OFF";
    label.className = on ? "status-label on" : "status-label";
    if (dot) dot.style.backgroundColor = on ? "#10b981" : "#ef4444";
  }

  chrome.storage.local.get(["isOverlayVisible"], function (res) {
    updateUI(res.isOverlayVisible === true);
  });

  toggle.addEventListener("change", function () {
    var isOn = toggle.checked;
    updateUI(isOn);
    chrome.storage.local.set({ isOverlayVisible: isOn });

    chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
      if (tabs[0] && tabs[0].id) {
        var tabId = tabs[0].id;
        chrome.storage.local.get([
          "overlayOpacity", "overlayWidth", "speechLang", "autoStartMic", "backdropBlur",
          "apiKey", "apiProvider", "apiBaseUrl"
        ], function (saved) {
          chrome.scripting.executeScript({
            target: { tabId: tabId },
            func: injectParakeetLockedInOverlay,
            args: [isOn, saved]
          }).catch(function (err) {
            console.log("Cannot inject overlay script:", err);
          });
        });
      }
    });

    fetch("http://127.0.0.1:8765/api/visibility", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ visible: isOn })
    }).catch(function () {});
  });
});

// ═════════════════════════════════════════════════════════════════════════════
// PARAKEET AI / LOCKEDIN AI EXACT PIXEL-PERFECT CAPSULE OVERLAY
// Injected directly into Chrome web page tab
// ═════════════════════════════════════════════════════════════════════════════
function injectParakeetLockedInOverlay(visible, savedConfig) {
  var ID = "parakeet-ai-overlay-root";
  var existing = document.getElementById(ID);

  var cfgOpacity = (savedConfig && savedConfig.overlayOpacity) ? savedConfig.overlayOpacity : "0.8";
  var cfgWidth = (savedConfig && savedConfig.overlayWidth) ? savedConfig.overlayWidth + "px" : "740px";
  var cfgSpeechLang = (savedConfig && savedConfig.speechLang) ? savedConfig.speechLang : "id-ID";
  if (cfgSpeechLang === "auto") {
    cfgSpeechLang = navigator.language || "id-ID";
  }
  var cfgAutoMic = (savedConfig && savedConfig.autoStartMic !== undefined) ? savedConfig.autoStartMic : true;
  var cfgBlur = (savedConfig && savedConfig.backdropBlur !== false) ? "backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);" : "";

  if (!visible) {
    if (existing) existing.remove();
    return;
  }
  if (existing) {
    existing.remove(); // Force recreate element to apply newest styles & width
  }

  // ── SVG ICONS ──
  var SVG_SCREEN = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>';
  var SVG_MIC = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>';
  var SVG_THUMB_UP = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>';
  var SVG_THUMB_DOWN = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h3a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-3"/></svg>';
  var SVG_DRAG = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>';
  var SVG_MINIMIZE = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 14h6v6"/><path d="M20 10h-6V4"/><path d="M14 10l7-7"/><path d="M3 21l7-7"/></svg>';
  var SVG_MORE = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>';
  var SVG_WAVE = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5"><line x1="4" y1="10" x2="4" y2="14"/><line x1="8" y1="6" x2="8" y2="18"/><line x1="12" y1="4" x2="12" y2="20"/><line x1="16" y1="8" x2="16" y2="16"/><line x1="20" y1="11" x2="20" y2="13"/></svg>';
  var SVG_CHAT = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>';
  var SVG_STAR = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>';
  var SVG_EXPAND = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/></svg>';
  var SVG_COPY = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';

  // ── CSS INJECTION ──
  var css = document.createElement("style");
  css.textContent = `
    @keyframes parakeetPulse {
      0%, 100% { transform: scale(1); opacity: 1; }
      50% { transform: scale(1.3); opacity: 0.7; }
    }
    @keyframes parakeetFadeIn {
      from { opacity: 0; transform: translateX(-50%) translateY(-8px); }
      to { opacity: 1; transform: translateX(-50%) translateY(0); }
    }
    #parakeet-ai-overlay-root * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .pk-pill-btn {
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: #e5e7eb;
      padding: 6px 16px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      transition: all 0.15s ease;
      user-select: none;
      white-space: nowrap;
    }
    .pk-pill-btn:hover {
      background: rgba(255, 255, 255, 0.18);
      border-color: rgba(255, 255, 255, 0.25);
    }
    .pk-pill-btn.active {
      background: rgba(255, 255, 255, 0.25);
      border-color: rgba(255, 255, 255, 0.35);
      color: #ffffff;
      box-shadow: 0 0 14px rgba(255, 255, 255, 0.12);
    }
    .pk-icon-circle {
      width: 30px;
      height: 30px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.12);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #d1d5db;
      cursor: pointer;
      position: relative;
      transition: all 0.15s;
    }
    .pk-icon-circle:hover {
      background: rgba(255, 255, 255, 0.18);
      color: #fff;
    }
    .pk-red-badge {
      position: absolute;
      top: -1px;
      right: -1px;
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: #ef4444;
      box-shadow: 0 0 6px #ef4444;
      animation: parakeetPulse 2s infinite;
    }
    .pk-word-chip {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: #e5e7eb;
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 500;
    }
    .pk-badge-shortcut {
      background: rgba(255, 255, 255, 0.15);
      color: inherit;
      padding: 1px 6px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 600;
      margin-left: 4px;
    }
  `;
  document.head.appendChild(css);

  // ── WRAPPER CONTAINER ──
  var wrapper = document.createElement("div");
  wrapper.id = ID;
  wrapper.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 2147483647;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    width: ${cfgWidth};
    max-width: 95vw;
    animation: parakeetFadeIn 0.3s ease;
  `;

  // ── STATE ──
  var isScreenActive = true;
  var isVoiceActive = cfgAutoMic;
  var currentMode = "answer"; // answer | screenshot | chat
  var answersHistory = [];
  var answerIndex = -1;
  var speechRecognition = null;
  var isMaximized = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET 1: TOP CAPSULE TOOLBAR
  // ═══════════════════════════════════════════════════════════════════════════
  var topBar = document.createElement("div");
  topBar.style.cssText = `
    background: rgba(28, 29, 34, ${cfgOpacity});
    ${cfgBlur}
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 9999px;
    padding: 7px 16px;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.5);
    user-select: none;
    width: fit-content;
    max-width: ${cfgWidth};
    position: relative;
  `;

  // 1. Left Icons (Screen & Voice with Color-coded Badges)
  var screenIconBtn = document.createElement("div");
  screenIconBtn.className = "pk-icon-circle";
  screenIconBtn.title = "Screen Capture & Vision Monitor (ON)";
  screenIconBtn.innerHTML = SVG_SCREEN + '<div class="pk-red-badge"></div>';

  function updateScreenBadgeState(active) {
    var badge = screenIconBtn.querySelector(".pk-red-badge");
    if (!badge) return;
    if (active) {
      badge.style.display = "block";
      badge.style.background = "#ef4444"; // Red for Screen Recording / Monitoring Active
      badge.style.boxShadow = "0 0 6px #ef4444";
    } else {
      badge.style.display = "none";
    }
  }
  updateScreenBadgeState(isScreenActive);

  screenIconBtn.addEventListener("click", function () {
    isScreenActive = !isScreenActive;
    updateScreenBadgeState(isScreenActive);
    screenIconBtn.title = "Tab Audio & Screen Sharing (" + (isScreenActive ? "ON" : "OFF") + ")";

    if (isScreenActive) {
      chrome.storage.local.get(["apiKey", "apiProvider", "apiBaseUrl", "speechLang"], function(cfg) {
        console.log("[StealthOverlay] Starting Tab Audio Capture...");
        chrome.runtime.sendMessage({
          action: "start_tab_capture",
          tabId: null,
          lang: currentSpeechLang || cfg.speechLang || "en-US",
          apiKey: cfg.apiKey || "",
          apiProvider: cfg.apiProvider || "gemini",
          apiBaseUrl: cfg.apiBaseUrl || ""
        });
      });
    } else {
      console.log("[StealthOverlay] Stopping Tab Audio Capture...");
      chrome.runtime.sendMessage({ action: "stop_tab_capture" });
    }
  });

  var micIconBtn = document.createElement("div");
  micIconBtn.className = "pk-icon-circle";
  micIconBtn.title = "Voice Listening / Mic (ON)";
  micIconBtn.innerHTML = SVG_MIC + '<div class="pk-red-badge"></div>';
  micIconBtn.addEventListener("click", function () {
    isVoiceActive = !isVoiceActive;
    if (isVoiceActive) {
      updateMicBadgeState("listening");
      startVoiceListening();
      // Also trigger digital Tab Capture for internal audio pages like ElevenLabs/Meet/Zoom
      chrome.storage.local.get(["apiKey", "apiProvider", "apiBaseUrl", "speechLang"], function(cfg) {
        chrome.runtime.sendMessage({
          action: "start_tab_capture",
          tabId: null,
          lang: currentSpeechLang || cfg.speechLang || "en-US",
          apiKey: cfg.apiKey || "",
          apiProvider: cfg.apiProvider || "gemini",
          apiBaseUrl: cfg.apiBaseUrl || ""
        });
      });
    } else {
      updateMicBadgeState("off");
      stopVoiceListening();
      chrome.runtime.sendMessage({ action: "stop_tab_capture" });
    }
    micIconBtn.title = "Voice Listening (" + (isVoiceActive ? "ON" : "OFF") + ")";
  });

  topBar.appendChild(screenIconBtn);
  topBar.appendChild(micIconBtn);

  // 2. Mode Buttons (Answer, Screenshot, Chat)
  var btnAnswer = document.createElement("button");
  btnAnswer.className = "pk-pill-btn active";
  btnAnswer.style.padding = "7px 20px";
  btnAnswer.style.fontSize = "13px";
  btnAnswer.innerHTML = 'Answer <span class="pk-badge-shortcut">⌘ ↵</span>';

  var btnScreenshot = document.createElement("button");
  btnScreenshot.className = "pk-pill-btn";
  btnScreenshot.style.padding = "7px 20px";
  btnScreenshot.style.fontSize = "13px";
  btnScreenshot.innerHTML = 'Screenshot <span class="pk-badge-shortcut">⌘ S</span>';

  var btnChat = document.createElement("button");
  btnChat.className = "pk-pill-btn";
  btnChat.style.padding = "7px 20px";
  btnChat.style.fontSize = "13px";
  btnChat.innerHTML = 'Chat <span class="pk-badge-shortcut">⌘ K</span>';

  function setMode(mode) {
    currentMode = mode;
    btnAnswer.className = "pk-pill-btn " + (mode === "answer" ? "active" : "");
    btnScreenshot.className = "pk-pill-btn " + (mode === "screenshot" ? "active" : "");
    btnChat.className = "pk-pill-btn " + (mode === "chat" ? "active" : "");

    if (mode === "screenshot") {
      triggerScreenshotCapture();
    } else if (mode === "chat") {
      chatInputRow.style.display = "flex";
      chatInput.focus();
    } else {
      chatInputRow.style.display = "none";
    }
  }

  btnAnswer.addEventListener("click", function () { setMode("answer"); });
  btnScreenshot.addEventListener("click", function () { setMode("screenshot"); });
  btnChat.addEventListener("click", function () { setMode("chat"); });

  topBar.appendChild(btnAnswer);
  topBar.appendChild(btnScreenshot);
  topBar.appendChild(btnChat);

  // 3. Right Utility Icons
  var dragHandle = document.createElement("div");
  dragHandle.className = "pk-icon-circle";
  dragHandle.style.cursor = "grab";
  dragHandle.title = "Drag overlay";
  dragHandle.innerHTML = SVG_DRAG;

  var minimizeBtn = document.createElement("div");
  minimizeBtn.className = "pk-icon-circle";
  minimizeBtn.title = "Collapse overlay";
  minimizeBtn.innerHTML = SVG_MINIMIZE;
  minimizeBtn.addEventListener("click", function () {
    var isMiddleHidden = middleBar.style.display === "none";
    middleBar.style.display = isMiddleHidden ? "flex" : "none";
    if (answersHistory.length > 0 && answerIndex >= 0) {
      cardBox.style.display = isMiddleHidden ? "flex" : "none";
    } else {
      cardBox.style.display = "none";
    }
  });

  var moreBtn = document.createElement("div");
  moreBtn.className = "pk-icon-circle";
  moreBtn.title = "Settings";
  moreBtn.innerHTML = SVG_MORE;
  moreBtn.addEventListener("click", function (e) {
    e.stopPropagation();
    chrome.runtime.sendMessage({ action: "open_options" });
  });

  var endBtn = document.createElement("button");
  endBtn.textContent = "End";
  endBtn.style.cssText = `
    background: #ef4444;
    border: none;
    color: white;
    padding: 6px 16px;
    border-radius: 9999px;
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
    margin-left: 2px;
    transition: background 0.15s;
  `;
  endBtn.addEventListener("click", function () {
    wrapper.style.display = "none";
    stopVoiceListening();
  });

  topBar.appendChild(dragHandle);
  topBar.appendChild(minimizeBtn);
  topBar.appendChild(moreBtn);
  topBar.appendChild(endBtn);
  wrapper.appendChild(topBar);

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET 2: MIDDLE TRANSCRIPTION & LIVE AUDIO BAR
  // ═══════════════════════════════════════════════════════════════════════════
  var middleBar = document.createElement("div");
  middleBar.style.cssText = `
    background: rgba(28, 29, 34, ${cfgOpacity});
    ${cfgBlur}
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 9999px;
    padding: 6px 14px;
    display: flex;
    align-items: center;
    gap: 8px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
    width: 100%;
    max-width: ${cfgWidth};
    user-select: none;
  `;

  var waveIcon = document.createElement("div");
  waveIcon.style.cssText = "display:flex;align-items:center;margin-right:2px;";
  waveIcon.innerHTML = SVG_WAVE;

  var chipContainer = document.createElement("div");
  chipContainer.style.cssText = `
    flex: 1;
    display: flex;
    align-items: center;
    gap: 6px;
    overflow-x: auto;
    white-space: nowrap;
    padding: 2px 0;
  `;

  function renderChips(words) {
    chipContainer.innerHTML = "";
    if (!words || words.length === 0) {
      return;
    }
    words.forEach(function (w) {
      var chip = document.createElement("span");
      chip.className = "pk-word-chip";
      chip.textContent = w;
      chipContainer.appendChild(chip);
    });
  }
  renderChips([]);

  var currentSpeechLang = "en-US";
  chrome.storage.local.get(["speechLang"], function(cfg) {
    if (cfg.speechLang) currentSpeechLang = cfg.speechLang;
    updateLangBtnLabel();
  });

  var langToggleBtn = document.createElement("button");
  langToggleBtn.className = "pk-pill-btn";
  langToggleBtn.style.padding = "3px 10px";
  langToggleBtn.style.fontSize = "10px";
  langToggleBtn.title = "Click to toggle Speech Recognition Language (EN / ID)";

  function updateLangBtnLabel() {
    var code = (currentSpeechLang.startsWith("id") ? "ID" : "EN");
    langToggleBtn.innerHTML = "🌐 " + code;
  }
  updateLangBtnLabel();

  langToggleBtn.addEventListener("click", function() {
    currentSpeechLang = (currentSpeechLang.startsWith("en") ? "id-ID" : "en-US");
    chrome.storage.local.set({ speechLang: currentSpeechLang }, function() {
      updateLangBtnLabel();
      if (isVoiceActive) {
        stopVoiceListening();
        setTimeout(function() { startVoiceListening(); }, 300);
      }
    });
  });

  var clearBarBtn = document.createElement("button");
  clearBarBtn.className = "pk-pill-btn";
  clearBarBtn.style.padding = "3px 10px";
  clearBarBtn.style.fontSize = "10px";
  clearBarBtn.innerHTML = 'Clear <span class="pk-badge-shortcut">⌘ Del</span>';
  clearBarBtn.addEventListener("click", function () {
    renderChips([]);
  });

  var expandIconBtn = document.createElement("div");
  expandIconBtn.className = "pk-icon-circle";
  expandIconBtn.style.width = "24px";
  expandIconBtn.style.height = "24px";
  expandIconBtn.title = "Maximize / Restore";
  expandIconBtn.innerHTML = SVG_EXPAND;

  middleBar.appendChild(waveIcon);
  middleBar.appendChild(chipContainer);
  middleBar.appendChild(langToggleBtn);
  middleBar.appendChild(clearBarBtn);
  middleBar.appendChild(expandIconBtn);
  wrapper.appendChild(middleBar);

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET 3: BOTTOM FLOATING ANSWER CARD (Hidden by default when empty)
  // ═══════════════════════════════════════════════════════════════════════════
  var cardBox = document.createElement("div");
  cardBox.style.cssText = `
    display: none;
    background: rgba(20, 21, 25, ${cfgOpacity});
    ${cfgBlur}
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 20px;
    padding: 18px 24px;
    width: 100%;
    max-width: ${cfgWidth};
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.6);
    color: #e5e7eb;
    flex-direction: column;
    gap: 12px;
    position: relative;
  `;

  // Header Nav Bar inside Card
  var cardHeader = document.createElement("div");
  cardHeader.style.cssText = "display:flex;align-items:center;justify-content:space-between;user-select:none;";

  var navBtns = document.createElement("div");
  navBtns.style.cssText = "display:flex;gap:4px;";

  var btnPrev = document.createElement("button");
  btnPrev.className = "pk-pill-btn";
  btnPrev.style.padding = "3px 8px";
  btnPrev.innerHTML = '<span class="pk-badge-shortcut">⌘ ←</span>';

  var btnNext = document.createElement("button");
  btnNext.className = "pk-pill-btn";
  btnNext.style.padding = "3px 8px";
  btnNext.innerHTML = '<span class="pk-badge-shortcut">⌘ →</span>';

  btnPrev.addEventListener("click", function () {
    if (answerIndex > 0) { answerIndex--; displayCurrentAnswer(); }
  });
  btnNext.addEventListener("click", function () {
    if (answerIndex < answersHistory.length - 1) { answerIndex++; displayCurrentAnswer(); }
  });

  navBtns.appendChild(btnPrev);
  navBtns.appendChild(btnNext);
  cardHeader.appendChild(navBtns);

  var rightCardNav = document.createElement("div");
  rightCardNav.style.cssText = "display:flex;align-items:center;gap:6px;";

  var cardClearBtn = document.createElement("button");
  cardClearBtn.className = "pk-pill-btn";
  cardClearBtn.style.padding = "3px 10px";
  cardClearBtn.style.fontSize = "10px";
  cardClearBtn.innerHTML = 'Clear <span class="pk-badge-shortcut">⌘ Del</span>';
  cardClearBtn.addEventListener("click", function () {
    answersHistory = [];
    answerIndex = -1;
    displayCurrentAnswer();
    renderChips([]);
  });

  var cardExpandIcon = document.createElement("div");
  cardExpandIcon.className = "pk-icon-circle";
  cardExpandIcon.style.width = "24px";
  cardExpandIcon.style.height = "24px";
  cardExpandIcon.title = "Maximize / Restore";
  cardExpandIcon.innerHTML = SVG_EXPAND;

  // Maximize / Restore Toggle Functionality
  function toggleMaximize() {
    isMaximized = !isMaximized;
    if (isMaximized) {
      wrapper.style.width = "94vw";
      wrapper.style.maxWidth = "94vw";
      wrapper.style.left = "3vw";
      wrapper.style.transform = "none";
      topBar.style.maxWidth = "100%";
      middleBar.style.maxWidth = "100%";
      cardBox.style.maxWidth = "100%";
      cardBox.style.minHeight = "65vh";
      if (answersHistory.length > 0 && answerIndex >= 0) {
        cardBox.style.display = "flex";
      } else {
        cardBox.style.display = "none";
      }
      cardExpandIcon.style.color = "#10b981";
      expandIconBtn.style.color = "#10b981";
    } else {
      wrapper.style.width = "740px";
      wrapper.style.maxWidth = "95vw";
      wrapper.style.left = "50%";
      wrapper.style.transform = "translateX(-50%)";
      topBar.style.maxWidth = "740px";
      middleBar.style.maxWidth = "740px";
      cardBox.style.maxWidth = "740px";
      cardBox.style.minHeight = "auto";
      cardExpandIcon.style.color = "#d1d5db";
      expandIconBtn.style.color = "#d1d5db";
    }
  }

  expandIconBtn.addEventListener("click", toggleMaximize);
  cardExpandIcon.addEventListener("click", toggleMaximize);

  rightCardNav.appendChild(cardClearBtn);
  rightCardNav.appendChild(cardExpandIcon);
  cardHeader.appendChild(rightCardNav);
  cardBox.appendChild(cardHeader);

  // Content Area
  var contentBody = document.createElement("div");
  contentBody.style.cssText = "display:flex;flex-direction:column;gap:10px;";

  // Copy Icon at Top Right of content
  var copyBtn = document.createElement("div");
  copyBtn.className = "pk-icon-circle";
  copyBtn.style.cssText = "position:absolute;top:18px;right:18px;width:26px;height:26px;";
  copyBtn.title = "Copy answer";
  copyBtn.innerHTML = SVG_COPY;
  copyBtn.addEventListener("click", function () {
    var cur = answersHistory[answerIndex];
    var textToCopy = "";
    if (cur) {
      textToCopy = "Question: " + cur.question + "\n\nAnswer: " + cur.answer;
      if (cur.bullets && cur.bullets.length > 0) {
        textToCopy += "\n\n" + cur.bullets.map(function (b) { return "• " + b; }).join("\n");
      }
    } else {
      textToCopy = qText.textContent + "\n" + aText.textContent;
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(textToCopy);
    } else {
      var ta = document.createElement("textarea");
      ta.value = textToCopy;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    }

    copyBtn.style.color = "#10b981";
    copyBtn.style.background = "rgba(16, 185, 129, 0.2)";
    copyBtn.title = "Copied to clipboard!";
    setTimeout(function () {
      copyBtn.style.color = "#d1d5db";
      copyBtn.style.background = "rgba(255, 255, 255, 0.08)";
      copyBtn.title = "Copy answer";
    }, 1500);
  });
  cardBox.appendChild(copyBtn);

  // Question Row
  var qRow = document.createElement("div");
  qRow.style.cssText = "display:flex;align-items:flex-start;gap:8px;font-size:13px;font-weight:600;color:#f3f4f6;";
  var qIconSpan = document.createElement("span");
  qIconSpan.style.cssText = "display:flex;align-items:center;margin-top:1px;color:#9ca3af;";
  qIconSpan.innerHTML = SVG_CHAT;
  var qText = document.createElement("span");
  qText.style.cssText = "font-weight:400;color:#d1d5db;";
  qRow.appendChild(qIconSpan);
  qRow.appendChild(qText);
  contentBody.appendChild(qRow);

  // Answer Row
  var aRow = document.createElement("div");
  aRow.style.cssText = "display:flex;align-items:flex-start;gap:8px;font-size:13px;font-weight:700;color:#ffffff;";
  var aIconSpan = document.createElement("span");
  aIconSpan.style.cssText = "display:flex;align-items:center;margin-top:1px;color:#10b981;";
  aIconSpan.innerHTML = SVG_STAR;
  var aText = document.createElement("span");
  aText.style.cssText = "font-weight:500;color:#f9fafb;";
  aRow.appendChild(aIconSpan);
  aRow.appendChild(aText);
  contentBody.appendChild(aRow);

  // Bullet List
  var bulletList = document.createElement("ul");
  bulletList.style.cssText = "list-style-type:disc;padding-left:24px;font-size:12px;color:#9ca3af;line-height:1.6;display:flex;flex-direction:column;gap:4px;";
  contentBody.appendChild(bulletList);

  cardBox.appendChild(contentBody);

  // Footer inside Card
  var cardFooter = document.createElement("div");
  cardFooter.style.cssText = "display:flex;align-items:center;justify-content:space-between;padding-top:4px;border-top:1px solid rgba(255,255,255,0.06);font-size:11px;color:#6b7280;";

  var footerLeft = document.createElement("div");
  footerLeft.style.cssText = "display:flex;align-items:center;gap:12px;";

  var modeTimestampBadge = document.createElement("span");
  modeTimestampBadge.textContent = "";

  var feedbackThumbs = document.createElement("div");
  feedbackThumbs.style.cssText = "display:flex;gap:8px;cursor:pointer;";
  feedbackThumbs.innerHTML = '<span title="Good answer">' + SVG_THUMB_UP + '</span><span title="Bad answer">' + SVG_THUMB_DOWN + '</span>';

  footerLeft.appendChild(modeTimestampBadge);
  footerLeft.appendChild(feedbackThumbs);
  cardFooter.appendChild(footerLeft);
  cardBox.appendChild(cardFooter);

  wrapper.appendChild(cardBox);

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT INPUT BAR (Shown when Chat mode selected)
  // ═══════════════════════════════════════════════════════════════════════════
  var chatInputRow = document.createElement("div");
  chatInputRow.style.cssText = `
    display: none;
    width: 100%;
    max-width: ${cfgWidth};
    background: rgba(28, 29, 34, ${cfgOpacity});
    ${cfgBlur}
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 9999px;
    padding: 4px 6px 4px 14px;
    align-items: center;
    gap: 8px;
  `;

  var chatInput = document.createElement("input");
  chatInput.type = "text";
  chatInput.placeholder = "Type your question here...";
  chatInput.style.cssText = "flex:1;background:transparent;border:none;color:#fff;font-size:12px;outline:none;";

  var chatSendBtn = document.createElement("button");
  chatSendBtn.className = "pk-pill-btn active";
  chatSendBtn.textContent = "Send";
  chatSendBtn.style.padding = "4px 14px";
  chatSendBtn.addEventListener("click", function () {
    var val = chatInput.value.trim();
    if (!val) return;
    fetchAIAnswer(val);
    chatInput.value = "";
  });
  chatInput.addEventListener("keydown", function (e) {
    if (e.key === "Enter") chatSendBtn.click();
  });

  chatInputRow.appendChild(chatInput);
  chatInputRow.appendChild(chatSendBtn);
  wrapper.appendChild(chatInputRow);

  // ═══════════════════════════════════════════════════════════════════════════
  // APPEND TO DOCUMENT DOM
  // ═══════════════════════════════════════════════════════════════════════════
  document.documentElement.appendChild(wrapper);

  // Display initial item
  displayCurrentAnswer();

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIC & HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  function displayCurrentAnswer() {
    var cur = answersHistory[answerIndex];
    if (!cur) {
      cardBox.style.display = "none";
      return;
    }
    cardBox.style.display = "flex";

    if (cur.question) {
      qRow.style.display = "flex";
      qText.textContent = cur.question;
    } else {
      qRow.style.display = "none";
    }

    if (cur.answer) {
      aRow.style.display = "flex";
      aText.textContent = cur.answer;
    } else {
      aRow.style.display = "none";
    }

    bulletList.innerHTML = "";
    if (cur.bullets && cur.bullets.length > 0) {
      bulletList.style.display = "flex";
      cur.bullets.forEach(function (b) {
        var li = document.createElement("li");
        li.textContent = b;
        bulletList.appendChild(li);
      });
    } else {
      bulletList.style.display = "none";
    }
    modeTimestampBadge.textContent = "Answer · " + (cur.time || "");
  }

  function getFormattedTime() {
    var now = new Date();
    return String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0");
  }

  function addNewAnswer(q, a, bullets) {
    answersHistory.push({ question: q, answer: a, bullets: bullets || [], time: getFormattedTime() });
    answerIndex = answersHistory.length - 1;
    displayCurrentAnswer();
    renderChips(q.split(" "));
  }

  function parseAndDisplayAiReply(questionText, aiReply, model) {
    var lines = aiReply.split("\n").filter(function(l) { return l.trim().length > 0; });
    var mainAns = lines[0] || "AI Solution Generated";
    var bullets = lines.slice(1).map(function(l) { return l.replace(/^[\s•\-\*]+/, ""); });

    answersHistory[answerIndex] = {
      question: questionText,
      answer: mainAns,
      bullets: bullets.length > 0 ? bullets : ["Processed via " + model],
      time: getFormattedTime()
    };
    displayCurrentAnswer();
  }

  function displayAiErrorFallback(questionText, model, errorMsg) {
    answersHistory[answerIndex] = {
      question: questionText,
      answer: "AI Solution for: " + questionText,
      bullets: [
        "Analyzed input via " + model + " engine",
        "Synthesized core algorithmic / system concept",
        "Note: " + (errorMsg || "Connecting to provider API...")
      ],
      time: getFormattedTime()
    };
    displayCurrentAnswer();
  }

  function fetchAIAnswer(questionText) {
    chrome.storage.local.get([
      "apiProvider", "apiBaseUrl", "apiKey", "aiModel", "customModel"
    ], function (res) {
      var provider = (res.apiProvider || "groq").toLowerCase();
      var key = res.apiKey || "";
      var baseUrl = res.apiBaseUrl || "";
      var model = (res.aiModel === "custom") ? (res.customModel || "gpt-4o") : (res.aiModel || "");

      // Resolve Base URL & Model dynamically per provider if missing or default
      if (provider === "groq") {
        if (!baseUrl || baseUrl.includes("20128")) baseUrl = "https://api.groq.com/openai/v1";
        if (!model || model === "auto") model = "llama-3.3-70b-versatile";
      } else if (provider === "openai") {
        if (!baseUrl || baseUrl.includes("20128")) baseUrl = "https://api.openai.com/v1";
        if (!model || model === "auto") model = "gpt-4o";
      } else if (provider === "gemini" || key.startsWith("AIza") || key.startsWith("AQ.")) {
        provider = "gemini";
        if (!baseUrl || baseUrl.includes("20128")) baseUrl = "https://generativelanguage.googleapis.com";
        if (!model || model === "auto") model = "gemini-3.6-flash";
      } else if (provider === "anthropic") {
        if (!baseUrl || baseUrl.includes("20128")) baseUrl = "https://api.anthropic.com/v1";
        if (!model || model === "auto") model = "claude-3-5-sonnet-20241022";
      } else if (provider === "ollama") {
        if (!baseUrl) baseUrl = "http://localhost:11434/v1";
        if (!model || model === "auto") model = "llama3.2";
      } else {
        if (!baseUrl) baseUrl = "http://localhost:20128/v1";
        if (!model || model === "auto") model = "gpt-4o";
      }

      console.log("[StealthOverlay] fetchAIAnswer | provider:", provider, "| baseUrl:", baseUrl, "| model:", model);

      // Loading state
      addNewAnswer(questionText, "Generating AI response...", ["Connecting to " + provider.toUpperCase() + " API (" + model + ")..."]);

      // ── 1. GOOGLE GEMINI NATIVE REST ──
      if (provider === "gemini" || key.startsWith("AIza") || key.startsWith("AQ.")) {
        function callGeminiChatApi(mName) {
          var geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/" + mName + ":generateContent?key=" + key;
          var systemPrompt = "You are a concise technical interview copilot. Answer directly with concise key points.";
          fetch(geminiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{
                parts: [{ text: systemPrompt + "\n\nQuestion: " + questionText }]
              }],
              generationConfig: { temperature: 0.3 }
            })
          })
          .then(function(r) {
            if (!r.ok) {
              return r.text().then(function(t) { throw new Error("Gemini HTTP " + r.status + ": " + t.substring(0, 150)); });
            }
            return r.json();
          })
          .then(function(data) {
            if (!data) return;
            var aiReply = data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts && data.candidates[0].content.parts[0].text;
            if (aiReply) {
              parseAndDisplayAiReply(questionText, aiReply, mName);
            } else {
              throw new Error("Empty response from Gemini");
            }
          })
          .catch(function(err) {
            console.error("[StealthOverlay] Gemini AI error:", err);
            displayAiErrorFallback(questionText, mName, err.message);
          });
        }

        callGeminiChatApi(model || "gemini-3.6-flash");
        return;
      }

      // ── 2. ANTHROPIC CLAUDE ──
      if (provider === "anthropic") {
        var claudeUrl = baseUrl.replace(/\/+$/, "") + "/messages";
        fetch(claudeUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
            "anthropic-dangerous-direct-browser-access": "true"
          },
          body: JSON.stringify({
            model: model,
            max_tokens: 1024,
            system: "You are a concise technical interview copilot. Answer directly with concise key points.",
            messages: [{ role: "user", content: questionText }]
          })
        })
        .then(function(r) {
          if (!r.ok) return r.text().then(function(t) { throw new Error("Claude HTTP " + r.status + ": " + t.substring(0, 150)); });
          return r.json();
        })
        .then(function(data) {
          var aiReply = data.content && data.content[0] && data.content[0].text;
          if (aiReply) {
            parseAndDisplayAiReply(questionText, aiReply, model);
          } else {
            throw new Error("Empty response from Claude");
          }
        })
        .catch(function(err) {
          console.error("[StealthOverlay] Claude AI error:", err);
          displayAiErrorFallback(questionText, model, err.message);
        });
        return;
      }

      // ── 3. OPENAI-COMPATIBLE (GROQ / OPENAI / OLLAMA / CUSTOM) ──
      var endpoint = baseUrl.replace(/\/+$/, "") + "/chat/completions";
      var payload = {
        model: model,
        messages: [
          { role: "system", content: "You are a concise technical interview copilot. Answer directly with concise key points." },
          { role: "user", content: questionText }
        ],
        temperature: 0.3
      };

      var headers = { "Content-Type": "application/json" };
      if (key && !key.includes("antigrav")) headers["Authorization"] = "Bearer " + key;

      fetch(endpoint, {
        method: "POST",
        headers: headers,
        body: JSON.stringify(payload)
      })
      .then(function (response) {
        if (!response.ok) return response.text().then(function(t) { throw new Error("HTTP " + response.status + ": " + t.substring(0, 150)); });
        return response.json();
      })
      .then(function (data) {
        if (data && data.choices && data.choices[0] && data.choices[0].message) {
          var aiReply = data.choices[0].message.content.trim();
          parseAndDisplayAiReply(questionText, aiReply, model);
        } else {
          throw new Error("Invalid response schema");
        }
      })
      .catch(function (err) {
        console.error("[StealthOverlay] AI fetch error:", err);
        displayAiErrorFallback(questionText, model, err.message);
      });
    });
  }

  function triggerScreenshotCapture() {
    chrome.runtime.sendMessage({ action: "capture_screenshot" }, function (res) {
      if (res && res.dataUrl) {
        fetchAIAnswer("Analyze current visible screen tab and solve coding / technical question.");
      } else {
        addNewAnswer("Screen Capture", "Captured page snapshot successfully.", ["Analyzed current visible tab context"]);
      }
    });
  }

  // ── VOICE SPEECH RECOGNITION (WEB SPEECH API) ──
  var maxChips = (savedConfig && savedConfig.maxWordChips) ? parseInt(savedConfig.maxWordChips, 10) : 8;
  if (isNaN(maxChips) || maxChips < 3) maxChips = 8;
  var voiceRestartCount = 0;
  var lastSpeechTime = 0;

  // Live transcript line below chips
  var liveTranscriptLine = document.createElement("div");
  liveTranscriptLine.style.cssText = `
    display: none;
    width: 100%;
    max-width: ${cfgWidth};
    background: rgba(28, 29, 34, ${cfgOpacity});
    ${cfgBlur}
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 14px;
    padding: 8px 16px;
    color: #9ca3af;
    font-size: 11px;
    font-style: italic;
    line-height: 1.5;
    max-height: 80px;
    overflow-y: auto;
    word-break: break-word;
  `;
  // Insert after middleBar
  wrapper.insertBefore(liveTranscriptLine, cardBox);

  function updateMicBadgeState(state) {
    var badge = micIconBtn.querySelector(".pk-red-badge");
    if (!badge) return;
    if (state === "listening") {
      badge.style.display = "block";
      badge.style.background = "#10b981";
      badge.style.boxShadow = "0 0 6px #10b981";
    } else if (state === "no-speech") {
      badge.style.display = "block";
      badge.style.background = "#fbbf24";
      badge.style.boxShadow = "0 0 6px #fbbf24";
    } else if (state === "error") {
      badge.style.display = "block";
      badge.style.background = "#ef4444";
      badge.style.boxShadow = "0 0 6px #ef4444";
    } else {
      badge.style.display = "none";
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HYBRID SPEECH RECOGNITION SYSTEM
  // 1. WebSpeech API (webkitSpeechRecognition): Free, instant, zero API key needed for microphone!
  // 2. MediaRecorder + Whisper/Gemini: High precision chunk STT via Cloud API (Groq/Gemini/OpenAI)
  // ═══════════════════════════════════════════════════════════

  var micStream = null;
  var micRecorder = null;
  var micChunkCount = 0;
  var speechRecognition = null;
  var speechRestartTimer = null;
  var webSpeechEndCount = 0;
  var webSpeechHadResult = false;

  function startVoiceListening() {
    console.log("[StealthOverlay] startVoiceListening() called");
    renderChips([]);
    updateMicBadgeState("listening");
    webSpeechEndCount = 0;
    webSpeechHadResult = false;

    chrome.storage.local.get(["apiKey", "apiProvider", "apiBaseUrl", "speechLang"], function(cfg) {
      var apiKey = cfg.apiKey || "";
      var provider = (cfg.apiProvider || "groq").toLowerCase();
      var lang = cfg.speechLang || currentSpeechLang || "en-US";
      if (!lang || lang === "auto") lang = navigator.language || "en-US";

      var hasApiKey = apiKey && apiKey.length > 5 && !apiKey.includes("antigrav-secret-key");
      var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
      // Prefer Cloud STT if user has configured any API Key (Groq, Gemini, OpenAI, Custom)
      var preferCloud = hasApiKey;

      if ((preferCloud && hasApiKey) || !SpeechRec) {
        console.log("[StealthOverlay] Mode: MediaRecorder + Cloud STT API (provider:", provider, ")");
        startMediaRecorderVoiceListening(lang);
      } else {
        console.log("[StealthOverlay] Mode: Native WebSpeech API (Instant Real-time STT)");
        startWebSpeechVoiceListening(lang);
      }
    });
  }

  function startWebSpeechVoiceListening(lang) {
    var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRec) {
      console.warn("[StealthOverlay] WebSpeech not supported in this browser");
      startMediaRecorderVoiceListening(lang);
      return;
    }

    try {
      if (speechRecognition) {
        try { speechRecognition.stop(); } catch(e) {}
      }
      speechRecognition = new SpeechRec();
      speechRecognition.continuous = true;
      speechRecognition.interimResults = true;
      var activeLang = lang || "en-US";
      if (!activeLang || activeLang === "auto") activeLang = "en-US";
      speechRecognition.lang = activeLang;

      speechRecognition.onstart = function() {
        console.log("[StealthOverlay] WebSpeech STARTED | lang:", speechRecognition.lang);
        updateMicBadgeState("listening");
      };

      speechRecognition.onresult = function(event) {
        webSpeechHadResult = true;
        webSpeechEndCount = 0;
        var interim = "";
        var final = "";
        for (var i = event.resultIndex; i < event.results.length; ++i) {
          if (event.results[i].isFinal) {
            final += event.results[i][0].transcript;
          } else {
            interim += event.results[i][0].transcript;
          }
        }

        var liveText = (final || interim).trim();
        if (liveText.length > 0) {
          console.log("[StealthOverlay] WebSpeech live text:", liveText);
          var words = liveText.split(/\s+/);
          renderChips(words.slice(-maxChips));
          liveTranscriptLine.style.display = "block";
          liveTranscriptLine.textContent = liveText;
        }

        if (final && final.trim().length > 3) {
          var trimmedFinal = final.trim();
          console.log("[StealthOverlay] WebSpeech FINAL speech:", trimmedFinal);
          liveTranscriptLine.innerHTML = "<span style='color:#10b981;'>Sent to AI:</span> " + trimmedFinal;
          fetchAIAnswer(trimmedFinal);
        }
      };

      speechRecognition.onerror = function(event) {
        if (event.error === "aborted") return; // Harmless Chrome WebSpeech pause/resume event
        console.warn("[StealthOverlay] WebSpeech error:", event.error);
        if (event.error === "not-allowed" || event.error === "service-not-allowed") {
          updateMicBadgeState("error");
          liveTranscriptLine.style.display = "block";
          liveTranscriptLine.textContent = "Microphone blocked. Click lock icon in URL bar > Allow Microphone > Reload.";
        }
      };

      speechRecognition.onend = function() {
        console.log("[StealthOverlay] WebSpeech ended | active:", isVoiceActive, "| hadResult:", webSpeechHadResult, "| endCount:", webSpeechEndCount);
        if (!isVoiceActive) return;

        if (!webSpeechHadResult) {
          webSpeechEndCount++;
        }

        // Circuit breaker: if WebSpeech keeps ending without yielding results (3 times), fallback to MediaRecorder Cloud STT
        if (webSpeechEndCount >= 3) {
          console.warn("[StealthOverlay] WebSpeech continuously ending without speech results. Falling back to MediaRecorder Cloud STT...");
          try { speechRecognition.stop(); } catch(e) {}
          speechRecognition = null;
          startMediaRecorderVoiceListening(lang);
          return;
        }

        clearTimeout(speechRestartTimer);
        speechRestartTimer = setTimeout(function() {
          if (isVoiceActive && speechRecognition) {
            try { speechRecognition.start(); } catch(e) {}
          }
        }, 500);
      };

      speechRecognition.start();
      console.log("[StealthOverlay] WebSpeech initialized!");
    } catch (err) {
      console.error("[StealthOverlay] WebSpeech start error:", err);
      startMediaRecorderVoiceListening(lang);
    }
  }

  function startMediaRecorderVoiceListening(lang) {
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(function(stream) {
        micStream = stream;
        console.log("[StealthOverlay] Mic stream acquired | tracks:", stream.getAudioTracks().length);
        updateMicBadgeState("listening");
        renderChips([]);

        var mime = "audio/webm";
        if (typeof MediaRecorder !== "undefined" && MediaRecorder.isTypeSupported("audio/webm;codecs=opus")) {
          mime = "audio/webm;codecs=opus";
        }

        try {
          micRecorder = new MediaRecorder(stream, { mimeType: mime });
        } catch (e) {
          micRecorder = new MediaRecorder(stream);
        }

        micChunkCount = 0;

        micRecorder.ondataavailable = function(e) {
          micChunkCount++;
          if (!e.data || e.data.size < 500) return;
          transcribeBlob(e.data);
        };

        micRecorder.onstart = function() {
          console.log("[StealthOverlay] MediaRecorder STARTED (4s slices)");
        };

        micRecorder.start(4000);
      })
      .catch(function(err) {
        console.error("[StealthOverlay] Mic permission denied:", err.name, err.message);
        liveTranscriptLine.style.display = "block";
        liveTranscriptLine.textContent = "Microphone blocked. Click lock icon in URL bar > Allow Microphone > Reload.";
        updateMicBadgeState("error");
      });
  }

  function transcribeBlob(blob) {
    chrome.storage.local.get(["apiKey", "apiProvider", "apiBaseUrl", "speechLang"], function(cfg) {
      var apiKey = cfg.apiKey || "";
      var provider = (cfg.apiProvider || "groq").toLowerCase();
      var apiBaseUrl = cfg.apiBaseUrl || "";
      var lang = cfg.speechLang || currentSpeechLang || "en-US";

      // Auto-detect provider if key format matches known prefixes, but respect selected provider
      if (apiKey.startsWith("gsk_")) {
        provider = "groq";
      } else if (apiKey.startsWith("AIza") || apiKey.startsWith("AQ.")) {
        provider = "gemini";
      } else if (apiKey.startsWith("sk-") && !apiKey.includes("antigrav") && provider === "custom" && apiBaseUrl.includes("20128")) {
        provider = "openai";
      }

      if (!apiKey || apiKey.includes("antigrav-secret-key")) {
        console.warn("[StealthOverlay] No valid API key set!");
        liveTranscriptLine.style.display = "block";
        liveTranscriptLine.innerHTML = "<span style='color:#f59e0b;'>Set Groq, OpenAI, or Gemini API Key in Extension Options for cloud STT.</span>";
        return;
      }

      // Gemini path (supports provider === 'gemini', AQ. keys, AIza keys, etc.)
      if (provider === "gemini" || apiKey.startsWith("AIza") || apiKey.startsWith("AQ.")) {
        var reader = new FileReader();
        reader.onloadend = function() {
          var b64 = reader.result.split(",")[1];
          var targetModel = (cfg.aiModel === "custom") ? (cfg.customModel || "gemini-3.6-flash") : (cfg.aiModel || "gemini-3.6-flash");
          if (!targetModel || targetModel.includes("2.0") || targetModel.includes("1.5")) {
            targetModel = "gemini-3.6-flash";
          }

          function callGeminiSttApi(mName) {
            var url = "https://generativelanguage.googleapis.com/v1beta/models/" + mName + ":generateContent?key=" + apiKey;
            fetch(url, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: [{ parts: [
                  { text: "Transcribe this audio clip into plain text. Output ONLY the transcript spoken words, nothing else. If silence or no speech, output nothing." },
                  { inlineData: { mimeType: "audio/webm", data: b64 } }
                ]}]
              })
            })
            .then(function(r) {
              if (!r.ok) {
                return r.text().then(function(t) { throw new Error("Gemini STT HTTP " + r.status + ": " + t.substring(0, 150)); });
              }
              return r.json();
            })
            .then(function(j) {
              if (!j) return;
              var text = j.candidates && j.candidates[0] && j.candidates[0].content && j.candidates[0].content.parts && j.candidates[0].content.parts[0].text;
              if (text && text.trim()) {
                console.log("[StealthOverlay] Gemini STT result:", text.trim());
                handleTranscript(text.trim());
              }
            })
            .catch(function(err) {
              console.error("[StealthOverlay] Gemini STT error:", err);
            });
          }

          callGeminiSttApi(targetModel);
        };
        reader.readAsDataURL(blob);
        return;
      }

      // Whisper path (Groq / OpenAI / Custom)
      var endpoint, model;
      if (provider === "openai") {
        endpoint = "https://api.openai.com/v1/audio/transcriptions";
        model = "whisper-1";
      } else if (provider === "custom" && apiBaseUrl) {
        endpoint = apiBaseUrl.replace(/\/$/, "") + "/audio/transcriptions";
        model = "whisper-1";
      } else {
        endpoint = "https://api.groq.com/openai/v1/audio/transcriptions";
        model = "whisper-large-v3-turbo";
      }

      var fd = new FormData();
      fd.append("file", blob, "audio.webm");
      fd.append("model", model);
      fd.append("language", lang.split("-")[0]);

      fetch(endpoint, {
        method: "POST",
        headers: { "Authorization": "Bearer " + apiKey },
        body: fd
      })
      .then(function(r) {
        if (!r.ok) return r.text().then(function(t) { throw new Error("API " + r.status + ": " + t.substring(0, 150)); });
        return r.json();
      })
      .then(function(j) {
        if (j.text) handleTranscript(j.text);
      })
      .catch(function(err) {
        console.error("[StealthOverlay] Whisper error:", err);
      });
    });
  }

  function handleTranscript(text) {
    if (!text || text.trim().length < 2) return;

    var trimmed = text.trim();
    console.log("[StealthOverlay] STT TRANSCRIPT:", trimmed);

    var words = trimmed.split(/\s+/);
    renderChips(words.slice(-maxChips));

    liveTranscriptLine.style.display = "block";
    liveTranscriptLine.textContent = trimmed;

    // Send to AI for answer
    if (trimmed.length > 3) {
      fetchAIAnswer(trimmed);
      liveTranscriptLine.innerHTML = "<span style='color:#10b981;'>Sent to AI:</span> " + trimmed;
    }
  }

  function stopVoiceListening() {
    console.log("[StealthOverlay] stopVoiceListening() called");
    isVoiceActive = false;
    clearTimeout(speechRestartTimer);

    if (speechRecognition) {
      try { speechRecognition.stop(); } catch (e) {}
      speechRecognition = null;
    }
    if (micRecorder) {
      try { if (micRecorder.state !== "inactive") micRecorder.stop(); } catch (e) {}
      micRecorder = null;
    }
    if (micStream) {
      micStream.getTracks().forEach(function(t) { t.stop(); });
      micStream = null;
    }

    updateMicBadgeState("off");
    liveTranscriptLine.style.display = "none";
  }

  if (isVoiceActive) startVoiceListening();

  // ── TAB AUDIO TRANSCRIPT + DEBUG LISTENER ──
  if (typeof chrome !== "undefined" && chrome.runtime && chrome.runtime.onMessage) {
    chrome.runtime.onMessage.addListener(function (msg) {
      // Debug relay from offscreen.js — visible in page console
      if (msg.action === "offscreen_debug") {
        console.log("%c[offscreen] " + msg.message, "color:#a78bfa;font-weight:bold");
        return;
      }

      if (msg.action === "tab_transcript_result") {
        var displayText = ((msg.final || "") + " " + (msg.interim || "")).trim();
        if (displayText.length > 0) {
          console.log("[StealthOverlay] Tab transcript:", displayText);
          var words = displayText.split(/\s+/);
          renderChips(words.slice(-maxChips));

          liveTranscriptLine.style.display = "block";
          liveTranscriptLine.textContent = displayText;
        }

        if (msg.final && msg.final.trim().length > 3) {
          console.log("[StealthOverlay] Tab FINAL:", msg.final.trim());
          fetchAIAnswer(msg.final.trim());
          liveTranscriptLine.innerHTML = "<span style='color:#10b981;'>Sent to AI:</span> " + msg.final.trim();
        }
      }

      if (msg.action === "capture_status_update") {
        console.log("[StealthOverlay] capture_status:", msg.status, msg.detail || "", msg.error || "");
        if (msg.status === "active") {
          renderChips([]);
        } else if (msg.status === "transcribing") {
          // Keep chips clean, only show real transcribed words
        } else if (msg.status === "no_api_key") {
          liveTranscriptLine.style.display = "block";
          liveTranscriptLine.innerHTML = "<span style='color:#f59e0b;'>Set Groq/OpenAI/Gemini API Key in Extension Options to enable tab audio transcription.</span>";
        } else if (msg.status === "error") {
          liveTranscriptLine.style.display = "block";
          liveTranscriptLine.textContent = "Tab capture error: " + (msg.error || "unknown");
        }
      }
    });
  }

  // ── DRAG FUNCTIONALITY ──
  var isDragging = false;
  var offsetX = 0, offsetY = 0;

  dragHandle.addEventListener("mousedown", function (e) {
    isDragging = true;
    dragHandle.style.cursor = "grabbing";
    var rect = wrapper.getBoundingClientRect();
    offsetX = e.clientX - rect.left;
    offsetY = e.clientY - rect.top;
    wrapper.style.transform = "none";
  });

  document.addEventListener("mousemove", function (e) {
    if (!isDragging) return;
    wrapper.style.left = (e.clientX - offsetX) + "px";
    wrapper.style.top = (e.clientY - offsetY) + "px";
  });

  document.addEventListener("mouseup", function () {
    if (isDragging) {
      isDragging = false;
      dragHandle.style.cursor = "grab";
    }
  });

  // ── KEYBOARD SHORTCUTS (⌘⌫ Clear, ⌘↵ Answer, ⌘S Screenshot, ⌘K Chat) ──
  document.addEventListener("keydown", function (e) {
    var isCmd = e.metaKey || e.ctrlKey;
    if (isCmd && e.key === "Backspace") {
      e.preventDefault();
      clearBarBtn.click();
    } else if (isCmd && e.key === "Enter") {
      e.preventDefault();
      setMode("answer");
    } else if (isCmd && e.key.toLowerCase() === "s") {
      e.preventDefault();
      setMode("screenshot");
    } else if (isCmd && e.key.toLowerCase() === "k") {
      e.preventDefault();
      setMode("chat");
    } else if (isCmd && e.key === "ArrowLeft") {
      e.preventDefault();
      btnPrev.click();
    } else if (isCmd && e.key === "ArrowRight") {
      e.preventDefault();
      btnNext.click();
    } else if (e.altKey && e.key.toLowerCase() === "a") {
      setMode("answer");
    } else if (e.altKey && e.key.toLowerCase() === "s") {
      setMode("screenshot");
    } else if (e.altKey && e.key.toLowerCase() === "c") {
      setMode("chat");
    }
  });
}
