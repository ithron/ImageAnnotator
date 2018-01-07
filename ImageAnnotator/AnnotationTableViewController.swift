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


