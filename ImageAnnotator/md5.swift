//
//  md5.swift
//  ImageAnnotator
//
//  Created by Stefan Reinhold on 02.01.18.
//  Copyright © 2018 Stefan Reinhold. All rights reserved.
//

import Foundation

/**
 MD5 C wrapper function
 - Author: Tanel Teemusk
 - Remark: Code originates from [this quora post](https://www.quora.com/How-do-you-generate-an-MD5-hash-in-Swift)
 */
func md5(_ string: String) -> String {
  let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
  var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
  CC_MD5_Init(context)
  CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
  CC_MD5_Final(&digest, context)
  context.deallocate(capacity: 1)
  var hexString = ""
  for byte in digest {
    hexString += String(format:"%02x", byte)
  }
  return hexString
}
