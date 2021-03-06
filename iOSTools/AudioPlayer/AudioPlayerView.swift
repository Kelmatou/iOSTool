//
//  AudioPlayerView.swift
//  iOSTools
//
//  Created by Antoine Clop on 11/6/17.
//  Copyright © 2017 clop_a. All rights reserved.
//

import UIKit

@IBDesignable public class AudioPlayerView: UIView {
  
  // MARK: IBOutlet
  
  @IBOutlet var audioPlayerView: UIView!
  @IBOutlet public weak var playingNow: UILabel!
  @IBOutlet public weak var playButton: UIButton!
  @IBOutlet public weak var stopButton: UIButton!
  @IBOutlet public weak var replayButton: UIButton!
  @IBOutlet public weak var rewindButton: UIButton!
  @IBOutlet public weak var forwardButton: UIButton!
  @IBOutlet public weak var speakerButton: UIButton!
  @IBOutlet public weak var progressBar: SongProgressView!
  
  // MARK: - Property
  
  private(set) public var player: AudioPlayer = AudioPlayer()
  public weak var delegate: AudioPlayerDelegate?
  public var noSongTitle: String = "AudioPlayer"
  
  private var muted: Bool = false
  private var timerRunning: Bool = false
  internal let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
  
  // MARK: - UIView
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    initView()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    initView()
  }
  
  private func initView() {
    if let frameworkBundle: Bundle = Bundle(identifier: "com.clop-a.iOSTools") {
      frameworkBundle.loadNibNamed("AudioPlayerView", owner: self, options: nil)
      player.delegate = self
      progressBar.delegate = self
      addSubview(audioPlayerView)
      audioPlayerView.frame = self.bounds
      audioPlayerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
      setupProgressBar()
      setupUpdater()
    }
  }
  
  // MARK: - Setup
  
  internal func setupProgressBar() {
    progressBar.transform = CGAffineTransform(scaleX: 1, y: 4)
    progressBar.setProgress(0, animated: false)
  }
  
  func setupUpdater() {
    timer.schedule(deadline: .now(), repeating: .milliseconds(100))
    timer.setEventHandler {
      if let player = self.player.player {
        let percentageProgression: Float = Float(player.currentTime / player.duration)
        self.progressBar.setProgress(percentageProgression, animated: true)
      }
    }
  }
  
  /**
   Update icon of play button
   
   - parameter playing: if true, set pause icone else play icone
   */
  internal func playButtonUpdate(playing: Bool) {
    let imageToUse: String = playing ? "pause" : "play"
    let image: UIImage? = UIImage(named: imageToUse, in: Bundle(for: AudioPlayer.self), compatibleWith: nil)
    DispatchQueue.main.async {
      self.playButton.setImage(image, for: .normal)
    }
  }
  
  /**
   Update icon of speaker button
   */
  internal func speakerButtonUpdate() {
    let imageToUse: String = muted ? "mute" : "speaker"
    let image: UIImage? = UIImage(named: imageToUse, in: Bundle(for: AudioPlayer.self), compatibleWith: nil)
    DispatchQueue.main.async {
      self.speakerButton.setImage(image, for: .normal)
    }
  }
  
  /**
   Update timer status
   
   - parameter running: if true, resume timer, if false suspend it
   */
  internal func timerUpdate(running: Bool) {
    guard running != timerRunning else {
      return
    }
    timerRunning = running
    if timerRunning {
      timer.resume()
    }
    else {
      timer.suspend()
    }
  }
  
  // MARK: - IBAction
  
  @IBAction func replaySong(_ sender: Any) {
    player.replay()
  }
  
  @IBAction func playSong(_ sender: Any) {
    if player.status == .Playing {
      player.pause()
    }
    else {
      player.play()
    }
  }
  
  @IBAction func stopSong(_ sender: Any) {
    player.stop()
  }
  
  @IBAction func fastRewindSong(_ sender: Any) {
    player.fastRewind()
  }
  
  @IBAction func fastForwardSong(_ sender: Any) {
    player.fastFoward()
  }
  
  @IBAction func muteSong(_ sender: Any) {
    muted = !muted
    speakerButtonUpdate()
    player.setVolume(muted ? 0 : 1)
  }
}

extension AudioPlayerView: SongProgressViewDelegate {
  
  public func touchEnded(_ view: SongProgressView, touch: UITouch) {
    guard let player = player.player else {
      return
    }
    let progress: Float = progressBar.progress
    let timeInSong: TimeInterval = player.duration * Double(progress)
    self.player.setCurrentTime(timeInSong)
  }
}
