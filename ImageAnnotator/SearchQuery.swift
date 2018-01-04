//
//  SearchQuery.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 02.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

import CoreData
import UIKit

class SearchQuery {
  
  enum QueryError : Error {
    case InvalidQuery(String)
    case QueryFailed(String)
    case CodingError(String)
  }
  
  let searchBaseUrl = "https://www.googleapis.com/customsearch/v1"
  
  let apiKey =
    Bundle.main.object(forInfoDictionaryKey: "Google API Key")! as! String
  
  let searchEngineID =
    Bundle.main.object(forInfoDictionaryKey: "Google Custom Search Engine ID")! as! String
  
  let searchFileds =
    "items(image(" +
      "byteSize%2C" + "height%2C" + "thumbnailHeight%2C" + "thumbnailLink%2C" +
      "thumbnailWidth%2C" + "width)%2" + "Clink%2Cmime%2Ctitle)%2Cqueries"
  
  let searchType = "image"
  
  var queryBaseUrl : String {
    let url =
      "\(searchBaseUrl)?key=\(apiKey)&cx=\(searchEngineID)&" +
    "fields=\(searchFileds)&searchType=\(searchType)"
    
    if let idx = self.nextIndex {
      return url + "&start=\(idx)"
    }
    return url
  }
  
  func queryUrl(query : String) -> URL {
    return URL(string: "\(queryBaseUrl)&q=\(query)")!
  }
  
  var task : URLSessionTask!
  
  let escapedQuery : String
  
  var nextIndex : Int?
  
  init(query: String) throws {
    
    guard let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      throw QueryError.InvalidQuery(query)
    }
    
    self.escapedQuery = escapedQuery
  }
  
  func run(completionHandler: @escaping (SearchResult?, QueryError?) -> (Void)) {
    let request = URLRequest(url: queryUrl(query: escapedQuery))
    
    task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let theError = error {
        completionHandler(nil, QueryError.QueryFailed(theError.localizedDescription))
        return
      }
      
      if let theData = data {
        guard let result = try? JSONDecoder().decode(SearchResult.self, from: theData) else {
          completionHandler(nil,
                            QueryError.CodingError(
                              "Failed to decode result: \(String(data: theData, encoding: .utf8)!)"))
          return
        }
        if let next = result.queries.nextPage.first?.startIndex {
          self.nextIndex = max(next, self.nextIndex ?? 0)
          
        }
        completionHandler(result, nil)
      }
    }
    
    task.resume()
  }
}
