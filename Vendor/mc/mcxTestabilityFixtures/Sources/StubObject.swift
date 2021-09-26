//
//  StubObject.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import CoreLocation
import Foundation

public class StubObject {

   public var credentials = CredentialStub()
   public var text = TextStub()
   public var unique = UniquieStub()
   public var image = ImageStub()
   public var date = DateStub()

   public init() {
   }
}

public class DateStub {

   public func makeTimestamp() -> String {
      let timestamp = Int(Date().timeIntervalSinceReferenceDate)
      return "\(timestamp)"
   }

   /// - Parameters:
   ///   - fromString: In format "YYYY-MM-dd HH:mm"
   public func date(fromString value: String) -> Date {
      let formatter = DateFormatter()
      formatter.timeZone = TimeZone(identifier: "UTC")
      formatter.dateFormat = "YYYY-MM-dd HH:mm"
      if let date = formatter.date(from: value) {
         return date
      } else {
         assertionFailure()
         return Date()
      }
   }

   public init() {
   }
}

public class UniquieStub {

   public func makeString() -> String {
      return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
   }

   public func makeInt() -> Int {
      return Int(Date.timeIntervalSinceReferenceDate)
   }

   public init() {
   }
}

public class CredentialStub {

   public let email = "user@example.com"
   public let password = "password"

   public init() {
   }
}

public class ImageStub {

   public let url = "http://www.ucarecdn.com/dd66f32a-670f-4b74-9735-cbd19b7310e4/-/crop/961x960/54,0/"

   public init() {
   }
}

public class TextStub {

   public let x128 = "Gallia est omnis divisa in partes tres, quarum. Quam temere in vitiis, legem sancim haerentia. Pellentesque habitant morbi tris."
   public let x32 = "Pellentesque habitant morb tris."
   public let x16 = "Pellentque tris."

   public init() {
   }
}

public class ErrorStub: Swift.Error, LocalizedError, CustomStringConvertible {

   public let message: String

   public init(message: String) {
      self.message = message
   }

   public var errorDescription: String? {
      return message
   }

   public var description: String {
      return message
   }
}
