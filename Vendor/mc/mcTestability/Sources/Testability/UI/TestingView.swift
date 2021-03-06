//
//  TestingView.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 08.08.18.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit

class TestingView: UIView {

   enum Event {
      case action
   }

   var eventHandler: ((Event) -> Void)?

   private lazy var stackView = UIStackView()

   private lazy var actionsStackView = UIStackView()
   private lazy var actionButton = UIButton()

   let targetView: UIView

   init(targetView: UIView) {
      self.targetView = targetView
      super.init(frame: CGRect(x: 0, y: 0, width: targetView.frame.width, height: targetView.frame.height))
      setupUI()
      setupLayout()
      setupHandlers()
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError()
   }
}

extension TestingView {

   private func setupUI() {

      addSubview(stackView)

      targetView.translatesAutoresizingMaskIntoConstraints = false

      stackView.addArrangedSubview(actionsStackView)
      stackView.addArrangedSubview(targetView)
      stackView.axis = .vertical
      stackView.spacing = 8
      stackView.translatesAutoresizingMaskIntoConstraints = false

      actionsStackView.addArrangedSubview(actionButton)
      actionsStackView.addArrangedSubview(UIView())
      actionsStackView.translatesAutoresizingMaskIntoConstraints = false

      actionButton.setTitle("Action button", for: .normal)
      actionButton.backgroundColor = .darkGray
      actionButton.layer.cornerRadius = 4
      actionButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
      actionButton.translatesAutoresizingMaskIntoConstraints = false
   }

   private func setupLayout() {
      let constraints = [stackView.topAnchor.constraint(equalTo: topAnchor),
                         stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                         stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                         stackView.trailingAnchor.constraint(equalTo: trailingAnchor)]
      NSLayoutConstraint.activate(constraints)
   }

   private func setupHandlers() {
      actionButton.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
   }

   @objc private func handleTap(_: UIControl) {
      eventHandler?(.action)
   }
}
#endif
