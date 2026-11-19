(function(){const clamp = (value, min, max) => Math.min(max, Math.max(min, value));const smooth = (value) => { const t = clamp(value, 0, 1); return t * t * (3 - 2 * t); };const PLAYGROUND_REACTION_DURATIONS={"boop":1.4,"wave":2.3,"bounce":2.2,"spin":2.4,"celebrate":3.4,"wiggle":2.2,"twirl":2.8,"shimmy":2.4,"flip":2.2,"groove":2.6,"snooze":3,"float":3.2,"nod":1.8,"shake":1.6,"bow":2.5,"heartbeat":2.4,"orbit":3.2,"peek":2.4,"jiggle":2,"dizzy":2.8,"blastoff":3.6};function playgroundReactionPose(kind, elapsed, amount = 1) {
  const pose = { y: 0, x: 0, squash: 0, roll: 0, turn: 0, pitch: 0, burst: 0 };
  const duration = PLAYGROUND_REACTION_DURATIONS[kind];
  if (!duration || elapsed < 0 || elapsed >= duration) return pose;
  const t = elapsed;
  const envelope = Math.sin(Math.PI * t / duration) ** 2;
  const tail = clamp((t - duration + 0.65) / 0.65, 0, 1);
  const settle = 1 - tail ** 3 * (tail * (tail * 6 - 15) + 10);

  if (kind === "boop") {
    pose.squash = Math.sin(t * 15) * Math.exp(-t * 4.2) * 0.24;
    pose.pitch = -Math.sin(t * 7) * Math.exp(-t * 3) * 0.18;
    pose.roll = Math.sin(t * 13) * Math.exp(-t * 4) * 0.09;
  } else if (kind === "wave") {
    pose.roll = Math.sin(t * 9) * envelope * 0.26;
    pose.x = Math.sin(t * 4.5) * envelope * 0.12;
    pose.y = envelope * 0.1;
  } else if (kind === "bounce") {
    if (t < 0.22) pose.squash = Math.sin(t / 0.22 * Math.PI) * 0.23;
    else {
      const b = t - 0.22;
      pose.y = Math.abs(Math.sin(b * 5.5)) * Math.exp(-b * 1.6) * 1.0;
      pose.squash = -Math.sin(b * 11) * Math.exp(-b * 1.7) * 0.16;
      pose.roll = Math.sin(b * 5.5) * Math.exp(-b * 1.7) * 0.12;
    }
  } else if (kind === "spin") {
    pose.turn = Math.PI * 2 * smooth((t - 0.2) / 1.8);
    pose.squash = Math.sin(t * 6) * envelope * 0.1;
    pose.y = envelope * 0.26;
    pose.roll = envelope * 0.16;
  } else if (kind === "celebrate") {
    pose.y = Math.abs(Math.sin(t * 6)) * envelope * 0.43;
    pose.roll = Math.sin(t * 8) * envelope * 0.25;
    pose.x = Math.sin(t * 4) * envelope * 0.17;
    pose.squash = Math.sin(t * 12) * envelope * 0.11;
    pose.burst = envelope;
  } else if (kind === "wiggle") {
    pose.roll = Math.sin(t * 18) * envelope * 0.22;
    pose.x = Math.sin(t * 12) * envelope * 0.15;
    pose.squash = Math.sin(t * 16) * envelope * 0.08;
    pose.y = envelope * 0.12;
  } else if (kind === "twirl") {
    pose.turn = Math.PI * 4 * smooth((t - 0.2) / 2.2);
    pose.y = Math.sin(Math.PI * t / duration) * 0.45;
    pose.squash = Math.sin(t * 8) * envelope * 0.12;
    pose.roll = Math.sin(t * 6) * envelope * 0.14;
  } else if (kind === "shimmy") {
    pose.roll = Math.sin(t * 14) * envelope * 0.18;
    pose.squash = Math.sin(t * 14 + Math.PI / 2) * envelope * 0.14;
    pose.x = Math.cos(t * 7) * envelope * 0.11;
    pose.y = Math.abs(Math.sin(t * 7)) * envelope * 0.18;
  } else if (kind === "flip") {
    pose.pitch = Math.PI * 2 * smooth((t - 0.15) / 1.7);
    pose.y = Math.sin(Math.PI * t / duration) * 0.58;
    pose.squash = (t < 0.2 ? Math.sin(t / 0.2 * Math.PI) * 0.2 : -Math.sin(t * 8) * 0.12) * envelope;
  } else if (kind === "groove") {
    pose.pitch = Math.sin(t * 10) * envelope * 0.18;
    pose.y = Math.abs(Math.sin(t * 10)) * envelope * 0.18;
    pose.roll = Math.sin(t * 5) * envelope * 0.15;
    pose.squash = -Math.sin(t * 10) * envelope * 0.10;
  } else if (kind === "snooze") {
    pose.y = -envelope * 0.16;
    pose.pitch = envelope * 0.14;
    pose.squash = envelope * 0.09;
    pose.roll = Math.sin(t * 2) * envelope * 0.05;
  } else if (kind === "float") {
    pose.y = Math.sin(t * 3.5) * envelope * 0.35;
    pose.roll = Math.sin(t * 2.5) * envelope * 0.12;
    pose.turn = Math.sin(t * 2.0) * envelope * 0.25;
    pose.x = Math.cos(t * 2.0) * envelope * 0.12;
  } else if (kind === "nod") {
    pose.pitch = Math.sin(t * 14) * envelope * 0.24;
    pose.y = Math.abs(Math.sin(t * 14)) * envelope * 0.09;
    pose.squash = Math.sin(t * 14) * envelope * 0.07;
  } else if (kind === "shake") {
    pose.roll = Math.sin(t * 36) * envelope * 0.16;
    pose.squash = Math.sin(t * 30) * envelope * 0.12;
    pose.x = Math.sin(t * 24) * envelope * 0.08;
  } else if (kind === "bow") {
    const bowCurve = Math.sin(Math.PI * t / duration);
    pose.pitch = bowCurve * 0.32;
    pose.y = -bowCurve * 0.16;
    pose.squash = bowCurve * 0.06;
  } else if (kind === "heartbeat") {
    const beat = Math.abs(Math.sin(t * 10)) * Math.exp(-((t % 0.6) * 4));
    pose.squash = -beat * envelope * 0.22;
    pose.y = beat * envelope * 0.16;
    pose.burst = envelope * 0.85;
  } else if (kind === "orbit") {
    const phase = t / duration * Math.PI * 2;
    pose.x = Math.sin(phase) * 0.34 * envelope;
    pose.y = Math.sin(phase * 2) * 0.12 * envelope;
    pose.turn = Math.sin(phase) * 0.45 * envelope;
    pose.roll = Math.cos(phase) * 0.14 * envelope;
  } else if (kind === "peek") {
    const duckTime = duration * 0.38;
    if (t < duckTime) {
      pose.y = -Math.sin(t / duckTime * Math.PI) * 0.36;
      pose.squash = Math.sin(t / duckTime * Math.PI) * 0.15;
    } else {
      const popT = (t - duckTime) / (duration - duckTime);
      pose.y = Math.sin(popT * Math.PI) * 0.22 * settle;
      pose.squash = -Math.sin(popT * Math.PI) * 0.12 * settle;
    }
  } else if (kind === "jiggle") {
    pose.squash = Math.sin(t * 22) * Math.exp(-t * 2.2) * 0.25;
    pose.roll = Math.sin(t * 18) * Math.exp(-t * 2.5) * 0.14;
    pose.y = Math.abs(Math.sin(t * 11)) * Math.exp(-t * 2.0) * 0.18;
  } else if (kind === "dizzy") {
    pose.turn = Math.sin(t * 7) * envelope * 1.5;
    pose.roll = Math.sin(t * 7 + Math.PI / 4) * envelope * 0.28;
    pose.pitch = Math.cos(t * 7) * envelope * 0.18;
    pose.squash = Math.sin(t * 14) * envelope * 0.09;
  } else if (kind === "blastoff") {
    if (t < 0.9) {
      pose.squash = (t / 0.9) * 0.24;
      pose.x = Math.sin(t * 40) * 0.05 * (t / 0.9);
      pose.y = -(t / 0.9) * 0.12;
    } else {
      const flyT = (t - 0.9) / (duration - 0.9);
      pose.y = (Math.sin(flyT * Math.PI) * 1.05) * settle;
      pose.squash = -Math.sin(flyT * Math.PI) * 0.18 * settle;
      pose.burst = Math.sin(flyT * Math.PI) * 1.2;
    }
  }

  for (const key of Object.keys(pose)) {
    if ((key === "turn" && (kind === "spin" || kind === "twirl")) || (key === "pitch" && kind === "flip")) {
      pose[key] *= amount > 0 ? 1 : 0;
    } else {
      pose[key] *= clamp(amount, 0, 1.5) * settle;
    }
  }
  return pose;
};function simulatedVoiceLevel(time) {
  return clamp((Math.sin(time * 8.7) * 0.3 + Math.sin(time * 13.1) * 0.2 + 0.48) * (0.6 + Math.sin(time * 2.1) * 0.4), 0, 1);
};return{voiceLevel:simulatedVoiceLevel,run(json){const p=JSON.parse(json);return JSON.stringify(playgroundReactionPose(p.kind,p.elapsed,p.amount))}}})()