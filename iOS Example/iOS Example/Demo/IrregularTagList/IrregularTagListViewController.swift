//
//  IrregularTagListViewController.swift
//  SwiftyCollectionViewFlowLayout
//
//  Created by dfsx6 on 2023/2/2.
//

import UIKit
import SwiftyCollectionViewFlowLayout
import SnapKit

private let heights: [CGFloat] = [40, 60, 80, 90, 100]
private let widths: [CGFloat] = [70, 80, 100, 120, 140]


public final class IrregularTagListViewController: UIViewController {
    
    private var dataSource: [[IrregularTagListModel]] = []
    
    private var direction: SwiftyCollectionViewRowDirection = .left {
        didSet {
            updateUI()
        }
    }
    private var alignment: SwiftyCollectionViewRowAlignment = .top {
        didSet {
            updateUI()
        }
    }
    private var scrollDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            updateUI()
        }
    }
    
    private lazy var layout: SwiftyCollectionViewFlowLayout = {
        let layout = SwiftyCollectionViewFlowLayout()
        layout.scrollDirection = scrollDirection
        layout.register(DecorationView.classForCoder(), forDecorationViewOfKind: SwiftyCollectionViewFlowLayout.DecorationElementKind)
        return layout
    }()
    
    private lazy var directionButton: UIButton = {
        let directionButton = UIButton(type: .system)
        directionButton.titleLabel?.numberOfLines = 0
        directionButton.contentHorizontalAlignment = .center
        directionButton.addTarget(self, action: #selector(directionAction), for: .touchUpInside)
        return directionButton
    }()
    
    private lazy var scrollDirectionButton: UIButton = {
        let scrollDirectionButton = UIButton(type: .system)
        scrollDirectionButton.titleLabel?.numberOfLines = 0
        scrollDirectionButton.contentHorizontalAlignment = .center
        scrollDirectionButton.addTarget(self, action: #selector(scrollDirectionAction), for: .touchUpInside)
        return scrollDirectionButton
    }()
    
    private lazy var alignmentButton: UIButton = {
        let alignmentButton = UIButton(type: .system)
        alignmentButton.titleLabel?.numberOfLines = 0
        alignmentButton.contentHorizontalAlignment = .center
        alignmentButton.addTarget(self, action: #selector(alignmentAction), for: .touchUpInside)
        return alignmentButton
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .cyan
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(IrregularTagListCell.classForCoder(), forCellWithReuseIdentifier: NSStringFromClass(IrregularTagListCell.classForCoder()))
        collectionView.register(IrregularTagListHeaderView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(IrregularTagListHeaderView.classForCoder()))
        collectionView.register(IrregularTagListFooterView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(IrregularTagListFooterView.classForCoder()))
        return collectionView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(scrollDirectionButton)
        view.addSubview(directionButton)
        view.addSubview(alignmentButton)
        view.addSubview(collectionView)
        
        
        scrollDirectionButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(120)
            make.height.equalTo(60)
        }
        directionButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.height.equalTo(scrollDirectionButton)
        }
        alignmentButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.height.equalTo(scrollDirectionButton)
        }
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(25)
            make.top.equalTo(scrollDirectionButton.snp.bottom).offset(15)
            make.bottom.equalToSuperview().offset(-80)
        }
        
        updateUI()
        
        loadData()
    }
}

extension IrregularTagListViewController {
    private func loadData() {
        dataSource.removeAll()
        
        let counts: [Int] = [5, 6, 7, 8, 9]
        for _ in 0...4 {
            var array: [IrregularTagListModel] = []
            for _ in 0..<counts.randomElement()! {
                let width = widths.randomElement()!
                let height = heights.randomElement()!
                let model = IrregularTagListModel(width: width, height: height)
                array.append(model)
            }
            dataSource.append(array)
        }
        
        collectionView.reloadData()
    }
    
    @objc private func directionAction() {
        if direction == .left {
            direction = .right
        } else {
            direction = .left
        }
        collectionView.reloadData()
    }
    
    @objc private func alignmentAction() {
        if alignment == .top {
            alignment = .center
        } else if alignment == .center {
            alignment = .bottom
        } else if alignment == .bottom {
            alignment = .top
        }
        collectionView.reloadData()
    }
    
    @objc private func scrollDirectionAction() {
        if scrollDirection == .vertical {
            layout.scrollDirection = .horizontal
        } else if scrollDirection == .horizontal {
            layout.scrollDirection = .vertical
        }
        scrollDirection = layout.scrollDirection
        
        collectionView.reloadData()
    }
    
    private func updateUI() {
        if scrollDirection == .vertical {
            if direction == .left {
                directionButton.setTitle("标签排列方向\n左", for: .normal)
            } else if direction == .right {
                directionButton.setTitle("标签排列方向\n右", for: .normal)
            }
            scrollDirectionButton.setTitle("滑动方向\n垂直", for: .normal)
        } else if scrollDirection == .horizontal {
            if direction == .left {
                directionButton.setTitle("标签排列方向\n上", for: .normal)
            } else if direction == .right {
                directionButton.setTitle("标签排列方向\n下", for: .normal)
            }
            scrollDirectionButton.setTitle("滑动方向\n水平", for: .normal)
        }
        
        
        if scrollDirection == .vertical {
            if alignment == .top {
                alignmentButton.setTitle("对齐方向\n顶部对齐", for: .normal)
            } else if alignment == .center {
                alignmentButton.setTitle("对齐方向\n居中对齐", for: .normal)
            } else if alignment == .bottom {
                alignmentButton.setTitle("对齐方向\n底部对齐", for: .normal)
            }
        } else if scrollDirection == .horizontal {
            if alignment == .top {
                alignmentButton.setTitle("对齐方向\n向左对齐", for: .normal)
            } else if alignment == .center {
                alignmentButton.setTitle("对齐方向\n居中对齐", for: .normal)
            } else if alignment == .bottom {
                alignmentButton.setTitle("对齐方向\n向右对齐", for: .normal)
            }
        }
    }
}

extension IrregularTagListViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(IrregularTagListCell.classForCoder()), for: indexPath) as? IrregularTagListCell else {
            return UICollectionViewCell()
        }
        let model = dataSource[indexPath.section][indexPath.item]
        cell.bind(to: model)
        cell.label.text = "\(indexPath.section) - \(indexPath.item)\n点我"
        
//        cell.clickClosure = { [weak self] in
//            guard let self = self else { return }
//            self.collectionView.performBatchUpdates { [weak self] in
//                guard let self = self else { return }
//                //self.collectionView.reloadItems(at: [indexPath])
//                if self.dataSource[indexPath.section].count > 1 {
//                    self.dataSource[indexPath.section].remove(at: indexPath.item)
//                    self.collectionView.deleteItems(at: [indexPath])
//                } else {
//                    self.dataSource[indexPath.section].removeAll()
//                    self.collectionView.deleteSections(IndexSet(integer: indexPath.section))
//                }
//            }
//        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(IrregularTagListHeaderView.classForCoder()), for: indexPath) as? IrregularTagListHeaderView else {
                return UICollectionReusableView()
            }
            return headerView
        } else if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(IrregularTagListFooterView.classForCoder()), for: indexPath) as? IrregularTagListFooterView else {
                return UICollectionReusableView()
            }
            return footerView
        }
        return UICollectionReusableView()
    }
}

extension IrregularTagListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView.performBatchUpdates { [weak self] in
            guard let self = self else { return }
            //self.collectionView.reloadItems(at: [indexPath])
            if self.dataSource[indexPath.section].count > 1 {
                self.dataSource[indexPath.section].remove(at: indexPath.item)
                self.collectionView.deleteItems(at: [indexPath])
            } else {
                self.dataSource.remove(at: indexPath.section)
                self.collectionView.deleteSections(IndexSet(integer: indexPath.section))
            }
        }
    }
}

extension IrregularTagListViewController: SwiftyCollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, sectionInsetContainHeader section: Int) -> Bool {
        return false
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, sectionInsetContainFooter section: Int) -> Bool {
        return false
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, sectionType section: Int) -> SwiftyCollectionViewSectionType {
        return .row(direction: direction, alignment: alignment)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, itemSizeModeAt indexPath: IndexPath) -> SwiftyCollectionViewLayoutSizeMode {
        let model = dataSource[indexPath.section][indexPath.row]
        return .init(width: .static(length: model.width), height: .static(length: model.height))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, visibilityModeForHeaderInSection section: Int) -> SwiftyCollectionViewLayoutSupplementaryVisibilityMode {
        // 当scrollDirection = .horizontal，高度无效
        // 当scrollDirection = .vertical，宽度无效
        return .visible(sizeMode: .init(width: .static(length: 80), height: .static(length: 80)))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, visibilityModeForFooterInSection section: Int) -> SwiftyCollectionViewLayoutSupplementaryVisibilityMode {
        // 当scrollDirection = .horizontal，高度无效
        // 当scrollDirection = .vertical，宽度无效
        return .visible(sizeMode: .init(width: .static(length: 80), height: .static(length: 80)))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, lineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, interitemSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, visibilityModeForDecorationInSection section: Int) -> SwiftyCollectionViewLayoutDecorationVisibilityMode {
        let extraAttributes = DecorationExtraAttributes()
        extraAttributes.cornerRadius = 10.0
        extraAttributes.backgroundColor = .purple
        return .visible(extraAttributes: extraAttributes)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: SwiftyCollectionViewFlowLayout, decorationExtraInset section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
