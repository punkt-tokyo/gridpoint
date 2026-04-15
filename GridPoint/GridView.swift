import SwiftUI

struct GridView: View {
    @ObservedObject var settings: GridSettings = .shared

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let cellW = settings.cellWidth
                let cellH = settings.cellHeight
                guard cellW > 0, cellH > 0 else { return }

                let color = settings.gridColor.opacity(settings.opacity)
                let strokeColor = GraphicsContext.Shading.color(color)

                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += cellW
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += cellH
                }
                context.stroke(path, with: strokeColor, lineWidth: 0.5)

                let cols = Int(ceil(size.width  / cellW))
                let rows = Int(ceil(size.height / cellH))
                let font = Font.custom("SFMono-Regular", size: 18)

                for r in 0..<rows {
                    for c in 0..<cols {
                        let label = "\(Self.rowLabel(r))\(c + 1)"
                        let text = Text(label).font(font).foregroundColor(color)
                        let resolved = context.resolve(text)
                        let center = CGPoint(x: CGFloat(c) * cellW + cellW / 2,
                                             y: CGFloat(r) * cellH + cellH / 2)
                        context.draw(resolved, at: center, anchor: .center)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    static func rowLabel(_ index: Int) -> String {
        var n = index
        var result = ""
        repeat {
            let rem = n % 26
            result = String(UnicodeScalar(65 + rem)!) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }
}
