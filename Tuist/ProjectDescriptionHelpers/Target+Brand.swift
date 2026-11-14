import ProjectDescription

public extension Target {
  /// The app target for one brand. Every brand gets the same shape: shared
  /// sources, its own resources and entitlements, its identity in Info.plist.
  static func app(_ brand: Brand) -> Target {
    .target(
      name: brand.name,
      destinations: [.iPhone],
      product: .app,
      bundleId: brand.bundleId,
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": .string(brand.displayName),
        "CFBundleShortVersionString": "0.1.0",
        "CFBundleVersion": "1",
        "UILaunchScreen": ["UIColorName": "LaunchBackground"],
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
        "UIApplicationSceneManifest": [
          "UIApplicationSupportsMultipleScenes": false,
          "UISceneConfigurations": [
            "UIWindowSceneSessionRoleApplication": [[
              "UISceneConfigurationName": "Default",
              "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
            ]],
          ],
        ],
        "CFBundleURLTypes": [[
          "CFBundleURLName": .string(brand.bundleId),
          "CFBundleURLSchemes": [.string(brand.urlScheme)],
        ]],
        "SGAppGroup": .string(brand.appGroup),
      ]),
      sources: ["Apps/Shared/Sources/**"],
      resources: ["Apps/\(brand.name)/Resources/**"],
      entitlements: .file(path: "Apps/\(brand.name)/\(brand.name).entitlements"),
      settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "BrandAccent",
        "TARGETED_DEVICE_FAMILY": "1",
      ]))
  }
}
