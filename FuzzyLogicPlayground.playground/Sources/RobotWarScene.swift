import Foundation
import UIKit
import GameplayKit
import SpriteKit

enum GameRunningState {
    case initializing
    case running
    case show(result: String)
    case gameOver
}

public class RobotWarScene: SKScene {
    let cellWidth: Int
    let cellHeight: Int
    let maxLaser: Int
    let maxRadar: Int
    var timeSinceMove: TimeInterval? = nil
    let timeBetweenMoves: TimeInterval
    var currentTime: TimeInterval = 0

    var gameRunningState = GameRunningState.initializing

    public let redRobot: Robot
    public let greenRobot: Robot

    public init(size: CGSize, cellSize: Int, timeBetweenMoves: TimeInterval) {
        self.cellWidth = cellSize
        self.cellHeight = cellSize
        self.timeBetweenMoves = timeBetweenMoves
        self.redRobot = Robot(imageNamed: "robot-red")
        self.greenRobot = Robot(imageNamed: "robot-green")
        self.maxLaser = cellSize / 2
        self.maxRadar = (cellSize - 2) / 2

        super.init(size: size)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func makeBoard() {
        for x in (0..<cellWidth) {
            for y in (0..<cellHeight) {
                let r = SKShapeNode(rect: CGRect(x: x*50, y:y*50, width:49, height: 49))
                r.fillColor = .gray
                r.strokeColor = .black
                self.addChild(r)
            }
        }
        redRobot.zPosition = 10
        greenRobot.zPosition = 10

        self.addChild(redRobot)
        self.addChild(greenRobot)

        let random = GKRandomDistribution(lowestValue: 0, highestValue: cellWidth - 1)


        redRobot.goto(cell: (x: random.nextInt() / 3, y: random.nextInt() / 3))
        greenRobot.goto(cell: (x: cellWidth - 1 - random.nextInt() / 3, y: cellHeight - 1 - random.nextInt() / 3))


        for _ in 0..<(random.nextInt()*3) {
            redRobot.turnLeft()
        }
        for _ in 0..<(random.nextInt()*3) {
            greenRobot.turnRight()
        }

        redRobot.moveTime = timeBetweenMoves * 0.8
        greenRobot.moveTime = timeBetweenMoves * 0.8
        redRobot.enemyCell = greenRobot.cell
        greenRobot.enemyCell = redRobot.cell
    }

    public func run() {
        self.gameRunningState = .running
    }

    func addGameState(to state: [String: Any], for robot: Robot) -> [String: Any] {
        var gameState = state

        gameState["currentTime"] = self.currentTime
        gameState["cellWidth"] = self.cellWidth
        gameState["cellHeight"] = self.cellHeight
        gameState["maxLaser"] = maxLaser
        gameState["maxRadar"] = maxRadar

        return gameState
    }

    override public func update(_ currentTime: TimeInterval) {
        self.currentTime = currentTime
        switch gameRunningState {
        case .initializing, .gameOver:
            return

        case .running:
            if let timeSinceMove = self.timeSinceMove {
                if (currentTime - timeSinceMove) > self.timeBetweenMoves {
                    self.redRobot.doAction(action: self.redRobot.nextAction(state: addGameState(to: redRobot.state(), for: redRobot)))
                    if case .running = self.gameRunningState {
                        self.greenRobot.doAction(action: self.greenRobot.nextAction(state: addGameState(to: greenRobot.state(), for: greenRobot)))
                    }
                    self.timeSinceMove = currentTime

                    if redRobot.cell == greenRobot.cell {
                        gameRunningState = .show(result: "You crashed, it's a tie")
                    }
                }
            } else {
                self.timeSinceMove = currentTime
            }

        case .show(let result):
            if let v = self.view, let scene = self.scene {
               let label = SKLabelNode(text: result)
                label.position = CGPoint(x: v.bounds.width / 2, y: v.bounds.height / 2)
                label.fontColor = .black
                scene.addChild(label)

                let background = SKShapeNode(rectOf: CGSize(width: label.frame.size.width + 10, height: label.frame.size.height + 10), cornerRadius: 4)
                background.fillColor = .lightGray
                background.position = CGPoint(x: label.frame.midX, y: label.frame.midY)
                scene.addChild(background)

                background.zPosition = redRobot.zPosition + 1
                label.zPosition = background.zPosition + 1
            }
            self.gameRunningState = .gameOver
        }

    }

    func otherRobot(from robot: Robot) -> Robot {
        return (robot == greenRobot) ? redRobot : greenRobot;
    }

    public func fireLaser(from robot: Robot) {
        guard robot.laserCharge > 0 else { return }

        let laser = SKShapeNode(rectOf: CGSize(width: 5, height: robot.laserCharge * 50))
        laser.fillColor = .blue
        laser.lineWidth = 0
        laser.zRotation = robot.direction.rotation()

        var laserCell = robot.cell
        for _ in (0..<robot.laserCharge) {
            laserCell = robot.direction.forwardCell(from: laserCell)
            if laserCell == otherRobot(from: robot).cell {
                gameRunningState = .show(result: robot == redRobot ? "You Win" : "You Lose")
            }
        }

        laser.position = CGPoint(x: CGFloat(laserCell.x + robot.cell.x)/2 * 50 + 25, y: CGFloat(laserCell.y + robot.cell.y)/2 * 50 + 25)

        scene?.addChild(laser)
        scene?.run(SKAction.wait(forDuration: timeBetweenMoves * 0.8)) {
            laser.removeFromParent()
        }
        robot.laserCharge = 0
    }

    public func radar(from robot: Robot) -> (Int, Int)? {
        guard robot.radarCharge > 0 else { return nil }

        let other = otherRobot(from: robot)
        var result: (x: Int, y: Int)? = nil

        if abs(robot.cell.x - other.cell.x) <= robot.radarCharge &&
            abs(robot.cell.y - other.cell.y) <= robot.radarCharge {
            result = other.cell
        }

        let radar = SKShapeNode(rectOf: CGSize(width: (robot.radarCharge * 2 + 1) * 50, height: (robot.radarCharge * 2 + 1) * 50))
        radar.fillColor = .yellow
        radar.alpha = 0.5
        radar.lineWidth = 0
        radar.position = robot.position
        radar.setScale(0)
        radar.zPosition = robot.zPosition - 1

        scene?.addChild(radar)
        radar.run(SKAction.scale(to: 1.0, duration: timeBetweenMoves * 0.8)) {
            radar.removeFromParent()
        }
        robot.radarCharge = 0

        return result
    }

    public func isInBounds(cell: (x: Int, y: Int)) -> Bool {
        guard cell.x >= 0 && cell.x < cellWidth else { return false }
        guard cell.y >= 0 && cell.y < cellHeight else { return false }

        return true
    }
}
