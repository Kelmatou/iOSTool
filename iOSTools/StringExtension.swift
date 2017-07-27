//
//  StringExtension.swift
//  iOSTools
//
//  Created by Antoine Clop on 7/21/17.
//  Copyright © 2017 clop_a. All rights reserved.
//

import Foundation

public extension String {
  
  /**
   Get the length of the string encoded in UTF8
   
   - returns: the length of the string in UTF8
  */
  public func length() -> Int {
    return self.lengthOfBytes(using: .utf8)
  }
  
  /**
   Get a substring of current String object
   
   - parameter startIndex: the starting character position
   
   - returns: a substring starting at start index and finishing at the end of current string. nil is returned if startIndex is out of range
  */
  public func substring(startIndex: Int) -> String? {
    guard startIndex >= 0 && startIndex <= length() else {
      return nil
    }
    let startStringIndex: String.Index = self.index(self.startIndex, offsetBy: startIndex)
    return substring(from: startStringIndex)
  }
  
  /**
   Get a substring of current String object
   
   - parameter startIndex: the starting character position
   - parameter length: the desired length of the new string
   
   - returns: a substring starting at start index with a length() of length. If length parameter is too big, stops at the last character.
              nil is returned if startIndex is out of range or if a negative length was passed.
   */
  public func substring(startIndex: Int, length: Int) -> String? {
    let strLength: Int = self.length()
    guard startIndex >= 0 && startIndex <= strLength && length >= 0 else {
      return nil
    }
    let startStringIndex: String.Index = self.index(self.startIndex, offsetBy: startIndex)
    let endPosition: Int = startIndex + length > strLength ? strLength : startIndex + length
    let endStringIndex: String.Index = self.index(self.startIndex, offsetBy: endPosition)
    let range: Range<String.Index> = startStringIndex..<endStringIndex
    return substring(with: range)
  }
  
  /**
   Get the number of occurence of pattern in current String object
   
   - parameter pattern: the string pattern
   
   - returns: the number of occurence of pattern in current string
   */
  public func numberOccurence(of pattern: String) -> Int {
    var occurences: Int = 0
    let curLength: Int = length()
    let patternLength: Int = pattern.length()
    if curLength >= patternLength && patternLength > 0 {
      for index in 0...curLength - patternLength {
        if let substr = substring(startIndex: index, length: patternLength), substr == pattern {
          occurences += 1
        }
      }
    }
    return occurences
  }
  
  /**
   Get the index of first occurence of pattern in current String object
   
   - parameter pattern: the string pattern
   
   - returns: the index of occurence of pattern in current string
   */
  public func firstOccurencePosition(of pattern: String) -> Int? {
    let curLength: Int = length()
    let patternLength: Int = pattern.length()
    if curLength >= patternLength && patternLength > 0 {
      for index in 0...curLength - patternLength {
        if let substr = substring(startIndex: index, length: patternLength), substr == pattern {
          return index
        }
      }
    }
    return nil
  }
}