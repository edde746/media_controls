import AVFoundation
import Flutter
import UIKit
import XCTest

@testable import os_media_controls

class RunnerTests: XCTestCase {

  func testAudioSessionOperationsRunOffMainThreadInSubmissionOrder() {
    let operationsFinished = expectation(description: "audio session operations finished")
    operationsFinished.expectedFulfillmentCount = 2
    let lock = NSLock()
    var observedStates: [Bool] = []
    var observedOptions: [AVAudioSession.SetActiveOptions] = []

    let queue = AudioSessionActivationQueue(useSystemAsyncAPI: false) { active, options in
      XCTAssertFalse(Thread.isMainThread)
      lock.lock()
      observedStates.append(active)
      observedOptions.append(options)
      lock.unlock()
      operationsFinished.fulfill()
    }

    queue.setActive(true) { error in
      XCTFail("Unexpected activation error: \(error)")
    }
    queue.setActive(false, options: .notifyOthersOnDeactivation) { error in
      XCTFail("Unexpected deactivation error: \(error)")
    }

    wait(for: [operationsFinished], timeout: 2)
    XCTAssertEqual(observedStates, [true, false])
    XCTAssertEqual(observedOptions, [[], .notifyOthersOnDeactivation])
  }

  func testAudioSessionOperationReportsErrorsAsynchronously() {
    enum ExpectedError: Error {
      case activationFailed
    }

    let errorReported = expectation(description: "activation error reported")
    let queue = AudioSessionActivationQueue(useSystemAsyncAPI: false) { _, _ in
      throw ExpectedError.activationFailed
    }

    queue.setActive(true) { error in
      XCTAssertTrue(error is ExpectedError)
      XCTAssertFalse(Thread.isMainThread)
      errorReported.fulfill()
    }

    wait(for: [errorReported], timeout: 2)
  }
}
