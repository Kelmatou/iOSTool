//
//  AudioPlayerQueue.swift
//  iOSTools
//
//  Created by Antoine Clop on 10/31/17.
//  Copyright © 2017 clop_a. All rights reserved.
//

import Foundation

open class AudioQueue {
  
  // Ways to move currentSong index
  public enum IndexMove {
    case Prev
    case Next
  }
  
  // MARK: - Properties
  
  internal weak var delegate: AudioPlayerQueueDelegate?
  private(set) public var songQueue: [AudioSong] = []
  private(set) public var currentSong: Int = 0
  
  public var canLoop: Bool = false
  
  // MARK: - Song Selection
  
  /**
   Get current song's name
   
   - returns: the name of the song at currently selected to be played. Return nil if songQueue is empty.
   */
  public func getCurrentSongName() -> String? {
    guard !songQueue.isEmpty else {
      return nil
    }
    return songQueue[currentSong].name
  }
  
  /**
   Get next song file path
   
   - returns: the path of the song, nil if file was not found
   */
  public func getCurrentSongURL() -> URL? {
    guard songQueue.count > 0 else {
      return nil
    }
    var nextSongURL: URL?
    let startIndex: Int = currentSong // Prevent infinite loop if canLoop option is enabled
    while (nextSongURL == nil) {
      let nextSong = songQueue[currentSong]
      if !nextSong.removed, let path = Bundle.main.path(forResource: nextSong.name, ofType: nil) {
        nextSongURL = URL(fileURLWithPath: path)
      }
      else {
        debugPrint("[ERROR]: Cannot find file " + nextSong.name)
        if !setCurrentSong(.Next) || startIndex == currentSong {
          return nil
        }
      }
    }
    return nextSongURL
  }

  /**
   Change currentSong index in queue
   
   - parameter move: the way index should move
   - parameter allowLoop: override canLoop for this call only. If nil, keep canLoop behavior
   
   - returns: true if index changed
   */
  @discardableResult public func setCurrentSong(_ move: IndexMove, allowLoop: Bool? = nil) -> Bool {
    let startIndex: Int = currentSong
    let loopAllowed: Bool = allowLoop == nil ? canLoop : allowLoop!
    switch move {
    case .Prev:
      currentSong = currentSong == 0 ? loopAllowed && songQueue.count > 0 ? songQueue.count - 1 : 0 : currentSong - 1
    case .Next:
      currentSong = currentSong + 1 >= songQueue.count ? loopAllowed ? 0 : currentSong : currentSong + 1
    }
    if startIndex != currentSong && songQueue[startIndex].removed {
      songQueue.remove(at: startIndex)
      if startIndex < currentSong {
        currentSong -= 1
      }
    }
    return startIndex != currentSong
  }
  
  /**
   Change currentSong index in queue
   
   - parameter index: the way index should move. If index is out of range, does nothing
   */
  public func setCurrentSong(at index: Int) {
    let currentSongIsRemoved: Bool = currentSong < songQueue.count && songQueue[currentSong].removed
    if index >= 0 && index < songQueue.count - (currentSongIsRemoved ? 1 : 0) {
      if currentSongIsRemoved {
        songQueue.remove(at: currentSong)
      }
      currentSong = index
    }
  }
  
  // MARK: - Song Queue Manipulation
  
  /**
   Initialize queue with songs file's name
   
   - parameter songs: the list of songs file's name
   */
  public init(songs: [String] = []) {
    currentSong = 0
    self.songQueue = []
    for song in songs {
      self.songQueue.append(AudioSong(song))
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Add a song to the queue
   
   - parameter song: the song to append to songQueue
   */
  public func append(_ song: String) {
    songQueue.append(AudioSong(song))
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Add a songs to the queue
   
   - parameter songs: the songs to append to songQueue
   */
  public func append(_ songs: [String]) {
    for song in songs {
      songQueue.append(AudioSong(song))
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Add a song to the queue at a specified position
   
   - parameter song: the song to add into songQueue
   - parameter index: the position of sound. If lower than 0, index = 0, if greater than songQueue.count, has the same behavior as append(song:)
   */
  public func insert(_ song: String, at index: Int) {
    if index <= currentSong {
      currentSong += 1
    }
    if index < songQueue.count {
      songQueue.insert(AudioSong(song), at: index < 0 ? 0 : currentSong < index ? index + 1 : index)
    }
    else {
      songQueue.append(AudioSong(song))
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Remove all songs from queue
   */
  public func removeAll() {
    guard !isEmpty() else { return }
    let currentSongName: String = songQueue[currentSong].name
    currentSong = 0
    songQueue.removeAll()
    currentSongRemoved(self, song: currentSongName)
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Remove song at a specified position. If no song are found at index, does nothing.
   
   - parameter index: the index of song to remove
   */
  public func remove(at index: Int) {
    let currentSongIsRemoved: Bool = currentSong < songQueue.count && songQueue[currentSong].removed
    let maxIndex: Int = songQueue.count - (currentSongIsRemoved ? 1 : 0)
    guard index >= 0 && index < maxIndex else {
      return
    }
    if index == currentSong && !currentSongIsRemoved {
      let currentSongName: String = songQueue[currentSong].name
      songQueue[index].removed = true
      currentSongRemoved(self, song: currentSongName)
    }
    else {
      let removingIndex: Int = index + (currentSongIsRemoved ? 1 : 0)
      songQueue.remove(at: removingIndex)
      if removingIndex < currentSong {
        currentSong -= 1
      }
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Remove songs by name. Can also specify if it should remove first match only
   
   - parameter named: the name of songs to remove
   - parameter firstOnly: if true, will only remove first match. Default is false
   */
  public func remove(named: String, firstOnly: Bool = false) {
    var songsRemoved: Int = 0
    for (index, song) in songQueue.enumerated() {
      let indexAdjusted: Int = index - songsRemoved
      if song.name == named && !song.removed {
        remove(at: indexAdjusted)
        songsRemoved += 1
        if firstOnly {
          break
        }
      }
      else if song.removed {
        songsRemoved += 1
      }
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Move a song from a position to another. Even when moved, current song remains selected
   
   - parameter src: the current index of the song if out of range, does nothing
   - parameter dst: the destination index, if out of range, does nothing
   */
  public func moveSong(at src: Int, to dst: Int) {
    let currentSongIsRemoved: Bool = currentSong < songQueue.count && songQueue[currentSong].removed
    let maxIndex: Int = songQueue.count - (currentSongIsRemoved ? 1 : 0)
    guard src >= 0 && src < maxIndex && dst >= 0 && dst < maxIndex else {
      return
    }
    let srcAdjusted: Int = currentSongIsRemoved && currentSong <= src ? src + 1 : src
    let dstAdjusted: Int = currentSongIsRemoved && currentSong <= dst ? dst + 1 : dst
    let songMoved: AudioSong = songQueue[srcAdjusted]
    songQueue.remove(at: srcAdjusted)
    songQueue.insert(songMoved, at: dstAdjusted)
    if currentSong == srcAdjusted {
      currentSong = dstAdjusted
    }
    else if currentSong > srcAdjusted && dstAdjusted >= currentSong {
      currentSong -= 1
    }
    else if currentSong < srcAdjusted && dstAdjusted <= currentSong {
      currentSong += 1
    }
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Randomly shuffle queue songs
   */
  public func shuffle() {
    var newQueue: [AudioSong] = []
    for _ in 0 ..< songQueue.count {
      let randomIndex: Int = Int(arc4random_uniform(UInt32(songQueue.count)))
      let randomSong: AudioSong = songQueue[randomIndex]
      if randomIndex == currentSong {
        currentSong = newQueue.count
      }
      newQueue.append(randomSong)
      songQueue.remove(at: randomIndex)
    }
    songQueue = newQueue
    queueUpdate(self, queue: AudioSong.toStringArray(songQueue))
  }
  
  /**
   Determines if currentSong is first in songQueue
   
   returns: true if currentSong is first in songQueue or queue is empty
   */
  public func currentIsFirstSong() -> Bool {
    return songQueue.isEmpty || currentSong == 0
  }
  
  /**
   Determines if currentSong is last in songQueue
   
   returns: true if currentSong is last in songQueue or queue is empty
   */
  public func currentIsLastSong() -> Bool {
    return songQueue.isEmpty || currentSong + 1 >= songQueue.count
  }
  
  /**
   Determines if queue is empty or not
   
   returns: true if songQueue is empty
   */
  public func isEmpty() -> Bool {
    return songQueue.isEmpty || (songQueue.count == 1 && songQueue[0].removed)
  }
}
