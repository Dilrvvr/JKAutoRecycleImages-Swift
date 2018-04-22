//
//  JKRecycleView.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

/** 图片 */
let JKRecycleImageUrlKey = "JKRecycleImageUrlKey"

/** 标题 */
let JKRecycleTitleKey = "JKRecycleTitleKey"

/** 其他数据 */
let JKRecycleOtherDictKey = "JKRecycleOtherDictKey"

// MARK: - 代理方法

@objc
protocol JKRecycleViewDelegate: NSObjectProtocol {
    
    /** 点击了轮播图 */
    @objc optional func recycleView(_ recycleView: JKRecycleView, didClickImageWith dict: [String : AnyObject])
}


class JKRecycleView: UIView {
    
    //MARK: - 公共属性
    
    /** 自动滚动的时间间隔（单位为s）默认3s 不可小于1s */
    public var autoRecycleInterval: TimeInterval = 3 {
        
        didSet{
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 是否自动循环 默认true */
    public var isAutoRecycle: Bool = true{
        
        didSet{
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 是否有缩放动画 默认没有 */
    public var isScaleAnimated = false
    
    /** 代理 */
    public weak var delegate: JKRecycleViewDelegate?
    
    /** 监听图片点击的block */
    public var imageClickBlock: ((_ dict: [String : AnyObject]) -> ())?
    
    /** contentView */
    private(set) lazy var contentView: UIView = {
        
        let contentView = UIView(frame: self.bounds)
        self.insertSubview(contentView, at: 0)
        
        return contentView
    }()
    
    /** contentView */
    private(set) lazy var flowlayout: UICollectionViewFlowLayout = {
        
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        flowlayout.minimumLineSpacing = 0
        flowlayout.minimumInteritemSpacing = 0
        
        return flowlayout
    }()
    
    /** pageControl */
    private(set) lazy var pageControl: UIPageControl = {
        
        let pageControl = UIPageControl(frame: CGRect(x: 0, y: self.bounds.size.height - 20, width: self.bounds.size.width, height: 20))
        pageControl.isUserInteractionEnabled = false
        //        pageControl.pageIndicatorTintColor = UIColor.lightGray
        //        pageControl.currentPageIndicatorTintColor = UIColor.white
        self.contentView.addSubview(pageControl)
        
        return pageControl
    }()
    
    
    //MARK: - 公共函数
    
    /** 构造函数 */
    public class func recycleViewWithFrame(frame: CGRect) -> JKRecycleView {
        
        let recycleView = JKRecycleView(frame: frame)
        
        return recycleView
    }
    
    /**
     * 设置数据
     * 数组中每个元素应是NSDictionary类型
     * NSDictionary必须有一个图片urlkey JKRecycleImageUrlKey
     * JKRecycleTitleKey和JKRecycleOtherDictKey可有可无
     */
    public func setDataSource(dataSource: [[String : AnyObject]]?) {
        
        guard let _ = dataSource else { return }
        
        pagesCount = dataSource!.count
        pageControl.numberOfPages = pagesCount
        
        for dict in dataSource! {
            
            dataSourceArr.append(dict)
        }
        
        if (pagesCount <= 1) {
            
            collectionView.isScrollEnabled = false
            
            collectionView.reloadData()
            
            return
        }
        
        dataSourceArr.append(dataSource!.first!)
        dataSourceArr.insert(dataSource!.last!, at: 0)
        
        collectionView.performBatchUpdates({
            
            self.collectionView.reloadSections(IndexSet.init(integer: 0))
            
        }) { (_) in
            
            self.collectionView.setContentOffset(CGPoint(x: self.collectionView.bounds.size.width, y: 0), animated: false)
            
            self.addTimer()
        }
    }
    
    /** 添加定时器 */
    public func addTimer() {
        
        if !isAutoRecycle ||
            pagesCount <= 1 ||
            timer != nil ||
            autoRecycleInterval < 1 {
            
            return
        }
        
        weak var weakSelf = self
        
        if #available(iOS 10.0, *) {
            
            timer = Timer.scheduledTimer(withTimeInterval: autoRecycleInterval, repeats: true, block: { (_) in
                
                weakSelf?.startAutoRecycle()
            })
            
        } else {
            
            timer = Timer.scheduledTimer(timeInterval: autoRecycleInterval, target: self, selector: #selector(startAutoRecycle), userInfo: nil, repeats: true)
        }
    }
    
    /** 移除定时器 */
    public func removeTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    //MARK: - 私有属性
    
    /** scrollView */
    private lazy var collectionView: UICollectionView = {
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.flowlayout)
        collectionView.backgroundColor = nil
        collectionView.scrollsToTop = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.contentView.insertSubview(collectionView, at: 0)
        
        collectionView.register(JKRecycleCell.self, forCellWithReuseIdentifier: "JKRecycleCell")
        
        return collectionView
    }()
    
    /** 定时器 */
    private var timer: Timer?
    
    /** 数据源 */
    private lazy var dataSourceArr = [[String : AnyObject]]()
    
    /** 当前的索引 */
    private var currentIndex: Int = 0
    
    /** 图片页数 */
    private var pagesCount: Int = 0
    
    // MARK: - 循环滚动的方法
    
    @objc private func startAutoRecycle() {
        
        if timer == nil {
            return
        }
        
        let newOffset = CGPoint(x: collectionView.contentOffset.x + collectionView.bounds.size.width, y: 0)
        collectionView.setContentOffset(newOffset, animated: true)
    }
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialization()
    }
    
    private func initialization() {
        
        backgroundColor = UIColor.lightGray
        
        autoRecycleInterval = 3
        
        let _ = collectionView
        let _ = pageControl
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = self.bounds
        collectionView.frame = self.contentView.bounds
        flowlayout.itemSize = self.bounds.size
        pageControl.frame = CGRect(x: 0, y: self.bounds.size.height - 20, width: self.bounds.size.width, height: 20)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension JKRecycleView: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSourceArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "JKRecycleCell", for: indexPath) as! JKRecycleCell
        
        cell.bindDict(dict: dataSourceArr[indexPath.item])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if let block = imageClickBlock {
            
            block(dataSourceArr[indexPath.item])
        }
        
        if delegate == nil { return }
        
        if delegate!.responds(to: #selector(JKRecycleViewDelegate.recycleView(_:didClickImageWith:))) {
            
            delegate?.recycleView!(self, didClickImageWith: dataSourceArr[indexPath.item])
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

// MARK: - UIScrollViewDelegate

extension JKRecycleView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    // 减速完毕 重新设置scrollView的x偏移
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        adjustContentOffset(scrollView: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        adjustContentOffset(scrollView: scrollView)
    }
    
    private func adjustContentOffset(scrollView: UIScrollView) {
        
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        
        if (page == 0) { // 滚动到左边，自动调整到倒数第二
            
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width * CGFloat(pagesCount), y: 0)
            pageControl.currentPage = pagesCount
            
            if (isScaleAnimated) {
                
                DispatchQueue.main.JKRecycle_afterMilliseconds(time: 10) {
                    
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: self.pagesCount, section: 0))
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        
                        cell?.transform = CGAffineTransform.identity
                    })
                }
            }
            
        }else if (page == pagesCount + 1){ // 滚动到右边，自动调整到第二个
            
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
            pageControl.currentPage = 0
            
            if (isScaleAnimated) {
                
                DispatchQueue.main.JKRecycle_afterMilliseconds(time: 10) {
                
                    let cell = self.collectionView.cellForItem(at: IndexPath(item: 1, section: 0))
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        
                        cell?.transform = CGAffineTransform.identity
                    })
                }
            }
            
        }else{
            
            pageControl.currentPage = page - 1
        }
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

class JKRecycleCell: UICollectionViewCell {
    
    private var dict: [String : AnyObject] = [:]
    
    /** containerView */
    private lazy var containerView: UIView = {
        
        let containerView = UIView()
        self.contentView.insertSubview(containerView, at: 0)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerViewCons1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[containerView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["containerView" : containerView])
        self.contentView.addConstraints(containerViewCons1)
        
        let containerViewCons2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[containerView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["containerView" : containerView])
        self.contentView.addConstraints(containerViewCons2)
        
        return containerView
    }()
    
    /** imageView */
    private lazy var imageView: UIImageView = {
        
        let imageView = UIImageView()
        self.containerView.insertSubview(imageView, at: 0)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageViewCons1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : imageView])
        self.containerView.addConstraints(imageViewCons1)
        
        let imageViewCons2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : imageView])
        self.containerView.addConstraints(imageViewCons2)
        
        return imageView
    }()
    
    /** titleLabel */
    private var _titleLabel: UILabel?
    
    /** titleLabel */
    private lazy var titleLabel: UILabel = {
        
        let titleLabel = UILabel()
        self.containerView.addSubview(titleLabel)
        
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.shadowColor = UIColor.darkGray
        titleLabel.shadowOffset = CGSize(width: 1, height: 0)
        titleLabel.textColor = UIColor.white
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.lineBreakMode = NSLineBreakMode.byCharWrapping
        
        return titleLabel
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if _titleLabel == nil { return }
        
        let labelSize = _titleLabel!.sizeThatFits(CGSize(width: self.contentView.bounds.size.width - 30, height: CGFloat.greatestFiniteMagnitude))
        _titleLabel!.frame = CGRect(x: 15, y: self.contentView.bounds.size.height - 20 - labelSize.height, width: self.contentView.bounds.size.width - 30, height: labelSize.height)
    }
    
    /** 设置数据 */
    public func bindDict(dict: [String : AnyObject]?) {
        
        guard let _ = dict else { return }
        
        self.dict = dict!
        
        imageView.image = UIImage(named: self.dict[JKRecycleImageUrlKey] as! String)
        
        if (self.dict[JKRecycleTitleKey] == nil) {
            
            _titleLabel?.isHidden = true
            
            return
        }
        
        _titleLabel = titleLabel
        
        _titleLabel?.text = self.dict[JKRecycleTitleKey] as? String
        
        _titleLabel?.isHidden = false
    }
}


extension DispatchQueue {
    
    func JKRecycle_afterMilliseconds(time: Int, block: @escaping ()->()) {
        
        let afterTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(time)
        
        self.asyncAfter(deadline: afterTime, execute: block)
    }
}
