# Software Design Document
# RandomFunny iOS Application

**Version:** 1.0  
**Date:** July 20, 2026  
**Author:** Stewart French  

---

## Public Domain Dedication

This software and all associated documentation are dedicated to the **public domain** 
worldwide under the **Creative Commons CC0 1.0 Universal (CC0 1.0) Public Domain 
Dedication**.

To the extent possible under law, the author has waived all copyright and related or 
neighboring rights to this work. This work is published from: United States.

**You are free to:**

  - Copy, modify, distribute and perform the work
  - Use the work for commercial purposes
  - Use the work without any restrictions whatsoever

**No Copyright   - No Warranty:**

The work is provided "as is", without warranty of any kind, express or implied, 
including but not limited to the warranties of merchantability, fitness for a 
particular purpose and noninfringement.

For more information, please refer to:

  - <https://creativecommons.org/publicdomain/zero/1.0/>

---

## Table of Contents

  1. [Executive Summary](#executive-summary)
  2. [Project Overview](#project-overview)
  3. [System Architecture](#system-architecture)
  4. [Feature Specifications](#feature-specifications)
  5. [Technical Implementation](#technical-implementation)
  6. [Data Management](#data-management)
  7. [Background Execution](#background-execution)
  8. [User Interface Design](#user-interface-design)
  9. [Copyright and Legal Analysis](#copyright-and-legal-analysis)
  10. [Code Style Guidelines](#code-style-guidelines)
  11. [Testing and Validation](#testing-and-validation)
  12. [Future Enhancements](#future-enhancements)

---

## 1. Executive Summary

**RandomFunny** is an iOS application that speaks random jokes and funny content at 
configurable intervals. The app runs in the background and standby mode, providing 
entertainment through text-to-speech technology without requiring user interaction.

**Key Features:**

  - Text-to-speech joke delivery with customizable voices
  - Configurable frequency (1-120 minutes)
  - Background and standby operation
  - Smart joke rotation (no repeats until all jokes heard)
  - Persistent state across app launches
  - Portrait-only orientation
  - 157+ dad jokes and puns

---

## 2. Project Overview

### 2.1 Purpose

RandomFunny delivers spontaneous humor throughout the day by speaking jokes at random 
intervals. The app is designed for users who want ambient entertainment while their 
phone is in their pocket, on a desk, or in standby mode.

### 2.2 Target Platform

  - **Platform:** iOS 15.0+
  - **Language:** Swift 5.9+
  - **UI Framework:** SwiftUI
  - **Device Support:** iPhone only (Portrait orientation)

### 2.3 Project Goals

1. Provide reliable background audio playback
2. Ensure jokes don't repeat until all have been heard
3. Maintain state persistence across app launches
4. Offer flexible timing controls
5. Support multiple voice options
6. Meet App Store guidelines

---

## 3. System Architecture

### 3.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    RandomFunnyApp                       │
│                  (Application Entry)                    │
└────────────────────┬────────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
┌─────────▼─────────┐  ┌────────▼──────────┐
│   ContentView     │  │   AppDelegate     │
│  (Main UI)        │  │  (Lifecycle)      │
└─────────┬─────────┘  └────────┬──────────┘
          │                     │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │   FunnyManager      │
          │  (Business Logic)   │
          └──────────┬──────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
┌────▼─────┐  ┌─────▼──────┐  ┌────▼───────┐
│ funnies  │  │AVSpeech    │  │UserDefaults│
│ .json    │  │Synthesizer │  │  (State)   │
└──────────┘  └────────────┘  └────────────┘
```

### 3.2 Component Responsibilities

**RandomFunnyApp:**

  - Application entry point
  - App delegate configuration
  - Audio session initialization

**ContentView:**

  - User interface presentation
  - User interaction handling
  - Voice selection UI
  - Frequency slider
  - Control buttons

**FunnyManager:**

  - Core business logic
  - Joke loading and management
  - Speech synthesis
  - Timer management
  - Background audio maintenance
  - State persistence

**AppDelegate:**

  - Background audio session setup
  - Application lifecycle management

---

## 4. Feature Specifications

### 4.1 Joke Playback

**Description:** Speaks random jokes using text-to-speech technology.

**Requirements:**

  - Load jokes from bundled JSON file
  - Select random joke from available pool
  - Speak joke using configured voice
  - Track which jokes have been spoken
  - Reset pool when all jokes have been heard

**Technical Details:**

  - Uses AVSpeechSynthesizer for text-to-speech
  - Configurable voice, rate, pitch, and volume
  - Speech parameters optimized for joke delivery

### 4.2 Frequency Control

**Description:** User-configurable interval between jokes.

**Requirements:**

  - Slider range: 1-120 minutes
  - Default: 5 minutes
  - Live updates when timer is running
  - Visual feedback of current setting

**Technical Details:**

  - Timer-based scheduling
  - RunLoop integration for background reliability
  - No immediate playback on frequency adjustment

### 4.3 Voice Selection

**Description:** Choose from available English voices.

**Requirements:**

  - Display all available English voices
  - Show voice name and language variant
  - Default voice: Daniel (en-GB)
  - Persistent selection across app launches

**Technical Details:**

  - Queries AVSpeechSynthesisVoice.speechVoices()
  - Filters for English language variants
  - Sorted alphabetically by name

### 4.4 Background Operation

**Description:** Continue playing jokes when app is backgrounded or
device is in standby.

**Requirements:**

  - Continue timer execution in background
  - Play audio while app is not in foreground
  - Work in silent mode
  - Maintain state across background transitions

**Technical Details:**

  - Silent audio looping technique
  - Background audio mode enabled
  - AVAudioSession configured for playback
  - Timer added to RunLoop with .common mode

### 4.5 State Persistence

**Description:** Remember joke history and settings across app launches.

**Requirements:**

  - Save which jokes have been spoken
  - Remember unused jokes pool
  - Restore state on app launch
  - Handle first launch gracefully

**Technical Details:**

  - UserDefaults storage
  - Keys: "usedFunnies", "unusedFunnies"
  - Save after each joke spoken
  - Save on pool reset

### 4.6 Stop Speaking Control

**Description:** Immediately stop current joke playback.

**Requirements:**

  - Button appears only during speech
  - Slides in from bottom without moving other UI
  - Immediate speech interruption
  - Smooth animation

**Technical Details:**

  - AVSpeechSynthesizerDelegate for state tracking
  - ZStack overlay positioning
  - .immediate boundary for stopping

---

## 5. Technical Implementation

### 5.1 Technology Stack

**Languages & Frameworks:**

  - Swift 5.9+
  - SwiftUI
  - Combine
  - AVFoundation
  - Foundation

**Apple Frameworks:**

  - AVSpeechSynthesizer (Text-to-speech)
  - AVAudioSession (Audio management)
  - AVAudioPlayer (Silent audio playback)
  - Timer (Scheduling)
  - UserDefaults (Persistence)

### 5.2 File Structure

```
RandomFunny/
├── RandomFunnyApp.swift        # App entry point and delegate
├── ContentView.swift           # Main UI view
├── FunnyManager.swift          # Business logic and state management
├── funnies.json               # Joke content database
├── Info.plist                 # App configuration
├── Assets.xcassets/           # Images and app icon
├── format_rules.md            # Code formatting guidelines
└── SoftwareDesignDocument.md  # This document
```

### 5.3 Key Classes and Structures

#### 5.3.1 FunniesData (Struct)

**Purpose:** JSON decoding model

**Properties:**

  - `funnies: [String]`   - Array of joke strings

#### 5.3.2 FunnyManager (Class)

**Purpose:** Core application logic

**Properties:**

```swift
@Published var funnies            : [String]
@Published var isEnabled          : Bool
@Published var frequencyMinutes   : Double
@Published var availableVoices    : [AVSpeechSynthesisVoice]
@Published var selectedVoice      : AVSpeechSynthesisVoice?
@Published var isSpeaking         : Bool

private let synthesizer           : AVSpeechSynthesizer
private var timer                 : Timer?
private var audioPlayer           : AVAudioPlayer?
private var unusedFunnies         : [String]
private var usedFunnies           : [String]
```

**Key Methods:**

  - `loadFunnies()`   - Load jokes from JSON
  - `loadJokeState()`   - Restore state from UserDefaults
  - `saveJokeState()`   - Persist state to UserDefaults
  - `resetJokePool()`   - Reset joke rotation
  - `speakRandomFunny()`   - Select and speak a joke
  - `startTimer()`   - Begin periodic joke playback
  - `stopTimer()`   - End periodic playback
  - `updateFrequency(_:)`   - Adjust timer interval
  - `stopSpeaking()`   - Interrupt current speech
  - `setupSilentAudioPlayer()`   - Create background audio player
  - `startSilentAudio()`   - Begin silent audio loop
  - `stopSilentAudio()`   - End silent audio loop
  - `configureAudioSession()`   - Setup AVAudioSession

#### 5.3.3 ContentView (Struct)

**Purpose:** SwiftUI user interface

**Components:**

  - Header with app name and joke count
  - Voice picker dropdown
  - Frequency slider with labels
  - Start/Stop jokes button
  - Tell me one now button
  - Stop speaking button (conditional)
  - Active status indicator

---

## 6. Data Management

### 6.1 Joke Database

**File:** funnies.json  
**Format:** JSON  
**Structure:**

```json
{
  "funnies": [
    "Why don't scientists trust atoms? Because they make up everything!",
    "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    ...
  ]
}
```

**Content Summary:**

  - 157 total jokes
  - Classic dad jokes and puns
  - Public domain content
  - No copyrighted material

### 6.2 Joke Rotation Algorithm

**Goal:** Prevent repetition until all jokes have been heard

**Implementation:**

  1. Maintain two arrays: `unusedFunnies` and `usedFunnies`
  2. On app launch, load state from UserDefaults
  3. When speaking a joke:
       - If `unusedFunnies` is empty, call `resetJokePool()`
       - Select random index from `unusedFunnies`
       - Move joke from `unusedFunnies` to `usedFunnies`
       - Save state to UserDefaults
  4. When pool resets:
       - Copy all jokes to `unusedFunnies`
       - Clear `usedFunnies`
       - Save state

**Benefits:**

  - No joke repeats until all heard
  - State persists across app launches
  - Automatic reset when exhausted
  - Fair random distribution

### 6.3 Persistence Strategy

**Storage:** UserDefaults  
**Keys:**

  - `usedFunnies`   - Array of spoken jokes
  - `unusedFunnies`   - Array of unspoken jokes

**Save Points:**

  - After each joke is spoken
  - On joke pool reset
  - Before app termination (automatic via UserDefaults)

**Load Points:**

  - App initialization
  - First launch detection (empty UserDefaults)

---

## 7. Background Execution

### 7.1 Challenge

iOS aggressively suspends apps in the background to preserve battery life. Timers 
typically don't fire when an app is backgrounded or the device is in standby mode.

### 7.2 Solution: Silent Audio Technique

**Strategy:** Play continuous silent audio to maintain "active audio app" status

**Implementation:**

1. Generate 1-second silent audio buffer (44.1kHz, mono, zeros)
2. Write buffer to temporary CAF file
3. Create AVAudioPlayer with silent file
4. Configure for infinite loop (`numberOfLoops = -1`)
5. Set volume to 0.0
6. Start playback when timer starts
7. Stop playback when timer stops

**Benefits:**

  - Keeps app active in background
  - Timer fires reliably
  - Works in standby mode
  - Minimal battery impact (no actual audio processing)
  - Standard technique used by time-speaking apps

### 7.3 Audio Session Configuration

**Category:** `.playback`  
**Mode:** `.default`  
**Options:** `[.mixWithOthers]`

**Reasoning:**

  - `.playback` enables background audio
  - `.default` mode for standard speech
  - `.mixWithOthers` allows other apps' audio to play simultaneously
  - Works even in silent mode

### 7.4 Background Modes

**Info.plist Configuration:**
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Required for:**

  - Background audio playback
  - Timer execution while backgrounded
  - Speech synthesis in background

---

## 8. User Interface Design

### 8.1 Design Principles

  - **Simplicity:** Single screen, clear controls
  - **Fixed Layout:** No movement when buttons appear/disappear
  - **Visual Feedback:** Status indicators, animations
  - **Portrait Only:** Locked orientation for consistent experience

### 8.2 Layout Structure

**Top to Bottom:**

  1. Header (Icon, Title, Joke Count)
  2. Voice Picker
  3. Frequency Slider with Labels
  4. Control Buttons (Start/Stop, Tell Me One Now)
  5. Status Indicator (when active)
  6. Stop Speaking Button (overlay, when speaking)

### 8.3 Color Scheme

  - **Primary:** Blue (app icon, text highlights)
  - **Success:** Green (Start button, active indicator)
  - **Warning:** Orange (Stop Speaking button)
  - **Danger:** Red (Stop Jokes button)
  - **Neutral:** System colors for text and backgrounds

### 8.4 Animations

**Stop Speaking Button:**

  - Transition: `.move(edge: .bottom)`
  - Duration: 0.2 seconds
  - Easing: `.easeInOut`
  - Fixed position at bottom (ZStack overlay)

**Button States:**

  - No animations on other buttons
  - Fixed positions
  - Instant color changes

### 8.5 Accessibility

**Text-to-Speech:**

  - Core feature is inherently accessible
  - Voice customization
  - Configurable timing

**Visual:**

  - Clear labels
  - System font sizes
  - High contrast buttons
  - Status indicators

---

## 9. Copyright and Legal Analysis

### 9.1 Software Code

**Status:** Public Domain (CC0 1.0)

All source code is dedicated to the public domain. Anyone may use, modify, distribute, 
or sell this software without restriction.

### 9.2 Joke Content Analysis

**Content Type:** Classic dad jokes, puns, and one-liners

**Copyright Status:** Public Domain / Not Copyrightable

**Legal Analysis:**

1. **Short Phrases Not Copyrightable**

     - Individual jokes are short phrases
     - Copyright law doesn't protect brief expressions
     - Jokes are considered "ideas" not copyrightable "expression"
     - Titles, names, short phrases, slogans generally not protected

2. **Traditional Public Domain Material**

     - These are widely-circulated classic jokes
     - No known original authors
     - Been in public use for decades
     - Part of common cultural knowledge
     - Similar to folk tales and traditional stories

3. **Compilation Exception**

     - While individual jokes aren't copyrightable
     - Collections/compilations can be copyrighted
     - Our selection and arrangement is unique
     - We dedicate our compilation to public domain (CC0)

4. **No Third-Party Content**

     - No jokes from copyrighted books/shows/comedians
     - No branded or trademarked material
     - No celebrity names or references
     - All traditional wordplay and puns

### 9.3 App Store Considerations

**Apple Review Concerns:**

Apple has strict policies about streaming content due to copyright issues with music, 
movies, and other media. RandomFunny is different:

**Why This App is Safe:**

  1. **No Internet Streaming**

     - All content bundled within app
     - No external downloads
     - No user-generated content
     - No third-party APIs

  2. **Public Domain Content**

     - Traditional jokes
     - No copyrighted material
     - Original compilation

  3. **Precedent**

     - Many joke apps exist on App Store
     - Dad joke apps are common category
     - Similar functionality to quote apps

**App Store Response Strategy:**

If questioned during review, state:

  - "All jokes are traditional public domain material"
  - "Content is bundled within the app, not streamed"
  - "No third-party copyrighted content is used"
  - "Similar to other approved joke and quote applications"

### 9.4 Attribution

While not required under CC0 dedication, attribution is appreciated:

"Based on RandomFunny by Stewart French (Public Domain)"

### 9.5 Disclaimer

THE SOFTWARE AND CONTENT ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS 
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## 10. Code Style Guidelines

All code follows the specifications in `format_rules.md`:

### 10.1 Formatting Rules

  - Braces on separate lines with matching alignment
  - Comments after every closing brace
  - Function parameters on separate lines with aligned colons
  - 12 dashes before top-level classes/structs
  - 4 dashes before function declarations
  - 2 blank lines before each function
  - Blank lines before and after comments
  - 2-space indentation (not 4)
  - Comments indented 8 spaces beyond code
  - Colons aligned in object definitions
  - Lines limited to 100 characters

### 10.2 Example

```swift
// ------------
class FunnyManager: NSObject, ObservableObject
{
  @Published var funnies : [String] = []
  
  // ----
  func speakRandomFunny()
  {
            // Select random joke from pool
    let randomIndex = Int.random(in: 0..<unusedFunnies.count)
    
    let utterance = AVSpeechUtterance(string: randomFunny)
    utterance.voice = selectedVoice
    utterance.rate  = 0.52
    
    synthesizer.speak(utterance)
  }
  // speakRandomFunny
}
// class FunnyManager
```

---

## 11. Testing and Validation

### 11.1 Functional Testing

These things have been tested.

**Joke Playback:**

  - Jokes load from JSON
  - Random selection works
  - Speech synthesis functions
  - Voice selection applies
  - Speech can be stopped

**Timer Functionality:**

  - Timer starts on button press
  - Timer fires at configured intervals
  - Timer stops on button press
  - Frequency adjustment works
  - Immediate joke on start

**Joke Rotation:**

  - No repeats until all heard
  - Pool resets automatically
  - State persists across launches
  - First launch initializes correctly

**Background Operation:**

  - Continues in background
  - Works in standby mode
  - Silent audio loops
  - Timer fires reliably
  - Audio session maintained

### 11.2 UI Testing

**Layout:**

  - Portrait-only orientation
  - Fixed element positioning
  - Stop speaking button overlay
  - No unwanted movement
  - ScrollView works

**Interactions:**

  - Buttons respond correctly
  - Slider updates frequency
  - Voice picker changes voice
  - Status indicator accurate
  - Animations smooth

### 11.3 Device Testing

**Tested on:**

  - iPhone 15 Pro (iOS 18+)
  - Various iOS versions
  - Background and foreground modes
  - Silent mode and ringer mode
  - Lock screen and standby

### 11.4 Edge Cases

**Handled:**

  - Empty joke list (graceful failure)
  - JSON parsing errors (error message)
  - Audio session failures (logging)
  - No voices available (fallback)
  - UserDefaults corruption (reset)

---

## 12. Future Enhancements

### 12.1 Potential Features

**Content Expansion:**

  - User-added custom jokes
  - Joke categories/themes
  - Import jokes from files
  - Cloud sync of custom content

**Playback Options:**

  - Speed control
  - Volume control
  - Pitch adjustment
  - Multiple voice rotation
  - Random vs sequential mode

**Scheduling:**

  - Time-of-day restrictions
  - Quiet hours
  - Weekend vs weekday schedules
  - Special occasion jokes

**Social Features:**

  - Share favorite jokes
  - Rate jokes (skip bad ones)
  - Community joke submissions
  - Joke of the day

**Notifications:**

  - Push notification with joke text
  - Option to read or hear
  - Daily summary
  - Streak tracking

**Analytics:**

  - Track joke ratings
  - Usage statistics
  - Favorite voices
  - Listen time

### 12.2 Technical Improvements

**Performance:**

  - Lazy loading of jokes
  - Optimized JSON parsing
  - Memory usage optimization
  - Battery life improvements

**Reliability:**

  - Error recovery
  - Network resilience (if adding cloud)
  - Crash reporting
  - Analytics integration

**Accessibility:**

  - VoiceOver support
  - Dynamic type support
  - Reduced motion mode
  - Accessibility labels

---

## Appendix A: Version History

**Version 1.0 (July 20, 2026)**

  - Initial release
  - 157 jokes
  - Background operation
  - Voice selection
  - Frequency control
  - State persistence
  - Portrait-only orientation
  - Stop speaking functionality

---

## Appendix B: Dependencies

**System Frameworks:**

  - Foundation
  - SwiftUI
  - AVFoundation
  - Combine
  - MediaPlayer (for audio types)

**No Third-Party Libraries**

  - Pure Swift/SwiftUI implementation
  - No external dependencies
  - No package managers required

---

## Appendix C: Build Configuration

**Minimum iOS Version:** 15.0  
**Supported Devices:** iPhone  
**Orientation:** Portrait only  
**Background Modes:** Audio  
**Swift Version:** 5.9+  
**Xcode Version:** 15.0+  

**Build Settings:**
  - Deployment target: iOS 15.0
  - Swift language version: 5
  - Enable background audio

**Info.plist Requirements:**

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
<key>UISupportedInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>
```

---

## Appendix D: Contact and Support

**Project:** RandomFunny  
**Author:** Stewart French  
**Date Created:** July 20, 2026  
**License:** CC0 1.0 Universal (Public Domain)  

**Support:**

This is public domain software provided as-is without warranty or support.
Users are free to modify and redistribute as desired.

---

*End of Software Design Document*
