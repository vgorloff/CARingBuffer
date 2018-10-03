//
//  NSMutableAttributedString.swift
//  mcFoundation
//
//  Created by Vlad Gorlov on 24/02/2017.
//  Copyright © 2017 WaveLabs. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

extension NSMutableAttributedString {

   #if os(iOS) || os(tvOS) || os(watchOS)
   public typealias Font = UIFont
   public typealias Color = UIColor
   #elseif os(OSX)
   public typealias Font = NSFont
   public typealias Color = NSColor
   #endif

   public struct Attribute {
      public let key: NSAttributedString.Key
      public let value: Any
   }

   public func replace(with: String) {
      let range = string.startIndex ..< string.endIndex
      replaceCharacters(in: NSRange(range, in: string), with: with)
   }

   public func removeAttributes(range: Range<String.Index>? = nil) {
      let range = range ?? string.startIndex ..< string.endIndex
      let nsRange = NSRange(range, in: string)
      setAttributes([:], range: nsRange)
   }

   public func setAttribute(_ attribute: NSAttributedString.Key, value: Any, range: Range<String.Index>? = nil) {
      let range = range ?? string.startIndex ..< string.endIndex
      let nsRange = NSRange(range, in: string)
      setAttributes([attribute: value], range: nsRange)
   }

   public func setAttribute(_ attribute: NSMutableAttributedString.Attribute, range: Range<String.Index>? = nil) {
      setAttribute(attribute.key, value: attribute.value, range: range)
   }

   public func setAttributes(_ attributes: [NSMutableAttributedString.Attribute], range: Range<String.Index>? = nil) {
      let range = range ?? string.startIndex ..< string.endIndex
      let nsRange = NSRange(range, in: string)
      let a = attributes.map { ($0.key, $0.value) }
      setAttributes(Dictionary(a), range: nsRange)
   }

   public func setForegroundColor(_ color: Color, range: Range<String.Index>? = nil) {
      setAttribute(.foregroundColor, value: color, range: range)
   }
}

extension NSMutableAttributedString {

   public func addAttributes(_ attributes: [NSAttributedString.Key: Any], range: Range<String.Index>? = nil) {
      let range = range ?? string.startIndex ..< string.endIndex
      let nsRange = NSRange(range, in: string)
      addAttributes(attributes, range: nsRange)
   }

   public func addAttribute(_ name: NSAttributedString.Key, value: Any, range: Range<String.Index>? = nil) {
      let range = range ?? string.startIndex ..< string.endIndex
      let nsRange = NSRange(range, in: string)
      addAttribute(name, value: value, range: nsRange)
   }

   public func addParagraphStyle(paragraphStyle: NSParagraphStyle, range: Range<String.Index>? = nil) {
      addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
   }

   public func addFont(font: Font, range: Range<String.Index>? = nil) {
      addAttribute(.font, value: font, range: range)
   }

   public func addForegroundColor(_ color: Color, range: Range<String.Index>? = nil) {
      addAttribute(.foregroundColor, value: color, range: range)
   }

   public func addBackgroundColor(_ color: Color, range: Range<String.Index>? = nil) {
      addAttribute(.backgroundColor, value: color, range: range)
   }
}

extension NSMutableAttributedString.Attribute {

   public static func foregroundColor(_ color: NSMutableAttributedString.Color) -> NSMutableAttributedString.Attribute {
      return NSMutableAttributedString.Attribute(key: .foregroundColor, value: color)
   }
}
