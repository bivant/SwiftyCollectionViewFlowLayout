//
//  SwiftyCollectionViewFlowLayout.swift
//  SwiftyCollectionViewFlowLayout
//
//  Created by dfsx6 on 2023/1/9.
//

import Foundation
import UIKit

private struct PrepareActions: OptionSet {
    let rawValue: UInt
    static let recreateSectionModels = PrepareActions(rawValue: 1 << 0)
    static let updateLayoutMetrics = PrepareActions(rawValue: 1 << 1)
}


/// `SwiftyCollectionViewFlowLayout`, Inherit `UICollectionViewLayout`
public final class SwiftyCollectionViewFlowLayout: UICollectionViewLayout {
    deinit {
#if DEBUG
        print("\(NSStringFromClass(self.classForCoder)) deinit")
#endif
    }
    
    public static let SectionBackgroundElementKind = "SwiftyCollectionViewFlowLayout.SectionBackgroundElementKind"
    
    internal var mDelegate: SwiftyCollectionViewDelegateFlowLayout? {
        return collectionView?.delegate as? SwiftyCollectionViewDelegateFlowLayout
    }
    
    private var cacheContentSize: CGSize?
    
    internal var mCollectionView: UICollectionView {
        guard let mCollectionView = collectionView else {
            fatalError("`collectionView` should not be `nil`")
        }
        return mCollectionView
    }
    
    private var hasPinnedHeaderOrFooter: Bool = false
    
    /// scroll direction.
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            invalidateLayout()
        }
    }
    
    private let shouldFlipForRTL: Bool	//If your subclass’s implementation overrides this property to return true, a UICollectionView showing this layout will ensure its bounds.origin is always found at the leading edge, flipping its coordinate system horizontally if necessary.
    public override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        shouldFlipForRTL
    }
    
    private var prepareActions: PrepareActions = []
    
    internal lazy var modeState: ModeState = {
        let modeState = ModeState(layout: self)
        return modeState
    }()
    
    public override init() {
        shouldFlipForRTL = false
        super.init()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(flipForRTL: Bool) {
        shouldFlipForRTL = flipForRTL
        super.init()
    }
}

extension SwiftyCollectionViewFlowLayout {
    public override class var invalidationContextClass: AnyClass {
        return SwiftyCollectionViewLayoutInvalidationContext.self
    }
    
    public override class var layoutAttributesClass: AnyClass {
        return SwiftyCollectionViewLayoutAttributes.self
    }
    
    public override func prepare() {
        super.prepare()
        
        if prepareActions.isEmpty {
            return
        }
        
        if prepareActions.contains(.updateLayoutMetrics) || prepareActions.contains(.recreateSectionModels) {
            hasPinnedHeaderOrFooter = false
        }
        
        if prepareActions.contains(.updateLayoutMetrics) {
            for section in 0..<modeState.numberOfSections() {
                
                let metrics = metricsForSection(at: section)
                modeState.updateMetrics(metrics, at: section)
                
                if let headerModel = headerModelForHeader(at: section, metrics: metrics) {
                    modeState.setHeader(headerModel: headerModel, at: section)
                } else {
                    modeState.removeFooter(at: section)
                }
                
                if let footerModel = footerModelForFooter(at: section, metrics: metrics) {
                    modeState.setFooter(footerModel: footerModel, at: section)
                } else {
                    modeState.removeFooter(at: section)
                }
                
                if let backgroundModel = backgroundModel(at: section) {
                    modeState.setBackground(backgroundModel: backgroundModel, at: section)
                } else {
                    modeState.removeBackground(at: section)
                }
                
                for i in 0..<modeState.numberOfItems(at: section) {
                    let indexPath = IndexPath(item: i, section: section)
                    let initialSizeMode = sizeModeForItem(at: indexPath)
                    let correctSizeMode = modeState.correctSizeMode(initialSizeMode,
                                                                    supplementaryElementKind: nil,
                                                                    metrics: metrics)
                    modeState.updateItemSizeMode(correctSizeMode: correctSizeMode, at: indexPath)
                }
            }
        }
        
        if prepareActions.contains(.recreateSectionModels) {
            modeState.clear()
            let numberOfSections = mCollectionView.numberOfSections
            var sectionModels: [SectionModel] = []
            for section in 0..<numberOfSections {
                let sectionModel = sectionModelForSection(at: section)
                sectionModels.append(sectionModel)
            }
            modeState.setSections(sectionModels)
        }
        
        prepareActions = []
    }
    
    public override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        var updates = [CollectionViewUpdate<SectionModel, ItemModel>]()
        
        for updateItem in updateItems {
            let updateAction = updateItem.updateAction
            let indexPathBeforeUpdate = updateItem.indexPathBeforeUpdate
            let indexPathAfterUpdate = updateItem.indexPathAfterUpdate
            
            if updateAction == .reload {
                guard let indexPath = indexPathBeforeUpdate else { continue }
                let sectionModel = sectionModelForSection(at: indexPath.section)
                if indexPath.item == NSNotFound {
                    updates.append(.sectionReload(sectionIndex: indexPath.section, newSection: sectionModel))
                } else {
                    let itemModel = itemModelForItem(at: indexPath, metrics: sectionModel.metrics)
                    updates.append(.itemReload(itemIndexPath: indexPath, newItem: itemModel))
                }
            }
            
            if updateAction == .delete {
                guard let indexPath = indexPathBeforeUpdate else { continue }
                if indexPath.item == NSNotFound {
                    updates.append(.sectionDelete(sectionIndex: indexPath.section))
                } else {
                    updates.append(.itemDelete(itemIndexPath: indexPath))
                }
            }
            
            if updateAction == .insert {
                guard let indexPath = indexPathAfterUpdate else { continue }
                let sectionModel = sectionModelForSection(at: indexPath.section)
                if indexPath.item == NSNotFound {
                    updates.append(.sectionInsert(sectionIndex: indexPath.section, newSection: sectionModel))
                } else {
                    let itemModel = itemModelForItem(at: indexPath, metrics: sectionModel.metrics)
                    updates.append(.itemInsert(itemIndexPath: indexPath, newItem: itemModel))
                }
            }
            
            if updateAction == .move {
                guard let initialIndexPath = indexPathBeforeUpdate, let finalIndexPath = indexPathAfterUpdate else { continue }
                if initialIndexPath.item == NSNotFound && finalIndexPath.item == NSNotFound {
                    updates.append(.sectionMove(initialSectionIndex: initialIndexPath.section, finalSectionIndex: finalIndexPath.section))
                } else {
                    updates.append(.itemMove(initialItemIndexPath: initialIndexPath, finalItemIndexPath: finalIndexPath))
                }
            }
        }
        modeState.applyUpdates(updates)
    }
    
    public override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        modeState.clearInProgressBatchUpdateState()
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let sectionModel = modeState.sectionModel(at: indexPath.section) else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        guard let itemModel = modeState.itemModel(sectionModel.itemModels, index: indexPath.item) else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        let attr = modeState.itemLayoutAttributes(at: indexPath, frame: itemModel.frame, sectionModel: sectionModel, correctSizeMode: itemModel.correctSizeMode)
        return attr
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let sectionModel = modeState.sectionModel(at: indexPath.section) {
            if elementKind == UICollectionView.elementKindSectionHeader {
                if let headerModel = sectionModel.headerModel {
                    hasPinnedHeaderOrFooter = modeState.hasPinnedHeaderOrFooter()
                    return modeState.headerLayoutAttributes(at: indexPath.section,
                                                            frame: headerModel.frame,
                                                            sectionModel: sectionModel,
                                                            correctSizeMode: headerModel.correctSizeMode)
                }
            } else if elementKind == UICollectionView.elementKindSectionFooter {
                if let footerModel = sectionModel.footerModel {
                    hasPinnedHeaderOrFooter = modeState.hasPinnedHeaderOrFooter()
                    return modeState.footerLayoutAttributes(at: indexPath.section,
                                                            frame: footerModel.frame,
                                                            sectionModel: sectionModel,
                                                            correctSizeMode: footerModel.correctSizeMode)
                }
            } else if elementKind == SwiftyCollectionViewFlowLayout.SectionBackgroundElementKind {
                if let backgroundModel = sectionModel.backgroundModel {
                    return modeState.backgroundLayoutAttributes(at: indexPath.section,
                                                                frame: backgroundModel.frame)
                }
            }
        }
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        hasPinnedHeaderOrFooter = modeState.hasPinnedHeaderOrFooter()
        let attrs = modeState.layoutAttributesForElements(in: rect)
        return attrs
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let shouldInvalidateLayout = modeState.shouldInvalidateLayout(forBoundsChange: newBounds)
        return shouldInvalidateLayout || hasPinnedHeaderOrFooter
    }
    
    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let invalidationContext = super.invalidationContext(forBoundsChange: newBounds) as! SwiftyCollectionViewLayoutInvalidationContext
        invalidationContext.invalidateLayoutMetrics = false
        return invalidationContext
    }
    
    public override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        if preferredAttributes.indexPath.isEmpty {
            return super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        }
        let shouldInvalidateLayout = modeState.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
        return shouldInvalidateLayout
    }
    
    public override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        modeState.updatePreferredLayoutAttributesSize(preferredAttributes: preferredAttributes)
        let invalidationContext = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) as! SwiftyCollectionViewLayoutInvalidationContext
        invalidationContext.invalidateLayoutMetrics = false
        return invalidationContext
    }
    
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let context = context as? SwiftyCollectionViewLayoutInvalidationContext else { return }
        
        
        if context.invalidateEverything {
            prepareActions.formUnion([.recreateSectionModels])
        }
        
        let shouldInvalidateLayoutMetrics = !context.invalidateEverything && !context.invalidateDataSourceCounts
        if shouldInvalidateLayoutMetrics && context.invalidateLayoutMetrics {
            prepareActions.formUnion(.updateLayoutMetrics)
        }
        
        super.invalidateLayout(with: context)
    }
    
    public override var collectionViewContentSize: CGSize {
        let size = modeState.collectionViewContentSize()
        
        if cacheContentSize == nil {
            mDelegate?.collectionView(mCollectionView, layout: self, contentSizeDidChange: size)
        } else {
            if !cacheContentSize!.equalTo(size) {
                mDelegate?.collectionView(mCollectionView, layout: self, contentSizeDidChange: size)
            }
        }
        cacheContentSize = size
        
        return size
    }
}

extension SwiftyCollectionViewFlowLayout {
    private func sectionModelForSection(at section: Int) -> SectionModel {
        let metrics = metricsForSection(at: section)
        
        var itemModels: [ItemModel] = []
        let numberOfItems = mCollectionView.numberOfItems(inSection: section)
        for index in 0..<numberOfItems {
            let itemModel = itemModelForItem(at: IndexPath(item: index, section: section), metrics: metrics)
            itemModels.append(itemModel)
        }
        
        let headerModel = headerModelForHeader(at: section, metrics: metrics)
        let footerModel = footerModelForFooter(at: section, metrics: metrics)
        let backgroundModel = backgroundModel(at: section)
        
        return SectionModel(headerModel: headerModel,
                            footerModel: footerModel,
                            itemModels: itemModels,
                            backgroundModel: backgroundModel,
                            metrics: metrics)
    }
    
    private func itemModelForItem(at indexPath: IndexPath, metrics: SectionMetrics) -> ItemModel {
        let itemSizeMode = sizeModeForItem(at: indexPath)
        let correctSizeMode = modeState.correctSizeMode(itemSizeMode,
                                                        supplementaryElementKind: nil,
                                                        metrics: metrics)
        return ItemModel(correctSizeMode: correctSizeMode)
    }
    
    private func headerModelForHeader(at section: Int, metrics: SectionMetrics) -> HeaderModel? {
        let headerVisibilityMode = visibilityModeForHeader(at: section)
        switch headerVisibilityMode {
            case .hidden:
                return nil
            case .visible(let sizeMode):
                let correctSizeMode = modeState.correctSizeMode(sizeMode,
                                                                supplementaryElementKind: UICollectionView.elementKindSectionHeader,
                                                                metrics: metrics)
                return HeaderModel(correctSizeMode: correctSizeMode)
        }
    }
    
    private func footerModelForFooter(at section: Int, metrics: SectionMetrics) -> FooterModel? {
        let footerVisibilityMode = visibilityModeForFooter(at: section)
        switch footerVisibilityMode {
            case .hidden:
                return nil
            case .visible(let sizeMode):
                let correctSizeMode = modeState.correctSizeMode(sizeMode,
                                                                supplementaryElementKind: UICollectionView.elementKindSectionFooter,
                                                                metrics: metrics)
                return FooterModel(correctSizeMode: correctSizeMode)
        }
    }
    
    private func backgroundModel(at section: Int) -> BackgroundModel? {
        let backgroundVisibilityMode = visibilityModeForBackground(at: section)
        switch backgroundVisibilityMode {
            case .hidden:
                return nil
            case .visible:
                return BackgroundModel()
        }
    }
    
    private func sizeModeForItem(at indexPath: IndexPath) -> SwiftyCollectionViewLayoutSizeMode {
        guard let mDelegate = mDelegate else { return Default.sizeMode }
        return mDelegate.collectionView(mCollectionView, layout: self, itemSizeModeAt: indexPath)
    }
    
    private func visibilityModeForHeader(at section: Int) -> SwiftyCollectionViewLayoutSupplementaryVisibilityMode {
        guard let mDelegate = mDelegate else { return Default.headerVisibilityMode }
        return mDelegate.collectionView(mCollectionView, layout: self, visibilityModeForHeaderInSection: section)
    }
    
    private func visibilityModeForFooter(at section: Int) -> SwiftyCollectionViewLayoutSupplementaryVisibilityMode {
        guard let mDelegate = mDelegate else { return Default.footerVisibilityMode }
        return mDelegate.collectionView(mCollectionView, layout: self, visibilityModeForFooterInSection: section)
    }
    
    private func visibilityModeForBackground(at section: Int) -> SwiftyCollectionViewLayoutBackgroundVisibilityMode {
        guard let mDelegate = mDelegate else { return Default.backgroundVisibilityMode }
        return mDelegate.collectionView(mCollectionView, layout: self, visibilityModeForBackgroundInSection: section)
    }
    
    private func metricsForSection(at section: Int) -> SectionMetrics {
        guard let mDelegate = mDelegate else { return Default.metrics }
        return SectionMetrics(section: section, collectionView: mCollectionView, layout: self, delegate: mDelegate)
    }
}
