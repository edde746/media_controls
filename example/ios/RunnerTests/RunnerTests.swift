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

    let queue = AudioSessionActivationQueue { active, options in
      XCTAssertFalse(Thread.isMainThread)
      lock.lock()
      observedStates.append(active)
      observedOptions.append(options)
      lock.unlock()
    }

    queue.setActive(true) { error in
      XCTAssertNil(error)
      operationsFinished.fulfill()
    }
    queue.setActive(false, options: .notifyOthersOnDeactivation) { error in
      XCTAssertNil(error)
      operationsFinished.fulfill()
    }

    wait(for: [operationsFinished], timeout: 2)
    XCTAssertEqual(observedStates, [true, false])
    XCTAssertEqual(observedOptions, [[], .notifyOthersOnDeactivation])
  }

  func testAudioSessionCompletionRunsAfterActivationInSubmissionOrder() {
    let completionsFinished = expectation(description: "completions ran")
    completionsFinished.expectedFulfillmentCount = 2
    let lock = NSLock()
    var log: [String] = []

    let queue = AudioSessionActivationQueue { active, _ in
      lock.lock()
      log.append(active ? "activate" : "deactivate")
      lock.unlock()
    }

    queue.setActive(true) { _ in
      lock.lock()
      log.append("activated")
      lock.unlock()
      completionsFinished.fulfill()
    }
    queue.setActive(false) { _ in
      lock.lock()
      log.append("deactivated")
      lock.unlock()
      completionsFinished.fulfill()
    }

    wait(for: [completionsFinished], timeout: 2)
    XCTAssertEqual(log, ["activate", "activated", "deactivate", "deactivated"])
  }

  func testAudioSessionOperationReportsErrorsAsynchronously() {
    enum ExpectedError: Error {
      case activationFailed
    }

    let errorReported = expectation(description: "activation error reported")
    let queue = AudioSessionActivationQueue { _, _ in
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
