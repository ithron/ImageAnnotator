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
