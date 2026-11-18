import SleepCore

public struct SnoreInterrupterRoutes {
  /// The sound picker, starting at `current`; `picked` with the choice.
  public var chooseSound: @MainActor (_ current: Int, _ picked: @escaping @MainActor (Int) -> Void) -> Void
  public var save: @MainActor (SnoreInterrupterChoice) -> Void
  public var cancel: @MainActor () -> Void

  public init(
    chooseSound: @escaping @MainActor (_ current: Int, _ picked: @escaping @MainActor (Int) -> Void) -> Void,
    save: @escaping @MainActor (SnoreInterrupterChoice) -> Void,
    cancel: @escaping @MainActor () -> Void)
  {
    self.chooseSound = chooseSound
    self.save = save
    self.cancel = cancel
  }
}

public struct MelodyPickerRoutes {
  /// Record a new sound; `saved` with it.
  public var record: @MainActor (_ saved: @escaping @MainActor (Melody) -> Void) -> Void
  /// Done, with the chosen melody's id.
  public var done: @MainActor (Int) -> Void

  public init(
    record: @escaping @MainActor (_ saved: @escaping @MainActor (Melody) -> Void) -> Void,
    done: @escaping @MainActor (Int) -> Void)
  {
    self.record = record
    self.done = done
  }
}
