# Native learner voice: OpenAI Realtime

Conversations, curriculum realtime lessons and the live tutor now use the reference app's `gpt-realtime-2.1-mini` model through native WebRTC. The separate public landing demo and explicitly selected legacy provider checks retain Firebase Gemini Live. Text generation keeps its existing Firebase/Responses path.

The reference remains read-only at `d6c1184e056aa8a0f51a78d9a687213e1d2051db`. The target exports the actual `Conversations.jsx` language/level/goal/personality instruction builder and its pure dependencies alongside the existing original lesson policies. Explicit JSON refs supply private learner state and saved conversation messages. The manifest records the source hashes. This extends the prompt interpreter; it does not embed React, web audio or a WebView.

## Connection and controls

`RealtimeRTCTransport` creates an audio track and the source `oai-events` data channel before offering SDP. The authenticated Piyali worker exchanges the offer at OpenAI's unified `/v1/realtime/calls` endpoint and returns the SDP answer. The API key stays in Cloudflare. The route requires App Check plus the existing verified Firebase/Nostr owner, bounds requests/session fields, permits the fixed model/known voices and limits each owner to five connection attempts per minute. Upstream bodies and credentials are not returned as errors. Worker version: `b22d4248-dca4-40bc-ac14-d4707042371f`.

The implementation follows the [official Realtime WebRTC guide](https://developers.openai.com/api/docs/guides/realtime-webrtc), using its Realtime interface rather than the separate newer GPT-Live interface. The native WebRTC framework is Jitsi release `v155.0.0`, pinned to revision `9edb2100fc29f847b5d01def716a979daf397901` and its upstream package checksum. WebRTC's copyright/license and patent grant are bundled under `Resources/ThirdParty`.

Conversations creates each response explicitly with the current source instructions and final personality reminder. It uses source server VAD settings (2-second pause, 0.35 threshold, 120-ms prefix, no automatic response or interruption). Other learner lessons use automatic server responses. Muting or assistant speech disables the local track, detaches it from the sender and disables server VAD. Microphone input resumes after `output_audio_buffer.stopped`, rather than the earlier generation-complete event. Source instruction updates do not change VAD during assistant speech.

Input items and responses retain their IDs until both transcripts are available. A delayed input transcript still answers the preceding completed tutor line and produces one callback. Duplicate completion events do not add another turn. Stopped connections invalidate their callbacks and release peer/data/audio resources. A 30-second idle timeout excludes active learner speech and assistant playback. Backgrounding stops the session; temporary inactivity for microphone permission does not cancel startup.

## Verified checkpoint

- The full Core suite passes `212` checks with zero failures (189.0 seconds), followed by five affected voice checks after the final transcript-ordering and incomplete-playback fixes. Coverage includes source conversation instructions/VAD, delayed transcripts, response aliases, mute and once-only turn pairing. The source exporter also regenerates 136 prompt fixtures and compares 96 story policy results with the original modules.
- `17` backend tests pass across authentication, ownership, Responses and Realtime. New checks cover authenticated/rate-limited access, bounded audio offers, stripped session overrides, exact multipart exchange and sanitized upstream failures.
- A real native connection through the deployed Piyali worker passes in 7.3 seconds using a disposable Piyali identity: source mini model, data channel, final transcript, audio-buffer events and positive incoming RTP audio bytes. Its transceiver is receive-only, so this check captures no microphone audio. The temporary Firebase authentication account is deleted afterward.
- Five native lifecycle/controller checks pass permission denial, late permission cancellation, source personality instructions, mute/playback locks, instruction-only updates, send failure, delayed input pairing, duplicate events and callbacks after stop. Synthetic events exercise the production controller; the separate live check exercises the actual transport.

Run `python3 scripts/test-live-api.py --only realtime` with the ignored local Firebase/App Check configuration for the actual connection. `--only realtime-legacy-gemini` selects the historical Gemini lesson/provider check explicitly.

## Remaining parity work

This checkpoint establishes the default provider connection and scoped turn controls. It does not establish full Conversations or tutor parity: the Conversations form has since been replaced by the source voice-first layout and its scoped journeys ([current correction](CONVERSATIONS.md)). Live tutor layouts, advanced voice/pause/personality settings, exact narration/replay, morpheme tools and complete physical audio journeys remain. Default voice currently uses source fallback `ash`; the source's randomized preference and complete voice picker remain open. The public demo still needs its full source lifecycle and provider alignment. Stories' speech connection is separate work.

Physical microphone capture, interruption/route changes, speaker routing and device background behavior require audio interaction on an iPhone. A received RTP packet and server playback event do not prove audible device playback. The first simulator attempt encountered a stale audio-device initialization deadlock; restarting the isolated QA simulator allowed the real connection check to complete. Full functional and design parity remains in progress.


Conversations now reads WebRTC input/receiver amplitude for its native animated orb, using the original visual-only envelope. The real receive-only check passes again (6.4s), verifying positive incoming audio amplitude as well as authenticated SDP, source mini model, data-channel transcript/playback events and RTP bytes. The eight controller checks include muting, playback ducking and stale-amplitude rejection. Neither the visual meter nor this receive-only check verifies physical microphone/speaker quality; the meter does not change VAD or input gating. See [native orb and dialog scope](CONVERSATIONS.md).
