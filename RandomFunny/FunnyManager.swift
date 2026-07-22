//
//  FunnyManager.swift
//  RandomFunny
//
//  Created by Stewart French on 7/20/26.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer


// ------------
        // Model for the JSON structure
struct FunniesData: Codable
{
  let funnies: [String]
} // struct FunniesData


// ------------
        // Manager class to handle loading and speaking jokes
class FunnyManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate
{
  @Published var funnies            : [String]                   = []
  @Published var isEnabled          : Bool                       = false
  @Published var frequencyMinutes   : Double                     = 5.0
  @Published var isRandomTiming     : Bool                       = false
  @Published var availableVoices    : [AVSpeechSynthesisVoice]   = []
  @Published var selectedVoice      : AVSpeechSynthesisVoice?
  @Published var isSpeaking         : Bool                       = false
  @Published var unusedFunnies      : [String]                   = []
  @Published var usedFunnies        : [String]                   = []
  @Published var nextJokeTime       : Date?
  
  private let synthesizer = AVSpeechSynthesizer()
  private var timer       : Timer?
  private var audioPlayer : AVAudioPlayer?
  
  
  
  // -----------------------------------------
  override init()
  {
    super.init()
    synthesizer.delegate = self
    loadFunnies()
    loadJokeState()
    loadFrequency()
    loadRandomTimingSetting()
    configureAudioSession()
    loadAvailableVoices()
    setupSilentAudioPlayer()
  } // init
  
  
  
  // -----------------------------------------
  private func loadAvailableVoices()
  {
    availableVoices = AVSpeechSynthesisVoice.speechVoices()
      .filter
      {
        $0.language.hasPrefix("en")
      }
      .sorted
      {
        $0.name < $1.name
      }
    
            // Debug: Print all available voice names

    print("Available voices:")
    for voice in availableVoices
    {
      print("  - \(voice.name) (\(voice.language))")
    } // for
    
            // Set default voice to Daniel (en-GB)
    
    selectedVoice = availableVoices.first
    {
      $0.name == "Daniel" && $0.language == "en-GB"
    }
    ?? availableVoices.first
    {
      $0.name == "Daniel"
    }
    ?? availableVoices.first
    {
      $0.language == "en-US"
    }
    ?? availableVoices.first
    
    if let selected = selectedVoice
    {
      print("Selected default voice: \(selected.name) (\(selected.language))")
    } // if
  } // loadAvailableVoices
  
  
  
  // -----------------------------------------
  private func configureAudioSession()
  {
    do
    {
      let audioSession = AVAudioSession.sharedInstance()
      
            // Use .playback category to ensure audio plays even in silent mode
      
      try audioSession.setCategory(.playback,
                                    mode    : .voicePrompt,  // works in CarPlay
//                                    mode    : .default,        // breaks up in CarPlay
//                                    mode    : .spokenAudio,    // breaks up in CarPlay
                                    options : [.mixWithOthers])
      try audioSession.setActive(true)
    }
    catch
    {
      print("Failed to configure audio session: \(error)")
    } // do
  } // configureAudioSession
  
  
  
  // -----------------------------------------
  private func setupSilentAudioPlayer()
  {
            // Create a 1 second silent audio buffer
    
    let sampleRate = 44100.0
    let duration   = 1.0
    let frameCount = UInt32(sampleRate * duration)
    
    guard let format = AVAudioFormat(standardFormatWithSampleRate : sampleRate,
                                      channels                    : 1),
          let buffer = AVAudioPCMBuffer(pcmFormat      : format,
                                         frameCapacity : frameCount) else
    {
      print("Failed to create audio buffer")
      return
    } // guard
    
    buffer.frameLength = frameCount
    
            // Fill with silence (zeros)
    
    if let channelData = buffer.floatChannelData
    {
      let data = channelData[0]
      for i in 0..<Int(frameCount)
      {
        data[i] = 0.0
      } // for
    } // if
    
            // Create temporary file for silent audio
    
    let tempDir    = FileManager.default.temporaryDirectory
    let silenceURL = tempDir.appendingPathComponent("silence.caf")
    
    do
    {
            // Write silent audio to file
      
      let audioFile = try AVAudioFile(forWriting : silenceURL,
                                       settings   : format.settings)
      try audioFile.write(from: buffer)
      
            // Setup audio player with the silent file
      
      audioPlayer = try AVAudioPlayer(contentsOf: silenceURL)
      audioPlayer?.numberOfLoops = -1
      audioPlayer?.volume        = 0.0
      audioPlayer?.prepareToPlay()
    }
    catch
    {
      print("Failed to setup silent audio player: \(error)")
    } // do
  } // setupSilentAudioPlayer
  
  
  
  // -----------------------------------------
  private func startSilentAudio()
  {
    audioPlayer?.play()
  } // startSilentAudio
  
  
  
  // -----------------------------------------
  private func stopSilentAudio()
  {
    audioPlayer?.stop()
  } // stopSilentAudio
  
  
  
  // -----------------------------------------
  func loadFunnies()
  {
    guard let url = Bundle.main.url( forResource : "funnies",
                                   withExtension : "json") else
    {
      print("Failed to locate funnies.json")
      return
    } // guard
    
    do
    {
      let data    = try Data(contentsOf: url)
      let decoded = try JSONDecoder().decode(FunniesData.self, from: data)
      self.funnies = decoded.funnies
      print("Loaded \(funnies.count) funnies")
    }
    catch
    {
      print("Failed to load funnies: \(error)")
    } // do
  } // loadFunnies
  
  
  
  // -----------------------------------------
  private func loadJokeState()
  {
    let defaults = UserDefaults.standard
    
    if let savedUsed   = defaults.array(forKey: "usedFunnies") as? [String],
       let savedUnused = defaults.array(forKey: "unusedFunnies") as? [String]
    {
            // Validate that saved jokes are still in the current joke list
      
      let validUsed   = savedUsed.filter { funnies.contains($0) }
      let validUnused = savedUnused.filter { funnies.contains($0) }
      
            // Check if joke list has changed (new jokes added or removed)
      
      let savedTotal = validUsed.count + validUnused.count
      if savedTotal < funnies.count
      {
                // New jokes were added - add them to unused pool
        
        let allSaved = Set(validUsed + validUnused)
        let newJokes = funnies.filter { !allSaved.contains($0) }
        
        usedFunnies   = validUsed
        unusedFunnies = validUnused + newJokes
        
        print("Restored joke state with \(newJokes.count) new jokes: " +
              "\(usedFunnies.count) used, \(unusedFunnies.count) unused")
      }
      else
      {
        usedFunnies   = validUsed
        unusedFunnies = validUnused
        print("Restored joke state: \(usedFunnies.count) used, " +
              "\(unusedFunnies.count) unused")
      }
      // if
      
      saveJokeState()
    }
    else
    {
            // First launch - start with all jokes available
      
      unusedFunnies = funnies
      usedFunnies   = []
      saveJokeState()
      print("First launch - all \(unusedFunnies.count) jokes available")
    } // if
  } // loadJokeState
  
  
  
  // -----------------------------------------
  private func loadFrequency()
  {
    let defaults = UserDefaults.standard
    
    if defaults.object(forKey: "frequencyMinutes") != nil
    {
      frequencyMinutes = defaults.double(forKey: "frequencyMinutes")
      print("Restored frequency: \(Int(frequencyMinutes)) minutes")
    }
    else
    {
      print("Using default frequency: \(Int(frequencyMinutes)) minutes")
    } // if
  } // loadFrequency
  
  
  
  // -----------------------------------------
  private func saveFrequency()
  {
    let defaults = UserDefaults.standard
    defaults.set(frequencyMinutes, forKey: "frequencyMinutes")
  } // saveFrequency
  
  
  
  // -----------------------------------------
  private func loadRandomTimingSetting()
  {
    let defaults = UserDefaults.standard
    
    if defaults.object(forKey: "isRandomTiming") != nil
    {
      isRandomTiming = defaults.bool(forKey: "isRandomTiming")
      print("Restored random timing: \(isRandomTiming)")
    }
    else
    {
      print("Using default random timing: \(isRandomTiming)")
    } // if
  } // loadRandomTimingSetting
  
  
  
  // -----------------------------------------
  func saveRandomTimingSetting()
  {
    let defaults = UserDefaults.standard
    defaults.set(isRandomTiming, forKey: "isRandomTiming")
  } // saveRandomTimingSetting
  
  
  
  // -----------------------------------------
  private func saveJokeState()
  {
    let defaults = UserDefaults.standard
    defaults.set(usedFunnies,   forKey: "usedFunnies")
    defaults.set(unusedFunnies, forKey: "unusedFunnies")
  } // saveJokeState
  
  
  
  // -----------------------------------------
  private func resetJokePool()
  {
    unusedFunnies = funnies
    usedFunnies.removeAll()
    saveJokeState()
    print("Reset joke pool - all \(unusedFunnies.count) jokes available again")
  } // resetJokePool
  
  
  
  // -----------------------------------------
  func speakRandomFunny()
  {
            // Reset pool if all jokes have been used
    
    if unusedFunnies.isEmpty
    {
      resetJokePool()
    } // if
    
    guard !unusedFunnies.isEmpty else
    {
      print("ERROR: No jokes available!")
      return
    } // guard
    
            // Pick a random joke from unused pool
    
    let randomIndex = Int.random(in: 0..<unusedFunnies.count)
    let randomFunny = unusedFunnies[randomIndex]
    
            // Move joke from unused to used
    
    unusedFunnies.remove(at: randomIndex)
    usedFunnies.append(randomFunny)
    saveJokeState()
    
    print("Speaking: '\(randomFunny.prefix(50))...' " +
          "(\(usedFunnies.count) used, \(unusedFunnies.count) remaining)")
    
    let utterance = AVSpeechUtterance(string: randomFunny)
    utterance.voice              = selectedVoice ?? 
                                   AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate               = 0.52
    utterance.pitchMultiplier    = 1.1
    utterance.volume             = 1.0
    utterance.preUtteranceDelay  = 0.1
    utterance.postUtteranceDelay = 0.2
    
    synthesizer.speak(utterance)
    
            // If timer is running, reschedule next joke from now
    
    if isEnabled
    {
      rescheduleNextJoke()
    } // if
  } // speakRandomFunny
  
  
  
  // -----------------------------------------
  func startTimer()
  {
    stopTimer()
    isEnabled = true
    
            // Start silent audio to keep app active in background
    
    startSilentAudio()
    
            // Calculate interval (random if enabled, fixed otherwise)
    
    let intervalSeconds = getNextInterval()
    
            // Set next joke time
    
    nextJokeTime = Date().addingTimeInterval(intervalSeconds)
    
    timer = Timer.scheduledTimer(withTimeInterval : intervalSeconds,
                                  repeats          : !isRandomTiming)
    {
      [weak self] _ in
      self?.speakRandomFunny()
      
              // If random timing, schedule next joke with new random interval
      
      if self?.isRandomTiming == true
      {
        self?.scheduleNextRandomJoke()
      }
      else
      {
                // For fixed timing, update next joke time
        
        if let interval = self?.frequencyMinutes
        {
          self?.nextJokeTime = Date().addingTimeInterval(interval * 60)
        } // if
      } // else
    } // timer
    
            // Add timer to run loop for background execution
    
    if let timer = timer
    {
      RunLoop.main.add(timer, forMode: .common)
    } // if
    
            // Speak one immediately when starting
    
    speakRandomFunny()
  } // startTimer
  
  
  
  // -----------------------------------------
  private func getNextInterval() -> TimeInterval
  {
    if isRandomTiming
    {
              // Random interval between 1 minute and the slider value
      
      let randomMinutes = Double.random(in: 1...frequencyMinutes)
      print("Next joke in \(Int(randomMinutes)) minutes (random, max: " +
            "\(Int(frequencyMinutes)))")
      return randomMinutes * 60
    }
    else
    {
      return frequencyMinutes * 60
    } // if
  } // getNextInterval
  
  
  
  // -----------------------------------------
  private func scheduleNextRandomJoke()
  {
            // Invalidate current timer
    
    timer?.invalidate()
    timer = nil
    
            // Schedule next joke with new random interval
    
    let intervalSeconds = getNextInterval()
    
            // Set next joke time
    
    nextJokeTime = Date().addingTimeInterval(intervalSeconds)
    
    timer = Timer.scheduledTimer(withTimeInterval : intervalSeconds,
                                  repeats          : false)
    {
      [weak self] _ in
      self?.speakRandomFunny()
      self?.scheduleNextRandomJoke()
    } // timer
    
            // Add timer to run loop for background execution
    
    if let timer = timer
    {
      RunLoop.main.add(timer, forMode: .common)
    } // if
  } // scheduleNextRandomJoke
  
  
  
  // -----------------------------------------
  func stopTimer()
  {
    timer?.invalidate()
    timer        = nil
    isEnabled    = false
    nextJokeTime = nil
    
            // Stop silent audio when timer is stopped
    
    stopSilentAudio()
  } // stopTimer
  
  
  
  // -----------------------------------------
  func updateFrequency(_ minutes: Double)
  {
    frequencyMinutes = minutes
    saveFrequency()
    
    if isEnabled
    {
            // Reschedule next joke with new frequency
      
      rescheduleNextJoke()
    } // if
  } // updateFrequency
  
  
  
  // -----------------------------------------
  private func rescheduleNextJoke()
  {
            // Stop current timer
    
    timer?.invalidate()
    timer = nil
    
            // Calculate new interval
    
    let intervalSeconds = getNextInterval()
    
            // Set next joke time from now
    
    nextJokeTime = Date().addingTimeInterval(intervalSeconds)
    
            // Create new timer
    
    timer = Timer.scheduledTimer(withTimeInterval : intervalSeconds,
                                  repeats          : !isRandomTiming)
    {
      [weak self] _ in
      self?.speakRandomFunny()
      
              // If random timing, schedule next joke with new random interval
      
      if self?.isRandomTiming == true
      {
        self?.scheduleNextRandomJoke()
      }
      else
      {
                // For fixed timing, update next joke time
        
        if let interval = self?.frequencyMinutes
        {
          self?.nextJokeTime = Date().addingTimeInterval(interval * 60)
        } // if
      } // else
    } // timer
    
            // Add timer to run loop for background execution
    
    if let timer = timer
    {
      RunLoop.main.add(timer, forMode: .common)
    } // if
  } // rescheduleNextJoke
  
  
  
  // -----------------------------------------
  func stopSpeaking()
  {
    synthesizer.stopSpeaking(at: .immediate)
  } // stopSpeaking
  
  
  
  // MARK: - AVSpeechSynthesizerDelegate
  
  
  
  // -----------------------------------------
  func speechSynthesizer(_ synthesizer : AVSpeechSynthesizer,
                         didStart utterance : AVSpeechUtterance)
  {
    isSpeaking = true
  } // speechSynthesizer didStart
  
  
  
  // -----------------------------------------
  func speechSynthesizer(_ synthesizer : AVSpeechSynthesizer,
                         didFinish utterance : AVSpeechUtterance)
  {
    isSpeaking = false
  } // speechSynthesizer didFinish
  
  
  
  // -----------------------------------------
  func speechSynthesizer(_ synthesizer : AVSpeechSynthesizer,
                         didCancel utterance : AVSpeechUtterance)
  {
    isSpeaking = false
  } // speechSynthesizer didCancel
} // class FunnyManager
