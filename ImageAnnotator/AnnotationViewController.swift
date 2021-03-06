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

import CoreData

class AnnotationViewController : UIViewController {
  
  var image : UIImage!
  var imageModel : Image!
  var managedObjectContext : NSManagedObjectContext!
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var scrollView : UIScrollView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imageView.image = image
    if let img = image {
      imageView.frame = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
      imageView.contentMode = .center
    
      let minScale = min(scrollView.frame.width / img.size.width,
                         scrollView.frame.height / img.size.height)
      scrollView.minimumZoomScale = minScale
      scrollView.contentSize = img.size
      scrollView.zoomScale = minScale
    }
  }
  
}

// MARK: - UIScrollViewDelegate
extension AnnotationViewController : UIScrollViewDelegate {
  
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    scaleAnnotationViews()
  }

}

// MARK: - Gestures
extension AnnotationViewController  {
  
  var selectableViews : [UIView] {
    return imageView.subviews.filter { ($0 as? Selectable) != nil }
  }
  
  var selectedView : UIView? {
    get {
      return selectableViews.first { ($0 as! Selectable).isSelected }
    }
  }
  
  @IBAction func handleLongPress(recognizer: UILongPressGestureRecognizer) {
    
    let location = recognizer.location(in: imageView)
    
    // First deselect the currently selected item
    if var oldSelection = selectedView as! Selectable? {
      oldSelection.isSelected = false
    }
    
    // check if location is inside a selectable subview's bounds
    if var view = (selectableViews.first{ $0.frame.contains(location) }) as! Selectable? {
      
      // Found a selectabel view at the tapped location, so select it
      view.isSelected = true
    } else {
      
      // No selctabel view tapped, so add a new feature view
      addFeature(at: location)
    }
  }
  
  @IBAction func handleTap(recognizer: UITapGestureRecognizer) {
    
    let location = recognizer.location(in: imageView)
    guard !(selectedView?.frame.contains(location) ?? false) else { return }
    
    if var selected = selectedView as! Selectable? {
      selected.isSelected = false
    }
  }
}

// MARK: - Helper methods
extension AnnotationViewController {
  
  var inverseScaleTransform : CGAffineTransform {
    let scale = 1.0 / scrollView.zoomScale
    return CGAffineTransform(scaleX: scale, y: scale)
  }
  
  fileprivate func scale<View : UIView>(view: View) {
    guard var scaleInvariantView = view as? ScaleInvariantView else { return }
    scaleInvariantView.transform = inverseScaleTransform
  }
  
  fileprivate func scaleAnnotationViews() {
    for view in imageView.subviews {
      scale(view: view)
    }
  }
  
  fileprivate func addFeature(at position: CGPoint) {
    
    // Add model
    do {
      let point = Point(context: managedObjectContext)
      point.x = Float(position.x / imageView.frame.size.width)
      point.y = Float(position.y / imageView.frame.size.height)
      
      let label = NumericLabel(context: managedObjectContext)
      // TODO: auto assign label to label count of image
      label.label = 23
      let annotation = Annotation(context: managedObjectContext)
      annotation.position = point
      annotation.label = label
      
      annotation.image = imageModel
      
      imageModel.addToAnnotations(annotation)
      
      try managedObjectContext.save()
      
    } catch {
      fatalError("Failed to save context")
    }
    
    // Add visuals
    let view = KeyPointView.loadFromNib(owner: self)
    
    view.position = position
    
    imageView.addSubview(view)
    scale(view: view)
    
  }
}
