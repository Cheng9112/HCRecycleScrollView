//
//  HCRecycleScrollView.swift
//  HCRecycleScrollView
//
//  Created by laihuaiOS on 2021/4/27.
//

import UIKit

public enum HCCycleScrollViewPageContolAliment {
    case HCCycleScrollViewPageContolAlimentRight
    case HCCycleScrollViewPageContolAlimentCenter
}

public enum HCCycleScrollViewPageContolStyle {
    /// 系统自带经典样式
    case HCCycleScrollViewPageContolStyleClassic
    /// 动画效果pagecontrol
    case HCCycleScrollViewPageContolStyleAnimated
    /// 不显示pagecontrol
    case HCCycleScrollViewPageContolStyleNone
}

@objc public protocol HCRecycleScrollViewDelegate: NSObjectProtocol {
    
    /// 点击图片回调
    @objc optional func cycleScrollView(cycleScrollView: HCRecycleScrollView, didSelectItemAtIndex index: Int)
    /// 图片滚动回调
    @objc optional func cycleScrollView(cycleScrollView: HCRecycleScrollView, didScrollToIndex index: Int)
    
    /// 自定义cell样式，返回自定义Cell的类名
    @objc optional func customCollectionViewCellClassForCycleScrollView(cycleScrollView: HCRecycleScrollView) -> String
    /// 自定义cell样式，填充自定义Cell的数据以及其他设置
    @objc optional func setupCustomCell(cell: UICollectionViewCell, forIndex index: Int, cycleScrollView: HCRecycleScrollView)
}

public class HCRecycleScrollView: UIView {

    /// 自定义样式属性
    /** 轮播图片的ContentMode，默认为 UIViewContentModeScaleToFill */
    public var bannerImageViewContentMode: ContentMode = .scaleToFill
    
    /** 占位图，用于网络未加载到图片时 */
    public var placeholderImage: UIImage?

    /** 是否显示分页控件 */
    public var showPageControl: Bool = false

    /** 是否在只有一张图时隐藏pagecontrol，默认为YES */
    public var hidesForSinglePage: Bool = true

    /** 只展示文字轮播 */
    public var onlyDisplayText: Bool = false

    /** pagecontrol 样式，默认为动画样式 */
    public var pageControlStyle: HCCycleScrollViewPageContolStyle = .HCCycleScrollViewPageContolStyleAnimated

    /** 分页控件位置 */
    public var pageControlAliment: HCCycleScrollViewPageContolAliment = .HCCycleScrollViewPageContolAlimentCenter

    /** 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量 */
    public var pageControlBottomOffset: CGFloat = 0

    /** 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量 */
    public var pageControlRightOffset: CGFloat = 0

    /** 分页控件小圆标大小 */
    public var pageControlDotSize: CGSize = CGSize(width: 10, height: 10)

    /** 当前分页控件小圆标颜色 */
    public var currentPageDotColor: UIColor = .black

    /** 其他分页控件小圆标颜色 */
    public var pageDotColor: UIColor = .white

    /** 当前分页控件小圆标图片 */
    public var currentPageDotImage: UIImage?

    /** 其他分页控件小圆标图片 */
    public var pageDotImage: UIImage?

    /** 轮播文字label字体颜色 */
    public var titleLabelTextColor: UIColor = .gray

    /** 轮播文字label字体大小 */
    public var titleLabelTextFont: UIFont = UIFont.systemFont(ofSize: 14)

    /** 轮播文字label背景颜色 */
    public var titleLabelBackgroundColor: UIColor = .white

    /** 轮播文字label高度 */
    public var titleLabelHeight: CGFloat = 0

    /** 轮播文字label对齐方式 */
    public var titleLabelTextAlignment: NSTextAlignment = .center
    
    /// 数据属性
    /// 网络图片数组
    public var imageURLStringsGroup: [String]?
    /// 文字数组
    public var titlesGroup: [String]?
    /// 本地图片数组
    public var localizationImagesGroup: [UIImage]?
    
    private var imagePathsGroup: [String]?
    private var totalItemCount: Int = 0
    private weak var timer: Timer?
    private weak var pageControl: UIControl?
    
    /// 初始化轮播图
    /// - Parameters:
    ///   - frame: frame
    ///   - delegate: 代理
    ///   - placeholderImage: 占位图
    public convenience init(frame: CGRect, delegate: HCRecycleScrollViewDelegate?, placeholderImage: UIImage) {
        
        self.init(frame: frame)
        
    }
    
    /// 初始化本地图片轮播图
    /// - Parameters:
    ///   - frame: frame
    ///   - delegate: 代理
    ///   - imageArray: 本地图片数组
    ///   - infiniteLoop: 是否无限循环
    public convenience init(frame: CGRect, delegate: HCRecycleScrollViewDelegate?, imageArray: [UIImage], _ infiniteLoop: Bool = false) {
        
        self.init(frame: frame)
        
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(self.collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(HCCollectionViewCell.self, forCellWithReuseIdentifier: "HCCollectionViewCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollsToTop = false
        return collectionView
    }()
    
}
// MARK: - Public
extension HCRecycleScrollView {
    
}
// MARK: - Private
extension HCRecycleScrollView {
    
    
}
// MARK: -
extension HCRecycleScrollView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    }
    
    
}
