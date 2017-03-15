import UIKit
import GameplayKit
import SpriteKit
import PlaygroundSupport

let robotWar = RobotWar(cellSize: 10, timeBetweenMoves: 0.5)

// Move towards enemy and fire when facing them
func attackAction(state: GameState) -> RobotAction? {
    // Calculate the distance between us and the opponent ...
    // if we move forward
    let fwdDist = state.enemyDistance(from: state.forwardCell(from: state.myDir))
    // if we turn left and then move forward
    let leftFwdDist = state.enemyDistance(from: state.forwardCell(from: state.myDir.left()))
    // if we turn right and then move forward
    let rightFwdDist = state.enemyDistance(from: state.forwardCell(from: state.myDir.right()))

    if fwdDist <= leftFwdDist && fwdDist <= rightFwdDist {
        // Only move forward if we are not within laser range
        if fwdDist > CGFloat(state.laserCharge) {
            return .moveForward
        }
    } else {
        return (leftFwdDist <= rightFwdDist) ? .turnLeft : .turnRight
    }
    return nil
}

// Assert the attack strategy with our certainty about their position
let attackRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let posCertainty = rs.grade(forFact: RobotFact.posCertainty.rawValue)

    if let action = attackAction(state: state) {
        rs.assertFact(action.rawValue, grade: posCertainty)
    }
}

// Wander around if we don't know where the enemy is
let wanderRule = fuzzyRule { (rs: GKRuleSystem, state:GameState) in

    let posUncertainty = rs.grade(forFact: RobotFact.posUncertainty.rawValue)

    if (state.isInBounds(pos: state.forwardCell(from: state.myDir, steps: 3))) {
        rs.assertFact(RobotAction.moveForward.rawValue, grade: posUncertainty)
    } else {
        rs.assertFact(RobotAction.turnLeft.rawValue, grade: posUncertainty)
    }
}

// Fire if the enemy is close and we have laser
let shouldFireRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in

    if !state.isFacingWall() {
        let shouldLaser = rs.minimumGrade(forFacts: [
            RobotFact.hasLaser.rawValue,
            RobotFact.isNear.rawValue]
        )
        rs.assertFact(RobotAction.fireLaser.rawValue, grade: shouldLaser)
    }
}

// Use Radar when you are unsure of the enemy position or
// have a lot of radar charge
let shouldRadarRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in

    let shouldRadar = rs.maximumGrade(forFacts: [
        RobotFact.hasRadar.rawValue,
        RobotFact.posUncertainty.rawValue]
    )
    rs.assertFact(RobotAction.radar.rawValue, grade:shouldRadar)
}


// Run the rule system and return what it says to do
func nextAction(state: [String: Any]) -> RobotAction {
    let ruleSystem = GKRuleSystem()
    ruleSystem.state.addEntries(from: state)
    ruleSystem.add([
        posUncertaintyRule,
        posCertaintyRule,

        isNearRule,
        hasLaserRule,
        hasRadarRule,
        
        attackRule,
        shouldFireRule,
        shouldRadarRule,
        wanderRule,
    ])
    ruleSystem.evaluate()

    // Find the action facts that have the highest grade
    let maxGrade = ruleSystem.maximumGrade(forFacts: RobotAction.allValues.map { $0.rawValue } )
    let maxFacts = RobotAction.allValues.flatMap { ruleSystem.grade(forFact: $0.rawValue) == maxGrade ? $0 : nil }

    // Choose randomly from the highest graded facts if there is a tie.
    return maxFacts[GKRandomDistribution(lowestValue:0, highestValue: maxFacts.count - 1).nextInt()]
}

robotWar.setRedRobotNextAction(actionFn: nextAction)

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = robotWar.makeGameBoard()

robotWar.run()


