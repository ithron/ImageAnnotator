/*
 * Copyright (c) 2018, Stefan Reinhold <stefan@sreinhold.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of ImageAnnotator nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

class KeyPointView : UIStackView, ScaleInvariantView, Selectable {
  
  @IBOutlet fileprivate weak var labelView : UITextField!
  @IBOutlet fileprivate weak var imageView: UIImageView!
  @IBOutlet fileprivate weak var removeButton : UIButton!
  
  var label : String? {
    get {
      return labelView.text
    }
    set {
      labelView.text = newValue
    }
  }
  
  var position : CGPoint {
    get {
      return CGPoint(x: self.imageView.center.x + self.frame.origin.x,
                        y: self.imageView.center.y + self.frame.origin.y)
    }
    set {
      center(at: newValue)
    }
  }
  
  var isSelected : Bool {
    get {
      return !removeButton.isHidden
    }
    set {
      removeButton.isHidden  = !newValue
    }
  }
  
  var panOrigin : CGPoint?
  
}

extension KeyPointView {
  
  fileprivate func center(at position: CGPoint) {
    let size = self.frame.size
    let center = imageView.center
    let origin = CGPoint(x: position.x - center.x, y: position.y - center.y)
    
    self.frame = CGRect(origin: origin, size: size)
  }
  
}

extension KeyPointView {
  
  static func loadFromNib(owner: Any? = nil, options: [AnyHashable : Any]? = nil) -> KeyPointView {
    
    guard let objects = Bundle.main.loadNibNamed("KeyPointView",
                                                 owner: owner,
                                                 options: options) else {
      fatalError("Failed to load Nib")
    }
    
    guard let view = (objects.first { return ($0 as? KeyPointView) != nil })
      as! KeyPointView? else {
      fatalError("Could not find FeatureLocationView in Nib")
    }
    
    // Ensure the transformation center (i.e. the anchor point) lies in the
    // center of the feature marker
    let centerY = view.imageView.center.y / view.frame.size.height
    view.layer.anchorPoint = CGPoint(x: 0.5, y: centerY)
    
    return view
  }
  
}

