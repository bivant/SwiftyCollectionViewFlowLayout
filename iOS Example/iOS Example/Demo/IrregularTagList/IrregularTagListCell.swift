//
//  IrregularTagListCell.swift
//  iOS Example
//
//  Created by dfsx6 on 2023/2/2.
//

import UIKit

public final class IrregularTagListCell: UICollectionViewCell {
    public private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.cornerRadius = 8.0
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor(red: 255.0/255.0, green: 105.0/255.0, blue: 193.0/255.0, alpha: 1)
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}