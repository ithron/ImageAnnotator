//
//  CGPointExtensions.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 15.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

import Foundation

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

extension CGPoint {
  
  static func +=(left: inout CGPoint, right: CGPoint) {
    left = left + right
  }
  
  static func -=(left: inout CGPoint, right: CGPoint) {
    left = left - right
  }
  
}
