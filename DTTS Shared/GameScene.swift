//
//  GameScene.swift
//  DTTS Shared
//
//  Created by Aluno a25979 Teste on 08/05/2025.
//

import SpriteKit
import GameplayKit

struct Category {
    static let none: UInt32 = 0
    static let edge: UInt32 = 0x1 << 2
    static let spike: UInt32 = 0x1 << 1
    static let player: UInt32 = 0x1 << 0
    static let powerUp: UInt32 = 0x1 << 3
}

enum TriangleOrientation {
    case left
    case right
    case up
    case down
}

class Powerup: SKSpriteNode {
    
    static var noActivePowerUp: Bool = false
    
    init(_ sprite: String) {
        let texture = SKTexture(imageNamed: sprite)
        super.init(texture: texture, color: .white, size: texture.size())
        
        self.size = CGSize(width: 50, height: 50)
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width * 0.8, height: self.size.height * 0.8))
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = Category.powerUp
        self.physicsBody?.contactTestBitMask = Category.player
        self.physicsBody?.collisionBitMask = Category.player
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func spawn(isLeft: Bool, screenSize: CGSize) {
        
        if Powerup.noActivePowerUp { return }
        
        let x = !isLeft ? 50 : Int(screenSize.width - 50)
        let y = Int.random(in: 220...Int(screenSize.height - 220))
        
        self.position = CGPoint(x: x, y: y)
        
        Powerup.noActivePowerUp = true
    }
    
    func use(player: Player) {}
}

class MarioStar: Powerup {
    override func use(player: Player) {
        
        player.invicible = true
        
        player.sprite.physicsBody?.contactTestBitMask = Category.edge
        player.sprite.physicsBody?.collisionBitMask = Category.edge
        
        let playerOriginalTexture = player.sprite.texture
        
        player.sprite.texture = SKTexture(imageNamed: "Untitled_lgbt")
        
        let move = SKAction.moveTo(x: -1000, duration: 0)
        
        self.run(move)

        let wait = SKAction.wait(forDuration: 0.4)
        
        let sequence = SKAction.sequence([wait])
        
        let repeatAction = SKAction.repeat(sequence, count: 9)
        
        let end = SKAction.run {
            player.invicible = false
            Powerup.noActivePowerUp = false
            player.sprite.texture = playerOriginalTexture
            print("Invincibility ended")
            player.sprite.physicsBody?.contactTestBitMask = Category.edge | Category.spike
            player.sprite.physicsBody?.collisionBitMask = Category.edge | Category.spike
        }
        
        let fullSequence = SKAction.sequence([repeatAction, end])
        
        self.run(fullSequence)
    }
}

class Player {
    
    var sprite: SKSpriteNode
    
    var invicible = false
    
    init(_ sprite: SKSpriteNode) {
        self.sprite = sprite
        self.sprite.size = CGSize(width: 50, height: 50)
        self.sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.sprite.size.width * 0.8, height: self.sprite.size.height * 0.8))
        self.sprite.physicsBody?.isDynamic = true
        self.sprite.physicsBody?.categoryBitMask = Category.player
        self.sprite.physicsBody?.contactTestBitMask = Category.edge | Category.spike
        self.sprite.physicsBody?.collisionBitMask = Category.edge | Category.spike
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // power ups
    
    var powerup1 = MarioStar("mariostar")
    
    var leftWallSpikes: [SKShapeNode] = []
    var rightWallSpikes: [SKShapeNode] = []
    
    var activeLeftWallSpikes: [Bool] = []
    var activeRightWallSpikes: [Bool] = []
    
    let player = Player(SKSpriteNode(imageNamed: "player"))
    
    var score = 0
    let labelPlayer = SKLabelNode(fontNamed: "Helvetica-Bold")
    let labelGameOver = SKLabelNode(fontNamed: "Helvetica-Bold")
    
    var playerSpeed = 15.0
    let jumpForce: CGFloat = 30
    let gravity: CGFloat = -5
    
    var isFlipped: Bool = false
    
    let wallCategory: UInt32 = 0x1 << 2
    let spikeCategory: UInt32 = 0x1 << 1
    let playerCategory: UInt32 = 0x1 << 0
    
    let funFactor = true
    
    var dead = false
    var started = false
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        if (bodyA.categoryBitMask == Category.player && bodyB.categoryBitMask == Category.edge) ||
           (bodyB.categoryBitMask == Category.player && bodyA.categoryBitMask == Category.edge) {
            print("Player colidiu com a borda do ecrã")
        }
        
        if (bodyA.categoryBitMask == Category.player && bodyB.categoryBitMask == Category.spike) ||
           (bodyB.categoryBitMask == Category.player && bodyA.categoryBitMask == Category.spike) {
            die()
        }
        
        if (bodyA.categoryBitMask == Category.player && bodyB.categoryBitMask == Category.powerUp) ||
           (bodyB.categoryBitMask == Category.player && bodyA.categoryBitMask == Category.powerUp) {
            let powerup = bodyA.node as? Powerup
            powerup?.use(player: player)
            run(SKAction.playSoundFileNamed("smw_1-up.mp3", waitForCompletion: false))
        }
    }

    override func didMove(to view: SKView) {
        
        addChild(powerup1)
        
        labelPlayer.text = "\(score)"
        labelPlayer.fontSize = 50
        labelPlayer.fontColor = .gray
        labelPlayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        labelPlayer.zPosition = -1
        labelPlayer.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        labelPlayer.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        addChild(labelPlayer)
        
        labelGameOver.text = "Game Over"
        labelGameOver.fontSize = 64
        labelGameOver.fontColor = .red
        labelGameOver.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        labelGameOver.zPosition = 1
        labelGameOver.alpha = 0
        addChild(labelGameOver)
        
        //Circle
        let circle = SKShapeNode(circleOfRadius: 75)
        circle.position = CGPoint(x: size.width / 2, y: size.height / 2)
        circle.fillColor = .white
        circle.strokeColor = .white
        circle.zPosition = -2
        
        addChild(circle)
        
        player.sprite.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 )
        player.sprite.size = CGSize(width: 50, height: 50)
        player.sprite.physicsBody?.allowsRotation = funFactor
        player.sprite.physicsBody?.restitution = 1
        player.sprite.physicsBody?.friction = 0
        player.sprite.physicsBody?.linearDamping = 0
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0)
        physicsWorld.contactDelegate = self
        
        backgroundColor = .lightGray
        
        
        addChild(player.sprite)
        
        self.addSpikesOnWall(xPosition: 0, isLeft: true)
        self.addSpikesOnWall(xPosition: size.width, isLeft: false)
        
        clearSpikes(isLeft: true)
        clearSpikes(isLeft: false)
        
        self.addVerticalSpikes(isTop: true)
        self.addVerticalSpikes(isTop: false)
    }
    
    func startGame() {
        player.sprite.physicsBody?.applyImpulse(CGVector(dx: playerSpeed, dy: 0))
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: gravity)
        
        jump()
    }
    
    
    func generateSpikes(isLeft: Bool) {
        let spikes = isLeft ? leftWallSpikes : rightWallSpikes
        var activeSpikes = isLeft ? activeLeftWallSpikes : activeRightWallSpikes
        
        var spikeNumber = Int.random(in: 0...spikes.count - 1)
        
        for _ in 0..<numberOfSpikesForScore()
        {
            //Find a deactive spike to activate
            while (activeSpikes[spikeNumber]) {
                spikeNumber = Int.random(in: 0...spikes.count - 1)
            }

            activeSpikes[spikeNumber] = true
            showSpike(isLeft: isLeft, index: spikeNumber)
        }
    }
    
    func numberOfSpikesForScore() -> Int {
        let minSpikes = 2
        let maxSpikes = 7
        let spikeIncrement = score / 5 // Aumenta a cada 5 pontos
        
        return min(maxSpikes, minSpikes + spikeIncrement)
    }
    
    func showSpike(isLeft: Bool, index: Int) {
        let spike = isLeft ? leftWallSpikes[index] : rightWallSpikes[index]
        var activeSpikes = isLeft ? activeLeftWallSpikes : activeRightWallSpikes
        
        let targetPositionX: CGFloat = isLeft ? 0 : size.width
        
        let move = SKAction.moveTo(x: targetPositionX, duration: 0.4)
        
        activeSpikes[index] = true
        
        spike.physicsBody?.collisionBitMask = Category.spike
        spike.run(move)
    }
    
    func clearSpikes(isLeft: Bool) {
        let spikesToRemove = isLeft ? leftWallSpikes : rightWallSpikes
        var activeSpikes = isLeft ? activeLeftWallSpikes : activeRightWallSpikes
        
        let targetPositionX: CGFloat = isLeft ? -40 : size.width + 40
        
        let move = SKAction.moveTo(x: targetPositionX, duration: 0.4)
        
        for i in 0..<activeSpikes.count {
            activeSpikes[i] = false
        }
        
        for spike in spikesToRemove {
            spike.physicsBody?.collisionBitMask = Category.none
            spike.run(move)
        }
    }

    func addSpikesOnWall(xPosition: CGFloat, isLeft: Bool) {
        let spikeSize = CGSize(width: 25, height: 40)
        let numSpikes = 10

        for i in 0..<numSpikes {
            let y = CGFloat(i) * spikeSize.height * 1.35 + spikeSize.height + 120

            let spike = isLeft ? createTriangle(size: spikeSize, orientation: .right) : createTriangle(size: spikeSize, orientation: .left)
            spike.position = CGPoint(x: xPosition, y: y)
            spike.physicsBody = SKPhysicsBody(polygonFrom: spike.path!)
            spike.physicsBody?.isDynamic = false
            spike.physicsBody?.categoryBitMask = Category.spike
            spike.physicsBody?.contactTestBitMask = Category.player
            spike.physicsBody?.collisionBitMask = Category.player
            spike.physicsBody?.usesPreciseCollisionDetection = true
            
            spike.fillColor = .gray
            spike.strokeColor = .gray

            addChild(spike)
            
            if (isLeft) {
                leftWallSpikes.append(spike)
                activeLeftWallSpikes.append(false)
            }
            else {
                rightWallSpikes.append(spike)
                activeRightWallSpikes.append(false)
            }
        }
    }
    
    func addVerticalSpikes(isTop: Bool) {
        let spikeSize = CGSize(width: 40, height: 25) // Tamanho dos espinhos
        let numSpikes = Int(size.width / spikeSize.width) // Número de espinhos ao longo do comprimento da tela
        let spikeColor = UIColor.gray // Cor dos espinhos

        // Adicionando retângulo acima dos espinhos no topo
        let rectHeight: CGFloat = 125 // Altura do retângulo
        let rect = SKShapeNode(rectOf: CGSize(width: size.width, height: rectHeight))
        rect.position = CGPoint(x: size.width / 2, y: (isTop) ? size.height - rectHeight / 2 : rectHeight / 2) // Posição logo acima dos espinhos
        rect.fillColor = spikeColor
        rect.strokeColor = spikeColor
        addChild(rect)

        // Adicionando espinhos na parte superior (topo)
        for i in 0..<numSpikes {
            let x = CGFloat(i) * spikeSize.width * 1.35 + 14 // Posição no eixo X
            var y: CGFloat
            if (isTop) {
                y = size.height - rectHeight // Posição na parte superior (topo da tela)
            }
            else {
                y = rectHeight // Posição na parte superior (topo da tela)
            }
            
            let spike = createTriangle(size: spikeSize, orientation: (isTop) ? .up : .down)
            spike.position = CGPoint(x: x, y: y)
            spike.physicsBody = SKPhysicsBody(polygonFrom: spike.path!)
            spike.physicsBody?.isDynamic = false
            spike.physicsBody?.categoryBitMask = Category.spike
            spike.physicsBody?.contactTestBitMask = Category.player
            spike.physicsBody?.collisionBitMask = Category.player
            spike.physicsBody?.usesPreciseCollisionDetection = true
            
            spike.fillColor = spikeColor
            spike.strokeColor = spikeColor

            addChild(spike)
        }
    }
    
    func createTriangle(size: CGSize, orientation: TriangleOrientation) -> SKShapeNode {
        let path = CGMutablePath()
        
        switch orientation {
        case .left:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: -size.width, y: size.height / 2))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            
        case .right:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            
        case .up:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: -size.height))
        case .down:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        }
        
        path.closeSubpath()

        return SKShapeNode(path: path)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !started {
            started = true
            startGame()
            return
        }
        
        if dead {
            restartGame()
            return
        }
        
        jump()
    }
    
    func jump() {
        player.sprite.physicsBody?.velocity.dy = 0
        player.sprite.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpForce))
    }

    override func update(_ currentTime: TimeInterval) {
        
        
        // Verificando se o jogador ultrapassou os limites superior e inferior
        if player.sprite.position.y >= size.height - player.sprite.size.height / 2 {
            print("Jogador ultrapassou a borda superior!")
        }
        
        if player.sprite.position.y <= player.sprite.size.height / 2 {
            print("Jogador ultrapassou a borda inferior!")
        }
        
        // Called before each frame is rendered
        if (player.sprite.position.x >= size.width - player.sprite.size.width / 2 && !isFlipped) {
            addscore()
        }
        else if (player.sprite.position.x <= 0 + player.sprite.size.width / 2 && isFlipped) {
            addscore()
        }
    }
    
    func die() {
        
        if (player.invicible) { return }
        
        print("skill issue lmao")
        if dead { return } // Evita que a morte ocorra mais de uma vez
        dead = true

        labelGameOver.alpha = 1
        
        player.sprite.physicsBody?.applyImpulse(CGVector(dx: 25 * (isFlipped ? 1 : -1), dy: 0))
        
        player.sprite.texture = SKTexture(imageNamed: "Untitled-2")
        run(SKAction.playSoundFileNamed("gameOver.mp3", waitForCompletion: false))
    }
    
    func updateBackgroundColor() {
        
        var backgroundColor = self.backgroundColor
        
        if score < 5 { backgroundColor = .lightGray }
        else if score < 10 { backgroundColor = SKColor(red: 0.82, green: 1, blue: 0.992, alpha: 1) }
        else { backgroundColor = .black }
        
        self.backgroundColor = backgroundColor
    }
    
    func spawnRandomPowerup() {
        let coolRandomNumber = Int.random(in: 0...4)
        if coolRandomNumber == 1 {
            powerup1.spawn(isLeft: isFlipped, screenSize: size)
        }
    }
    
    func addscore() {
        if dead { return; }
        
        spawnRandomPowerup()
        
        score += 1
        labelPlayer.text = "\(score)"
        
        playerSpeed += 0.5
        
        updateBackgroundColor()
        flip()
    }
    
    func flip() {
        if (!isFlipped) {
            player.sprite.physicsBody?.velocity.dx = 0
            player.sprite.physicsBody?.applyImpulse(CGVector(dx: -playerSpeed, dy: 0))
            isFlipped = true
            
            player.sprite.run(SKAction.scaleX(to: -1, duration: 0))
            
            clearSpikes(isLeft: !isFlipped)
            
            generateSpikes(isLeft: isFlipped)
        }
        else if (isFlipped) {
            player.sprite.physicsBody?.velocity.dx = 0
            player.sprite.physicsBody?.applyImpulse(CGVector(dx: playerSpeed, dy: 0))
            isFlipped = false
            
            player.sprite.run(SKAction.scaleX(to: 1, duration: 0))
            
            clearSpikes(isLeft: !isFlipped)
            
            generateSpikes(isLeft: isFlipped)
        }
        
        run(SKAction.playSoundFileNamed("hitmarker_2.mp3", waitForCompletion: false))
    }
    
    func restartGame() {
        if let view = self.view {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
}
