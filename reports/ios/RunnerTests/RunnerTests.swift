import Foundation
import XCTest

class RunnerTests: XCTestCase {

  func testRequiredPermissionDescriptionsArePresent() {
    for key in [
      "NSCameraUsageDescription",
      "NSLocationWhenInUseUsageDescription",
      "NSPhotoLibraryUsageDescription",
    ] {
      let description = Bundle.main.object(forInfoDictionaryKey: key) as? String
      XCTAssertFalse(
        description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true,
        "\(key) must explain why Reports needs permission"
      )
    }
  }

}
