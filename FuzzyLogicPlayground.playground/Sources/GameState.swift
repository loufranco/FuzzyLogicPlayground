import Foundation
import UIKit
import GameplayKit

public struct GameState {
    public let myPos: CGPoint
    public let myDir: Direction

    public let enemyPos: CGPoint
    public let ticksSinceEnemyKnown: Int

    public let gameCellSize: CGSize
    public let currentTime: TimeInterval

    public let laserCharge: Int
    public let maxLaser: Int
    public let radarCharge: Int
    public let maxRadar: Int

    public init(state: NSMutableDictionary) {
        self.myPos = CGPoint(x: state["myPosX"] as? Int ?? 0, y: state["myPosY"] as? Int ?? 0)
        self.myDir = state["myDir"] as? Direction ?? Direction.north

        self.enemyPos = CGPoint(x: state["enemyPosX"] as? Int ?? 0, y: state["enemyPosY"] as? Int ?? 0)
        self.ticksSinceEnemyKnown = state["ticksSinceEnemyKnown"] as? Int ?? 1000

        self.gameCellSize = CGSize(width: state["cellWidth"] as? Int ?? 0, height: state["cellHeight"] as? Int ?? 0)
        self.currentTime = state["currentTime"] as? TimeInterval ?? 0
        self.laserCharge = state["laserCharge"] as? Int ?? 0
        self.maxLaser = state["maxLaser"] as? Int ?? 1
        self.radarCharge = state["radarCharge"] as? Int ?? 0
        self.maxRadar = state["maxRadar"] as? Int ?? 0
    }

    public func enemyDistance() -> CGFloat {
        return enemyDistance(from: myPos)
    }

    public func enemyDistance(from pos: CGPoint) -> CGFloat {
        return sqrt(pow(pos.x - enemyPos.x, 2) + pow(pos.y - enemyPos.y, 2))
    }

    public func maximumDistance() -> CGFloat {
        return sqrt(pow(gameCellSize.width, 2) + pow(gameCellSize.height, 2))
    }

    public func isFacingWall() -> Bool {
        let cell: (Int, Int) = myDir.forwardCell(from: (Int(myPos.x), Int(myPos.y)))
        return !isInBounds(pos: CGPoint(x: cell.0, y: cell.1))
    }

    public func isInBounds(pos: CGPoint) -> Bool {
        guard pos.x >= 0 && pos.x < gameCellSize.width else { return false }
        guard pos.y >= 0 && pos.y < gameCellSize.height else { return false }

        return true
    }

    public func forwardCell(from dir: Direction) -> CGPoint {
        return forwardCell(from: dir, steps: 1)
    }

    public func forwardCell(from dir: Direction, steps: Int) -> CGPoint {
        var fwd = myPos
        for _ in 0..<steps {
            let cell = dir.forwardCell(from: (Int(fwd.x), Int(fwd.y)))
            fwd = CGPoint(x: cell.0, y: cell.1)
        }
        return fwd
    }
}
