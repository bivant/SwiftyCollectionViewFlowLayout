//
//  SwiftyCollectionViewFlowLayout.swift
//  SwiftyCollectionViewFlowLayout
//
//  Created by dfsx6 on 2023/1/9.
//

import UIKit

class WaterFlowSectionAttributes {
    var inset: UIEdgeInsets = .zero
    var headerHeight: CGFloat = .zero
    var footerHeight: CGFloat = .zero
    var body: [Int: CGFloat] = [:]
    
    
    /// 当前Section的Body总高度
    var maxBodyHeight: CGFloat {
        var maxHeight: CGFloat = .zero
        for height in body.values {
            if !height.isLessThanOrEqualTo(maxHeight) {
                maxHeight = height
            }
        }
        return maxHeight
    }
    
    /// 当前Section总高度
    var totalHeight: CGFloat {
        return headerHeight + inset.top + maxBodyHeight + inset.bottom + footerHeight
    }
    
    /// 当前Section Body之前的高度
    var bodyBeforeHeight: CGFloat {
        return headerHeight + inset.top
    }
    
    /// 当前Section Footer之前的高度
    var footerBeforeHeight: CGFloat {
        return headerHeight + inset.top + maxBodyHeight + inset.bottom
    }
}

open class SwiftyCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    
    private var mDelegate: SwiftyCollectionViewDelegateFlowLayout? {
        return collectionView?.delegate as? SwiftyCollectionViewDelegateFlowLayout
    }
    
    private var waterFlowSectionAttributes: [Int: WaterFlowSectionAttributes] = [:]
    
    
    public override init() {
        super.init() 
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SwiftyCollectionViewFlowLayout {
    open override func prepare() {
        super.prepare()
       
        guard let collectionView = collectionView else { return }
        
        
        waterFlowSectionAttributes.removeAll()
        
        for section in 0..<collectionView.numberOfSections {
            let sectionInset = mDelegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? .zero
            let sectionHeaderSize = mDelegate?.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? .zero
            let sectionFooterSize = mDelegate?.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? .zero
            
            var headerHeight: CGFloat = .zero
            var footerHeight: CGFloat = .zero
            
            if scrollDirection == .vertical {
                headerHeight = sectionHeaderSize.height
                footerHeight = sectionFooterSize.height
            } else if scrollDirection == .horizontal {
                headerHeight = sectionHeaderSize.width
                footerHeight = sectionFooterSize.width
            }
            
            let numberOfColumns = mDelegate?.collectionView(collectionView, layout: self, numberOfColumnsInSection: section) ?? 0
            
            var body: [Int: CGFloat] = [:]
            for column in 0..<numberOfColumns {
                body[column] = .zero
            }
            
            let waterFlowSectionAttr = WaterFlowSectionAttributes()
            waterFlowSectionAttr.inset = sectionInset
            waterFlowSectionAttr.headerHeight = headerHeight
            waterFlowSectionAttr.footerHeight = footerHeight
            waterFlowSectionAttr.body = body
            
            waterFlowSectionAttributes[section] = waterFlowSectionAttr
        }
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return []
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        
        let numberOfColumns = mDelegate?.collectionView(collectionView, layout: self, numberOfColumnsInSection: indexPath.section) ?? 0
        let sectionInset = mDelegate?.collectionView?(collectionView, layout: self, insetForSectionAt: indexPath.section) ?? .zero
        let columnSpacing = mDelegate?.collectionView(collectionView, layout: self, columnSpacingForSectionAt: indexPath.section) ?? .zero
        let itemSize = mDelegate?.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
        
        let columnWidth = (collectionView.frame.width - sectionInset.left - sectionInset.right - (numberOfColumns - 1) * columnSpacing) / CGFloat(numberOfColumns)
        
        
        var body: [Int: CGFloat] = [:]
        for column in 0..<numberOfColumns {
            body[column] = .zero
        }
        
        if let attr = waterFlowSectionAttributes[indexPath.section] {
            if attr.body.isEmpty && numberOfColumns > 0 {
                attr.body = body
            }
        } else {
            let attr = WaterFlowSectionAttributes()
            attr.body = body
            waterFlowSectionAttributes[indexPath.section] = attr
        }
        
        if scrollDirection == .vertical {
            let columnHeight = itemSize.height
            
            let sectionAttr = waterFlowSectionAttributes[indexPath.section]! // 一定存在
            
            for (_, element) in sectionAttr.body.enumerated() {
                
            }
        }
        
        
        
        
        return nil
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        
        let attr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        
        if elementKind == UICollectionView.elementKindSectionHeader {
            let headerSize = mDelegate?.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: indexPath.section) ?? .zero
            
            let beforeHeight = getBeforeSectionTotalHeight(currentSection: indexPath.section)
            
            var header_x: CGFloat = .zero
            var header_y: CGFloat = .zero
            var header_width: CGFloat = .zero
            var header_height: CGFloat = .zero
            
            if scrollDirection == .vertical {
                header_x = .zero
                header_y = beforeHeight
                header_width = collectionView.frame.width
                header_height = headerSize.height
            } else if scrollDirection == .horizontal {
                header_x = beforeHeight
                header_y = .zero
                header_width = headerSize.width
                header_height = collectionView.frame.height
            }
            
            attr.frame = CGRect(x: header_x, y: header_y, width: header_width, height: header_height)
            
            if let attr = waterFlowSectionAttributes[indexPath.section] {
                attr.headerHeight = headerSize.height
            } else {
                let attr = WaterFlowSectionAttributes()
                attr.headerHeight = headerSize.height
                waterFlowSectionAttributes[indexPath.section] = attr
            }
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            let footerSize = mDelegate?.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: indexPath.section) ?? .zero
            
            var beforeHeight = getBeforeSectionTotalHeight(currentSection: indexPath.section)
            
            if let attr = waterFlowSectionAttributes[indexPath.section] {
                beforeHeight += attr.footerBeforeHeight
            }
            
            var header_x: CGFloat = .zero
            var header_y: CGFloat = .zero
            var header_width: CGFloat = .zero
            var header_height: CGFloat = .zero
            
            if scrollDirection == .vertical {
                header_x = .zero
                header_y = beforeHeight
                header_width = collectionView.frame.width
                header_height = footerSize.height
            } else if scrollDirection == .horizontal {
                header_x = beforeHeight
                header_y = .zero
                header_width = footerSize.width
                header_height = collectionView.frame.height
            }
            
            attr.frame = CGRect(x: header_x, y: header_y, width: header_width, height: header_height)
            
            if let attr = waterFlowSectionAttributes[indexPath.section] {
                attr.footerHeight = footerSize.height
            } else {
                let attr = WaterFlowSectionAttributes()
                attr.footerHeight = footerSize.height
                waterFlowSectionAttributes[indexPath.section] = attr
            }
        }
        return nil
    }
    
    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
    
    open override var collectionViewContentSize: CGSize {
        return .zero
    }
}

extension SwiftyCollectionViewFlowLayout {
    private func getBeforeSectionTotalHeight(currentSection: Int) -> CGFloat {
        var totalHeight: CGFloat = .zero
        
        for (_, element) in waterFlowSectionAttributes.enumerated() {
            let section = element.key
            let attr = element.value
            if section < currentSection {
                totalHeight = totalHeight + attr.totalHeight
            }
        }
        return totalHeight
    }
}
