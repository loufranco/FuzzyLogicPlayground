import Foundation
import UIKit
import GameplayKit
import SpriteKit
import PlaygroundSupport

public enum Direction: Int {
    case north = 0
    case northwest = 1
    case west = 2
    case southwest = 3
    case south = 4
    case southeast = 5
    case east = 6
    case northeast = 7

    public func left() -> Direction {
        return Direction(rawValue: ((self.rawValue + 1) % 8)) ?? .north
    }

    public func right() -> Direction {
        return Direction(rawValue: ((self.rawValue + 7) % 8)) ?? .north
    }

    public func rotation() -> CGFloat {
        return CGFloat(self.rawValue) * CGFloat.pi / 4
    }

    public func forwardCell(from cell: (x: Int, y: Int)) -> (Int, Int) {
        switch self {
        case .north:
            return (cell.x, cell.y+1)
        case .northwest:
            return (cell.x-1, cell.y+1)
        case .west:
            return (cell.x-1, cell.y)
        case .southwest:
            return (cell.x-1, cell.y-1)
        case .south:
            return (cell.x, cell.y-1)
        case .southeast:
            return (cell.x+1, cell.y-1)
        case .east:
            return (cell.x+1, cell.y)
        case .northeast:
            return (cell.x+1, cell.y+1)
        }
    }
}

public enum RobotAction: NSString {
    case turnRight
    case turnLeft
    case moveForward
    case radar
    case fireLaser

    public static let allValues = [
        turnRight,
        turnLeft,
        moveForward,
        radar,
        fireLaser]
}

public typealias RobotNextAction = ([String: Any]) -> RobotAction

public class Robot: SKSpriteNode {

    var direction: Direction = .north
    var cell: (x: Int, y: Int) = (x: 0, y: 0)
    var nextActionFn: RobotNextAction?
    var radarCharge: Int = 0
    var laserCharge: Int = 0
    let die = GKRandomDistribution.d20()
    var moveTime: TimeInterval = 0

    var enemyCell: (x: Int, y: Int) = (x: 0, y: 0)
    var ticksSinceEnemyKnown: Int = 0

    @discardableResult
    public func goto(cell: (x: Int, y: Int)) -> Robot {
        guard let rwScene = self.scene as? RobotWarScene, rwScene.isInBounds(cell: cell) else { return self }
        self.cell = cell

        self.run(SKAction.move(to: CGPoint(x: (cell.x * 50) + 25, y: (cell.y * 50) + 25), duration: moveTime))

        return self
    }

    @discardableResult
    public func turnLeft() -> Robot {
        direction = direction.left()
        self.run(SKAction.rotate(toAngle: direction.rotation(), duration: moveTime, shortestUnitArc: true))
        return self
    }

    @discardableResult
    public func turnRight() -> Robot {
        direction = direction.right()
        self.run(SKAction.rotate(toAngle: direction.rotation(), duration: moveTime, shortestUnitArc: true))
        return self
    }

    @discardableResult
    public func moveForward() -> Robot {
        return goto(cell: direction.forwardCell(from: self.cell))
    }

    public func canMoveForward() -> Bool {
        guard let rwScene = self.scene as? RobotWarScene else { return false }
        return rwScene.isInBounds(cell: direction.forwardCell(from: self.cell))
    }

    public func nextAction(state: [String: Any]) -> RobotAction {
        if let nextActionFn = nextActionFn {
            return nextActionFn(state)
        }

        let dieRoll = die.nextInt()

        if canMoveForward() && dieRoll < 8 {
            return .moveForward
        } else if canMoveForward() && self.laserCharge > 2 && dieRoll < 12 {
            return .fireLaser
        } else if self.radarCharge > 1 && dieRoll < 12 {
            return .radar
        } else if dieRoll % 2 == 0 {
            return .turnRight
        } else {
            return .turnLeft
        }
    }

    public func radar() {
        guard let rwScene = self.scene as? RobotWarScene else { return }
        if let enemyCell = rwScene.radar(from: self) {
            self.enemyCell = enemyCell
            self.ticksSinceEnemyKnown = 0
        }
    }

    public func state() -> [String: Any] {
        var state = [String: Any]()
        state["myPosX"] = self.cell.x
        state["myPosY"] = self.cell.y
        state["myDir"] = self.direction
        state["laserCharge"] = max(0, self.laserCharge)
        state["radarCharge"] = max(0, self.radarCharge)

        state["enemyPosX"] = enemyCell.x
        state["enemyPosY"] = enemyCell.y
        state["ticksSinceEnemyKnown"] = ticksSinceEnemyKnown

        return state
    }

    public func doAction(action: RobotAction) {
        guard let rwScene = self.scene as? RobotWarScene else { return }
        switch action {
        case .turnRight:
            turnRight()
        case .turnLeft:
            turnLeft()
        case .moveForward:
            moveForward()
        case .radar:
            radar()
        case .fireLaser:
            rwScene.fireLaser(from: self)
        }
        laserCharge = min(laserCharge + 1, rwScene.maxLaser)
        radarCharge = min(radarCharge + 1, rwScene.maxRadar)
        self.ticksSinceEnemyKnown += 1
    }
    
}
