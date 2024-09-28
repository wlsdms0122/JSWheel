//
//  _Preview.swift
//
//
//  Created by JSilver on 9/29/24.
//

import SwiftUI

#if DEBUG
struct _Preview: View {
    var body: some View {
        List {
            Section {
                HStack {
                    JSWheel(selection: $first, data: 1...9) { value in
                        Text("\(value)")
                            .foregroundColor(value == first ? .blue : .gray)
                            .scaleEffect(value == first ? .init(width: 1.4, height: 1.4) : .init(width: 1, height: 1))
                            .animation(.default)
                    }
                    JSWheel(selection: $second, data: 1...9) { value in
                        Text("\(value)")
                            .foregroundColor(value == second ? .blue : .gray)
                            .scaleEffect(value == second ? .init(width: 1.4, height: 1.4) : .init(width: 1, height: 1))
                            .animation(.default)
                    }
                    JSWheel(selection: $third, data: 1...9) { value in
                        Text("\(value)")
                            .foregroundColor(value == third ? .blue : .gray)
                            .scaleEffect(value == third ? .init(width: 1.4, height: 1.4) : .init(width: 1, height: 1))
                            .animation(.default)
                    }
                }
                    .config(JSWheelOption.self, style: \.itemHeight, to: isExpand ? 60 : 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.gray.opacity(0.1))
                            .frame(height: 40)
                            .allowsHitTesting(false)
                    )
                    .frame(height: 180)
            } header: {
                Text("Wheel")
            }
            
            Section {
                HStack {
                    Text("Value")
                    
                    Spacer()
                    
                    HStack {
                        Text("\(first ?? 0)")
                            .frame(width: 20)
                        Text("\(second ?? 0)")
                            .frame(width: 20)
                        Text("\(third ?? 0)")
                            .frame(width: 20)
                    }
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Expand")
                    Spacer()
                    Toggle(isOn: $isExpand) { EmptyView() }
                }
                
                Button("Shuffle") {
                    first = Int.random(in: 1...9)
                    second = Int.random(in: 1...9)
                    third = Int.random(in: 1...9)
                }
            }
        }
    }
    
    @State
    private var first: Int? = 3
    @State
    private var second: Int? = 4
    @State
    private var third: Int? = 5
    
    @State
    private var isExpand: Bool = false
    
    init() { }
}

#Preview {
    _Preview()
}
#endif
