//
//  TestabilityViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 20.02.19.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

#if !os(macOS)
import UIKit
typealias ViewController = UIViewController
typealias View = UIView
#else
import AppKit
typealias ViewController = NSViewController
typealias View = NSView
class TestView: NSView {
   override var isFlipped: Bool {
      return true
   }
}
#endif

class TestabilityViewController: ViewController {

   private let safeAreaView = View()
   private var testableView = View()

   #if os(macOS)
   override func loadView() {
      view = TestView()
   }
   #endif

   #if os(iOS)
   private var supportedInterfaceOrientationsValue: UIInterfaceOrientationMask?

   override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
      return supportedInterfaceOrientationsValue ?? super.supportedInterfaceOrientations
   }

   init(supportedInterfaceOrientations: UIInterfaceOrientationMask?) {
      supportedInterfaceOrientationsValue = supportedInterfaceOrientations
      super.init(nibName: nil, bundle: nil)
   }
   #endif

   #if !os(macOS)
   override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
      super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
      viewRespectsSystemMinimumLayoutMargins = false
      view.insetsLayoutMarginsFromSafeArea = false
      view.layoutMargins = UIEdgeInsets()
      let gr = UITapGestureRecognizer(target: self, action: #selector(handleTap))
      gr.cancelsTouchesInView = false
      view.addGestureRecognizer(gr)
      view.backgroundColor = .lightGray
      setupSafeAreaView()
   }

   @available(*, unavailable)
   required init?(coder aDecoder: NSCoder) {
      fatalError()
   }

   override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      super.viewWillTransition(to: size, with: coordinator)
      coordinator.animate(alongsideTransition: { _ in
         self.view.layoutIfNeeded()
      }, completion: nil)
   }
   #endif

   func configure(view testableView: View, mode: TestableViewPresentationMode) {
      self.testableView = testableView
      testableView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(testableView)

      var constraints: [NSLayoutConstraint] = []
      switch mode {
      case .asIs:
         testableView.translatesAutoresizingMaskIntoConstraints = true
      case .fullScreen:
         constraints += [testableView.topAnchor.constraint(equalTo: view.topAnchor),
                         view.bottomAnchor.constraint(equalTo: testableView.bottomAnchor),
                         testableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                         view.trailingAnchor.constraint(equalTo: testableView.trailingAnchor)]
      #if !os(macOS)
      case .fullScreenInsideSafeAreas:
         constraints += [testableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                         view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: testableView.bottomAnchor),
                         testableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                         view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: testableView.trailingAnchor)]

      case .fullHeightInsideSafeAreas:
         constraints += [testableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                         view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: testableView.bottomAnchor),
                         testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor)]
      case .fullWidthInsideSafeAreas:
         constraints += [testableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                         view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: testableView.trailingAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)]
      #endif
      case .fullWidth:
         constraints += [testableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                         view.trailingAnchor.constraint(equalTo: testableView.trailingAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)]
      case .fullHeight:
         constraints += [testableView.topAnchor.constraint(equalTo: view.topAnchor),
                         view.bottomAnchor.constraint(equalTo: testableView.bottomAnchor),
                         testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor)]

      case .atCenter:
         constraints += [testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)]
      case .atCenterWithSize(let size):
         constraints += [testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)]
         constraints += [testableView.widthAnchor.constraint(equalToConstant: size.width),
                         testableView.heightAnchor.constraint(equalToConstant: size.height)]
      case .margins(let insets):
         constraints += [testableView.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
                         view.bottomAnchor.constraint(equalTo: testableView.bottomAnchor, constant: insets.bottom),
                         testableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
                         view.trailingAnchor.constraint(equalTo: testableView.trailingAnchor, constant: insets.right)]
      case .atCenterWithHeight(let height):
         constraints += [testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                         testableView.heightAnchor.constraint(equalToConstant: height)]
      case .atCenterWithWidth(let width):
         constraints += [testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                         testableView.widthAnchor.constraint(equalToConstant: width)]
      case .fullWidthWithHeight(let height):
         constraints += [testableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                         view.trailingAnchor.constraint(equalTo: testableView.trailingAnchor),
                         testableView.heightAnchor.constraint(equalToConstant: height),
                         testableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)]
      case .fullHeightWithWidth(let width):
         constraints += [testableView.topAnchor.constraint(equalTo: view.topAnchor),
                         view.bottomAnchor.constraint(equalTo: testableView.bottomAnchor),
                         testableView.widthAnchor.constraint(equalToConstant: width),
                         testableView.centerXAnchor.constraint(equalTo: view.centerXAnchor)]
      }
      NSLayoutConstraint.activate(constraints)
   }

   // MARK: - Private

   #if !os(macOS)
   private func setupSafeAreaView() {
      safeAreaView.translatesAutoresizingMaskIntoConstraints = false
      safeAreaView.layer.borderWidth = 0.5
      safeAreaView.layer.borderColor = UIColor.green.cgColor

      view.addSubview(safeAreaView)

      safeAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
      view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaView.bottomAnchor).isActive = true
      safeAreaView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
      view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaView.trailingAnchor).isActive = true
   }

   @objc private func handleTap() {
      view.endEditing(true)
   }
   #endif
}
