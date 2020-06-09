import Foundation
import CanvasGraphics
import AudioKit

class Sketch : NSObject {
    
    // NOTE: Every sketch must contain an object of type Canvas named 'canvas'
    //       Therefore, the line immediately below must always be present.
    let canvas : Canvas
    
    // Create an array of many agents
    var agents: [Agent] = []
    
    // Set up objects needed for microphone analysis
    // SOURCE: https://audiokit.io/examples/MicrophoneAnalysis/
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    // Track whether AudioKit has been started
    var audioKitStarted = false
    
    // Used to analyze mic input
    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    
    // This function runs once
    override init() {
        
        // Create canvas object – specify size
        canvas = Canvas(width: 700, height: 700)
        
        // No fill on canvas
        canvas.drawShapesWithFill = false
        
        // Create many instances of the Agent structure
        for _ in 1...50 {
            
            let anotherAgent = Agent(centre: Point(x: Int.random(in: 345...355), y: Int.random(in: 345...355)),
                                     radius: Int.random(in: 35...55),
                                     velocity: Vector(x: Double.random(in: -2...2),
                                                      y: Double.random(in: -2...2)),
                                     drawsUpon: canvas)
            
            agents.append(anotherAgent)
            
        }
        
    }
    
    // this variable won't update since it is outside the draw function
    // Use x to randomly choose a colour for the animation
    var x: Double = random(in: 0...360)
    
    
    // This function runs repeatedly, forever, to create the animated effect
    func draw() {
        
        //every 15 seconds
        if canvas.frameCount % 1000 == 0{
            
            //colour of animation changes
            if x + 50 > 360 {
                x = Double.random(in: 0...15)
            } else {
                x += 50
            }
        }
        
        
        //DEBUG: Print x values
        print("\(x) is the x value")
        
        // Clear the canvas
        //clearCanvas()
        
        // Update the position of the agent
        for agent in agents {
            agent.update(drawingBoundary: false)
        }
        
        // On first frame, initialize the audio analysis
        if canvas.frameCount == 0 {
            
            // Ask for permission to access the microphone, then start audio kit
            getMicrophoneAccessPermission()
            
        }
        
        // See what's happening with the microphone, if AudioKit is available
        
        //starting values for brightness and hue
        var brightness: Double = 5
        var hue: Double = x
        
        
        if audioKitStarted {
            
            updateMicrophoneInputAnalysis()
            
            
            // Adjust how hue changes based on frequency
            hue = map(value: tracker.frequency, fromLower: 0, fromUpper: 2500, toLower: x, toUpper: x + 100)
            // Adjust how brightness changes based on amplitude
            brightness = map(value: tracker.amplitude, fromLower: 0, fromUpper: 1, toLower: 25, toUpper: 100)
            
            // DEBUG: Print pitch and amplitude
            print(tracker.amplitude)
            print(tracker.frequency)
            
            //            // Change direction when loud sound occurs
            //            if angle > 2.5 {
            //
            //                if turnRight == true {
            //                    turnRight = false
            //                } else {
            //                    turnRight = true
            //                }
            //
            //            }
        }
        
        //Checks for overlaps between all agents
        //Left side (agent checking)
        for i in 0...agents.count - 2 {
            
            //Right side (agent being checked)
            for j in (i + 1)...agents.count - 1 {
                
                
                
                if agents[i].isOverlapping(this: agents[j]) {
                    //distance between circles (length of lines) corelates to alpha of lines
                    let distance = map(value: Double(distanceBetween(a: agents[i].centre, b: agents[j].centre)), fromLower: 0, fromUpper: 110, toLower: 0, toUpper: 10)
                    
                    //adjust line colour based on hue, brightness and distance variables
                    canvas.lineColor = Color.init(hue: Int(hue), saturation: 100, brightness: Int(brightness), alpha: Int(distance))
                    
                    canvas.drawLine(from: agents[i].centre, to: agents[j].centre)
                }
            }
        }
        
        
    }
    
    // Clear the canvas
    func clearCanvas() {
        
        // "Clear" the canvas after each draw
        canvas.drawShapesWithBorders = false
        canvas.drawShapesWithFill = true
        canvas.fillColor = .white
        canvas.drawRectangle(at: Point(x: 0, y: 0), width: canvas.width, height: canvas.height)
        canvas.drawShapesWithFill = false
        canvas.drawShapesWithBorders = true
        
    }
    
    //get the distance between one point and another point
    func distanceBetween(a: Point, b: Point) -> CGFloat {
        
        //length of a line segment formula
        return sqrt( pow(b.x - a.x, 2) + pow(b.y - a.y, 2) )
    }
    // Update analysis of input from mic
    func updateMicrophoneInputAnalysis() {
        
        if tracker.amplitude > 0.1 {
            let trackerFrequency = Float(tracker.frequency)
            
            guard trackerFrequency < 7_000 else {
                // This is a bit of hack because of modern Macbooks giving super high frequencies
                return
            }
            
            let frequencyText = String(format: "%0.1f", tracker.frequency)
            //            print("Frequency is: \(frequencyText)")
            
            var frequency = trackerFrequency
            while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
                frequency /= 2.0
            }
            while frequency < Float(noteFrequencies[0]) {
                frequency *= 2.0
            }
            
            var minDistance: Float = 10_000.0
            var index = 0
            
            for i in 0..<noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[i]) - frequency)
                if distance < minDistance {
                    index = i
                    minDistance = distance
                }
            }
            let octave = Int(log2f(trackerFrequency / frequency))
            
            let noteNameWithSharps =  "\(noteNamesWithSharps[index])\(octave)"
            //            print("Note name with sharps is: \(noteNameWithSharps)")
            let noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
            //            print("Note name with flats is: \(noteNameWithFlats)")
            
        }
        
        let amplitudeValue = String(format: "%0.2f", tracker.amplitude)
        //        print("Amplitude is: \(amplitudeValue)")
        
    }
    
    // This is necessary to gain access to the microphone
    func getMicrophoneAccessPermission() {
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
        case .authorized: // The user has previously granted access to the camera.
            print("User has previously granted microphone access.")
            self.setupCaptureSession()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: AVMediaType.audio) { granted in
                if granted {
                    print("User granted microphone access.")
                    self.setupCaptureSession()
                } else {
                    print("Error: User did not grant microphone access.")
                }
            }
            
        case .denied: // The user has previously denied access.
            print("Error: User has previously denied access to the microphone.")
            
        case .restricted: // The user can't grant access due to restrictions.
            print("Error: User does not have permission to grant access to the microphone.")
        @unknown default:
            fatalError()
        }
        
    }
    
    // Setup microphone capture and start audio kit
    func setupCaptureSession() {
        
        // Allow for audio input
        AKSettings.audioInputEnabled = true
        
        // Set audio kit sample rate to match microphone sampling rate
        // NOTE: This is key to avoid a crash.
        // SEE: https://github.com/AudioKit/AudioKit/issues/1851
        AKSettings.sampleRate = AudioKit.engine.inputNode.inputFormat(forBus: 0).sampleRate
        
        // Initialize audio objects
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        
        // Try starting AudioKit
        AudioKit.output = silence
        do {
            try AudioKit.start()
            audioKitStarted = true
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        
    }
    
    
}
