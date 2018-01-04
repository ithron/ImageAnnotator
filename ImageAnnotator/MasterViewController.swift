//
//  MasterViewController.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 02.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
  
  var detailViewController: DetailViewController?
  var managedObjectContext: NSManagedObjectContext?
  
  var _fetchedResultsController: NSFetchedResultsController<Image>?
  
  var searchQuery : SearchQuery?
  
  let imageQueue = DispatchQueue(label: "ImageQueue")
  
}

// MARK: - UIViewController Overrides
extension MasterViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    if let split = splitViewController {
      let controllers = split.viewControllers
      detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    tableView.bottomRefreshControl = refreshControl
  }
  
  override func viewWillAppear(_ animated: Bool) {
    clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}

// MARK: - Search Query
extension MasterViewController {
  
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
extension MasterViewController {
  
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

// MARK: - UITableViewDataSource
extension MasterViewController {
  
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
extension MasterViewController {
  
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
    fetchRequest.predicate = NSPredicate(format: "state == 0")
    
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

// MARK: - SearchBarDelegate
extension MasterViewController {
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let keywords = searchBar.text else { return }
    print("Search for: \(keywords)")
    
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
  
}


// MARK: - Segues
extension MasterViewController {
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let object = fetchedResultsController.object(at: indexPath)
        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
        controller.detailItem = object
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  
}
