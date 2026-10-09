import Flutter
import UIKit
import XCTest

@testable import social_story_share_plus

class RunnerTests: XCTestCase {

  func testUnknownMethodIsNotImplemented() {
    let plugin = SocialStorySharePlusPlugin()
    let call = FlutterMethodCall(methodName: "unknown", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result as AnyObject === FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testStoryWithoutAppIdIsRejected() {
    let plugin = SocialStorySharePlusPlugin()
    let call = FlutterMethodCall(methodName: "shareToInstagramStories", arguments: ["stickerPath": "/tmp/sticker.png"])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual((result as? FlutterError)?.code, "INVALID_ARGUMENT")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
