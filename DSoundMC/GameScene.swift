//
//  GameScene.swift
//  DSoundMC
//
//  Created by George Oblapenko on 24/12/2017.
//  Copyright © 2017 George Oblapenko. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    let osc1 = AKOscillator()
    let osc2 = AKOscillator()
    let mixer = AKMixer()
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        osc1.frequency = 50
        osc2.frequency = 50
        mixer.connect(input: osc1)
        mixer.connect(input: osc2)
        mixer.volume /= 2.0
//        mixer = AKMixer(osc1, osc2)
        
        AudioKit.output = mixer
        osc1.start()
        osc2.start()
        AudioKit.start()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
