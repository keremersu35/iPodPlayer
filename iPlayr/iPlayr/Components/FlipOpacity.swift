import SwiftUI

struct FlipOpacity: ViewModifier, Animatable {
   var pct: CGFloat = 0

   nonisolated var animatableData: CGFloat {
      get { pct }
      set { pct = newValue }
   }

   func body(content: Content) -> some View {
       content.opacity(Double(pct.rounded()))
   }
}
