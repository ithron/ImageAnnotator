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
import CoreData

class ThumbnailTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  
  var managedObjectContext: NSManagedObjectContext?
  
  var _fetchedResultsController: NSFetchedResultsController<Image>?
  
  var fetchPredicate : NSPredicate?
  
}

// MARK: - UITableViewDataSource
extension ThumbnailTableViewController {
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 0
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.numberOfObjects
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ThumbnailCell", for: indexPath)
    let image = fetchedResultsController.object(at: indexPath)
    configureCell(cell, withImage: image)
    return cell
  }
  
  func configureCell(_ cell: UITableViewCell, withImage image: Image) {
    if let thumbnailData = image.thumbnail?.data?.data {
      cell.imageView?.image = UIImage(data: thumbnailData)
    } else {
      print("Fetch thumbnail from: \(String(describing: image.thumbnail?.url))")
    }
    
    cell.textLabel?.text = image.id!
    cell.textLabel?.adjustsFontSizeToFitWidth = true
    
    cell.detailTextLabel?.text = "w: \(image.width) h: \(image.height)"
    
  }
  
}

// MARK: - NSFetchedResultsControllerDelegate
extension ThumbnailTableViewController {
  
  var fetchedResultsController: NSFetchedResultsController<Image> {
    if _fetchedResultsController != nil {
      return _fetchedResultsController!
    }
    
    let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
    
    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 20
    
    // Edit the sort key as appropriate.
    let sortDescriptor = NSSortDescriptor(key: "index", ascending: true)
    
    fetchRequest.sortDescriptors = [sortDescriptor]
    if let pred = fetchPredicate {
      fetchRequest.predicate = pred
    }
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
    aFetchedResultsController.delegate = self
    _fetchedResultsController = aFetchedResultsController
    
    do {
      try _fetchedResultsController!.performFetch()
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    return _fetchedResultsController!
  }
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .fade)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .fade)
    case .update:
      configureCell(tableView.cellForRow(at: indexPath!)!, withImage: anObject as! Image)
    case .move:
      configureCell(tableView.cellForRow(at: indexPath!)!, withImage: anObject as! Image)
      tableView.moveRow(at: indexPath!, to: newIndexPath!)
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
}
