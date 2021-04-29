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

    //////////////////////  滚动控制API //////////////////////

    /** 自动滚动间隔时间,默认2s */
    public var autoScrollTimeInterval: CGFloat = 2.0
    
    /** 是否无限循环,默认true */
    public var infiniteLoop: Bool = true

    /** 是否自动滚动,默认Yes */
    public var autoScroll: Bool = true

    /** 图片滚动方向，默认为水平滚动 */
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal

    public weak var delegate: HCRecycleScrollViewDelegate?

    /** block方式监听点击 */
    public var clickItemOperationBlock: ((Int) -> ())?

    /** block方式监听滚动 */
    public var itemDidScrollOperationBlock: (() -> Void)?
    
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
    public var pageControlStyle: HCCycleScrollViewPageContolStyle = .HCCycleScrollViewPageContolStyleClassic

    /** 分页控件位置 */
    public var pageControlAliment: HCCycleScrollViewPageContolAliment = .HCCycleScrollViewPageContolAlimentCenter

    /** 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量 */
    public var pageControlBottomOffset: CGFloat = 0

    /** 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量 */
    public var pageControlRightOffset: CGFloat = 0

    /** 分页控件小圆标大小 */
    public var pageControlDotSize: CGSize = CGSize(width: 10, height: 10)

    /** 当前分页控件小圆标颜色 */
    public var currentPageDotColor: UIColor = .white

    /** 其他分页控件小圆标颜色 */
    public var pageDotColor: UIColor = .lightGray

    /** 当前分页控件小圆标图片 */
    public var currentPageDotImage: UIImage?

    /** 其他分页控件小圆标图片 */
    public var pageDotImage: UIImage?

    /** 轮播文字label字体颜色 */
    public var titleLabelTextColor: UIColor = .white

    /** 轮播文字label字体大小 */
    public var titleLabelTextFont: UIFont = UIFont.systemFont(ofSize: 14)

    /** 轮播文字label背景颜色 */
    public var titleLabelBackgroundColor: UIColor = UIColor.init(white: 0, alpha: 0.5)

    /** 轮播文字label高度 */
    public var titleLabelHeight: CGFloat = 30

    /** 轮播文字label对齐方式 */
    public var titleLabelTextAlignment: NSTextAlignment = .left
    
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
        self.placeholderImage = placeholderImage
        self.delegate = delegate
    }
    
    /// 初始化本地图片轮播图
    /// - Parameters:
    ///   - frame: frame
    ///   - delegate: 代理
    ///   - imageArray: 本地图片数组
    ///   - infiniteLoop: 是否无限循环
    public convenience init(frame: CGRect, delegate: HCRecycleScrollViewDelegate?, imageArray: [UIImage], _ infiniteLoop: Bool = false) {
        
        self.init(frame: frame)
        self.localizationImagesGroup = imageArray
        self.delegate = delegate
        self.infiniteLoop = infiniteLoop
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightGray
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
public extension HCRecycleScrollView {
    
    /** 可以调用此方法手动控制滚动到哪一个index */
    func makeScrollViewScrollToIndex(index: Int) {
        
    }

    /** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
    func adjustWhenControllerViewWillAppera() {
        
    }

}
// MARK: - Private
private extension HCRecycleScrollView {
    
    func pageControlIndexWithCurrentCellIndex(index: Int) -> Int {
        return index % (imagePathsGroup?.count ?? 1)
    }
    
    /// 初始化定时器
    func setupTimer() {
        
        invalidateTimer()
        timer = Timer.scheduledTimer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(), userInfo: nil, repeats: true)
        if let temp = timer {
            RunLoop.main.add(temp, forMode: .common)
        }
    }
    /// 释放定时器
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    /// 自动滚动
    func automaticScroll() {
    
        guard totalItemCount > 0 else {
            return
        }
        let currentIndex = currentIndex()
        scrollToIndex(currentIndex + 1)
    }
    /// 滚动到对应的下标
    func scrollToIndex(targetIndex: Int) {
        
    }
    ///
    func currentIndex() -> Int {
        if (_mainView.sd_width == 0 || _mainView.sd_height == 0) {
            return 0;
        }
        
        int index = 0;
        if (_flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            index = (_mainView.contentOffset.x + _flowLayout.itemSize.width * 0.5) / _flowLayout.itemSize.width;
        } else {
            index = (_mainView.contentOffset.y + _flowLayout.itemSize.height * 0.5) / _flowLayout.itemSize.height;
        }
        
        return MAX(0, index);
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension HCRecycleScrollView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        delegate?.cycleScrollView?(cycleScrollView: self, didSelectItemAtIndex: pageControlIndexWithCurrentCellIndex(index: indexPath.item))

        if let clickItemOperationBlock = clickItemOperationBlock {
            clickItemOperationBlock(pageControlIndexWithCurrentCellIndex(index: indexPath.item))
        }
    }
}
// MARK: - UIScrollViewDelegate
extension HCRecycleScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
        guard let array = imagePathsGroup, array.count > 0 else {
            return
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if autoScroll {
            
        }
    }
}
