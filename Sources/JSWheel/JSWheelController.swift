//
//  JSWheelController.swift
//  
//
//  Created by JSilver on 9/29/24.
//

import UIKit
import SwiftUI

public protocol JSWheelControllerDelegate<Element>: AnyObject {
    associatedtype Element
    
    /// Called when an item is selected in the wheel controller.
    func wheelController(_ wheelController: some JSWheelControllable, didSelect element: Element?)
    /// Called when the wheel finished selecting an item.
    func wheelControllerDidEndSelecting(_ wheelController: some JSWheelControllable)
}

public protocol JSWheelControllable { }

public class JSWheelController<
    Data: RandomAccessCollection,
    ID: Hashable,
    Content: View
>: UIViewController, JSWheelControllable, UICollectionViewDelegate {
    // MARK: - View
    private var collectionView: UICollectionView!
    
    // MARK: - Property
    private var cache: [ID: Data.Element] = [:]
    public private(set) var selection: Data.Element? {
        didSet {
            guard oldValue?[keyPath: id] != selection?[keyPath: id] else { return }
            // Send wheel item selected event only when item changes.
            delegate?.wheelController(self, didSelect: selection)
            
            if let selection {
                // Reconfigure cell layout if selection item exists.
                reconfigCell(element: selection)
            }
        }
    }
    
    public var itemHeight: CGFloat = 32 {
        didSet {
            guard oldValue != itemHeight else { return }
            
            // Update collection view layout
            let layout = makeCollectionViewLayout(itemHeight: itemHeight, spacing: spacing)
            updateLayout(layout, animated: true)
            
            // Update collection view's content inset when item height changed.
            setCollectionViewContentInsets(itemHeight: itemHeight)
        }
    }
    public var spacing: CGFloat = 0 {
        didSet {
            guard oldValue != spacing else { return }
            
            // Update collection view layout.
            let layout = makeCollectionViewLayout(itemHeight: itemHeight, spacing: spacing)
            updateLayout(layout, animated: true)
        }
    }
    
    private var data: Data
    private let id: KeyPath<Data.Element, ID>
    var content: (Data.Element) -> Content {
        didSet {
            // Reconfig visible cells when content changed.
            reconfigVisibleCells()
        }
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, ID>?
    public weak var delegate: (any JSWheelControllerDelegate<Data.Element>)?
    
    // MARK: - Initializer
    init(
        initial selection: Data.Element? = nil,
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        content: @escaping (Data.Element) -> Content
    ) {
        self.selection = selection
        self.data = data
        self.id = id
        self.content = content
        
        self.cache = Dictionary(
            data.map { element in (element[keyPath: id], element) }
        ) { _, rhs in rhs }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func loadView() {
        self.collectionView = {
            let layout = makeCollectionViewLayout(itemHeight: itemHeight, spacing: spacing)
            
            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            view.backgroundColor = .clear
            view.showsVerticalScrollIndicator = false
            view.scrollsToTop = false
            
            return view
        }()
        
        self.view = {
            let view = UIView()
            view.backgroundColor = .clear
            
            return view
        }()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update collection view's content inset when collection view's bounds changed.
        setCollectionViewContentInsets(itemHeight: itemHeight)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let selection, !scrollView.isTracking else { return }
        
        // Adjust scroll position to the center of the item.
        scrollToElement(selection, animated: true)
        // Send wheel item selecting ended event.
        delegate?.wheelControllerDidEndSelecting(self)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let selection, !decelerate else { return }
        
        // Adjust scroll position to the center of the item.
        scrollToElement(selection, animated: true)
        // Send wheel item selecting ended event.
        delegate?.wheelControllerDidEndSelecting(self)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard collectionView.isTracking || collectionView.isDecelerating else { return }
        
        guard let indexPath = centerIndexPath(), let id = dataSource?.itemIdentifier(for: indexPath) else { return }
        
        selection = cache[id]
    }
    
    // MARK: - Public
    public func updateData(_ data: Data) {
        // Set data and make item cache dictionary.
        self.data = data
        self.cache = Dictionary(
            data.map { element in (element[keyPath: id], element) }
        ) { _, rhs in rhs }
        
        // Set selection through new data set. If the existing selection is not in the new data set, it will be set to `nil`.
        self.selection = selection.map { element in element[keyPath: id] }
            .flatMap { id in cache[id] }
        
        // Reload data source.
        let snapshot = makeDataSourceSnapshot(data: data)
        dataSource?.apply(snapshot)
    }
    
    public func setSelection(_ selection: Data.Element?, animated: Bool) {
        guard let selection, cache[selection[keyPath: id]] != nil else {
            self.selection = nil
            return
        }
        
        self.selection = selection
        
        // Scroll to selected item.
        scrollToElement(selection, animated: animated)
    }
    
    // MARK: - Private
    private func setUp() {
        setUpLayout()
        setUpState()
        setUpAction()
    }
    
    private func setUpLayout() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    private func setUpState() {
        let cellRegistration = UICollectionView.CellRegistration<_UIHostingCollectionViewCell<Content>, ID> { [weak self] cell, indexPath, id in
            guard let data = self?.cache[id], let content = self?.content(data) else { return }
            cell.configure(content: content)
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Int, ID>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        let snapshot = makeDataSourceSnapshot(data: data)
        dataSource.apply(snapshot)
        
        self.dataSource = dataSource
        
        collectionView.delegate = self
    }
    
    private func setUpAction() {
        
    }
    
    private func setCollectionViewContentInsets(itemHeight: CGFloat) {
        let inset = (collectionView.bounds.height - itemHeight) / 2
        collectionView.contentInset = .init(top: inset, left: 0, bottom: inset, right: 0)
    }
    
    private func makeCollectionViewLayout(itemHeight: CGFloat, spacing: CGFloat) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(itemHeight)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func makeDataSourceSnapshot(data: Data) -> NSDiffableDataSourceSnapshot<Int, ID> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(data.map { element in element[keyPath: id] })
        
        return snapshot
    }
    
    private func reconfigCell(element: Data.Element) {
        guard let indexPath = dataSource?.indexPath(for: element[keyPath: id]),
            let cell = collectionView.cellForItem(at: indexPath) as? _UIHostingCollectionViewCell<Content>
        else { return }
        
        cell.configure(content: content(element))
    }
    
    private func reconfigVisibleCells() {
        collectionView.indexPathsForVisibleItems
            .compactMap { indexPath -> (_UIHostingCollectionViewCell<Content>, ID)? in
                guard let cell = collectionView.cellForItem(at: indexPath) as? _UIHostingCollectionViewCell<Content>,
                    let id = dataSource?.itemIdentifier(for: indexPath)
                else { return nil }
                
                return (cell, id)
            }
            .forEach { cell, id in
                guard let element = cache[id] else { return }
                
                cell.configure(content: content(element))
            }
    }
    
    private func updateLayout(_ layout: UICollectionViewLayout, animated: Bool) {
        collectionView.setCollectionViewLayout(layout, animated: animated) { [weak self] _ in
            guard let selection = self?.selection else { return }
            self?.scrollToElement(selection, animated: animated)
        }
    }
    
    private func centerIndexPath() -> IndexPath? {
        let center = view.convert(collectionView.center, to: collectionView)
        return collectionView.indexPathForItem(at: center)
    }
    
    private func scrollToElement(_ element: Data.Element, animated: Bool) {
        guard let indexPath = dataSource?.indexPath(for: element[keyPath: id]) else { return }
        scrollToIndexPath(indexPath, animated: animated)
    }
    
    private func scrollToIndexPath(_ indexPath: IndexPath, animated: Bool) {
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
    }
}

class _UIHostingCollectionViewCell<Content: View>: UICollectionViewCell {
    // MARK: - View
    
    // MARK: - Property
    private var hostingController: UIHostingController<Content>?
    
    // MARK: - Initializer
    
    // MARK: - Lifecycle
    
    // MARK: - Public
    func configure(content: Content) {
        guard let hostingController else {
            let hostingController = UIHostingController(rootView: content)
            
            let view = hostingController.view!
            view.backgroundColor = .clear
            
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            ])
            
            self.hostingController = hostingController
            return
        }
        
        hostingController.rootView = content
        hostingController.view.invalidateIntrinsicContentSize()
    }
    
    func attach(to viewController: UIViewController) {
        guard let hostingController else { return }
        
        viewController.addChild(hostingController)
        hostingController.didMove(toParent: viewController)
    }
    
    func dettach() {
        hostingController?.removeFromParent()
    }
    
    // MARK: - Private
}
