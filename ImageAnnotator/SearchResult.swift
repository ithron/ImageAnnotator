//
//  SearchResult.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 02.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

import Foundation

struct SearchResult : Codable {
  
  struct Item : Codable {
    
    struct Image : Codable {
      let width : Int
      let height : Int
      let byteSize : Int
      let thumbnailURL : URL
      let thumbnailWidth : Int
      let thumbnailHeight : Int
      
      enum CodingKeys : String, CodingKey {
        case width
        case height
        case byteSize
        case thumbnailURL = "thumbnailLink"
        case thumbnailWidth
        case thumbnailHeight
      }
    }
    
    let title : String
    let imageURL : URL
    let mimeType : String
    let image : Image
    
    enum CodingKeys : String, CodingKey {
      case title
      case imageURL = "link"
      case mimeType = "mime"
      case image
    }
    
  }
  
  struct Queries : Codable {
    struct NextPage : Codable {
      let startIndex : Int
    }
    
    let nextPage : [NextPage]
  }
  
  let queries : Queries
  let items : [Item]
  
}
