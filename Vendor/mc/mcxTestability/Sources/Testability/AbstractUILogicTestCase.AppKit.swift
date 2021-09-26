//
//  AbstractUILogicTestCase.AppKit.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 18.02.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit

open class AbstractUILogicTestCase<Expectation, TestCase: TestCaseType>: AbstractBaseUILogicTestCase<Expectation, TestCase> where TestCase.Expectation == Expectation {

   private lazy var windowFrameAutosaveName: String = {
      "mc-testability-view-controller-frame-\(testCase.testName)"
   }()

   private let defaultSize = CGSize(width: 640, height: 480)

   public func showWindowController(_ wc: NSWindowController, isFloating: Bool = true,
                                    configureHandler: (() throws -> Void)? = nil) {
      guard let window = wc.window else {
         fatalError()
      }
      wc.shouldCascadeWindows = false
      wc.windowFrameAutosaveName = windowFrameAutosaveName
      setWindowFrame(window: window)
      waitForAnimationTransactionCompleted {
         wc.showWindow(nil)
      }
      do {
         try configureHandler?()
      } catch {
         assert.shouldNeverHappen(error, file: #file, line: #line)
      }
      // TODO: Take screenshot here
      // add(XCTAttachment(screenshot: ...))
      if testEnvironment.isUnderPlaygroundTesting {
         if isFloating {
            window.level = .floating
         }
         let exp = testCase.expectation(forNotification: NSWindow.willCloseNotification, object: window, handler: nil)
         wait(expectation: exp)
      }
   }

   func showFloatingWindow(_ window: NSWindow) {
      window.level = .floating
      showWindow(window)
   }

   public func showWindow(_ window: NSWindow, configureHandler: (() throws -> Void)? = nil) {
      let wc = NSWindowController(window: window)
      showWindowController(wc, configureHandler: configureHandler)
   }

   public func showViewController(_ vc: NSViewController, size: CGSize? = nil,
                                  configureBlock: (() throws -> Void)? = nil) {
      var windowSize = size ?? defaultSize
      let zeroValue = CGFloat.leastNormalMagnitude
      if vc.preferredContentSize.width > zeroValue, vc.preferredContentSize.height > zeroValue {
         windowSize = vc.preferredContentSize
      }
      let styleMask: NSWindow.StyleMask = [.closable, .titled, .miniaturizable, .resizable]
      let contentRect = CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
      let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: true)
      window.level = .floating
      let frameSize = window.contentRect(forFrameRect: window.frame).size
      vc.view.setFrameSize(frameSize)
      window.contentViewController = vc
      showWindow(window, configureHandler: configureBlock)
   }

   public func showView<T: NSView>(_ view: T, mode: TestableViewPresentationMode = .fullScreen,
                                   configureBlock: ((T) -> Void)? = nil) {

      let vc = TestabilityViewController()
      vc.configure(view: view, mode: mode)
      showViewController(vc) {
         configureBlock?(view)
      }
   }

   public func showView(_ view: NSView, size: CGSize? = nil, insets: NSEdgeInsets = NSEdgeInsets(),
                        shouldAutoresizeView: Bool = true, configureBlock: (() throws -> Void)? = nil) {
      let vc = TestabilityViewController()
      vc.view.addSubview(view)
      var viewSize = CGSize()
      if let size = size {
         viewSize = size
      } else {
         viewSize = view.fittingSize
         if viewSize.width < CGFloat.leastNormalMagnitude || viewSize.height < CGFloat.leastNormalMagnitude {
            viewSize = view.intrinsicContentSize
         }
         if viewSize.width < CGFloat.leastNormalMagnitude || viewSize.height < CGFloat.leastNormalMagnitude {
            viewSize = defaultSize
         }
      }
      let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: viewSize).insetBy(dx: -(insets.left + insets.right),
                                                                              dy: -(insets.top + insets.bottom))
      view.frame = frame
      if shouldAutoresizeView {
         view.translatesAutoresizingMaskIntoConstraints = false
         let constraints = [vc.view.topAnchor.constraint(equalTo: view.topAnchor, constant: -insets.top),
                            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom),
                            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -insets.left),
                            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right)]
         NSLayoutConstraint.activate(constraints)
      }
      showViewController(vc, size: viewSize, configureBlock: configureBlock)
   }

   func addTestAction(title: String, handler: @escaping () -> Void) {
      testActions.append((title, handler))
      let actionsMenu = NSApplication.shared.mainMenu?.items.last?.submenu
      let item = NSMenuItem(title: title, action: #selector(onMenuItemSelected(_:)), keyEquivalent: "\(testActions.count)")
      item.target = self
      actionsMenu?.addItem(item)
   }

   @available(OSX 10.14, *)
   func addSwitchToDarkAction(_ wc: NSWindowController) {
      addTestAction(title: "Switch to Dark") { [weak wc] in
         if let window = wc?.window {
            window.appearance = NSAppearance(named: .darkAqua)
         } else if let view = wc?.contentViewController?.view {
            view.appearance = NSAppearance(named: .darkAqua)
         } else {
            assertionFailure()
         }
      }
   }

   @available(OSX 10.14, *)
   func addSwitchToLightAction(_ wc: NSWindowController) {
      addTestAction(title: "Switch to Light") { [weak wc] in
         if let window = wc?.window {
            window.appearance = NSAppearance(named: .aqua)
         } else if let view = wc?.contentViewController?.view {
            view.appearance = NSAppearance(named: .aqua)
         } else {
            assertionFailure()
         }
      }
   }

   @available(OSX 10.14, *)
   func addSwitchToDarkAction(_ view: NSView) {
      addTestAction(title: "Switch to Dark") { [weak view] in
         view?.appearance = NSAppearance(named: .darkAqua)
      }
   }

   @available(OSX 10.14, *)
   func addSwitchToLightAction(_ view: NSView) {
      addTestAction(title: "Switch to Light") { [weak view] in
         view?.appearance = NSAppearance(named: .aqua)
      }
   }

   @objc private func onMenuItemSelected(_ sender: NSMenuItem) {
      let action = testActions.first(where: { $0.0 == sender.title })
      Swift.assert(action != nil)
      action?.1()
   }

   private func setWindowFrame(window: NSWindow) {
      if !window.setFrameUsingName(windowFrameAutosaveName) {
         if let screenSize = window.screen?.visibleFrame.size {
            let frameSize = window.contentRect(forFrameRect: window.frame).size
            let origin = NSPoint(x: (screenSize.width - frameSize.width) / 2,
                                 y: (screenSize.height - frameSize.height) / 2)

            window.setFrameOrigin(origin)
         }
      }
   }
}
#endif
