import Foundation
import SleepCore
import SleepGuardContentKit

/// A night's PDF report, written to a file to share: SleepCore's
/// `NightReport` drawn by the shared `NightReportPDF`. Here, not in the shell,
/// because the shell doesn't import the content kit.
public enum NightReportExport {
  @MainActor
  public static func write(_ night: Night, appName: String, to directory: URL) throws -> URL {
    try NightReportPDF.write(NightReport(night: night), appName: appName, to: directory)
  }
}
