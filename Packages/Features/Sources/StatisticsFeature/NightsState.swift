import SleepCore

/// The state of a screen that shows statistics over every night: no empty
/// state (the numbers read 0), live from the repository.
enum NightsState {
  case loading
  case loaded([NightSummary])
}
