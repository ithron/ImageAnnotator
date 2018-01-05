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

class SearchViewController: ThumbnailTableViewController, UISearchBarDelegate {
  
  var searchQuery : SearchQuery?
  
  let imageQueue = DispatchQueue(label: "ImageQueue")
  
}

// MARK: - UIViewController Overrides
extension SearchViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    super.fetchPredicate = NSPredicate(format: "state == 0")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    tableView.bottomRefreshControl = refreshControl
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    tableView.bottomRefreshControl = nil
    
    super.viewWillDisappear(animated)
  }
  
}

// MARK: - Search Query
extension SearchViewController {
  
  fileprivate func searchCompletionHandler(_ result_: SearchResult?, _ error: SearchQuery.QueryError?) {
    DispatchQueue.main.async {
      
      guard let result = result_ else {
        UIAlertController(title: "Search Failed",
                          message: error?.localizedDescription ?? "Unknown error",
                          preferredStyle: .alert).show(self, sender: self)
        return
      }
      
      let context = self.fetchedResultsController.managedObjectContext
      
      let query = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
      
      for item in result.items {
        
        let id = md5(item.imageURL.absoluteString)
        
        query.predicate = NSPredicate(format: "id == '\(id)'")
        // ignore duplicates
        if (try? context.fetch(query) as! [Image])?.isEmpty == false {
          continue
        }
        
        let newImage = Image(context: context)
        
        newImage.index = Int64(Date().timeIntervalSinceReferenceDate)
        newImage.id = id
        newImage.width = Int32(item.image.width)
        newImage.height = Int32(item.image.height)
        newImage.url = item.imageURL
        newImage.state = 0
        
        let newThumbnail = Thumbnail(context: context)
        newThumbnail.image = newImage
        newThumbnail.url = item.image.thumbnailURL
        
        newImage.thumbnail = newThumbnail
      }
      
      // Save the context.
      do {
        try context.save()
      } catch {
        UIAlertController(title: "Saving Failed",
                          message: error.localizedDescription,
                          preferredStyle: .alert).show(self, sender: self)
        return
      }
      
      self.fetchImages()
    }
  }
  
  fileprivate func fetchImages() {
    let context = fetchedResultsController.managedObjectContext
    let fetchRequest = NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
    fetchRequest.predicate = NSPredicate(format: "data == nil")
    
    if let results = try? context.fetch(fetchRequest) {
      for fetchResult in results {
        imageQueue.async {
          if let data = try? Data(contentsOf: fetchResult.url!) {
            
            DispatchQueue.main.async {
              let newData = ThumbnailData(context: context)
              newData.data = data
              
              fetchResult.data = newData
            }
          }
        }
      }
      
      imageQueue.async {
        DispatchQueue.main.async {
          
          do {
            try context.save()
          } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
          }
          
          
          self.tableView.reloadData()
        }
      }
    }
  }
  
  @objc
  fileprivate func refresh() {
    searchQuery?.run(completionHandler: searchCompletionHandler)
    tableView.bottomRefreshControl?.endRefreshing()
  }
  
}

// MARK: - UITableViewDelegate
extension SearchViewController {
  
  // Add gesture
  override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    
    let addAction = UIContextualAction(style: .destructive, title: "Add") {_,_, success in
      
      let object = self.fetchedResultsController.object(at: indexPath)
      object.setValue(2, forKey: "state")
      
      try? self.fetchedResultsController.managedObjectContext.save()
      
      success(true)
    }
    addAction.backgroundColor = .green
    
    return UISwipeActionsConfiguration(actions: [addAction])
  }
  
  // Remove gesture
  override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    
    let removeAction = UIContextualAction(style: .destructive, title: "Remove") { _, _, success in
      
      let object = self.fetchedResultsController.object(at: indexPath)
      object.setValue(1, forKey: "state")
      do {
        try self.fetchedResultsController.managedObjectContext.save()
      } catch {
        print("Failed to save context: \(error.localizedDescription)")
      }
      
      success(true)
    }
    removeAction.backgroundColor = .red
    
    return UISwipeActionsConfiguration(actions: [removeAction])
  }
  
}

// MARK: - SearchBarDelegate
extension SearchViewController {
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let keywords = searchBar.text else { return }
    
    defer {
      searchBar.resignFirstResponder()
    }
    
    do {
      searchQuery = try SearchQuery(query: keywords)
      searchQuery?.run(completionHandler: searchCompletionHandler)
    } catch {
      UIAlertController(title: "Invalid Query",
                        message: error.localizedDescription,
                        preferredStyle: .alert).show(self, sender: self)
      return
    }
    
  }
  
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
  
}

