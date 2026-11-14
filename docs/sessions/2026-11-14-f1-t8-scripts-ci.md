
### Completed
- F1-T8: `check-layering.py`, `check-view-size.py`, `check-hardcoded-strings.py`, `run-tests.sh` (macOS, standalone packages, hosted per brand), `bump-shared.sh`, `.github/workflows/ci.yml`, `mise.toml`.
- F1 complete: feature doc `docs/features/f1-foundation.md`.

### Technical Details
- `check-layering.py` holds the import table (`ALLOWED_IMPORTS`); an unknown module fails, so new modules must be placed in it.
- The standalone package lane first let `import FactoryKit` in an adapter compile: all packages shared one derived-data folder. Each package now builds in its own.
- CI generates with `TUIST_SHARED_RELEASE=1` and builds Release for all three brands, unsigned.

### Build Status
- Each check shown failing on a deliberate violation, then passing.
- `run-tests.sh`: all lanes pass (Core 1; Core and Adapters build standalone; Presentation 11; AppShell 7; hosted 4 × 3 brands).
- Not verified: the workflow on GitHub (first run on this PR).

### Next Session
- Merge F1 into `main`; F2-T1.
