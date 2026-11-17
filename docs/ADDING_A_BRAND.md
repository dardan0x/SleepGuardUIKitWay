# Adding a brand

A brand is a separate app on the same product: its own name, icon, colours, bundle id and capabilities, built from the same code. This walks through adding the fourth one, **Dawn**, exactly as it was added. The whole change is one folder and one list entry; nothing in the packages knows Dawn exists.

## What a brand is made of

| Piece | Where | Decides |
|---|---|---|
| An entry in `Brand.all` | `Tuist/ProjectDescriptionHelpers/Brand.swift` | Build time: target name, display name, bundle id, URL scheme, whether `SleepHealth` (HealthKit) is linked |
| `Brand.swift` | `Apps/<Name>/Sources/` | Run time: theme, tabs, Apple Health port, Snore Interrupter, Learn page, App Store id (`BrandConfiguration`) |
| Asset catalog | `Apps/<Name>/Resources/Assets.xcassets` | App icon, `BrandAccent` (tint), `LaunchBackground` |
| Entitlements | `Apps/<Name>/<Name>.entitlements` | App group; HealthKit when the brand uses it |

From the entry, Tuist generates the app target and its `<Name>HostedTests` target (`Project.swift` maps `Brand.all`). The test script and CI find every brand by its `Apps/<Name>/Sources/Brand.swift`, so they need no edit.

## 1. The brand list

```diff
--- a/Tuist/ProjectDescriptionHelpers/Brand.swift
+++ b/Tuist/ProjectDescriptionHelpers/Brand.swift
-  static let all: [Brand] = [sleepGuard, sleepGuardLite, nocturne]
+  static let all: [Brand] = [sleepGuard, sleepGuardLite, nocturne, dawn]
@@
     urlScheme: "nocturne",
     usesHealthKit: true)
+
+  static let dawn = Brand(
+    name: "Dawn",
+    displayName: "Dawn",
+    bundleId: "com.dardan.sleepguardway.dawn",
+    urlScheme: "dawn",
+    usesHealthKit: true)
 }
```

`usesHealthKit: true` links `SleepHealth` and adds the Health usage texts to Info.plist. Keep it in step with the HealthKit entitlement.

## 2. The brand's configuration

`Apps/Dawn/Sources/Brand.swift`:

```swift
nonisolated struct DawnBrand: BrandComposition {
  let configuration = BrandConfiguration(
    theme: .dawn,
    tabs: [.statistics, .history, .settings],
    health: SleepHealth.makeHealthAccess(),
    appStoreID: nil,
    snoreInterrupter: false,
    learnURL: nil)
}

let appBrand = DawnBrand()

private extension Theme {
  nonisolated static let dawn: Theme = {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#1A1210")
    theme.palette.bgSecondary = Color(hex: "#24170F")
    theme.palette.bgCard = Color(hex: "#2E1E14")
    theme.palette.bgElevated = Color(hex: "#44301F")
    theme.palette.border = Color(hex: "#44301F")
    theme.palette.accent = Color(hex: "#FF9A5C")
    theme.palette.tabInactive = Color(hex: "#A08A78")
    theme.palette.textTertiary = Color(hex: "#B09A88")
    return theme
  }()
}
```

- `appBrand` is the one name the shared scene delegate looks for: it passes it to `AppShell.bootstrap(brand:)`. Each brand's type has its own name (`DawnBrand`), and nothing is swapped by target membership.
- `BrandConfiguration` has no default values. Leave one out and the brand doesn't compile, so a new capability can't be forgotten in one brand.
- Dawn's mix: Apple Health (and with it sleep stages, the Health rows and the onboarding's Health page), no Snore Interrupter (no prestart row, nothing at night), no Learn tab. No other brand has this combination; nothing outside this file had to change for it.
- The theme starts from SleepGuard's and changes colours only. A brand can also change type design and corner radii (Nocturne does).

## 3. Assets and entitlements

```
Apps/Dawn/Dawn.entitlements                                  app group, HealthKit
Apps/Dawn/Resources/Assets.xcassets/Contents.json
Apps/Dawn/Resources/Assets.xcassets/AppIcon.appiconset/      one 1024 px icon, no alpha
Apps/Dawn/Resources/Assets.xcassets/BrandAccent.colorset/    #FF9A5C, the same as theme.palette.accent
Apps/Dawn/Resources/Assets.xcassets/LaunchBackground.colorset/  #1A1210, the same as bgPrimary
```

The launch screen shows `LaunchBackground`; `BrandAccent` is the asset catalog's accent colour; once the app runs, the window's tint comes from the theme. Make all three match the theme, so the launch screen fades straight into the app.

## 4. Generate and test

```sh
tuist generate
sh scripts/run-tests.sh hosted
```

The in-app tests run inside each brand's own app, Dawn's included, with no new test code:

- `BrandBootstrapTests` checks that every container registration resolves for this brand and that the tab bar shows the brand's tabs in order, and waits for the Debug sample nights.
- The tab, night detail, player and recording tests run against Dawn's real wiring.

## The diff, in full

```
 Apps/Dawn/Dawn.entitlements                        |  14 +++++++++
 .../AppIcon.appiconset/Contents.json               |  14 +++++++++
 .../AppIcon.appiconset/icon-1024.png               | Bin 0 -> 13883 bytes
 .../BrandAccent.colorset/Contents.json             |  20 ++++++++++++
 Apps/Dawn/Resources/Assets.xcassets/Contents.json  |   6 ++++
 .../LaunchBackground.colorset/Contents.json        |  20 ++++++++++++
 Apps/Dawn/Sources/Brand.swift                      |  35 +++++++++++++++++++++
 Tuist/ProjectDescriptionHelpers/Brand.swift        |   9 +++++-
 8 files changed, 117 insertions(+), 1 deletion(-)
```

No package, feature, flow, script or test changed. All four brands' in-app tests passed on the first run (9 each).

(One change came before this, so that adding a brand needs nothing else: the test script and CI used to list the three brands by name; they now find every `Apps/<Name>/Sources/Brand.swift`.)

## What a brand can't do here (yet)

- Strings are shared, so every brand speaks the same copy. A brand-specific string would be a value in `BrandConfiguration`, not a fork of the catalog.
- Screen layouts are shared with SleepGuard (ADR 0005). A brand changes how they look through its theme, not their structure.
- A capability that no brand has yet (a Watch app, say) needs the shell to grow first: a port or a value in `BrandConfiguration` (ADR 0006). That's a change to the shell, and every brand states its choice.
