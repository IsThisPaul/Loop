//
//  LiveActivityConfiguration.swift
//  Loop Widget Extension
//
//  Created by Bastiaan Verhaar on 23/06/2024.
//  Copyright © 2024 LoopKit Authors. All rights reserved.
//

import ActivityKit
import Charts
import HealthKit
import UIKit
import LoopCore
import LoopKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct GlucoseLiveActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
        if #available(iOS 18.0, *) {
            return ActivityConfiguration(for: GlucoseActivityAttributes.self) {
                context in
                lockScreenView(context: context)
            } dynamicIsland: { context in
                dynamicIslandView(context: context)
            }
            .supplementalActivityFamilies([.small])
        } else {
            return ActivityConfiguration(for: GlucoseActivityAttributes.self) {
                context in
                lockScreenView(context: context)
            } dynamicIsland: { context in
                dynamicIslandView(context: context)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> some View {
        // Create the presentation that appears on the Lock Screen and as a
        // banner on the Home Screen of devices that don't support the Dynamic Island.
        if #available(iOS 18.0, *) {
            AdaptiveLockScreenView(context: context)
        } else {
            fullLockScreenView(context: context)
        }
    }

    @available(iOS 18.0, *)
    struct AdaptiveLockScreenView: View {
        let context: ActivityViewContext<GlucoseActivityAttributes>
        @Environment(\.activityFamily) private var activityFamily

        var body: some View {
            if activityFamily == .small {
                // WatchOS & CarPlay supplemental view - show only bottom row
                compactLockScreenView(context: context)
            } else {
                // Lock screen - show full view with chart
                fullLockScreenView(context: context)
            }
        }

        @ViewBuilder
        private func fullLockScreenView(
            context: ActivityViewContext<GlucoseActivityAttributes>
        ) -> some View {
            GlucoseLiveActivityConfiguration().fullLockScreenView(
                context: context
            )
        }

        @ViewBuilder
        private func compactLockScreenView(
            context: ActivityViewContext<GlucoseActivityAttributes>
        ) -> some View {
            GlucoseLiveActivityConfiguration().compactLockScreenView(
                context: context
            )
        }
    }

    @ViewBuilder
    private func fullLockScreenView(
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> some View {
        ZStack {
            VStack {
                if context.attributes.mode == .large {
                    HStack(spacing: 15) {
                        loopIcon(context)
                        if context.attributes.addPredictiveLine {
                            ChartView(
                                glucoseSamples: context.state.glucoseSamples,
                                predicatedGlucose: context.state
                                    .predicatedGlucose,
                                predicatedStartDate: context.state
                                    .predicatedStartDate,
                                predicatedInterval: context.state
                                    .predicatedInterval,
                                useLimits: context.attributes.useLimits,
                                lowerLimit: context.state.isMmol
                                ? context.attributes.lowerLimitChartMmol
                                : context.attributes.lowerLimitChartMg,
                                upperLimit: context.state.isMmol
                                ? context.attributes.upperLimitChartMmol
                                : context.attributes.upperLimitChartMg,
                                glucoseRanges: context.state.glucoseRanges,
                                preset: context.state.preset,
                                yAxisMarks: context.state.yAxisMarks,
                                markerDate: context.state.lastCompleted
                            )
                            .frame(height: 85)
                        } else {
                            ChartView(
                                glucoseSamples: context.state.glucoseSamples,
                                useLimits: context.attributes.useLimits,
                                lowerLimit: context.state.isMmol
                                ? context.attributes.lowerLimitChartMmol
                                : context.attributes.lowerLimitChartMg,
                                upperLimit: context.state.isMmol
                                ? context.attributes.upperLimitChartMmol
                                : context.attributes.upperLimitChartMg,
                                glucoseRanges: context.state.glucoseRanges,
                                preset: context.state.preset,
                                yAxisMarks: context.state.yAxisMarks,
                                markerDate: context.state.lastCompleted
                            )
                            .frame(height: 85)
                        }
                    }
                }
                
                HStack {
                    bottomSpacer(border: false)
                    
                    let endIndex = context.state.bottomRow.endIndex - 1
                    ForEach(
                        Array(context.state.bottomRow.enumerated()),
                        id: \.element
                    ) { (index, item) in
                        switch item.type {
                        case .generic:
                            bottomItemGeneric(
                                title: item.label,
                                value: item.value,
                                unit: LocalizedString(
                                    item.unit,
                                    comment: "No comment"
                                )
                            )
                            
                        case .basal:
                            BasalViewActivity(
                                percent: item.percentage,
                                rate: item.rate
                            )
                            
                        case .currentBg:
                            bottomItemCurrentBG(
                                value: item.value,
                                trend: item.trend,
                                context: context
                            )
                        }
                        
                        if index != endIndex {
                            bottomSpacer(border: true)
                        }
                    }
                    
                    bottomSpacer(border: false)
                }
            }
            if context.state.ended {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(
                            NSLocalizedString(
                                "Open the app to update the widget",
                                comment: "No comment"
                            )
                        )
                        Spacer()
                    }
                    Spacer()
                }
                .background(.ultraThinMaterial.opacity(0.8))
                .padding(.all, -15)
            }
        }
        .privacySensitive()
        .padding(.all, 15)
        .background(BackgroundStyle.background.opacity(0.4))
        .activityBackgroundTint(Color.clear)
    }

    @ViewBuilder
    private func compactLockScreenView(
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> some View {
        let glucoseFormatter = NumberFormatter.glucoseFormatter(
            for: context.state.isMmol
                ? HKUnit.millimolesPerLiter
                : HKUnit.milligramsPerDeciliter
        )
        let unit = context.state.isMmol
            ? HKUnit.millimolesPerLiter.localizedShortUnitString
            : HKUnit.milligramsPerDeciliter.localizedShortUnitString

        let glucoseColor = !context.attributes.useLimits ? .primary : getGlucoseColor(context: context)
        let currentBG = (glucoseFormatter.string(from: context.state.currentGlucose) ?? "??") + getArrowImage(context.state.trendType)
        GeometryReader { geometry in
            let iobUnitLabel = NSLocalizedString("Units", comment: "Full unit name for insulin units in compact live activity metrics")
            let iobCaption = "IOB"
            let cobValue = context.state.cob
            let cobUnitLabel = NSLocalizedString("grams", comment: "Full unit name for grams in compact live activity metrics")
            let cobCaption = "COB"

            ViewThatFits(in: .horizontal) {
                compactBubbleRow(
                    context: context,
                    currentBG: currentBG,
                    delta: context.state.delta + " " + unit,
                    glucoseColor: glucoseColor,
                    iob: context.state.iob,
                    iobUnitLabel: iobUnitLabel,
                    iobCaption: iobCaption,
                    cob: cobValue,
                    cobUnitLabel: cobUnitLabel,
                    cobCaption: cobCaption,
                    valueFont: .headline,
                    valueUIFont: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .semibold),
                    unitFont: .system(size: 6),
                    unitUIFont: UIFont.systemFont(ofSize: 6),
                    captionFont: .caption2,
                    captionUIFont: UIFont.preferredFont(forTextStyle: .caption2),
                    containerSize: geometry.size,
                    glucoseMinimumScaleFactor: 1.0
                )
                compactBubbleRow(
                    context: context,
                    currentBG: currentBG,
                    delta: context.state.delta + " " + unit,
                    glucoseColor: glucoseColor,
                    iob: context.state.iob,
                    iobUnitLabel: iobUnitLabel,
                    iobCaption: iobCaption,
                    cob: cobValue,
                    cobUnitLabel: cobUnitLabel,
                    cobCaption: cobCaption,
                    valueFont: .subheadline,
                    valueUIFont: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold),
                    unitFont: .system(size: 6),
                    unitUIFont: UIFont.systemFont(ofSize: 6),
                    captionFont: .caption2,
                    captionUIFont: UIFont.preferredFont(forTextStyle: .caption2),
                    containerSize: geometry.size,
                    glucoseMinimumScaleFactor: 1.0
                )
                compactBubbleRow(
                    context: context,
                    currentBG: currentBG,
                    delta: context.state.delta + " " + unit,
                    glucoseColor: glucoseColor,
                    iob: context.state.iob,
                    iobUnitLabel: iobUnitLabel,
                    iobCaption: iobCaption,
                    cob: cobValue,
                    cobUnitLabel: cobUnitLabel,
                    cobCaption: cobCaption,
                    valueFont: .footnote,
                    valueUIFont: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .semibold),
                    unitFont: .system(size: 6),
                    unitUIFont: UIFont.systemFont(ofSize: 6),
                    captionFont: .caption2,
                    captionUIFont: UIFont.preferredFont(forTextStyle: .caption2),
                    containerSize: geometry.size,
                    glucoseMinimumScaleFactor: 1.0
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .privacySensitive()
        .padding(.all, 8)
        .background(Color.clear)
    }

    @ViewBuilder
    private func compactBubbleRow(
        context: ActivityViewContext<GlucoseActivityAttributes>,
        currentBG: String,
        delta: String,
        glucoseColor: Color,
        iob: String,
        iobUnitLabel: String,
        iobCaption: String,
        cob: String,
        cobUnitLabel: String,
        cobCaption: String,
        valueFont: Font,
        valueUIFont: UIFont,
        unitFont: Font,
        unitUIFont: UIFont,
        captionFont: Font,
        captionUIFont: UIFont,
        containerSize: CGSize,
        glucoseMinimumScaleFactor: CGFloat
    ) -> some View {
        HStack(spacing: 2) {
            compactGlucoseBubble(
                currentBG: currentBG,
                delta: delta,
                glucoseColor: glucoseColor,
                context: context,
                glucoseMinimumScaleFactor: glucoseMinimumScaleFactor
            )
            .frame(height: containerSize.height)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)

            synchronizedCompactMetricsRow(
                iob: iob,
                iobUnitLabel: iobUnitLabel,
                iobCaption: iobCaption,
                cob: cob,
                cobUnitLabel: cobUnitLabel,
                cobCaption: cobCaption,
                valueFont: valueFont,
                unitFont: unitFont,
                captionFont: captionFont,
                spacing: 2
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func synchronizedCompactMetricsRow(
        iob: String,
        iobUnitLabel: String,
        iobCaption: String,
        cob: String,
        cobUnitLabel: String,
        cobCaption: String,
        valueFont: Font,
        unitFont: Font,
        captionFont: Font,
        spacing: CGFloat
    ) -> some View {
        HStack(spacing: spacing) {
            compactValueItem(value: iob, unitLabel: iobUnitLabel, caption: iobCaption, valueFont: valueFont, unitFont: unitFont, captionFont: captionFont)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            compactValueItem(value: cob, unitLabel: cobUnitLabel, caption: cobCaption, valueFont: valueFont, unitFont: unitFont, captionFont: captionFont)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func compactValueItem(
        value: String,
        unitLabel: String,
        caption: String,
        valueFont: Font,
        unitFont: Font,
        captionFont: Font
    ) -> some View {
        VStack(alignment: .center) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(unitLabel)
                .font(unitFont)
                .foregroundStyle(Color(white: 0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(caption)
                .font(captionFont)
                .foregroundStyle(Color(white: 0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func compactGlucoseBubble(
        currentBG: String,
        delta: String,
        glucoseColor: Color,
        context: ActivityViewContext<GlucoseActivityAttributes>,
        glucoseMinimumScaleFactor: CGFloat
    ) -> some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 6) {
                loopIcon(context, size: 11)
                    .frame(width: 11, height: 11)
                Text(currentBG)
                    .font(.headline)
                    .foregroundStyle(glucoseColor)
                    .lineLimit(1)
                    .minimumScaleFactor(glucoseMinimumScaleFactor)
            }

            Text(delta)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 6)
        .frame(maxHeight: .infinity, alignment: .center)
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Dynamic Island View

    private func dynamicIslandView(
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> DynamicIsland {
        let glucoseFormatter = NumberFormatter.glucoseFormatter(
            for: context.state.isMmol
                ? HKUnit.millimolesPerLiter : HKUnit.milligramsPerDeciliter
        )

        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                HStack(alignment: .center) {
                    loopIcon(context)
                        .frame(width: 40, height: 40, alignment: .trailing)
                    Spacer()
                    Text(
                        "\(glucoseFormatter.string(from: context.state.currentGlucose) ?? "??")\(getArrowImage(context.state.trendType))"
                    )
                    .foregroundStyle(getGlucoseColor(context: context))
                    .font(.headline)
                    .fontWeight(.heavy)
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                HStack {
                    Text(context.state.delta)
                        .foregroundStyle(Color(white: 0.9))
                        .font(.headline)
                    Text(
                        context.state.isMmol
                            ? HKUnit.millimolesPerLiter.localizedShortUnitString
                            : HKUnit.milligramsPerDeciliter
                                .localizedShortUnitString
                    )
                    .foregroundStyle(Color(white: 0.7))
                    .font(.subheadline)
                }
            }
            DynamicIslandExpandedRegion(.bottom) {
                if context.attributes.addPredictiveLine {
                    ChartView(
                        glucoseSamples: context.state.glucoseSamples,
                        predicatedGlucose: context.state.predicatedGlucose,
                        predicatedStartDate: context.state.predicatedStartDate,
                        predicatedInterval: context.state.predicatedInterval,
                        useLimits: context.attributes.useLimits,
                        lowerLimit: context.state.isMmol
                            ? context.attributes.lowerLimitChartMmol
                            : context.attributes.lowerLimitChartMg,
                        upperLimit: context.state.isMmol
                            ? context.attributes.upperLimitChartMmol
                            : context.attributes.upperLimitChartMg,
                        glucoseRanges: context.state.glucoseRanges,
                        preset: context.state.preset,
                        yAxisMarks: context.state.yAxisMarks,
                        markerDate: context.state.lastCompleted
                    )
                    .frame(height: 75)
                } else {
                    ChartView(
                        glucoseSamples: context.state.glucoseSamples,
                        useLimits: context.attributes.useLimits,
                        lowerLimit: context.state.isMmol
                            ? context.attributes.lowerLimitChartMmol
                            : context.attributes.lowerLimitChartMg,
                        upperLimit: context.state.isMmol
                            ? context.attributes.upperLimitChartMmol
                            : context.attributes.upperLimitChartMg,
                        glucoseRanges: context.state.glucoseRanges,
                        preset: context.state.preset,
                        yAxisMarks: context.state.yAxisMarks,
                        markerDate: context.state.lastCompleted
                    )
                    .frame(height: 75)
                }
            }
        } compactLeading: {
            Text(
                "\(glucoseFormatter.string(from: context.state.currentGlucose) ?? "??")\(getArrowImage(context.state.trendType))"
            )
            .foregroundStyle(
                getGlucoseColor(context: context)
            )
            .minimumScaleFactor(0.1)
        } compactTrailing: {
            Text(context.state.delta)
                .foregroundStyle(Color(white: 0.9))
                .minimumScaleFactor(0.1)
        } minimal: {
            Text(
                glucoseFormatter.string(from: context.state.currentGlucose)
                    ?? "??"
            )
            .foregroundStyle(
                getGlucoseColor(context: context)
            )
            .minimumScaleFactor(0.1)
        }
    }

    @ViewBuilder
    private func loopIcon(
        _ context: ActivityViewContext<GlucoseActivityAttributes>,
        size: CGFloat = 36
    ) -> some View {
        Circle()
            .trim(from: context.state.isCloseLoop ? 0 : 0.2, to: 1)
            .stroke(getLoopColor(context.state.lastCompleted), lineWidth: size/4.5)
            .rotationEffect(Angle(degrees: -126))
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func bottomItemGeneric(title: String, value: String, unit: String)
        -> some View
    {
        VStack(alignment: .center) {
            Text("\(value)\(unit)")
                .font(.headline)
                .foregroundStyle(.primary)
                .fontWeight(.heavy)
                .font(Font.body.leading(.tight))
            Text(title)
                .font(.caption2)
        }
    }

    @ViewBuilder
    private func bottomItemCurrentBG(
        value: String,
        trend: GlucoseTrend?,
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> some View {
        VStack(alignment: .center) {
            HStack {
                Text(value + getArrowImage(trend))
                    .font(.title)
                    .foregroundStyle(
                        !context.attributes.useLimits
                            ? .primary
                            : getGlucoseColor(context: context)
                    )
                    .fontWeight(.heavy)
                    .font(Font.body.leading(.tight))
            }
        }
    }

    @ViewBuilder
    private func bottomItemLoopCircle(
        context: ActivityViewContext<GlucoseActivityAttributes>
    ) -> some View {
        VStack(alignment: .center) {
            loopIcon(context)
        }
    }

    @ViewBuilder
    private func bottomSpacer(border: Bool) -> some View {
        Spacer()
        if border {
            Divider()
                .background(.secondary)
            Spacer()
        }

    }

    private func getArrowImage(_ trendType: GlucoseTrend?) -> String {
        switch trendType {
        case .upUpUp:
            return "\u{2191}\u{2191}"  // ↑↑
        case .upUp:
            return "\u{2191}"  // ↑
        case .up:
            return "\u{2197}"  // ↗
        case .flat:
            return "\u{2192}"  // →
        case .down:
            return "\u{2198}"  // ↘
        case .downDown:
            return "\u{2193}"  // ↓
        case .downDownDown:
            return "\u{2193}\u{2193}"  // ↓↓
        case .none:
            return ""
        }
    }

    private func getLoopColor(_ age: Date?) -> Color {
        var freshness: LoopCompletionFreshness = .stale
        if let age = age {
            freshness = LoopCompletionFreshness(
                age: abs(min(0, age.timeIntervalSinceNow))
            )
        }

        switch freshness {
        case .fresh:
            return Color("fresh")
        case .aging:
            return Color("warning")
        case .stale:
            return .red
        }
    }

    private func getGlucoseColor(context: ActivityViewContext<GlucoseActivityAttributes>) -> Color {
        guard context.attributes.useLimits else {
            return .primary
        }
        
        let value = context.state.currentGlucose
        if context.state.isMmol
            && value < context.attributes.lowerLimitChartMmol
            || !context.state.isMmol
                && value < context.attributes.lowerLimitChartMg
        {
            return .red
        }

        if context.state.isMmol
            && value > context.attributes.upperLimitChartMmol
            || !context.state.isMmol
                && value > context.attributes.upperLimitChartMg
        {
            return .orange
        }

        return .green
    }

}
