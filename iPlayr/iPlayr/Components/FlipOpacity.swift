import SwiftUI

struct FlipOpacity: AnimatableModifier {
   var pct: CGFloat = 0
   
   var animatableData: CGFloat {
      get { pct }
      set { pct = newValue }
   }
   
   func body(content: Content) -> some View {
      return content.opacity(Double(pct.rounded()))
   }
}
