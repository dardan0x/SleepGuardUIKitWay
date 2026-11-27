import Foundation
import SleepCore

/// What the person chose in Settings: SleepCore's `SleepPreferences`, the
/// value SleepGuard uses too (same fields, same defaults). One value, read
/// whole and written whole through `PreferencesStorePort`.
public typealias AppPreferences = SleepPreferences
