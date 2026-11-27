# ADR 0013: The adapters' behaviour lives in the shared repo

- **Status:** Accepted
- **Date:** 2026-11-26
- **Tasks:** F13-T18 (shared 0.34.0), F13-T19 (0.35.0), F13-T20 (0.36.0), F13-T21

## Context

This app and SleepGuard record the same night. The rules, the score, the strings and the screen layouts were already shared (ADR 0004, 0005). The behaviour behind the ports was not:
- logging
- the live sample classification
- sample nights
- the file layout and the profile, survey and checkpoint files
- storage cleanup and the start notification
- the AVFoundation audio stack (capture, compression, playback, waveform, melodies)
- the SwiftData records

SleepGuard had its own copy of each. Its audio copy had four bugs this app's didn't have. The owner asked to uniform the two apps as far as possible.

## Decision

The adapters' implementations move to SleepGuardShared, mostly as this app wrote them. The ports, the use cases, the composition and the brands stay here.

| Release | Shared now | Here |
|---|---|---|
| 0.34.0 | `SleepLogging`; `LiveSampleClassifier`; `SampleNights`; `RawRecording`, `NightFiles`, `StorageSweep`; `StorageLocation`, `ClipFolder`, `NightCheckpoint`, `ProfileFile`, `LifestyleLogFile`; `StartNotification` | The file stores wrap the shared files behind the same ports; `EnforceStorageLimits` decides with `StorageSweep` |
| 0.35.0 | `SleepAudioKit` (from `SleepAudio`): `CaptureEngine`, `ClipCompressor`, `ClipPlayerEngine`, `ClipWaveform`, `MelodyPlayback`, `MelodyRecording`, `MelodyFiles`, `SampleClip`, plus SleepGuard's `ClipSpectrum` and `ClipExtractor`; `CaptureSample` / `CaptureEvent` in SleepCore | `SleepAudio` is the factories and `KitConformances.swift`: the kit's types conform to the unchanged ports |
| 0.36.0 | `SleepStore`: the records (this app's shape), mapping, schema, safe opening | `SwiftDataSessionStore`, its actor, the port and its contract |

Both apps use one file layout in the app group: `Nights.store`, `Clips/`, `Melodies/`, `Profile.json`, `LifestyleLogs.json`, `Recording.json`.

## Consequences

- An audio, file or storage fix is made once, in the shared repo, and reaches SleepGuard too. SleepGuard's four audio bugs went away by using this app's code.
- The concurrency escape hatch (the tap's lock) is now in the shared repo, so this repo has no allow-listed exception left.
- The records are public in the shared package. Here, only the repository actor touches them, as before.
- Event records gained SleepGuard's spectral fields; this app stores 0 in them.
- Honest limits:
  - The audio code is checked by unit tests on the simulator. A device night with the shared kit is still owed.
  - A change here now needs a shared release and a bump in both apps.
  - A breaking schema change is a migration both apps take.

## Alternatives

- **Share the ports too:** rejected. They are this app's hexagonal boundary (ADR 0002); SleepGuard has its own protocols, DI and isolation.
- **Keep the adapters here and copy them into SleepGuard:** rejected. Two copies is the problem this solves.
