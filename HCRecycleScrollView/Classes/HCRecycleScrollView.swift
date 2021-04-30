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
    @objc optional func setupCustomCell(cell: UICollectionViewCell, forIndex index: Int, cycleScrollView: HCRecycleScrollView) -> Bool
}

public class HCRecycleScrollView: UIView {

    //////////////////////  滚动控制API //////////////////////

    /** 自动滚动间隔时间,默认2s */
    public var autoScrollTimeInterval: CGFloat = 2.0 {
        
        didSet {
            self.autoScroll = autoScroll ? true : false
        }
    }
    
    /** 是否无限循环,默认true */
    public var infiniteLoop: Bool = true

    /** 是否自动滚动,默认Yes */
    public var autoScroll: Bool = true {
        didSet {
            invalidateTimer()
            
            if autoScroll {
                setupTimer()
            }
        }
    }

    /** 图片滚动方向，默认为水平滚动 */
    public var scrollDirection: UICollectionView.ScrollDirection? {
        
        didSet {
            flowLayout.scrollDirection = scrollDirection ?? .horizontal
        }
    }

    public weak var delegate: HCRecycleScrollViewDelegate? {
        didSet {
            if let cellStr = delegate?.customCollectionViewCellClassForCycleScrollView?(cycleScrollView: self), cellStr.count > 0 {
                let cellClass: AnyClass? = NSClassFromString(cellStr)
                collectionView.register(cellClass, forCellWithReuseIdentifier: "HCCollectionViewCell")
            }
        }
    }

    /** block方式监听点击 */
    public var clickItemOperationBlock: ((Int) -> Void)?

    /** block方式监听滚动 */
    public var itemDidScrollOperationBlock: ((Int) -> Void)?
    
    /// 自定义样式属性
    /** 轮播图片的ContentMode，默认为 UIViewContentModeScaleToFill */
    public var bannerImageViewContentMode: ContentMode = .scaleToFill
    
    /** 占位图，用于网络未加载到图片时 */
    public var placeholderImage: UIImage? {
        didSet {
            backgroundImageView.image = placeholderImage
        }
    }

    /** 是否显示分页控件 */
    public var showPageControl: Bool = false {
        didSet {
            pageControl.isHidden = !showPageControl
        }
    }

    /** 是否在只有一张图时隐藏pagecontrol，默认为YES */
    public var hidesForSinglePage: Bool = true

    /** 只展示文字轮播 */
    public var onlyDisplayText: Bool = false

    /** pagecontrol 样式，默认为动画样式 */
    public var pageControlStyle: HCCycleScrollViewPageContolStyle? {
        
        didSet {
            self.autoScroll = autoScroll ? true : false
        }
    }

    /** 分页控件位置 */
    public var pageControlAliment: HCCycleScrollViewPageContolAliment = .HCCycleScrollViewPageContolAlimentCenter

    /** 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量 */
    public var pageControlBottomOffset: CGFloat = 0

    /** 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量 */
    public var pageControlRightOffset: CGFloat = 0

    /** 分页控件小圆标大小 */
    public var pageControlDotSize: CGSize? {
        didSet {
            setupPageControl()
        }
    }

    /** 当前分页控件小圆标颜色 */
    public var currentPageDotColor: UIColor? {
        didSet {
            pageControl.currentPageIndicatorTintColor = currentPageDotColor
        }
    }

    /** 其他分页控件小圆标颜色 */
    public var pageDotColor: UIColor? {
        didSet {
            pageControl.pageIndicatorTintColor = pageDotColor
        }
    }

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
    /// 文字数组
    public var titlesGroup: [String]?
    
    private var imagePathsGroup: [String]? {
        
        didSet {
            invalidateTimer()
            if let imagePathsGroup = self.imagePathsGroup {
                
                totalItemCount = infiniteLoop ? imagePathsGroup.count * 100 : imagePathsGroup.count
                if imagePathsGroup.count > 1 {
                    collectionView.isScrollEnabled = true
                    autoScroll = autoScroll ? true : false
                } else {
                    collectionView.isScrollEnabled = false
                    invalidateTimer()
                }
                setupPageControl()
                collectionView.reloadData()
            }
            
        }
    }
    
    private var totalItemCount: Int = 0
    private weak var timer: Timer?
    private var pageControl = UIPageControl()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        insertSubview(imageView, belowSubview: collectionView)
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
    public convenience init(frame: CGRect, delegate: HCRecycleScrollViewDelegate?, imageArray: [String], _ infiniteLoop: Bool = false) {
        
        self.init(frame: frame)
        self.imagePathsGroup = imageArray
        self.delegate = delegate
        self.infiniteLoop = infiniteLoop
    }

    override init(frame: CGRect) {
        
        super.init(frame: frame)
        backgroundColor = .lightGray
        addSubview(self.collectionView)
        setupDefalutValue()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }
    
    public override func layoutSubviews() {
        
        super.layoutSubviews()
        
        flowLayout.itemSize = frame.size
        collectionView.frame = bounds
        
        if collectionView.contentOffset.x == 0 && totalItemCount > 0 {
            var targetIndex = 0
            if infiniteLoop {
                targetIndex = Int(Double(totalItemCount) * 0.5)
            }
            collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
        
        var size = CGSize.zero
        if let imagePathGroup = self.imagePathsGroup {
            size = CGSize(width: CGFloat(imagePathGroup.count) * (pageControlDotSize?.width ?? 1) * 1.5, height: (pageControlDotSize?.height ?? 0))
            // ios14 需要按照系统规则适配pageControl size
            size.width = pageControl.size(forNumberOfPages: imagePathGroup.count).width
        }
        
        var x = (self.frame.width - size.width) * 0.5
        if self.pageControlAliment == .HCCycleScrollViewPageContolAlimentRight {
            x = collectionView.width - size.width - 10
        }
        let y = collectionView.height - size.height - 10;
                
        var pageControlFrame = CGRect(x: x, y: y, width: size.width, height: size.height)
        pageControlFrame.origin.y = pageControlFrame.origin.y - pageControlBottomOffset
        pageControlFrame.origin.x = pageControlFrame.origin.x - pageControlRightOffset
        self.pageControl.frame = pageControlFrame;
        self.pageControl.isHidden = !showPageControl
        
        self.backgroundImageView.frame = self.bounds
    }
        
}
// MARK: - Public
public extension HCRecycleScrollView {
    /// 禁用滚动手势
    func disableScrollGesture() {
        collectionView.canCancelContentTouches = false
        for gesture in collectionView.gestureRecognizers ?? [UIGestureRecognizer]() {
            if let ges = gesture as? UIPanGestureRecognizer {
                collectionView.removeGestureRecognizer(ges)
            }
        }
    }
    
    /** 可以调用此方法手动控制滚动到哪一个index */
    func makeScrollViewScrollToIndex(index: Int) {
        if (self.autoScroll) {
            invalidateTimer()
        }
        if 0 == totalItemCount {
            return
        }
        
        scrollToIndex(targetIndex: (Int)(Double(totalItemCount) * 0.5 + Double(index)))
        
        if (self.autoScroll) {
            setupTimer()
        }
    }

    /** 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法 */
    func adjustWhenControllerViewWillAppera() {
        
        let targetIndex = currentIndex()
        if (targetIndex < totalItemCount) {
            collectionView.scrollToItem(at: NSIndexPath(item: targetIndex, section: 0) as IndexPath, at: .centeredHorizontally, animated: false)
        }
    }

}
// MARK: - Private
private extension HCRecycleScrollView {
    
    /// 初始化默认值
    func setupDefalutValue() {
        currentPageDotColor = .white
        pageControlDotSize = CGSize(width: 10, height: 10)
        pageDotColor = .lightGray
        scrollDirection = .horizontal
        pageControlStyle = .HCCycleScrollViewPageContolStyleClassic
    }
    
    func pageControlIndexWithCurrentCellIndex(index: Int) -> Int {
        return index % (imagePathsGroup?.count ?? 1)
    }
    
    /// 初始化定时器
    func setupTimer() {
        
        invalidateTimer()
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(autoScrollTimeInterval), target: self, selector: #selector(automaticScroll), userInfo: nil, repeats: true)
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
    @objc func automaticScroll() {
    
        guard totalItemCount > 0 else {
            return
        }
        let index = currentIndex()
        scrollToIndex(targetIndex: index + 1)
    }
    /// 滚动到对应的下标
    func scrollToIndex(targetIndex: Int) {
        
        if (targetIndex >= totalItemCount) {
            if (self.infiniteLoop) {
                let index = Double(totalItemCount) * 0.5
                collectionView.scrollToItem(at: NSIndexPath(item: Int(index), section: 0) as IndexPath, at: .centeredHorizontally, animated: false)
            }
            return;
        }
        collectionView.scrollToItem(at: NSIndexPath(item: targetIndex, section: 0) as IndexPath, at: .centeredHorizontally, animated: true)
    }
    /// 当前下标
    func currentIndex() -> Int {
        if (collectionView.width == 0 || collectionView.height == 0) {
            return 0
        }
        
        var index: CGFloat = 0
        if (flowLayout.scrollDirection == .horizontal) {
            index = (collectionView.contentOffset.x + flowLayout.itemSize.width * 0.5) / flowLayout.itemSize.width
        } else {
            index = (collectionView.contentOffset.y + flowLayout.itemSize.height * 0.5) / flowLayout.itemSize.height
        }
        return max(0, Int(index))
    }
    /// 设置PageControl
    func setupPageControl() {
        
        pageControl.removeFromSuperview() // 重新加载数据时调整
        
        guard let imagePathsGroup = self.imagePathsGroup, imagePathsGroup.count > 0 && !onlyDisplayText else {
            return
        }
        
        if imagePathsGroup.count == 1 && self.hidesForSinglePage { return }
        
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: currentIndex())
        
        switch (pageControlStyle) {

        case .HCCycleScrollViewPageContolStyleClassic:
            pageControl = UIPageControl()
            pageControl.numberOfPages = imagePathsGroup.count
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor
            pageControl.pageIndicatorTintColor = self.pageDotColor
            pageControl.isUserInteractionEnabled = false
            pageControl.currentPage = indexOnPageControl
            addSubview(pageControl)
                        
        default: break
        }
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension HCRecycleScrollView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalItemCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HCCollectionViewCell", for: indexPath)
        let itemIndex = pageControlIndexWithCurrentCellIndex(index: indexPath.item)
        
        if ((delegate?.setupCustomCell?(cell: cell, forIndex: itemIndex, cycleScrollView: self)) != nil) {
            return cell
        }
        
        guard let hcCell = cell as? HCCollectionViewCell else {
            return cell
        }
        
        let imagePath = imagePathsGroup?[itemIndex]
        
        if onlyDisplayText , let imageStr = imagePath, imageStr.count > 0 {
            
            if imageStr.hasPrefix("http") {
//                [cell.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:self.placeholderImage];
            } else {
                var image = UIImage(named: imageStr)
                if image == nil {
                    image = UIImage(contentsOfFile: imageStr)
                }
                hcCell.imageView.image = image
            }
        }
        
        if let titlesGroup = self.titlesGroup, titlesGroup.count > 0 && itemIndex < titlesGroup.count {
            hcCell.title = titlesGroup[itemIndex];
        }
        
        if hcCell.hasConfigured == false {
            hcCell.titleLabelBackgroundColor = self.titleLabelBackgroundColor;
            hcCell.titleLabelHeight = self.titleLabelHeight;
            hcCell.titleLabelTextAlignment = self.titleLabelTextAlignment;
            hcCell.titleLabelTextColor = self.titleLabelTextColor;
            hcCell.titleLabelTextFont = self.titleLabelTextFont;
            hcCell.hasConfigured = true
            hcCell.imageView.contentMode = self.bannerImageViewContentMode;
            hcCell.clipsToBounds = true
            hcCell.onlyDisplayText = self.onlyDisplayText;
        }
        
        return cell
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
        let itemIndex = currentIndex()
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: itemIndex)
        pageControl.currentPage = indexOnPageControl
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if autoScroll {
            setupTimer()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(collectionView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        if imagePathsGroup?.count == 0 { return }
        
        let itemIndex = currentIndex()
        let indexOnPageControl = pageControlIndexWithCurrentCellIndex(index: itemIndex)
        
        delegate?.cycleScrollView?(cycleScrollView: self, didScrollToIndex: indexOnPageControl)
        
        if let itemDidScrollBlock = itemDidScrollOperationBlock {
            itemDidScrollBlock(indexOnPageControl)
        }
    }

}
