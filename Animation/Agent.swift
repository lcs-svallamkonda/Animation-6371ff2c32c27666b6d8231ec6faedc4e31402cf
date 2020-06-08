//
//  Agent.swift
//  Animation
//
//  Created by Russell Gordon on 2020-05-25.
//  Copyright © 2020 Royal St. George's College. All rights reserved.
//

import Foundation
import CanvasGraphics
import AudioKit

// Set up objects needed for microphone analysis
// SOURCE: https://audiokit.io/examples/MicrophoneAnalysis/
var mic: AKMicrophone!
var tracker: AKFrequencyTracker!
var silence: AKBooster!

class Agent {

    // Agent properties
    var centre: Point
    let radius: Int
    var velocity: Vector
    
    // Canvas the agent will be drawn upon
    var c: Canvas

    // Initialize the agent
    init(centre: Point, radius: Int, velocity: Vector, drawsUpon: Canvas) {
        
        self.centre = centre
        self.radius = radius
        self.velocity = velocity
        self.c = drawsUpon
        
    }
    
    // Update position of agent
    func update(drawingBoundary: Bool) {
        
        // Move the circle
        centre = Point(x: centre.x + velocity.x,
                       y: centre.y + velocity.y)
        
        // Bounce at edges
        bounceAtEdge()
        
        // Draw a circle at this point
        if drawingBoundary == true {
            c.drawEllipse(at: centre, width: radius * 2, height: radius * 2)
        }
        
        
    }
    
    // Bounce the agent when it hit's an edge
    func bounceAtEdge() {
        
        // Bounce at "circle" edges
        if centre.x + CGFloat(radius) > CGFloat((c.width / 2) + 350) || centre.x - CGFloat(radius) < CGFloat((c.width / 2) - 350) {
            centre = Point(x: c.width/2, y: c.height/2)
            velocity.x *= -1
        }
        
        // Bounce at "circle" edges
        if centre.y + CGFloat(radius) > CGFloat((c.height / 2) + 350) || centre.y - CGFloat(radius) < CGFloat((c.height / 2) - 350) {
            centre = Point(x: c.width/2, y: c.height/2)
            velocity.y *= -1
        }

        
    }
    
    //Returns true when this circle overlaps another cirlce
    func isOverlapping(this: Agent) -> Bool {
        
        //Two circles are overlapping when the sum of their radii is greater than the distance between their centre points
        if distanceBetween(a: self.centre, b: this.centre) < CGFloat(self.radius) + CGFloat(this.radius) {
            return true
        } else {
            return false
        }
        
    }
    
//get the distance between one point and another point
    func distanceBetween(a: Point, b: Point) -> CGFloat {
        
        //length of a line segment formula
        return sqrt( pow(b.x - a.x, 2) + pow(b.y - a.y, 2) )
    }
    
    
}
