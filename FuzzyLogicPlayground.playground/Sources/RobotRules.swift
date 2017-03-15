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

// We are less certain of the enemy position the less recent the last radar hit was
public let posUncertaintyRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let posUncertainty: Float = min(1.0, 0.05 * Float(state.ticksSinceEnemyKnown))
    rs.assertFact(RobotFact.posUncertainty.rawValue, grade: posUncertainty)
}

// Apply the Fuzzy Not operator (1.0 - x) to uncertainty
public let posCertaintyRule = fuzzyRule { (rs: GKRuleSystem, state: GameState) in
    let posUncertainty = rs.grade(forFact: RobotFact.posUncertainty.rawValue)
    let posCertainty = 1.0 - posUncertainty
    rs.assertFact(RobotFact.posCertainty.rawValue, grade: posCertainty)
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


