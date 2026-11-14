import FactoryKit
import SleepGuardDesignKit

/// The shell's registrations. Everything derives from `brand`, the one value
/// supplied from outside (`AppShell.bootstrap(brand:)`). Only `AppShell`
/// imports Factory; packages below it take plain initializer arguments.
extension Container {
  var brand: Factory<any BrandComposition> {
    self { preconditionFailure("AppShell.bootstrap(brand:) registers the brand before anything resolves") }
      .singleton
  }

  var theme: Factory<Theme> {
    self { self.brand().configuration.theme }
  }
}
