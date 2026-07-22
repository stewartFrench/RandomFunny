//
//  ContentView.swift
//  RandomFunny
//
//  Created by Stewart French on 7/20/26.
//

import SwiftUI
import AVFoundation


// ------------
struct ContentView: View
{
  @StateObject private var funnyManager = FunnyManager()
  
  
  
  var body: some View
  {
    ZStack(alignment: .bottom)
    {
            // Main content
      
      ScrollView
      {
        VStack(spacing: 30)
        {
                  // Header
          
          VStack(spacing: 10)
          {
            Image(systemName: "face.smiling")
              .font(.system(size: 60))
              .foregroundStyle(.blue)
            
            Text("Random Funny")
              .font(.largeTitle)
              .fontWeight(.bold)
            
            Text("\(funnyManager.funnies.count) jokes loaded")
              .font(.caption)
              .foregroundStyle(.secondary)
          } // VStack
          .padding(.top, 40)
          
                  // Voice picker
          
          VStack(alignment: .leading, spacing: 10)
          {
            Text("Voice")
              .font(.headline)
            
            Picker("Select Voice", selection: $funnyManager.selectedVoice)
            {
              ForEach(funnyManager.availableVoices, id: \.identifier)
              {
                voice in
                Text(voiceDisplayName(voice))
                  .tag(voice as AVSpeechSynthesisVoice?)
              } // ForEach
            } // Picker
            .pickerStyle(.menu)
          } // VStack
          .padding(.horizontal)
          
                  // Frequency slider
          
          VStack(alignment: .leading, spacing: 15)
          {
            Text("How often should I tell you jokes?")
              .font(.headline)
            
            HStack
            {
              Text("Very often")
                .font(.caption)
                .foregroundStyle(.secondary)
              
              Slider(value : $funnyManager.frequencyMinutes,
                     in    : 1...120,
                     step  : 1)
                .onChange(of: funnyManager.frequencyMinutes)
                {
                  oldValue, newValue in
                  funnyManager.updateFrequency(newValue)
                } // onChange
              
              Text("Not often")
                .font(.caption)
                .foregroundStyle(.secondary)
              
              Button(action:
              {
                funnyManager.isRandomTiming.toggle()
                funnyManager.saveRandomTimingSetting()
              },
              label:
              {
                Text("Random")
                  .font(.caption)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(funnyManager.isRandomTiming ? 
                              Color.blue : 
                              Color.gray.opacity(0.2))
                  .foregroundStyle(funnyManager.isRandomTiming ? 
                                   .white : 
                                   .primary)
                  .cornerRadius(8)
              } // Button label
              ) // Button
            } // HStack
            
            Text(funnyManager.isRandomTiming ? 
                 "Random timing (1-\(Int(funnyManager.frequencyMinutes)) minutes)" :
                 "Every \(Int(funnyManager.frequencyMinutes)) minutes")
              .font(.subheadline)
              .foregroundStyle(.blue)
              .frame(maxWidth  : .infinity,
                     alignment : .center)
          } // VStack
          .padding(.horizontal)
          
                  // Control buttons
          
          VStack(spacing: 15)
          {
            Button(action:
            {
              if funnyManager.isEnabled
              {
                funnyManager.stopTimer()
              }
              else
              {
                funnyManager.startTimer()
              } // if
            },
            label:
            {
              Label(
                funnyManager.isEnabled ? "Stop Jokes" : "Start Jokes",
                systemImage: funnyManager.isEnabled ? 
                             "stop.circle.fill" : 
                             "play.circle.fill"
              )
              .font(.headline)
              .foregroundStyle(.white)
              .frame(maxWidth : .infinity)
              .padding()
              .background(funnyManager.isEnabled ? Color.red : Color.green)
              .cornerRadius(12)
            } // Button label
            ) // Button
            
            Button(action:
            {
              funnyManager.speakRandomFunny()
            },
            label:
            {
              Label("Tell Me One Now", systemImage: "speaker.wave.2.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth : .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            } // Button label
            ) // Button
          } // VStack
          .padding(.horizontal)
          
                  // Status indicator
          
          HStack
          {
            Circle()
              .fill(funnyManager.isEnabled ? Color.green : Color.clear)
              .frame(width  : 10,
                     height : 10)
            
            Text(funnyManager.isEnabled ? "Active" : "")
              .font(.caption)
              .foregroundStyle(.secondary)
          } // HStack
          .frame(height : 20)
          .padding(.bottom, 20)
          
                  // Debug information (temporary)
          
//          if funnyManager.isEnabled
//          {
//            VStack(alignment: .leading, spacing: 8)
//            {
//              Text("Debug Info:")
//                .font(.caption)
//                .fontWeight(.bold)
//                .foregroundStyle(.secondary)
//              
//              Text("To be told: \(funnyManager.unusedFunnies.count)")
//                .font(.caption)
//                .foregroundStyle(.secondary)
//              
//              Text("Already told: \(funnyManager.usedFunnies.count)")
//                .font(.caption)
//                .foregroundStyle(.secondary)
//              
//              if let nextTime = funnyManager.nextJokeTime
//              {
//                Text("Next joke: \(nextTime.formatted(date: .omitted, time: .shortened))")
//                  .font(.caption)
//                  .foregroundStyle(.secondary)
//              } // if
//            } // VStack
//            .padding(.horizontal)
//            .padding(.vertical, 10)
//            .frame(maxWidth  : .infinity,
//                   alignment : .leading)
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(8)
//            .padding(.horizontal)
//          } // if
          
          // Extra padding for stop button
          
          Color.clear.frame(height : 70)
        } // VStack
      } // ScrollView
      
            // Stop speaking button - fixed at bottom, overlays content
      
      if funnyManager.isSpeaking
      {
        VStack
        {
          Button(action:
          {
            funnyManager.stopSpeaking()
          },
          label:
          {
            Label("Stop Speaking", systemImage: "stop.fill")
              .font(.headline)
              .foregroundStyle(.white)
              .frame(maxWidth : .infinity)
              .padding()
              .background(Color.orange)
              .cornerRadius(12)
          } // Button label
          ) // Button
          .padding(.horizontal)
          .padding(.bottom, 20)
          .background(
            Color(UIColor.systemBackground)
              .shadow(color  : .black.opacity(0.1),
                      radius : 10,
                      x      : 0,
                      y      : -5)
          ) // background
        } // VStack
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.2), value: funnyManager.isSpeaking)
      } // if
    } // ZStack
  } // body
  
  
  
  // ----
  private func voiceDisplayName(_ voice: AVSpeechSynthesisVoice) -> String
  {
    let languageCode = voice.language
    return "\(voice.name) (\(languageCode))"
  } // voiceDisplayName
} // struct ContentView
