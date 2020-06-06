//
//  TestabilityOverlayWindow.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 22.11.18.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class TestabilityOverlayWindow: UIWindow {

   enum Gravity: Int {
      case topLeft, topRight
   }

   private(set) lazy var viewController = ViewController()
   private var observer: NSObjectProtocol?
   private let size = CGSize(width: 30, height: 30)
   let gravity: Gravity

   init(gravity: Gravity) {
      self.gravity = gravity
      super.init(frame: CGRect(origin: CGPoint(), size: size))
      #if os(iOS)
      windowLevel = UIWindow.Level.statusBar + 2
      #else
      windowLevel = UIWindow.Level.alert + 2
      #endif
      rootViewController = viewController
      setupHandlers()
      handleRotation()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError()
   }

   private func setupHandlers() {
      // See also: https://stackoverflow.com/a/6698102/1418981
      observer = NotificationCenter.default.addObserver(forName: UIApplication.didChangeStatusBarFrameNotification, object: nil, queue: nil) { [weak self] _ in
         self?.handleRotation()
      }
   }

   private func handleRotation() {
      #if targetEnvironment(macCatalyst)
      let offset: CGFloat = 20
      let y: CGFloat = 40
      let width = UIApplication.shared.windows.map { $0.bounds.width }.max() ?? 0
      #else
      let offset: CGFloat = 10
      let width = UIApplication.shared.statusBarFrame.width
      let y = UIApplication.shared.statusBarFrame.height
      #endif
      let x: CGFloat
      switch gravity {
      case .topLeft:
         x = offset
      case .topRight:
         x = width - offset - size.width
      }
      frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
   }
}

extension TestabilityOverlayWindow {

   class ViewController: UIViewController {

      enum Event {
         case singleTap
         case doubleTap
      }

      var eventHandler: ((Event) -> Void)?

      init() {
         super.init(nibName: nil, bundle: nil)
         view.backgroundColor = UIColor.magenta.withAlphaComponent(0.2)
         let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
         let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
         doubleTapGestureRecognizer.numberOfTapsRequired = 2
         singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
         view.addGestureRecognizer(singleTapGestureRecognizer)
         view.addGestureRecognizer(doubleTapGestureRecognizer)
         view.layer.borderWidth = 0.25
      }

      required init?(coder: NSCoder) {
         fatalError()
      }

      @objc func onSingleTap() {
         eventHandler?(.singleTap)
      }

      @objc func onDoubleTap() {
         eventHandler?(.doubleTap)
      }
   }
}
#endif
