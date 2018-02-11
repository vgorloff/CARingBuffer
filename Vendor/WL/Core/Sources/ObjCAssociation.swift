//
//  ObjCAssociation.swift
//  WLCore
//
//  Created by Vlad Gorlov on 03.01.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import ObjectiveC

struct ObjCAssociation {

   static func value<T>(from object: AnyObject, forKey key: UnsafeRawPointer) -> T? {
      return objc_getAssociatedObject(object, key) as? T
   }

   static func setAssign<T>(value: T?, to object: Any, forKey key: UnsafeRawPointer) {
      objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_ASSIGN)
   }

   static func setRetainNonAtomic<T>(value: T?, to object: Any, forKey key: UnsafeRawPointer) {
      objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
   }

   static func setCopyNonAtomic<T>(value: T?, to object: Any, forKey key: UnsafeRawPointer) {
      objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_COPY_NONATOMIC)
   }

   static func setRetain<T>(value: T?, to object: Any, forKey key: UnsafeRawPointer) {
      objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN)
   }

   static func setCopy<T>(value: T?, to object: Any, forKey key: UnsafeRawPointer) {
      objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_COPY)
   }
}
