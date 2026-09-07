document.addEventListener("DOMContentLoaded", function () {
  // API & AI Configuration
  var apiProvider = document.getElementById("apiProvider");
  var apiBaseUrl = document.getElementById("apiBaseUrl");
  var apiKey = document.getElementById("apiKey");
  var toggleApiKey = document.getElementById("toggleApiKey");
  var aiModel = document.getElementById("aiModel");
  var customModel = document.getElementById("customModel");

  // Overlay & Stealth
  var overlayOpacity = document.getElementById("overlayOpacity");
  var overlayWidth = document.getElementById("overlayWidth");
  var stealthDefense = document.getElementById("stealthDefense");
  var backdropBlur = document.getElementById("backdropBlur");

  // Voice & Speech
  var speechLang = document.getElementById("speechLang");
  var autoStartMic = document.getElementById("autoStartMic");
  var maxWordChips = document.getElementById("maxWordChips");

  // Desktop App Integration
  var desktopEndpoint = document.getElementById("desktopEndpoint");
  var syncDesktop = document.getElementById("syncDesktop");
  var connectionBadge = document.getElementById("connectionBadge");
  var testConnBtn = document.getElementById("testConnBtn");

  // Buttons & Toast
  var saveBtn = document.getElementById("saveBtn");
  var resetBtn = document.getElementById("resetBtn");
  var toast = document.getElementById("toast");

  // Vector SVG Icons for eye toggle
  var SVG_EYE = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
  var SVG_EYE_OFF = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>';

  // Eye button toggle for API Key
  toggleApiKey.addEventListener("click", function () {
    if (apiKey.type === "password") {
      apiKey.type = "text";
      toggleApiKey.innerHTML = SVG_EYE_OFF;
    } else {
      apiKey.type = "password";
      toggleApiKey.innerHTML = SVG_EYE;
    }
  });

  // Standard provider defaults (Base URL & Models)
  var PROVIDER_DEFAULTS = {
    groq: { url: "https://api.groq.com/openai/v1", defaultModel: "llama-3.3-70b-versatile" },
    openai: { url: "https://api.openai.com/v1", defaultModel: "gpt-4o" },
    gemini: { url: "https://generativelanguage.googleapis.com", defaultModel: "gemini-3.6-flash" },
    anthropic: { url: "https://api.anthropic.com/v1", defaultModel: "claude-3-5-sonnet-20241022" },
    ollama: { url: "http://localhost:11434/v1", defaultModel: "llama3.2" },
    custom: { url: "http://localhost:20128/v1", defaultModel: "custom" }
  };

  var PROVIDER_MODELS = {
    groq: [
      { value: "llama-3.3-70b-versatile", text: "llama-3.3-70b-versatile (Groq Default)" },
      { value: "llama-3.1-8b-instant", text: "llama-3.1-8b-instant (Ultra Fast)" },
      { value: "mixtral-8x7b-32768", text: "mixtral-8x7b-32768 (High Context)" },
      { value: "deepseek-r1-distill-llama-70b", text: "deepseek-r1-distill-llama-70b (DeepSeek R1)" },
      { value: "custom", text: "Custom Model Name..." }
    ],
    openai: [
      { value: "gpt-4o", text: "gpt-4o (Omni Flagship)" },
      { value: "gpt-4o-mini", text: "gpt-4o-mini (Fast & Cheap)" },
      { value: "o3-mini", text: "o3-mini (Reasoning)" },
      { value: "o1", text: "o1 (Advanced Reasoning)" },
      { value: "custom", text: "Custom Model Name..." }
    ],
    gemini: [
      { value: "gemini-3.6-flash", text: "Gemini 3.6 Flash (Free & Recommended)" },
      { value: "gemini-3.5-flash", text: "Gemini 3.5 Flash (Free Tier)" },
      { value: "gemini-3.5-flash-lite", text: "Gemini 3.5 Flash-Lite (Free Tier)" },
      { value: "gemini-flash-latest", text: "Gemini Flash Latest (Auto Free)" },
      { value: "custom", text: "Custom Model Name..." }
    ],
    anthropic: [
      { value: "claude-3-5-sonnet-20241022", text: "claude-3-5-sonnet-20241022 (Flagship)" },
      { value: "claude-3-5-haiku-20241022", text: "claude-3-5-haiku-20241022 (Fast)" },
      { value: "claude-3-opus-20240229", text: "claude-3-opus-20240229 (Opus)" },
      { value: "custom", text: "Custom Model Name..." }
    ],
    ollama: [
      { value: "llama3.2", text: "llama3.2 (Ollama Default)" },
      { value: "llama3.1", text: "llama3.1 (Ollama 8B)" },
      { value: "deepseek-r1:8b", text: "deepseek-r1:8b (DeepSeek Local)" },
      { value: "mistral", text: "mistral (Mistral 7B)" },
      { value: "custom", text: "Custom Model Name..." }
    ],
    custom: [
      { value: "custom", text: "Custom Model Name..." }
    ]
  };

  function updateModelDropdown(provider, selectedModel) {
    aiModel.innerHTML = "";
    var list = PROVIDER_MODELS[provider] || PROVIDER_MODELS.custom;
    list.forEach(function (m) {
      var opt = document.createElement("option");
      opt.value = m.value;
      opt.textContent = m.text;
      aiModel.appendChild(opt);
    });

    if (selectedModel && list.some(function(i) { return i.value === selectedModel; })) {
      aiModel.value = selectedModel;
    } else if (list.length > 0) {
      aiModel.value = list[0].value;
    }

    updateCustomModelRowVisibility();
  }

  function updateCustomModelRowVisibility() {
    var customRow = document.getElementById("customModelRow");
    if (!customRow) return;
    if (aiModel.value === "custom" || apiProvider.value === "custom") {
      customRow.style.display = "flex";
    } else {
      customRow.style.display = "none";
    }
  }

  // Auto-switch Base URL and Model dropdown when Provider changes
  apiProvider.addEventListener("change", function () {
    var p = apiProvider.value;
    if (PROVIDER_DEFAULTS[p]) {
      apiBaseUrl.value = PROVIDER_DEFAULTS[p].url;
    }
    updateModelDropdown(p, PROVIDER_DEFAULTS[p] ? PROVIDER_DEFAULTS[p].defaultModel : null);
  });

  aiModel.addEventListener("change", function () {
    updateCustomModelRowVisibility();
  });

  // Test Connection Ping to Desktop Server
  function testDesktopConnection() {
    if (!syncDesktop.checked) {
      connectionBadge.className = "status-badge disabled";
      connectionBadge.textContent = "● Sync Disabled";
      return;
    }

    var endpoint = desktopEndpoint.value.trim() || "http://127.0.0.1:8765";
    connectionBadge.className = "status-badge";
    connectionBadge.textContent = "● Testing...";
    connectionBadge.style.color = "#fbbf24";

    fetch(endpoint + "/api/status", { method: "GET" })
      .then(function (res) {
        if (res.ok) {
          connectionBadge.className = "status-badge connected";
          connectionBadge.textContent = "● App Connected";
        } else {
          return fetch(endpoint + "/api/health", { method: "GET" }).then(function(res2) {
            if (res2.ok) {
              connectionBadge.className = "status-badge connected";
              connectionBadge.textContent = "● App Connected";
            } else {
              throw new Error("HTTP " + res2.status);
            }
          });
        }
      })
      .catch(function () {
        connectionBadge.className = "status-badge standalone";
        connectionBadge.textContent = "● Standalone Active (App Not Running)";
      });
  }

  testConnBtn.addEventListener("click", testDesktopConnection);

  syncDesktop.addEventListener("change", function () {
    if (!syncDesktop.checked) {
      connectionBadge.className = "status-badge disabled";
      connectionBadge.textContent = "● Sync Disabled";
    } else {
      testDesktopConnection();
    }
  });

  // Load saved settings from chrome.storage.local
  function loadSettings() {
    chrome.storage.local.get([
      "apiProvider", "apiBaseUrl", "apiKey", "aiModel", "customModel",
      "overlayOpacity", "overlayWidth", "stealthDefense", "backdropBlur",
      "speechLang", "autoStartMic", "maxWordChips",
      "desktopEndpoint", "syncDesktop"
    ], function (res) {
      var provider = res.apiProvider || "groq";
      apiProvider.value = provider;
      if (res.apiBaseUrl) apiBaseUrl.value = res.apiBaseUrl;
      if (res.apiKey) apiKey.value = res.apiKey;
      if (res.customModel) customModel.value = res.customModel;

      updateModelDropdown(provider, res.aiModel);

      if (res.overlayOpacity) overlayOpacity.value = res.overlayOpacity;
      if (res.overlayWidth) overlayWidth.value = res.overlayWidth;
      stealthDefense.checked = res.stealthDefense !== false;
      backdropBlur.checked = res.backdropBlur !== false;

      if (res.speechLang) speechLang.value = res.speechLang;
      autoStartMic.checked = res.autoStartMic !== false;
      if (res.maxWordChips) maxWordChips.value = res.maxWordChips;

      if (res.desktopEndpoint) desktopEndpoint.value = res.desktopEndpoint;
      syncDesktop.checked = res.syncDesktop !== false;

      // Auto test connection on page load
      testDesktopConnection();
    });
  }

  loadSettings();

  // Save settings
  saveBtn.addEventListener("click", function () {
    var settings = {
      apiProvider: apiProvider.value,
      apiBaseUrl: apiBaseUrl.value,
      apiKey: apiKey.value,
      aiModel: aiModel.value,
      customModel: customModel.value,

      overlayOpacity: overlayOpacity.value,
      overlayWidth: overlayWidth.value,
      stealthDefense: stealthDefense.checked,
      backdropBlur: backdropBlur.checked,

      speechLang: speechLang.value,
      autoStartMic: autoStartMic.checked,
      maxWordChips: parseInt(maxWordChips.value, 10) || 6,

      desktopEndpoint: desktopEndpoint.value,
      syncDesktop: syncDesktop.checked
    };

    chrome.storage.local.set(settings, function () {
      toast.textContent = "Settings saved successfully!";
      toast.style.display = "block";
      setTimeout(function () { toast.style.display = "none"; }, 2000);
    });
  });

  // Reset settings
  resetBtn.addEventListener("click", function () {
    if (confirm("Reset all settings to default project values?")) {
      chrome.storage.local.remove([
        "apiProvider", "apiBaseUrl", "apiKey", "aiModel", "customModel",
        "overlayOpacity", "overlayWidth", "stealthDefense", "backdropBlur",
        "speechLang", "autoStartMic", "maxWordChips",
        "desktopEndpoint", "syncDesktop"
      ], function () {
        loadSettings();
        toast.textContent = "Settings reset to project defaults!";
        toast.style.display = "block";
        setTimeout(function () {
          toast.style.display = "none";
        }, 2000);
      });
    }
  });
});
