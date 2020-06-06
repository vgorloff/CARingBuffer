//
//  UILogicTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

open class UILogicTestCase: XCTestCase {

   public private(set) var test: AbstractUILogicTestCase<XCTestExpectation, XCTestCase>!

   public var stub: StubObject {
      return test.stub
   }

   open func onStart() throws {
      // Base class dows nothing
   }

   open func onShutdown() throws {
      // Base class dows nothing
   }

   override open func setUp() {
      let env = DefaultTestEnvironment(isUnderPlaygroundTesting: TestabilityRuntime.isPlaygroundTesting,
                                       isReferenceTest: TestabilityRuntime.isReferenceTest)
      TestSettings.shared.testEnvironment = env
      test = AbstractUILogicTestCase(testCase: self)
      super.setUp()
      test.setUp()
      do {
         try onStart()
      } catch {
         Assert.shouldNeverHappen(error)
      }
   }

   override open func tearDown() {
      do {
         try onShutdown()
      } catch {
         Assert.shouldNeverHappen(error)
      }
      test.tearDown()
      super.tearDown()
   }

   #if canImport(AppKit) && !targetEnvironment(macCatalyst)
   public func showView<T: NSView>(_ view: T, mode: TestableViewPresentationMode = .fullScreen,
                                   configureBlock: ((T) -> Void)? = nil) {
      test.showView(view, mode: mode, configureBlock: configureBlock)
   }

   public func showView(_ view: NSView, size: CGSize? = nil, insets: NSEdgeInsets = NSEdgeInsets(),
                        shouldAutoresizeView: Bool = true, configureBlock: (() throws -> Void)? = nil) {
      test.showView(view, size: size, insets: insets, shouldAutoresizeView: shouldAutoresizeView, configureBlock: configureBlock)
   }

   public func showViewController(_ vc: NSViewController, size: CGSize? = nil, configureBlock: (() throws -> Void)? = nil) {
      test.showViewController(vc, size: size, configureBlock: configureBlock)
   }

   public func showWindowController(_ wc: NSWindowController, configureHandler: (() throws -> Void)? = nil) {
      test.showWindowController(wc, configureHandler: configureHandler)
   }

   public func addSwitchAppearanceActions(windowController wc: NSWindowController) {
      if #available(OSX 10.14, *) {
         test.addSwitchToLightAction(wc)
         test.addSwitchToDarkAction(wc)
      }
   }

   public func addSwitchAppearanceActions(view: NSView) {
      if #available(OSX 10.14, *) {
         test.addSwitchToLightAction(view)
         test.addSwitchToDarkAction(view)
      }
   }
   #endif

   #if canImport(UIKit)
   public func showView<T: UIView>(_ view: T, mode: TestableViewPresentationMode = .fullScreen,
                                   delay: TimeInterval = 0,
                                   isLandscape: Bool = false,
                                   shouldPlay: Bool = true,
                                   configureBlock: ((T) -> Void)? = nil) {
      test.showView(view, mode: mode, delay: delay, shouldPlay: shouldPlay, configureBlock: configureBlock)
   }

   public func showViewController<T: UIViewController>(_ vc: T,
                                                       mode: TestableControllerPresentationMode = .fullScreen,
                                                       delay: TimeInterval = 0,
                                                       shouldPlay: Bool = true,
                                                       configureBlock: ((T) throws -> Void)? = nil) {
      test.showViewController(vc, mode: mode, delay: delay, shouldPlay: shouldPlay, configureBlock: configureBlock)
   }

   public func embedViewController<T: UIViewController>(_ vc: T,
                                                        mode: ControllerEmbedingMode = .fullScreen,
                                                        delay: TimeInterval = 0,
                                                        configureBlock: ((T) throws -> Void)? = nil) {
      test.embedViewController(vc, mode: mode, delay: delay, configureBlock: configureBlock)
   }
   #endif

   public func addTestAction(title: String, handler: @escaping () -> Void) {
      test.addTestAction(title: title, handler: handler)
   }
}
#endif
