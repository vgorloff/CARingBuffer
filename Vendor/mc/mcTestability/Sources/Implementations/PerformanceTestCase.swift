//
//  PerformanceTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

#if canImport(XCTest)

class PerformanceTestCase: UILogicTestCase {

   private(set) lazy var serialQueue: OperationQueue = {
      let queue = OperationQueue()
      queue.qualityOfService = .userInitiated
      queue.name = "com.testability.PerformanceTestQueue"
      queue.maxConcurrentOperationCount = 1
      queue.isSuspended = true
      return queue
   }()

   /* FIXME: RESTORE
    func addUIUpdateOperations(numberOfIterations: Int, workItem: @escaping (Int) throws -> Void) {
       for iteration in 0 ..< numberOfIterations {
          serialQueue.addOperation(UIUpdateOperation(iteration: iteration, workItem: workItem))
       }
    }

    func addUpdateOperations(numberOfIterations: Int, workItem: @escaping (Int) throws -> Void) {
       for iteration in 0 ..< numberOfIterations {
          serialQueue.addOperation(UpdateOperation(iteration: iteration, workItem: workItem))
       }
    }

    func resumeOperations() {
       serialQueue.addOperation(UIUpdateOperation(iteration: 0) { [weak self] _ in
          self?.test.playExpectation.fulfill()
       })
       serialQueue.isSuspended = false
    }
    */
}

/* FIXME: RESTORE
 private class UIUpdateOperation: AsynchronousOperation {

 private let workItem: (Int) throws -> Void
 private let iteration: Int

 init(iteration: Int, workItem: @escaping (Int) throws -> Void) {
    self.workItem = workItem
    self.iteration = iteration
    super.init()
 }

 override func main() {
    DispatchQueue.main.async {
       do {
          try self.workItem(self.iteration)
       } catch {
          Assert.shouldNeverHappen(error)
       }
       self.finish()
    }
 }
 }

 private class UpdateOperation: AsynchronousOperation {

 private let workItem: (Int) throws -> Void
 private let iteration: Int

 init(iteration: Int, workItem: @escaping (Int) throws -> Void) {
    self.workItem = workItem
    self.iteration = iteration
    super.init()
 }

 override func main() {
    do {
       try workItem(iteration)
    } catch {
       Assert.shouldNeverHappen(error)
    }
    finish()
 }
 }
 */
#endif
