//
//  JSWheel.swift
//
//
//  Created by jsilver on 9/28/24.
//

import SwiftUI
import UIKit
import Stylish

@Stylish
public struct JSWheelOption {
    /// The height of each item in the wheel.
    public var itemHeight: CGFloat = 32
    /// The spacing between items in the wheel.
    public var spacing: CGFloat = 0
    /// A closure that gets called when the scrolling ends.
    public var onScrollEnd: (() -> Void)?
}

public struct JSWheel<
    Data: RandomAccessCollection,
    ID: Hashable,
    Content: View
>: UIViewControllerRepresentable {
    public class Coordinator: JSWheelControllerDelegate {
        // MARK: - Property
        @Binding
        private var selection: Data.Element?
        
        var onScrollEnd: (() -> Void)?
        
        // MARK: - Initializer
        init(selection: Binding<Data.Element?>) {
            self._selection = selection
        }
        
        // MARK: - Lifecycle
        public func wheelController(_ wheelController: some JSWheelControllable, didSelect item: Data.Element?) {
            Task {
                selection = item
            }
        }
        
        public func wheelControllerDidEndScroll(_ wheelController: some JSWheelControllable) {
            onScrollEnd?()
        }
        
        // MARK: - Public
        
        // MARK: - Private
    }
    
    // MARK: - Property
    @Binding
    private var selection: Data.Element?
    
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content
    
    @Style(JSWheelOption.self)
    private var option
    
    // MARK: - Initializer
    public init(
        selection: Binding<Data.Element?>,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self._selection = selection
        self.data = data
        self.id = id
        self.content = content
    }
    
    public init(
        selection: Binding<Data.Element?>,
        data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Data.Element == ID {
        self.init(selection: selection, data: data, id: \.self, content: content)
    }
    
    // MARK: - Lifecycle
    public func makeUIViewController(context: Context) -> JSWheelController<Data, ID, Content> {
        let controller = JSWheelController<Data, ID, Content>(
            initial: selection,
            data,
            id: id,
            content: content
        )
        
        controller.delegate = context.coordinator
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: JSWheelController<Data, ID, Content>, context: Context) {
        uiViewController.content = content
        uiViewController.itemHeight = option.itemHeight
        uiViewController.spacing = option.spacing
        
        uiViewController.updateData(data)
        
        context.coordinator.onScrollEnd = option.onScrollEnd
        
        if selection?[keyPath: id] != uiViewController.selection?[keyPath: id] {
            uiViewController.setSelection(selection, animated: true)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }
    
    // MARK: - Public
    
    // MARK: - Private
}

#if DEBUG
#Preview {
    _Preview()
}
#endif
