//
//  GameScene.swift
//  the_playground
//
//  Created by Mauricio de Oliveira on 10/29/14.
//

import SpriteKit
import Darwin
import Foundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var x:CGFloat = 0
    var y:CGFloat = 0
    var lastTime:CFTimeInterval = 0
    var score = 0;
    
    let bgImage0:SKSpriteNode = SKSpriteNode(imageNamed: "background")
    let bgImage1:SKSpriteNode = SKSpriteNode(imageNamed: "background")
    let sprite = SKSpriteNode(imageNamed:"Spaceship")
    let scoreLabel:SKLabelNode = SKLabelNode(fontNamed:"Arial")
    
    var boom:Bool = false
    var emitter:SKEmitterNode = SKEmitterNode();
    
    var timeToBoom = 100
    
    override func didMoveToView(view: SKView) {
        
        bgImage0.xScale = 2.75
        bgImage0.yScale = 2.75
        bgImage0.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame))
        bgImage0.zPosition = -1.0
        bgImage1.xScale = 2.75
        bgImage1.yScale = 2.75
        bgImage1.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - bgImage1.size.height/2)
        bgImage1.zPosition = -1.0
        
        self.addChild(bgImage0)
        self.addChild(bgImage1)
        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0)
        self.physicsWorld.contactDelegate = self
        
        sprite.xScale = 0.1
        sprite.yScale = 0.1
        sprite.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width*sprite.xScale*2)
        self.addChild(sprite)
        
        sprite.physicsBody?.categoryBitMask = 0x1 << 0
        sprite.physicsBody?.contactTestBitMask = 0x1 << 1
        
        let untypedEmitter : AnyObject = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("Explosion", ofType: "sks")!)!;
        emitter = untypedEmitter as SKEmitterNode;
        emitter.particleLifetimeRange = 100.0
        emitter.particleScale = 0.1
        
        scoreLabel.text = "0";
        scoreLabel.fontSize = 20;
        scoreLabel.position = CGPointMake(CGRectGetMinX(self.frame)+375, CGRectGetMinY(self.frame)+16);
        self.addChild(scoreLabel);
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            x = location.x
            y = location.y
        }
        
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            if(!boom) { // movement
                sprite.physicsBody?.velocity = CGVectorMake((location.x-x)*50, (location.y-y)*50)
                let action = SKAction.rotateToAngle(-atan2(location.x-x, location.y-y), duration:1)
                sprite.runAction(action)
            }
            x = location.x
            y = location.y
        }
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if(contact.collisionImpulse > 4 && timeToBoom == 100) {
            if(contact.bodyA.node == sprite || contact.bodyB.node == sprite) {
                boom = true // death
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        if(boom || timeToBoom < 0) {
            if(timeToBoom == 100) {
                addChild(emitter)
                emitter.particleColor = UIColor.orangeColor()
            }
            emitter.particlePosition = sprite.position;
            timeToBoom--
            if(timeToBoom < 40 && timeToBoom >= 36) {
                emitter.particleScale = 0.8
                removeChildrenInArray([sprite])
                for child : AnyObject in self.children {
                    let node = child as SKNode
                    let force = CGVector(dx: (child.position.x-sprite.position.x)*0.1, dy:(child.position.y-sprite.position.y)*2)
                    node.physicsBody?.applyForce(force)
                }
            }
            if(timeToBoom < 36 && timeToBoom >= 0) {
                var scale = 0.01 as Float
                scale *= Float(timeToBoom)/2
                emitter.particleColor = UIColor.blackColor()
                emitter.particleScale = CGFloat(scale)
            }
            if(timeToBoom == 0) {
                removeChildrenInArray([emitter])
                score=0
                scoreLabel.text = String(score)
            }
            if(timeToBoom < 0 && timeToBoom >= -20) {
                sprite.physicsBody!.velocity.dx=0
                sprite.physicsBody!.velocity.dy=0
                let action = SKAction.rotateToAngle(CGFloat(2 * M_PI), duration:1)
                sprite.runAction(action)
                sprite.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
                
            }
            if(timeToBoom == -20) {
                addChild(sprite)
            }
            if(timeToBoom < -20 && timeToBoom >= -60) {
                sprite.physicsBody?.categoryBitMask = 0x0
                sprite.physicsBody?.contactTestBitMask = 0x0
                sprite.alpha = 0.5
                boom = false
            }
            if(timeToBoom < -60) {
                sprite.physicsBody?.categoryBitMask = 0x1 << 0
                sprite.physicsBody?.contactTestBitMask = 0x1 << 1
                sprite.alpha = 1.0
                timeToBoom = 100
            }
        }else{
            score += 1;
            scoreLabel.text = String(score)
        }
        
        // Add asteroid
        if(lastTime.distanceTo(currentTime) > 0.3) {
            lastTime = currentTime
            let aX = CGFloat(arc4random_uniform(800))
            var enemy = SKSpriteNode(imageNamed:"asteroid")
            enemy.xScale = CGFloat(arc4random_uniform(90)) * 0.01 + 0.1
            enemy.yScale = enemy.xScale
            enemy.position = CGPoint(x:aX, y:CGRectGetMaxY(self.frame))
            let radius = 1.7*(sprite.size.width * enemy.xScale)
            enemy.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            self.addChild(enemy)
            enemy.physicsBody?.velocity = CGVectorMake(0, -100 - 100 * CGFloat(arc4random_uniform(10)))
            enemy.name = "asteroid"
        }
        
        // Remove out of bounds asteroid
        for childAst : AnyObject in self.children {
            let node = childAst as SKNode
            if(node.name == "asteroid"){
                if(node.position.y < CGRectGetMinY(self.frame)) {
                    //NSLog("asteroid removed")
                    removeChildrenInArray([node])
                }
            }
        }
        
        // Bounce spaceship out of bounds
        let child = sprite
        if(child.position.x < 300) {
            child.position.x = 300
            child.physicsBody?.velocity.dx *= -1
        }
        if(child.position.x > CGRectGetMaxX(self.frame)-300) {
            child.position.x = CGRectGetMaxX(self.frame)-300
            child.physicsBody?.velocity.dx *= -1
        }
        if(child.position.y < 0) {
            child.position.y = 0
            child.physicsBody?.velocity.dy *= -1
        }
        if(child.position.y > CGRectGetMaxY(self.frame)-0) {
            child.position.y = CGRectGetMaxY(self.frame)-0
            child.physicsBody?.velocity.dy *= -1
        }
        
        // Scroll background
        bgImage0.position.y -= 10
        bgImage1.position.y -= 10
        if(bgImage0.position.y < CGRectGetMinY(self.frame) - bgImage0.size.height/2) {
            bgImage0.position.y = CGRectGetMaxY(self.frame) + bgImage0.size.height/2
        }
        if(bgImage1.position.y < CGRectGetMinY(self.frame) - bgImage1.size.height/2) {
            bgImage1.position.y = CGRectGetMaxY(self.frame) + bgImage1.size.height/2
        }
    }
}
