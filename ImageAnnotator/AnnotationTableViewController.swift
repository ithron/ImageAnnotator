//
//  AnnotateTableViewController.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 05.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

class AnnotationTableViewController : ThumbnailTableViewController {
  
  override var fetchPredicate: NSPredicate? {
    return NSPredicate(format: "state == 2")
  }
  
  override var cacheName: String? { return "AnnotationTableView" }
  
}

// MARK: UITableViewDelegate
extension AnnotationTableViewController {
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAt: indexPath)
    
    if fetchedResultsController.object(at: indexPath).file != nil {
      cell.accessoryType = .disclosureIndicator
    }
    
    return cell
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "annotate", let dest = segue.destination as? AnnotationViewController {
      
      if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
        let img = fetchedResultsController.object(at: indexPath)
        do {
          
          let fileManager = FileManager.default
          let docUrl = try fileManager.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: false)
          let imgDir = docUrl.appendingPathComponent("Images")
          let imgURL = imgDir.appendingPathComponent("\(img.id!).png")
          
          let data = try Data(contentsOf: imgURL)
          dest.image = UIImage(data: data)
          dest.managedObjectContext = self.managedObjectContext
          dest.imageModel = img
        } catch {
          print("Failed to load image \(img.id!)")
          return
        }
      }
      
    }
  }
  
}
