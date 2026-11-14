
### Completed
- F0-T6: night entities and rules moved from `SleepDomain` to `SleepCore` (shared), renamed `Night`, `NightEvent`, `NightEpisode`, `NightSummary`. `SleepDomain` keeps ports, use cases, `SessionDetail` and fakes. SleepGuard now calls the same rules.

### Technical Details
- Renames applied across `SleepDomain`, `SleepPersistence` (record mapping property `session` → `night`, to stop it reading like `EventRecord.session`), `AppShell` sample nights and all tests. Test fixture namespace `Night` → `Sample`.
- `NightEpisode` instead of `SnoringEpisode` in the shared repo: SleepGuard already has a `SnoringEpisode` struct.
- Verification against the unreleased shared code: manifests temporarily pointed at `../SleepGuardShared` for the test runs, then restored (with the lockfiles).

### Build Status
- Shared: 72 `SleepCoreTests` pass.
- This app: domain 10, adapters 9, ScreenKit 11, shell 13, hosted 5 × 3 brands; checks pass.
- SleepGuard: all 8 suites pass, no test changed; app builds.
- Needs shared `0.4.0` before either app's CI passes.

### Next Session
- F3-T1 History screen.
