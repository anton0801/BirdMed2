import SwiftUI

/// Экран «Нет интернета» (раздел 2 ТЗ), по макету: карточка с тонкой тёмной рамкой
/// поверх слегка размытого фона стройки.
struct NoInternetView: View {
    private let borderColor = Color(hex: "333333").opacity(0.35)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("bgLoading")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.35))
                    .ignoresSafeArea()
                Image("noInternet")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 280)
            }
        }
        .ignoresSafeArea()
    }
}
