//
//  JKCycleBannerView.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

/** 图片 value对应NSString类型 可传imageName 内部默认[UIImage ImageNamed:] */
public let JKCycleBannerImageUrlKey = "JKCycleBannerImageUrlKey"

/** 占位图片 value对应UIImage类型 */
public let JKCycleBannerPlaceholderImageKey = "JKCycleBannerPlaceholderImageKey"

/** 标题 value对应NSString类型 */
public let JKCycleBannerTitleKey = "JKCycleBannerTitleKey"

/** 其他数据 value对应任意类型 */
public let JKCycleBannerDataKey = "JKCycleBannerDataKey"

// MARK:
// MARK: - 代理方法

@objc
protocol JKCycleBannerViewDelegate: NSObjectProtocol {
    
    /** 自定义加载图片 */
    @objc optional func cycleBannerView(_ cycleBannerView: JKCycleBannerView, loadImageWith imageView: UIImageView, dict: [String : AnyObject])
    
    /** 点击了轮播图 */
    @objc optional func cycleBannerView(_ cycleBannerView: JKCycleBannerView, didClickImageWith dict: [String : AnyObject])
}

@objc
protocol JKCycleBannerCellDelegate: NSObjectProtocol {
    
    /** 自定义加载图片 */
    @objc optional func bannerCell(_ bannerCell: JKCycleBannerCell, loadImageWith imageView: UIImageView, dict: [String : AnyObject]) -> Bool
}

// MARK:
// MARK: - JKCycleBannerView

class JKCycleBannerView: UIView {
    
    // MARK:
    // MARK: - Public Property
    
    /** 是否自动循环 默认true */
    public var isAutoRecycle: Bool = true {
        
        didSet {
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 自动滚动的时间间隔（单位为s）默认3s 不可小于1s */
    public var autoRecycleInterval: TimeInterval = 3.0 {
        
        didSet {
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 是否有缩放动画 */
    public var isScaleAnimated = false
    
    /** 图片内缩的大小 */
    public var contentInset: UIEdgeInsets = UIEdgeInsets.zero
    
    /** 图片的圆角大小 */
    public var cornerRadius: CGFloat = 0.0
    
    /** 代理 */
    public weak var delegate: JKCycleBannerViewDelegate?
    
    /** 监听图片点击的block */
    public var imageClickBlock: ((_ dict: [String : AnyObject]) -> ())?
    
    /** 自定义加载图片 */
    public var loadImageBlock: ((_ imageView: UIImageView, _ dict: [String : AnyObject]) -> Void)?
    
    /** contentView */
    public private(set) lazy var contentView: UIView = {
        
        let contentView = UIView(frame: self.bounds)
        contentView.clipsToBounds = true
        
        return contentView
    }()
    
    /** flowlayout */
    public private(set) lazy var flowlayout: UICollectionViewFlowLayout = {
        
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        flowlayout.minimumLineSpacing = 0.0
        flowlayout.minimumInteritemSpacing = 0.0
        
        return flowlayout
    }()
    
    /** pageControl */
    public private(set) lazy var pageControl: UIPageControl = {
        
        let pageControl = UIPageControl(frame: CGRect(x: 0.0, y: self.bounds.size.height - 20.0, width: self.bounds.size.width, height: 20.0))
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.white
        
        self.contentView.addSubview(pageControl)
        
        return pageControl
    }()
    
    /** 是否让pageControl位于contentInset.bottom高度的中间 */
    public var pageControlInBottomInset: Bool = false
    
    /** 是否手动设置pageControl的frame */
    public var manualPageControlFrame: Bool = false
    
    // MARK:
    // MARK: - Public Methods
    
    /** 构造函数 */
    public class func recycleViewWithFrame(frame: CGRect) -> JKCycleBannerView {
        
        let recycleView = JKCycleBannerView(frame: frame)
        
        // collectionView宽度加2 但是实际图片是正常大小
        recycleView.flowlayout.itemSize = CGSize(width: frame.size.width + 2.0, height: frame.size.height)
        
        return recycleView
    }
    
    /**
     * 设置数据
     * 数组中每个元素应是NSDictionary类型
     * NSDictionary必须有一个图片urlkey JKCycleBannerImageUrlKey
     * JKCycleBannerTitleKey和JKCycleBannerOtherDictKey可有可无
     */
    public func setDataSource(dataSource: [[String : AnyObject]]?) {
        
        guard let _ = dataSource else { return }
        
        pagesCount = dataSource!.count
        pageControl.numberOfPages = pagesCount
        
        dataSourceArr.removeAll()
        
        dataSourceArr += dataSource!
        
        if (pagesCount <= 1) {
            
            collectionView.isScrollEnabled = false
            
            collectionView.reloadData()
            
            return
        }
        
        collectionView.isScrollEnabled = true
        
        dataSourceArr.append(dataSource!.first!)
        dataSourceArr.insert(dataSource!.last!, at: 0)
        
        collectionView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            let indexPath = IndexPath(item: 1, section: 0)
            
            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            
            if (self.isScaleAnimated) {
                
                self.collectionView.layoutIfNeeded()
                
                let cell = self.collectionView.cellForItem(at: indexPath)
                
                cell?.transform = .identity
            }
            
            self.addTimer()
        }
    }
    
    /** 添加定时器 */
    public func addTimer() {
        
        if timer != nil ||
            !isAutoRecycle ||
            pagesCount <= 1 ||
            autoRecycleInterval < 1 ||
            collectionView.isDragging {
            
            return
        }
        
        weak var weakSelf = self
        
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        
        timer?.schedule(deadline: DispatchTime.now() + autoRecycleInterval, repeating: autoRecycleInterval)
        
        timer?.setEventHandler(handler: {
            
            DispatchQueue.main.async {
                
                weakSelf?.startAutoRecycle()
            }
        })
        
        timer?.resume()
    }
    
    /** 移除定时器 */
    public func removeTimer() {
        
        if timer == nil {
            return
        }
        
        timer?.cancel()
        
        timer = nil
    }
    
    // MARK:
    // MARK: - Override
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
        removeTimer()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview == nil {
            
            removeTimer()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = self.bounds
        
        // collectionView宽度加2 但是实际图片是正常大小
        collectionView.frame = CGRect(x: -1.0, y: 0.0, width: contentView.bounds.size.width + 2.0, height: contentView.bounds.size.height)
        
        flowlayout.itemSize = collectionView.bounds.size
        
        if (!manualPageControlFrame) {
            
            if (pageControlInBottomInset) {
                
                pageControl.frame = CGRect(x: 0.0, y: bounds.size.height - contentInset.bottom + (contentInset.bottom - 20.0) * 0.5, width: bounds.size.width, height: 20.0)
                
            } else {
                
                pageControl.frame = CGRect(x: 0.0, y: bounds.size.height - 20.0 - contentInset.bottom, width: bounds.size.width, height: 20.0)
            }
        }
    }
    
    // MARK:
    // MARK: - Private Methods
    
    @objc private func startAutoRecycle() {
        
        if timer == nil ||
            collectionView.isDragging {
            return
        }
        
        let newOffset = CGPoint(x: collectionView.contentOffset.x + collectionView.bounds.size.width, y: 0.0)
        
        collectionView.setContentOffset(newOffset, animated: true)
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /** 初始化自身属性 交给子类重写 super自动调用该方法 */
    internal func initializeProperty() {
        
    }
    
    /** 构造函数初始化时调用 注意调用super */
    internal func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /** 创建UI 交给子类重写 super自动调用该方法 */
    internal func createUI() {
        
        insertSubview(contentView, at: 0)
        contentView.insertSubview(collectionView, at: 0)
    }
    
    /** 布局UI 交给子类重写 super自动调用该方法 */
    internal func layoutUI() {
        
    }
    
    /** 初始化UI数据 交给子类重写 super自动调用该方法 */
    internal func initializeUIData() {
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    /** scrollView */
    private lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowlayout)
        collectionView.backgroundColor = nil
        collectionView.scrollsToTop = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
        collectionView.register(JKCycleBannerCell.self, forCellWithReuseIdentifier: String(describing: JKCycleBannerCell.self))
        
        return collectionView
    }()
    
    /** 定时器 */
    private var timer: DispatchSourceTimer?
    
    /** 数据源 */
    private lazy var dataSourceArr = [[String : AnyObject]]()
    
    /** 图片页数 */
    private var pagesCount: Int = 0
}

// MARK:
// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension JKCycleBannerView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSourceArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: JKCycleBannerCell.self), for: indexPath) as! JKCycleBannerCell
        
        cell.delegate = self
        
        cell.bindDict(dict: dataSourceArr[indexPath.item], contentInset: contentInset, cornerRadius: cornerRadius)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if let block = imageClickBlock {
            
            block(dataSourceArr[indexPath.item])
        }
        
        if delegate == nil { return }
        
        if delegate!.responds(to: #selector(JKCycleBannerViewDelegate.cycleBannerView(_:didClickImageWith:))) {
            
            delegate?.cycleBannerView!(self, didClickImageWith: dataSourceArr[indexPath.item])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if (!isScaleAnimated) { return }
        
        cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if (!isScaleAnimated) { return }
        
        guard let index = collectionView.indexPathsForVisibleItems.last else { return }
        
        let cell1 = collectionView.cellForItem(at: index)
        
        UIView.animate(withDuration: 0.25) {
            
            cell1?.transform = CGAffineTransform.identity
        }
    }
}

// MARK:
// MARK: - UIScrollViewDelegate

extension JKCycleBannerView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (!scrollView.isDragging) {
            return
        }
        
        var contentOffset = scrollView.contentOffset
        
        // 在最左侧
        if (contentOffset.x < scrollView.bounds.size.width) {
            
            contentOffset.x = contentOffset.x + (scrollView.bounds.size.width * (CGFloat(pagesCount) * 1.0))
            
            scrollView.contentOffset = contentOffset
            
            return
        }
        
        let delta = scrollView.contentOffset.x / scrollView.bounds.size.width - (CGFloat((pagesCount + 1)) * 1.0)
        
        // 在最右侧
        if (delta > 0.0) {
            
            contentOffset.x = scrollView.bounds.size.width * (1.0 + delta)
            
            scrollView.contentOffset = contentOffset
        }
    }
    
    // 减速完毕 重新设置scrollView的x偏移
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        adjustContentOffset(scrollView: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        adjustContentOffset(scrollView: scrollView)
    }
    
    private func adjustContentOffset(scrollView: UIScrollView) {
        
        let page = Int((scrollView.contentOffset.x) / scrollView.bounds.size.width)
        
        if (page == 0) { // 滚动到左边，自动调整到倒数第二
            
            //scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width * CGFloat(pagesCount), y: 0)
            
            collectionView.scrollToItem(at: IndexPath(item: dataSourceArr.count - 2, section: 0), at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            
            pageControl.currentPage = pagesCount
            
            if (isScaleAnimated) {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: self.pagesCount, section: 0))
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        
                        cell?.transform = CGAffineTransform.identity
                    })
                }
            }
            
        } else if (page == pagesCount + 1){ // 滚动到右边，自动调整到第二个
            
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0.0)
            
            collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            
            pageControl.currentPage = 0
            
            if (isScaleAnimated) {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: 1, section: 0))
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        
                        cell?.transform = CGAffineTransform.identity
                    })
                }
            }
            
        } else {
            
            pageControl.currentPage = page - 1
        }
        
        addTimer()
    }
    
    // 手指拖动 移除定时器
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        removeTimer()
    }
    
    // 手指松开 添加定时器
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        addTimer()
    }
}

// MARK:
// MARK: - JKCycleBannerCellDelegate

extension JKCycleBannerView: JKCycleBannerCellDelegate {
    
    func bannerCell(_ bannerCell: JKCycleBannerCell, loadImageWith imageView: UIImageView, dict: [String : AnyObject]) -> Bool {
        
        let respondFlag = delegate?.responds(to: #selector(JKCycleBannerViewDelegate.cycleBannerView(_:loadImageWith:dict:)))
        
        if respondFlag == true {
            
            delegate?.cycleBannerView?(self, loadImageWith: imageView, dict: dict)
        }
        
        var blockFlag = false
        
        if loadImageBlock != nil {
            
            blockFlag = true
            
            self.loadImageBlock!(imageView, dict)
        }
        
        return blockFlag || (respondFlag == true)
    }
}

// MARK:
// MARK: - JKCycleBannerCell

class JKCycleBannerCell: UICollectionViewCell {
    
    // MARK:
    // MARK: - Public Property
    
    /** delegate */
    public weak var delegate: JKCycleBannerCellDelegate?
    
    // MARK:
    // MARK: - Public Methods
    
    /** 设置数据 */
    public func bindDict(dict: [String : AnyObject]?, contentInset: UIEdgeInsets, cornerRadius: CGFloat) {
        
        guard let _ = dict else { return }
        
        self.dict = dict!
        
        updateUI(contentInset: contentInset, cornerRadius: cornerRadius)
        
        // MARK:
        // MARK: - 设置图片
        
        // 是否自定义加载图片
        var loadImageFlag = false
        
        if let _ = delegate {
            
            // 代理是否响应方法
            let respondFlag = delegate!.responds(to: #selector(JKCycleBannerCellDelegate.bannerCell(_:loadImageWith:dict:)))
            
            if respondFlag == true {
                
                // 判断是否自定义加载图片
                loadImageFlag = delegate!.bannerCell!(self, loadImageWith: imageView, dict: dict!)
            }
        }
        
        // 没有自定义加载图片
        if !loadImageFlag {
            
            imageView.image = UIImage(named: self.dict[JKCycleBannerImageUrlKey] as! String)
        }
        
        if (self.dict[JKCycleBannerTitleKey] == nil) {
            
            _titleLabel?.isHidden = true
            
            return
        }
        
        _titleLabel = titleLabel
        
        _titleLabel?.text = self.dict[JKCycleBannerTitleKey] as? String
        
        _titleLabel?.isHidden = false
    }
    
    // MARK:
    // MARK: - Override
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialization()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutUI()
    }
    
    // MARK:
    // MARK: - Private Methods
    
    /** 更新UI */
    private func updateUI(contentInset: UIEdgeInsets, cornerRadius: CGFloat) {
        
        if (imageView.layer.cornerRadius != cornerRadius) {
            
            imageView.layer.cornerRadius = cornerRadius
            imageView.layer.masksToBounds = true
        }
        
        if (!UIEdgeInsetsEqualToEdgeInsets(self.contentInset, contentInset)) {
            
            self.contentInset = contentInset
            
            setNeedsLayout()
        }
    }
    
    // MARK:
    // MARK: - Private Selector
    
    
    
    // MARK:
    // MARK: - Custom Delegates
    
    
    
    // MARK:
    // MARK: - Initialization & Build UI
    
    /** 初始化自身属性 交给子类重写 super自动调用该方法 */
    internal func initializeProperty() {
        
    }
    
    /** 构造函数初始化时调用 注意调用super */
    internal func initialization() {
        
        initializeProperty()
        createUI()
        layoutUI()
        initializeUIData()
    }
    
    /** 创建UI 交给子类重写 super自动调用该方法 */
    internal func createUI() {
        
        contentView.insertSubview(containerView, at: 0)
        containerView.insertSubview(imageView, at: 0)
        containerView.addSubview(titleLabel)
    }
    
    /** 布局UI 交给子类重写 super自动调用该方法 */
    internal func layoutUI() {
        
        // collectionView的宽度加了2 这里还原
        containerView.frame = CGRect(x: 1.0, y: 0.0, width: contentView.frame.width - 2.0, height: contentView.frame.height)
        
        imageView.frame = CGRect(x: contentInset.left, y: contentInset.top, width: containerView.frame.width - contentInset.left - contentInset.right, height: containerView.frame.height - contentInset.top - contentInset.bottom)
        
        if _titleLabel == nil {
            return
        }
        
        let labelSize = _titleLabel!.sizeThatFits(CGSize(width: self.contentView.bounds.size.width - 30.0, height: CGFloat.greatestFiniteMagnitude))
        
        _titleLabel!.frame = CGRect(x: (containerView.frame.width - labelSize.width) * 0.5, y: containerView.bounds.size.height - 20.0 - labelSize.height - contentInset.bottom, width: labelSize.width, height: labelSize.height)
    }
    
    /** 初始化UI数据 交给子类重写 super自动调用该方法 */
    internal func initializeUIData() {
        
    }
    
    // MARK:
    // MARK: - Private Property
    
    /** dict */
    private var dict: [String : AnyObject] = [:]
    
    /** 图片内缩的大小 */
    private var contentInset: UIEdgeInsets = UIEdgeInsets.zero
    
    /** containerView */
    private lazy var containerView: UIView = UIView()
    
    /** imageView */
    private lazy var imageView: UIImageView = UIImageView()
    
    /** titleLabel */
    private var _titleLabel: UILabel?
    
    /** titleLabel */
    private lazy var titleLabel: UILabel = {
        
        let titleLabel = UILabel()
        
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        titleLabel.shadowColor = UIColor.darkGray
        titleLabel.shadowOffset = CGSize(width: 1.0, height: 0.0)
        titleLabel.textColor = UIColor.white
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.lineBreakMode = NSLineBreakMode.byCharWrapping
        
        return titleLabel
    }()
}
