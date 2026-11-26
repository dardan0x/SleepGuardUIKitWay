# ADR 0011: Detection runs on 20 Hz samples, off the disk

- **Status:** Accepted
- **Date:** 2026-11-26
- **Task:** F13-T6, T7 (architecture review Q13, Q14, Q17, Q39)
- **Amends:** ADR 0002 (the `AudioCapture` port)

## Context

Detection's thresholds and replay fixtures assume SleepGuard's 20 Hz samples. This app fed one sample per audio buffer, about 43–47 Hz depending on the hardware, so the same sound could make a different night; the docs claimed the same samples. A call stopped the engine and sent nothing, so the time without a microphone counted as quiet sleep; an interruption that ended without `.shouldResume` never resumed. The FFT ran on every buffer though only the raw log uses its score. Checkpoints (the whole night as JSON) and raw-log batches were written while the sample path waited.

## Decision

- The capture stream carries `CaptureEvent`: `.sample` per buffer, `.interrupted`, `.resumed`. Rate stays the adapter's business.
- `RecordingSession` decimates readings to 20 Hz with SleepCore's `SampleDecimator` (latest value per window, on a time grid) and sends `captureDidPause` / `captureDidResume` into the engine, which records an interruption gap the score leaves out. The grid restarts after a resume.
- The adapter reports interruptions, resumes when one ends with or without `.shouldResume`, and after a media-services reset; the FFT runs only when the raw recording is kept; the thermal state is logged.
- Disk writes leave the sample path: checkpoints go to a latest-wins writer task, raw-log batches to a serial one, both owned by the session; `stop` drains them before its final save.

## Consequences

**Better:** the same sound gives the same events in both apps (43 Hz and 47 Hz input are tested to give the same night); a call is a gap, not sleep; a slow disk can't stall detection or queue stale nights.

**Limits, honestly:**
- A resume that fails is retried only at the next route, configuration or media-services event; there is no foreground retry (SleepAudio doesn't import UIKit). A real night on a device has to show whether that's enough.
- Thermal state is only logged; nothing changes behaviour on it.

## Alternatives

- **Decimate in the adapter:** the tap thread would hold decimator state under its lock, and fakes would bypass the rule.
- **A timer loop (SleepGuard's old 50 ms sleep):** drifts to about 54 ms with the work in between.
