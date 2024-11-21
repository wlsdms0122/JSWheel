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
    public var onSelectingEnd: (() -> Void)?
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
        
        var onSelectingEnd: (() -> Void)?
        
        // MARK: - Initializer
        init(selection: Binding<Data.Element?>) {
            self._selection = selection
        }
        
        // MARK: - Lifecycle
        public func wheelController(_ wheelController: some JSWheelControllable, didSelect item: Data.Element?) {
            Task { @MainActor in
                selection = item
            }
        }
        
        public func wheelControllerDidEndSelecting(_ wheelController: some JSWheelControllable) {
            Task { @MainActor in
                onSelectingEnd?()
            }
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
        
        context.coordinator.onSelectingEnd = option.onSelectingEnd
        
        if selection?[keyPath: id] != uiViewController.selection?[keyPath: id] {
            uiViewController.setSelection(selection, animated: true)
            Task {
                selection = uiViewController.selection
            }
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
