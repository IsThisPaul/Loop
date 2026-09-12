//
//  WatchContext.swift
//  Loop
//
//  Created by Bharat Mediratta on 12/16/16.
//  Copyright © 2016 LoopKit Authors. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit

extension WatchContext {
    var reservoirVolumeText: String? {
        if reservoirAboveThreshold == true {
            return NSLocalizedString(
                "50+ U",
                comment: "Watch HUD text for reservoir volume when current Omnipod reservoir is above the maximum exact reading"
            )
        }

        guard let reservoirVolume = reservoirVolume else {
            return nil
        }

        let insulinFormatter: QuantityFormatter = {
            let insulinFormatter = QuantityFormatter(for: .internationalUnit())
            insulinFormatter.unitStyle = .long
            insulinFormatter.numberFormatter.minimumFractionDigits = 0
            insulinFormatter.numberFormatter.maximumFractionDigits = 0

            return insulinFormatter
        }()

        return insulinFormatter.string(from: reservoirVolume)
    }

    var activeInsulin: HKQuantity? {
        guard let value = iob else {
            return nil
        }

        return HKQuantity(unit: .internationalUnit(), doubleValue: value)
    }

    var activeCarbohydrates: HKQuantity? {
        guard let value = cob else {
            return nil
        }

        return HKQuantity(unit: .gram(), doubleValue: value)
    }

    var reservoirVolume: HKQuantity? {
        guard let value = reservoir else {
            return nil
        }

        return HKQuantity(unit: .internationalUnit(), doubleValue: value)
    }
}
