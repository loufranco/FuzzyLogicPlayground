import Foundation
import GameplayKit

public enum RobotFact: NSString {
    case posCertainty
    case posUncertainty
    case isNear
    case hasRadar
    case hasLaser
}


public func fuzzyRule(action: @escaping (GKRuleSystem, GameState) -> ()) -> GKRule {
    return GKRule(blockPredicate: { _ in true }, action: { (rs) in
        return action(rs, GameState(state: rs.state))
    })
}

// We more certain of the enemy position the more recent the last radar hit was
public let posCertaintyRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let posCertainty: Float = max(0, 1.0 - (0.05 * Float(state.ticksSinceEnemyKnown)))
    rs.assertFact(RobotFact.posCertainty.rawValue, grade: posCertainty)
}

// Apply the Fuzzy Not operator (1.0 - x) to certainty
public let posUncertaintyRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let posCertainty = rs.grade(forFact: RobotFact.posCertainty.rawValue)
    let posUncertainty = 1.0 - posCertainty
    rs.assertFact(RobotFact.posUncertainty.rawValue, grade: posUncertainty)
}


// A fuzzy nearness -- 1.0 is very close and 0.0 is very far
public let isNearRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let diff = state.enemyDistance()
    let maxDiff = state.maximumDistance()
    let isNearValue = Float(1.0 - diff / maxDiff)
    rs.assertFact(RobotFact.isNear.rawValue, grade: isNearValue)
}

// 1.0 is full laser charge and 0.0 is a depleted laser
public let hasLaserRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let hasLaserValue = Float(state.laserCharge) / Float(state.maxLaser)
    rs.assertFact(RobotFact.hasLaser.rawValue, grade: hasLaserValue)
}

// 1.0 is full radar charge and 0.0 is a depleted radar
public let hasRadarRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let hasRadarValue = Float(state.radarCharge) / Float(state.maxRadar)
    rs.assertFact(RobotFact.hasRadar.rawValue, grade: hasRadarValue)
}


