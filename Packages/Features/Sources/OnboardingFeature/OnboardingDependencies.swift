import SleepCore

public struct OnboardingDependencies {
  /// The microphone is already allowed (the page then shows it granted).
  public var microphoneGranted: @MainActor () -> Bool
  public var requestMicrophone: @MainActor () async -> Bool
  /// Apple Health, in a brand that has it; `nil`: no Health page.
  public var requestHealth: (@MainActor () async -> Bool)?

  public init(
    microphoneGranted: @escaping @MainActor () -> Bool,
    requestMicrophone: @escaping @MainActor () async -> Bool,
    requestHealth: (@MainActor () async -> Bool)?)
  {
    self.microphoneGranted = microphoneGranted
    self.requestMicrophone = requestMicrophone
    self.requestHealth = requestHealth
  }
}

public struct OnboardingRoutes {
  /// Onboarding is over. `healthGranted`: Health was allowed here.
  /// `startRecording`: "Start recording" rather than "Just browsing".
  public var finish: @MainActor (_ healthGranted: Bool, _ startRecording: Bool) -> Void

  public init(finish: @escaping @MainActor (_ healthGranted: Bool, _ startRecording: Bool) -> Void) {
    self.finish = finish
  }
}
