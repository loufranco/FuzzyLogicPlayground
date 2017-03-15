import UIKit
import GameplayKit
import SpriteKit

public class RobotWar {

    let view: SKView
    private let scene: RobotWarScene

    public init(cellSize: Int, timeBetweenMoves: TimeInterval) {
        view = SKView(frame: CGRect(x: 0, y:0, width: cellSize * 50, height: cellSize * 50))
        scene = RobotWarScene(size: view.frame.size, cellSize: cellSize, timeBetweenMoves: timeBetweenMoves)
    }

    public func makeGameBoard() -> UIView {
        scene.makeBoard()
        view.presentScene(scene)
        return view
    }

    public func run() {
        scene.run()
    }

    public func setRedRobotNextAction(actionFn: @escaping RobotNextAction) {
        scene.redRobot.nextActionFn = actionFn
    }

    public func setGreenRobotNextAction(actionFn: @escaping RobotNextAction) {
        scene.greenRobot.nextActionFn = actionFn
    }

    public func isInBounds(cell: (x: Int, y: Int)) -> Bool {
        return scene.isInBounds(cell: cell)
    }
}

