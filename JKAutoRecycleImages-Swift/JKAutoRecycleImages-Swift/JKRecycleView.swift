//
//  JKRecycleView.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

public let JKRecycleViewIsIphoneX = UIScreen.instancesRespond(to: #selector(getter: UIScreen.currentMode)) ? UIScreen.main.currentMode?.size.equalTo(CGSize(width: 1125, height: 2436)) : false

// MARK: - 代理方法

@objc
protocol JKRecycleViewDelegate: NSObjectProtocol {
    
    /** 点击了轮播图 */
    @objc optional func recycleView(recycleView: JKRecycleView, didClickImageWithIndex: Int, otherDataDict: [String : AnyObject])
    
}


class JKRecycleView: UIView {
    
    //MARK: - 公共属性
    
    /** 自动滚动的时间间隔（单位为s）默认3s 不可小于1s */
    var autoRecycleInterval: TimeInterval = 3 {
        
        didSet{
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 是否自动循环 默认true */
    var isAutoRecycle: Bool = true{
        
        didSet{
            
            removeTimer()
            
            addTimer()
        }
    }
    
    /** 是否有缩放动画 默认没有 */
    var scaleAnimated = false
    
    /** 代理 */
    weak var delegate: JKRecycleViewDelegate?
    
    /** 监听图片点击的block */
    var imageClickBlock: ((_ index: Int, _ otherDataDict: [String : AnyObject]) -> ())?
    
    /** pageControl */
    private(set) lazy var pageControl: UIPageControl = {
        
        let pageControl = UIPageControl(frame: CGRect(x: 0, y: self.bounds.size.height - 20, width: self.bounds.size.width, height: 20))
        pageControl.isUserInteractionEnabled = false
        //        pageControl.pageIndicatorTintColor = UIColor.lightGray
        //        pageControl.currentPageIndicatorTintColor = UIColor.white
        
        return pageControl
    }()
    
    /** contentView */
    lazy var contentView: UIView = {
        
        let contentView = UIView(frame: self.bounds)
        
        return contentView
    }()
    
    
    //MARK: - 公共函数
    
    /** 构造函数 */
    public class func recycleViewWithFrame(frame: CGRect) -> JKRecycleView {
        
        let recycleView = JKRecycleView(frame: frame)
        
        return recycleView
    }
    
    /** 设置数据 */
    public func setImageData(imageUrls: [String], titles: [String]?, otherDataDicts: [[String : AnyObject]]?) {
        
        if (imageUrls.count <= 0) {
            
            removeTimer()
            
            pagesCount = 0
            scrollView.isScrollEnabled = false
            pageControl.isHidden = true
            tipLabel?.isHidden = false
            
            for imgv in allImageViews {
                
                imgv.removeFromSuperview()
            }
            
            allImageViews.removeAll()
            recycleImageViews.removeAll()
            allTitleLabels.removeAll()
            dataDicts.removeAll()
            
            return
        }
        
        self.tipLabel?.isHidden = true
        
        isDataAdded = false
        
        // 防止重复赋值
        if (self.urls != nil && imageUrls.count == self.urls?.count) {
            
            self.isDataAdded = true
            
            for i in 0 ..< urls!.count {
                
                let str1 = imageUrls[i]
                let str2 = urls![i]
                
                if str1 == str2 { continue }
                
                self.isDataAdded = false
                
                break
            }
        }
        
        // 如果数据已经添加，直接返回
        if (self.isDataAdded) {
            return
        }
        
        removeTimer()
        pagesCount = 0
        currentIndex = 0
        scrollView.isScrollEnabled = false
        
        // 赋值
        urls = nil
        urls = imageUrls
        dataDicts.removeAll()
        //(dataDicts as! NSMutableArray).addObjects(from: otherDataDicts!)
        if let dicts = otherDataDicts {
            
            dataDicts = dicts
        }
        
        // pageControl的页数就是图片的个数
        pagesCount = imageUrls.count
        pageControl.numberOfPages = pagesCount
        
        // 先清空数组
        allImageViews.removeAll()
        allTitleLabels.removeAll()
        
        // 循环创建imageView等控件，添加到数组中
        for i in 0 ..< pagesCount {
            
            // 创建imageView
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height))
            
            // MARK: - Warning - 此处设置图片
            imageView.image = UIImage(named: imageUrls[i])
            //            imageView.jk_setImage(withUrlStr: imageUrls[i])
            
            // 将控件添加到数组
            allImageViews.append(imageView)
            
            if (titles == nil || (titles?.count)! < pagesCount) { continue }
            
            // 创建titleLabel
            let titleLabel = UILabel()
            titleLabel.frame = CGRect(x: 15, y: imageView.bounds.size.height-60-125 + (JKRecycleViewIsIphoneX! ? 10 : 0), width: imageView.bounds.size.width-30, height: 100)
            titleLabel.textAlignment = NSTextAlignment.left
            titleLabel.numberOfLines = 0
            titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
            titleLabel.shadowColor = UIColor.darkGray
            titleLabel.shadowOffset = CGSize(width: 1, height: 0)
            titleLabel.textColor = UIColor.white
            //            titleLabel.backgroundColor = UIColor.blue
            titleLabel.lineBreakMode = NSLineBreakMode.byCharWrapping
            
            
            titleLabel.text = titles?[i]
            let labelSize = titleLabel.sizeThatFits(CGSize(width: imageView.bounds.size.width-30, height: 100))
            titleLabel.frame = CGRect(x: 15, y: pageControl.frame.origin.y - labelSize.height, width: imageView.bounds.size.width-30, height: labelSize.height)
            imageView.addSubview(titleLabel)
            
            allTitleLabels.append(titleLabel)
        }
        
        scrollView.isScrollEnabled = true
        
        // 更新要进行循环的三张图片
        reloadRecycleImageViews()
        
        // 开始自动循环
        addTimer()
        
        if (imageUrls.count <= 1) {
            
            pageControl.isHidden = true
        }
        
        currentImageView = allImageViews.first
        
        if (!scaleAnimated) {
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.currentImageView?.transform = CGAffineTransform.identity
            
        }) { (_) in
            
        }
    }
    
    /** 添加定时器 */
    public func addTimer() {
        
        if !isAutoRecycle ||
            pagesCount <= 1 ||
            timer != nil ||
            autoRecycleInterval <= 1 {
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
    private lazy var scrollView: UIScrollView = {
        
        let scrollView = UIScrollView(frame: self.bounds)
        
        scrollView.scrollsToTop = false
        scrollView.isScrollEnabled = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.clear
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: 3 * self.bounds.size.width, height: 0)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        for vv in scrollView.subviews {
            
            vv.removeFromSuperview()
        }
        
        //        scrollView.translatesAutoresizingMaskIntoConstraints = false
        //        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        //            make.left.right.top.bottom.mas_equalTo(0)
        //        }]
        
        return scrollView
    }()
    
    /** 要循环的imageView 数组 */
    private lazy var recycleImageViews = [UIImageView]()
    
    /** 所有的imageView 数组 */
    fileprivate lazy var allImageViews = [UIImageView]()
    
    /** 所有的label 数组 */
    private lazy var allTitleLabels = [UILabel]()
    
    /** 其它数据 */
    private lazy var dataDicts = [[String : AnyObject]]()
    
    /** 只有2张图片时，额外的图片 */
    private lazy var thirdImageView = UIImageView(frame: self.scrollView.bounds)
    
    /** 图片容器view数组 */
    private lazy var imageContainerViews: [UIView] = {
        
        var imageContainerViews = [UIView]()
        
        for i in 0 ..< 3 {
            
            let containerView = UIView()
            
            imageContainerViews.append(containerView)
        }
        
        return imageContainerViews
    }()
    
    
    /** 中间的label */
    var middleLabel: UILabel?
    
    /** 提示的label */
    var tipLabel: UILabel?
    
    /** 定时器 */
    var timer: Timer?
    
    /** 当前的数据 */
    var urls: [String]?
    
    /** 当前的索引 */
    var currentIndex: Int = 0
    
    /** 当前的图片 */
    var currentImageView: UIImageView?
    
    /** 图片页数 */
    var pagesCount: Int = 0
    
    /** 数据是否已经添加 */
    var isDataAdded: Bool = false
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialization()
        
        //        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialization() {
        
        self.backgroundColor = UIColor.lightGray
        
        autoRecycleInterval = 5
        
        addSubview(contentView)
        contentView.insertSubview(scrollView, at: 0)
        contentView.addSubview(pageControl)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickMiddleImageView)))
    }
    
    // MARK: - 传入一个index来获取下一个正确的index
    fileprivate func getVaildNextPageIndexWith(index: Int) -> Int {
        
        if (index == -1) {
            
            return pagesCount - 1
            
        } else if (index == pagesCount) {
            
            return 0
        }
        
        return index
    }
    
    // MARK: - 更新recycleImageViews
    
    private func updateRecycleImageViews() {
        
        if (allImageViews.count <= 0) {
            return
        }
        
        // 先清空数组
        recycleImageViews.removeAll()
        
        // 计算好上一张和下一张图片的索引
        let previousIndex = getVaildNextPageIndexWith(index: currentIndex - 1)
        let nextIndex = getVaildNextPageIndexWith(index: currentIndex + 1)
        
        // 按顺序添加要循环的三张图片
        if (pagesCount == 2) {
            
            recycleImageViews.append(thirdImageView)
            
            // MARK: - Warning - 只有两张图时 这里也要设置图片
            thirdImageView.image = UIImage(named: (urls?[previousIndex])!)
            //            thirdImageView.jk_setImage(withUrlStr: urls?[previousIndex])
            
        }else{
            
            recycleImageViews.append(allImageViews[previousIndex])
        }
        recycleImageViews.append(allImageViews[currentIndex])
        recycleImageViews.append(allImageViews[nextIndex])
        
        if (allTitleLabels.count >= currentIndex + 1) {
            
            // 中间label赋值
            middleLabel = allTitleLabels[currentIndex]
        }
    }
    
    // MARK: - 重载recycleImageViews
    
    fileprivate func reloadRecycleImageViews() {
        
        // 先让scrollView移除所有控件
        for imgv in recycleImageViews {
            
            imgv.removeFromSuperview()
        }
        
        // 更新要循环的三张图片
        updateRecycleImageViews()
        
        // 将这三张图片添加到scrollView
        for i in 0 ..< 3 {
            
            let containerView = imageContainerViews[i]
            
            let imageView = recycleImageViews[i]
            imageView.transform = CGAffineTransform.identity
            
            let rect = imageView.frame
            
            containerView.frame = CGRect(x: scrollView.bounds.size.width * CGFloat(i), y: rect.origin.y, width: rect.size.width, height: rect.size.height)
            
            imageView.frame = containerView.bounds
            
            containerView.addSubview(imageView)
            
            if (self.scaleAnimated) {
                
                imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                imageView.center = CGPoint(x: containerView.frame.size.width * 0.5, y: containerView.frame.size.height * 0.5)
            }
            
            scrollView.addSubview(containerView)
        }
        
        // 如果只有一张图片及以下，就没必要滚动了吧
        scrollView.isScrollEnabled = true
        
        if (pagesCount <= 1) {
            
            scrollView.contentOffset = CGPoint(x: self.bounds.size.width * 2, y: 0)
            scrollView.isScrollEnabled = false
            pageControl.isHidden = true
            
            return
        }
        
        // 设置scollView偏移
        scrollView.contentOffset = CGPoint(x: self.bounds.size.width, y: 0)
        
        // 设置pageControl的当前页
        pageControl.currentPage = currentIndex
    }
    
    // MARK: - 循环滚动的方法
    
    @objc private func startAutoRecycle() {
        
        if timer == nil {
            return
        }
        
        let newOffset = CGPoint(x: scrollView.bounds.size.width * 2, y: 0)
        scrollView.setContentOffset(newOffset, animated: true)
    }
    
    // MARK: - 点击了中间的ImageView即当前显示的ImageView
    
    @objc private func clickMiddleImageView() {
        
        if (pagesCount <= 0) {
            
            return
        }
        
        if let block = imageClickBlock {
            
            block(currentIndex, (dataDicts.count == urls!.count) ? dataDicts[currentIndex] : ["error" : "图片和其它数据不一致"] as [String : AnyObject])
        }
        
        if delegate == nil {
            return
        }
        
        if delegate!.responds(to: #selector(JKRecycleViewDelegate.recycleView(recycleView:didClickImageWithIndex:otherDataDict:))) {
            
            delegate?.recycleView!(recycleView: self, didClickImageWithIndex: currentIndex, otherDataDict: (dataDicts.count == urls!.count) ? dataDicts[currentIndex] : ["error" : "图片和其它数据不一致"] as [String : AnyObject])
        }
    }
    
    /** x偏移量 */
    fileprivate var offsetX: CGFloat = 0
}

// MARK: - UIScrollViewDelegate

extension JKRecycleView: UIScrollViewDelegate {
    
    // 根据滚动的偏移量设置当前的索引，并更新要进行循环的三张图片
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        offsetX = scrollView.contentOffset.x
        
        if offsetX >= (2 * scrollView.bounds.size.width) {
            
            currentIndex = getVaildNextPageIndexWith(index: currentIndex + 1)
            currentImageView = allImageViews[currentIndex]
            reloadRecycleImageViews()
        }
        
        if offsetX <= 0 {
            
            currentIndex = getVaildNextPageIndexWith(index: currentIndex - 1)
            currentImageView = allImageViews[currentIndex]
            reloadRecycleImageViews()
        }
    }
    
    // 减速完毕 重新设置scrollView的x偏移
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.size.width, y: 0), animated: true)
        
        if !scaleAnimated {
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.currentImageView?.transform = CGAffineTransform.identity
            
        }) { (_) in
            
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        
        if !scaleAnimated {
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.currentImageView?.transform = CGAffineTransform.identity
            
        }) { (_) in
            
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

