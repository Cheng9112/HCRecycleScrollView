//
//  HCCollectionViewCell.swift
//  HCRecycleScrollView
//
//  Created by laihuaiOS on 2021/4/27.
//

import UIKit
import CHCUIKit

class HCCollectionViewCell: UICollectionViewCell {
    
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    public var title: String? {
        didSet {
            if let titleStr = title {
                titleLable.text = "  \(titleStr)"
                if titleLable.isHidden {
                    titleLable.isHidden = false
                }
            }
        }
    }
    public var titleLabelTextColor: UIColor? {
        didSet {
            if let color = titleLabelTextColor {
                titleLable.textColor = color
            }
        }
    }
    
    public var titleLabelBackgroundColor: UIColor? {
        didSet {
            if let color = titleLabelBackgroundColor {
                titleLable.backgroundColor = color
            }
        }
    }
    public var titleLabelTextAlignment: NSTextAlignment? {
        didSet {
            if let textAlignment = titleLabelTextAlignment {
                titleLable.textAlignment = textAlignment
            }
        }
    }
    public var titleLabelTextFont: UIFont? {
        didSet {
            if let font = titleLabelTextFont {
                titleLable.font = font
            }
        }
    }
    public var hasConfigured: Bool = false
    /// 文字高度
    public var titleLabelHeight: CGFloat = 0
    /// 只展示文字轮播
    public var onlyDisplayText: Bool = false
    
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(self.imageView)
        contentView.addSubview(self.titleLable)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if onlyDisplayText {
            titleLable.frame = bounds
        } else {
            imageView.frame = bounds
            titleLable.frame = CGRect(x: 0, y: height - titleLabelHeight, width: width, height: titleLabelHeight)

        }
    }
}

