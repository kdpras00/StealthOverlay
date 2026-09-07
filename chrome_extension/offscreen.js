// offscreen.js — Tab audio capture + MediaRecorder + Whisper/Gemini STT
// All diagnostic logs relay to page console via background.js debug_log

var audioStream = null;
var audioCtx = null;
var mediaRecorder = null;
var checkInterval = null;
var captureTabId = null;
var recognitionLang = "id-ID";
var configApiKey = "";
var configApiProvider = "groq";
var configApiBaseUrl = "";

// Relay log to page console via background → content script
function debugLog(msg) {
  console.log("[offscreen]", msg);
  try {
    chrome.runtime.sendMessage({
      action: "debug_log",
      tabId: captureTabId,
      message: msg
    });
  } catch (e) {}
}

chrome.runtime.onMessage.addListener(function (msg, sender, sendResponse) {
  if (msg.target !== "offscreen") return;

  if (msg.action === "start_capture") {
    startCapture(msg.streamId, msg.tabId, msg.lang, msg.apiKey, msg.apiProvider, msg.apiBaseUrl);
    sendResponse({ status: "ok" });
  } else if (msg.action === "stop_capture") {
    stopCapture();
    sendResponse({ status: "ok" });
  }
  return true;
});

function startCapture(streamId, tabId, lang, apiKey, apiProvider, apiBaseUrl) {
  stopCapture();

  captureTabId = tabId;
  recognitionLang = lang || "id-ID";
  configApiKey = apiKey || "";
  configApiProvider = apiProvider || "groq";
  configApiBaseUrl = apiBaseUrl || "";

  debugLog("Starting capture | tab=" + tabId + " | provider=" + configApiProvider + " | hasKey=" + (configApiKey.length > 0) + " | keyLen=" + configApiKey.length);

  navigator.mediaDevices
    .getUserMedia({
      audio: {
        mandatory: {
          chromeMediaSource: "tab",
          chromeMediaSourceId: streamId,
        },
      },
    })
    .then(function (stream) {
      audioStream = stream;
      debugLog("Got tab audio stream | tracks=" + stream.getAudioTracks().length);

      audioCtx = new AudioContext();
      var source = audioCtx.createMediaStreamSource(stream);

      // Route tab audio to speakers (user hears interviewer)
      source.connect(audioCtx.destination);

      // VAD analyser
      var analyser = audioCtx.createAnalyser();
      analyser.fftSize = 512;
      source.connect(analyser);

      debugLog("AudioContext ready | sampleRate=" + audioCtx.sampleRate);

      // Notify overlay
      chrome.runtime.sendMessage({
        action: "capture_status",
        status: "active",
        tabId: tabId,
      });

      // Start recording chunks
      startChunkRecorder(stream, analyser, tabId);
    })
    .catch(function (err) {
      debugLog("CAPTURE FAILED: " + err.message);
      chrome.runtime.sendMessage({
        action: "capture_status",
        status: "error",
        error: err.message,
        tabId: tabId,
      });
    });
}

function startChunkRecorder(stream, analyser, tabId) {
  var dataArray = new Uint8Array(analyser.frequencyBinCount);
  var maxVol = 0;
  var chunkCount = 0;

  // Poll volume every 200ms
  checkInterval = setInterval(function () {
    if (!analyser) return;
    analyser.getByteFrequencyData(dataArray);
    var sum = 0;
    for (var i = 0; i < dataArray.length; i++) sum += dataArray[i];
    var avg = sum / dataArray.length;
    if (avg > maxVol) maxVol = avg;
  }, 200);

  // Pick best supported mime
  var mime = "audio/webm";
  if (typeof MediaRecorder !== "undefined" && MediaRecorder.isTypeSupported("audio/webm;codecs=opus")) {
    mime = "audio/webm;codecs=opus";
  }
  debugLog("MediaRecorder mime=" + mime);

  try {
    mediaRecorder = new MediaRecorder(stream, { mimeType: mime });
  } catch (e) {
    debugLog("MediaRecorder fallback: " + e.message);
    mediaRecorder = new MediaRecorder(stream);
  }

  mediaRecorder.ondataavailable = async function (e) {
    chunkCount++;
    var peakVol = maxVol;
    maxVol = 0;

    debugLog("Chunk #" + chunkCount + " | size=" + (e.data ? e.data.size : 0) + " bytes | peakVol=" + peakVol.toFixed(1));

    if (!e.data || e.data.size < 500) {
      debugLog("Chunk too small, skipping");
      return;
    }

    // ALWAYS try to transcribe (skip VAD for now to debug)
    chrome.runtime.sendMessage({
      action: "capture_status",
      status: "transcribing",
      tabId: tabId,
      detail: "chunk #" + chunkCount + " vol=" + peakVol.toFixed(1)
    });

    try {
      var text = await transcribeAudioBlob(e.data);
      if (text && text.trim().length > 1) {
        debugLog("STT RESULT: " + JSON.stringify(text.trim()));
        chrome.runtime.sendMessage({
          action: "tab_transcript",
          tabId: tabId,
          interim: "",
          final: text.trim()
        });
      } else {
        debugLog("STT empty result (silence or unrecognized speech)");
      }
    } catch (err) {
      debugLog("Transcribe ERROR: " + err.message);
    }
  };

  mediaRecorder.onerror = function (e) {
    debugLog("MediaRecorder ERROR: " + (e.error ? e.error.message : "unknown"));
  };

  mediaRecorder.onstart = function () {
    debugLog("MediaRecorder STARTED (slicing every 4s)");
  };

  // Slice every 4 seconds
  mediaRecorder.start(4000);
}

async function transcribeAudioBlob(blob) {
  debugLog("Transcribing blob size=" + blob.size + " type=" + blob.type);

  // Option A: Local server
  try {
    var fd = new FormData();
    fd.append("file", blob, "audio.webm");
    fd.append("language", recognitionLang || "id");
    var r = await fetch("http://127.0.0.1:8765/api/transcribe", { method: "POST", body: fd });
    if (r.ok) {
      var j = await r.json();
      if (j.text) { debugLog("Local STT ok: " + j.text); return j.text; }
    }
  } catch (e) {
    // Local not available, continue to cloud
  }

  // Option B: Cloud API
  if (!configApiKey) {
    debugLog("NO API KEY! Set Groq/OpenAI/Gemini key in Extension Options");
    chrome.runtime.sendMessage({
      action: "capture_status",
      status: "no_api_key",
      tabId: captureTabId
    });
    return null;
  }

  var provider = (configApiProvider || "groq").toLowerCase();
  debugLog("Using cloud STT provider=" + provider);

  // Gemini
  if (provider === "gemini" || configApiKey.startsWith("AIza") || configApiKey.startsWith("AQ.")) {
    return await transcribeGemini(blob);
  }

  // Groq / OpenAI / Custom Whisper
  var endpoint, model;
  if (provider === "openai") {
    endpoint = "https://api.openai.com/v1/audio/transcriptions";
    model = "whisper-1";
  } else if (provider === "custom" && configApiBaseUrl) {
    endpoint = configApiBaseUrl.replace(/\/$/, "") + "/audio/transcriptions";
    model = "whisper-1";
  } else {
    // Default: Groq
    endpoint = "https://api.groq.com/openai/v1/audio/transcriptions";
    model = "whisper-large-v3-turbo";
  }

  debugLog("Whisper API endpoint=" + endpoint + " model=" + model);

  var fd2 = new FormData();
  fd2.append("file", blob, "audio.webm");
  fd2.append("model", model);
  if (recognitionLang) fd2.append("language", recognitionLang.split("-")[0]);

  var res = await fetch(endpoint, {
    method: "POST",
    headers: { "Authorization": "Bearer " + configApiKey },
    body: fd2
  });

  if (!res.ok) {
    var errBody = await res.text();
    debugLog("Whisper API ERROR " + res.status + ": " + errBody.substring(0, 200));
    return null;
  }

  var json = await res.json();
  debugLog("Whisper API OK: " + JSON.stringify(json.text || "").substring(0, 100));
  return json.text || "";
}

async function transcribeGemini(blob) {
  return new Promise(function (resolve) {
    var reader = new FileReader();
    reader.onloadend = async function () {
      try {
        var b64 = reader.result.split(",")[1];
        debugLog("Gemini STT | b64 len=" + b64.length);
        var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + configApiKey;
        var res = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{
              parts: [
                { text: "Transcribe this audio clip into plain text. Output ONLY the transcript, nothing else." },
                { inlineData: { mimeType: "audio/webm", data: b64 } }
              ]
            }]
          })
        });
        if (res.ok) {
          var j = await res.json();
          var t = j.candidates && j.candidates[0] && j.candidates[0].content && j.candidates[0].content.parts && j.candidates[0].content.parts[0].text;
          debugLog("Gemini STT result: " + (t || "(empty)"));
          resolve(t || "");
        } else {
          var err = await res.text();
          debugLog("Gemini STT error " + res.status + ": " + err.substring(0, 200));
          resolve("");
        }
      } catch (e) {
        debugLog("Gemini STT exception: " + e.message);
        resolve("");
      }
    };
    reader.readAsDataURL(blob);
  });
}

function stopCapture() {
  debugLog("Stopping capture");
  captureTabId = null;

  if (checkInterval) { clearInterval(checkInterval); checkInterval = null; }
  if (mediaRecorder) {
    try { if (mediaRecorder.state !== "inactive") mediaRecorder.stop(); } catch (e) {}
    mediaRecorder = null;
  }
  if (audioStream) {
    audioStream.getTracks().forEach(function (t) { t.stop(); });
    audioStream = null;
  }
  if (audioCtx) {
    audioCtx.close().catch(function () {});
    audioCtx = null;
  }
}
