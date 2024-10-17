//
//  StoryView.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-11.
//

import ComposableArchitecture
import SwiftUI

struct StoryView: View {
    let store: StoreOf<StoryViewFeature>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color(colorScheme == .dark ? .black : .white)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 0) {
                        // Custom navigation bar
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.blue)
                                Text("Back")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                        }
                        .padding()

                        // Custom progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<viewStore.images.count, id: \.self) { index in
                                GeometryReader { geo in
                                    let width = geo.size.width
                                    let isCompleted = viewStore.completedSegments[index]
                                    let progress = isCompleted ? 1 : (index == viewStore.currentIndex ? viewStore.progress : 0)

                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.5))

                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: width * progress)
                                    }
                                    .cornerRadius(2)
                                }
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                        // Image container
                        GeometryReader { imageGeometry in
                            HStack(spacing: 0) {
                                ForEach(0..<viewStore.images.count, id: \.self) { index in
                                    Image(systemName: viewStore.images[index])
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(width: imageGeometry.size.width, height: imageGeometry.size.height)
                                        .clipped()
                                }
                            }
                            .offset(x: -CGFloat(viewStore.currentIndex) * imageGeometry.size.width + viewStore.offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        viewStore.send(.dragChanged(gesture.translation.width))
                                    }
                                    .onEnded { gesture in
                                        viewStore.send(.dragEnded(gesture.translation.width))
                                    }
                            )
                        }
                    }
                    .animation(.easeInOut, value: viewStore.currentIndex)
                }
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                        viewStore.send(.togglePauseResume)
                    }
            )
            .navigationBarHidden(true)
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

#Preview {
    StoryView(
        store: Store(initialState: StoryViewFeature.State(
            images: [
                "person.crop.circle",
                "person.crop.circle.fill",
                "person.crop.square",
                "person.crop.square.fill",
                "person.crop.rectangle"
            ],
            transitionDuration: 3.0
        )) {
            StoryViewFeature()
        }
    )
}
