import SwiftUI

struct RepairFocusSummary:View {
    let step:RepairStep
    @EnvironmentObject var app:AppModel
    var body:some View {
        Section {
            Text(ProductCopy.course(app.learner.support,"repair")+" · \(step.index+1)/\(step.stepCount)").font(.headline).accessibilityIdentifier("repairStepCounter")
            Text(step.item["concept"].string).accessibilityIdentifier("repairFocusConcept")
            if !step.item["summary"].string.isEmpty {Text(step.item["summary"].string).font(.footnote)}
        }
    }
}
