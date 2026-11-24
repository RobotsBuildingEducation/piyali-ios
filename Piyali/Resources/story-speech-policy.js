(()=>{const DEFAULT_VOICE_PAUSE_MS=1200;function options(p){const currentSentence={tgt:p.target||''},currentTurn={target:p.target||''},targetLang=p.language,awaitingSpeech=!!p.awaiting,user=p.user||null,pauseMs=user?.progress?.pauseMs ?? DEFAULT_VOICE_PAUSE_MS;const value=p.mode==='speaking'?({targetText: currentSentence?.tgt || "",targetLang,timeoutMs: pauseMs}):({targetText: awaitingSpeech ? currentTurn?.target : "",transcriptionHint: awaitingSpeech ? currentTurn?.target : "",targetLang});return{options:value,capture:{targetLang:value.targetLang??"es",transcriptionHint:value.transcriptionHint??"",timeoutMs:value.timeoutMs??15000}}}function result(p){const finalTranscript=String(p.transcript||'').trim();return {
          recognizedText: finalTranscript,
          confidence: finalTranscript ? 0.9 : 0, // Whisper is generally high confidence
          audioMetrics: null,
          method: "realtime-whisper",
        }}return{run(op,json){const p=JSON.parse(json);return JSON.stringify(op==='result'?result(p):options(p))}}})()
