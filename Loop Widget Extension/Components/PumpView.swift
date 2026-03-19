//
//  PumpView.swift
//  Loop Widget Extension
//
//  Created by Cameron Ingham on 6/26/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import SwiftUI

struct PumpView: View {
    var entry: StatusWidgetTimelineProvider.Entry

    private static let iobFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static let cobFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center) {
            if let pumpHighlight = entry.pumpHighlight {
                HStack {
                    Image(systemName: pumpHighlight.imageName)
                        .foregroundColor(pumpHighlight.state == .critical ? .critical : .warning)
                    Text(pumpHighlight.localizedMessage)
                        .fontWeight(.heavy)
                }
            }
            else {
                HStack(spacing: 6) {
                    metricView(
                        label: NSLocalizedString("IOB", comment: "Label for insulin on board in widget"),
                        unitLabel: NSLocalizedString("Units", comment: "Full unit name for insulin units in widget metrics"),
                        value: formatIOB(entry.insulinOnBoard)
                    )

                    metricView(
                        label: NSLocalizedString("COB", comment: "Label for carbohydrates on board in widget"),
                        unitLabel: NSLocalizedString("grams", comment: "Full unit name for grams in widget metrics"),
                        value: formatCOB(entry.carbsOnBoard)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func metricView(label: String, unitLabel: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(unitLabel)
                .font(.footnote)
                .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : Color(UIColor.secondaryLabel))
                .lineLimit(1)

            Text(label)
                .font(.footnote)
                .foregroundColor(entry.contextIsStale ? Color(UIColor.systemGray3) : Color(UIColor.secondaryLabel))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.black.opacity(0.9))
        .clipShape(ContainerRelativeShape())
    }

    private func formatIOB(_ value: Double?) -> String {
        guard let value = value else {
            return "--"
        }
        let roundedValue = (value * 10).rounded() / 10
        if roundedValue == 0 {
            return "0"
        }
        return Self.iobFormatter.string(from: NSNumber(value: roundedValue)) ?? "--"
    }

    private func formatCOB(_ value: Double?) -> String {
        guard let value = value else {
            return "--"
        }
        let roundedValue = value.rounded()
        if roundedValue == 0 {
            return "0"
        }
        return Self.cobFormatter.string(from: NSNumber(value: value)) ?? "--"
    }
}
