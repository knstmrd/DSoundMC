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

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let left_diffuse_reflection = 0.0
    let right_diffuse_reflection = 0.0
    let down_diffuse_reflection = 1.0
    let up_diffuse_reflection = 0.0
    
    var tmpvector = CGVector(dx: 0, dy: 0)
    var randangle = 0.0
    var vel = CGFloat(0.0)
    
    let particle_mask  : UInt32 = 0x1 << 1
    let left_wall_mask: UInt32 = 0x1 << 2
    let right_wall_mask : UInt32 = 0x1 << 3
    let upper_wall_mask : UInt32 = 0x1 << 4
    let lower_wall_mask : UInt32 = 0x1 << 5
    
    let min_osc_freq = 40.0
    let max_osc_freq = 1200.0
    let max_vel_projection : UInt32 = 400
    
    var lower_wall = SKSpriteNode()
    var upper_wall = SKSpriteNode()
    var left_wall = SKSpriteNode()
    var right_wall = SKSpriteNode()
    
    let tapRec = UITapGestureRecognizer()
    
    let mixer = AKMixer()
    
    var particle_arr : [SKShapeNode] = []
    var osc1_arr : [AKOscillator] = []
    var osc2_arr : [AKOscillator] = []
    
    var num_of_particles : UInt32 = 0
    
    override func didMove(to view: SKView) {
        if let lower_wall_obj = self.childNode(withName: "lower_wall") as? SKSpriteNode {
            lower_wall = lower_wall_obj
        }
        if let upper_wall_obj = self.childNode(withName: "upper_wall") as? SKSpriteNode {
            upper_wall = upper_wall_obj
        }
        if let left_wall_obj = self.childNode(withName: "left_wall") as? SKSpriteNode {
            left_wall = left_wall_obj
        }
        if let right_wall_obj = self.childNode(withName: "right_wall") as? SKSpriteNode {
            right_wall = right_wall_obj
        }
        
        lower_wall.physicsBody?.categoryBitMask = lower_wall_mask
        lower_wall.physicsBody?.contactTestBitMask = particle_mask
        
        upper_wall.physicsBody?.categoryBitMask = upper_wall_mask
        upper_wall.physicsBody?.contactTestBitMask = particle_mask
        
        right_wall.physicsBody?.categoryBitMask = right_wall_mask
        right_wall.physicsBody?.contactTestBitMask = particle_mask
        
        left_wall.physicsBody?.categoryBitMask = left_wall_mask
        left_wall.physicsBody?.contactTestBitMask = particle_mask
 
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.1)
        
        tapRec.addTarget(self, action:#selector(GameScene.tapAdd(_:) ))
        tapRec.numberOfTouchesRequired = 1
        tapRec.numberOfTapsRequired = 1
        self.view!.addGestureRecognizer(tapRec)
        
        AudioKit.output = mixer
        AudioKit.start()
    }
    
    func magnitude(dx: CGFloat, dy: CGFloat) -> CGFloat {
        return sqrt(dx*dx + dy*dy)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == lower_wall_mask && contact.bodyB.categoryBitMask == particle_mask {
            randangle = drand48() * Double.pi
            vel = magnitude(dx: contact.bodyB.velocity.dx, dy: contact.bodyB.velocity.dy)
            tmpvector = CGVector(dx: vel * CGFloat(cos(randangle)), dy: vel * CGFloat(sin(randangle)))
            contact.bodyB.velocity = tmpvector
//            contact.bodyB.velocity = CGVector(dx: contact.bodyB.velocity.dx, dy: -contact.bodyB.velocity.dy)
        }
        else if contact.bodyA.categoryBitMask == particle_mask && contact.bodyB.categoryBitMask == lower_wall_mask {
            contact.bodyA.velocity = CGVector(dx: contact.bodyA.velocity.dx, dy: -contact.bodyA.velocity.dy)
            randangle = drand48() * Double.pi
            vel = magnitude(dx: contact.bodyA.velocity.dx, dy: contact.bodyA.velocity.dy)
            tmpvector = CGVector(dx: vel * CGFloat(cos(randangle)), dy: vel * CGFloat(sin(randangle)))
            contact.bodyA.velocity = tmpvector
        }
            
        else if contact.bodyA.categoryBitMask == upper_wall_mask && contact.bodyB.categoryBitMask == particle_mask {
            contact.bodyB.velocity = CGVector(dx: contact.bodyB.velocity.dx, dy: -contact.bodyB.velocity.dy)
        }
        else if contact.bodyA.categoryBitMask == particle_mask && contact.bodyB.categoryBitMask == upper_wall_mask {
            contact.bodyA.velocity = CGVector(dx: contact.bodyA.velocity.dx, dy: -contact.bodyA.velocity.dy)
        }
            
        else if contact.bodyA.categoryBitMask == left_wall_mask && contact.bodyB.categoryBitMask == particle_mask {
            contact.bodyB.velocity = CGVector(dx: -contact.bodyB.velocity.dx + 100, dy: contact.bodyB.velocity.dy)
        }
        else if contact.bodyA.categoryBitMask == particle_mask && contact.bodyB.categoryBitMask == left_wall_mask {
            contact.bodyA.velocity = CGVector(dx: -contact.bodyA.velocity.dx + 100, dy: contact.bodyA.velocity.dy)
        }
            
        else if contact.bodyA.categoryBitMask == right_wall_mask && contact.bodyB.categoryBitMask == particle_mask {
            contact.bodyB.velocity = CGVector(dx: -contact.bodyB.velocity.dx - 50, dy: contact.bodyB.velocity.dy)
        }
        else if contact.bodyA.categoryBitMask == particle_mask && contact.bodyB.categoryBitMask == right_wall_mask {
            contact.bodyA.velocity = CGVector(dx: -contact.bodyA.velocity.dx - 50, dy: contact.bodyA.velocity.dy)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        for (index, particle) in particle_arr.enumerated() {
            osc1_arr[index].frequency = min(min_osc_freq + abs(Double(particle.physicsBody!.velocity.dx)), max_osc_freq)
            osc2_arr[index].frequency = min(min_osc_freq + abs(Double(particle.physicsBody!.velocity.dy)), max_osc_freq)
        }
    }
    
    @objc func tapAdd(_ sender:UITapGestureRecognizer) {
        let point:CGPoint = sender.location(in: self.view)
        let pointconv = convertPoint(fromView: point)

        let particle = SKShapeNode(circleOfRadius: 30.0)
        particle.position = CGPoint(x: pointconv.x, y: pointconv.y)
        particle.strokeColor = UIColor.yellow
        particle.physicsBody = SKPhysicsBody(circleOfRadius: 30.0)
        
        particle.physicsBody?.categoryBitMask = particle_mask
        particle.physicsBody?.collisionBitMask = particle_mask
        
        let vel_x : Int = Int(arc4random_uniform(max_vel_projection*2+1) ) - Int(max_vel_projection)
        let vel_y : Int = Int(arc4random_uniform(max_vel_projection*2+1) ) - Int(max_vel_projection)
        print(vel_x, vel_y)
        
        particle.physicsBody?.velocity = CGVector(dx: vel_x, dy: vel_y)
        
        particle_arr.append(particle)
        num_of_particles += 1
        
        let osc1 = AKOscillator()
        let osc2 = AKOscillator()
        osc1.frequency = min(min_osc_freq + abs(Double(particle.physicsBody!.velocity.dx)), max_osc_freq)
        osc2.frequency = min(min_osc_freq + abs(Double(particle.physicsBody!.velocity.dy)), max_osc_freq)
        
        mixer.connect(input: osc1)
        mixer.connect(input: osc2)
        
        mixer.volume = 1.0 / Double(num_of_particles)
        
        osc1.start()
        osc2.start()
        osc1_arr.append(osc1)
        osc2_arr.append(osc2)
        
        self.addChild(particle)
    }
}
