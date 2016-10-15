//
//  JKRecycleView.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

// MARK: - 代理方法
@objc
protocol JKRecycleViewDelegate: NSObjectProtocol {
    /** 点击添加照片按钮 */
    optional func recycleView(recycleView: JKRecycleView, didClickCurrentImageView: Int)
}

class JKRecycleView: UIView {
    //MARK: - 私有属性
    /** scrollView */
    private lazy var scrollView: UIScrollView = {
        let sc = UIScrollView(frame: self.bounds)
        sc.delegate = self
        sc.backgroundColor = UIColor.clearColor()
        sc.pagingEnabled = true
        sc.contentSize = CGSizeMake(3 * self.bounds.size.width, 0)
        return sc
    }()
    
    /** pageControl */
    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.frame = CGRect(x: 0, y: self.bounds.size.height - 30, width: self.bounds.size.width, height: 37)
        pc.userInteractionEnabled = false
        pc.pageIndicatorTintColor = UIColor.darkGrayColor()
        return pc
    }()
    
    /** 中间的label */
    private var middleLabel: UILabel?
    
    /** 定时器 */
    private var timer: NSTimer?
    
    /** 要循环的imageView */
    private var recycleImageViews = [UIImageView]()
    
    /** 所有的imageView */
    private var allImageViews = [UIImageView]()
    
    /** 所有的label */
    private var allTitleLabels = [UILabel]()
    
    /** 当前的索引 */
    private var currentIndex = 0
    
    /** 图片页数 */
    private var pagesCount = 0
    
    /** 数据是否应添加 */
    private var isDataAdded = false
    
    //MARK: - 外部属性
    /** 自动滚动的时间间隔（单位为s）默认3s */
    var autoRecycleInterval: NSTimeInterval = 3
    
    /** 当前的数据 */
    var imageNames = [String]()
    
    /** 代理 */
    weak var delegate: JKRecycleViewDelegate?
    
    //MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    private func initialization() {
        addSubview(scrollView)
        addSubview(pageControl)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "clickMiddleImageView"))
    }
    
    //MARK: - 内部方法
    /** 点击了中间的ImageView即当前显示的ImageView */
    @objc private func clickMiddleImageView(){
        if let tempDelegate = delegate {
            if tempDelegate.respondsToSelector("recycleView:didClickCurrentImageView:") {
                tempDelegate.recycleView!(self, didClickCurrentImageView: currentIndex)
            }
        }
    }
    
    /** 传入一个index来获取下一个正确的index */
    private func getVaildNextPageIndex(index: Int) -> Int{
        if (index == -1) {
            return pagesCount - 1;
        } else if (index == pagesCount) {
            return 0;
        }
        return index;
    }
    
    /** 更新recycleImageViews */
    private func updaterecycleImageViews (){
        // 先清空数组
        recycleImageViews.removeAll()
        
        // 计算好上一张和下一张图片的索引
        let previousIndex = getVaildNextPageIndex(currentIndex - 1)
        let nextIndex = getVaildNextPageIndex(currentIndex + 1)
        
        // 按顺序添加要循环的三张图片
        recycleImageViews.append(allImageViews[previousIndex])
        recycleImageViews.append(allImageViews[self.currentIndex])
        recycleImageViews.append(allImageViews[nextIndex])
        
        // 中间label赋值
        if allTitleLabels.count < currentIndex + 1 {
            return;
        }
        middleLabel = allTitleLabels[currentIndex];
    }
    
    /** 重载recycleImageViews */
    private func reloadRecycleImageViews() {
        // 先让scrollView移除所有控件
        for view: UIView in scrollView.subviews {
            view.removeFromSuperview()
        }
        
        // 更新要循环的三张图片
        updaterecycleImageViews()
        
        // 将这三张图片添加到scrollView
        for var i = 0; i < recycleImageViews.count; i++ {
            let imageView = recycleImageViews[i]
            let rect = imageView.frame;
            imageView.frame = CGRect(x: scrollView.bounds.size.width * CGFloat(i), y: rect.origin.y, width: rect.size.width, height: rect.size.height)
            scrollView.insertSubview(imageView, atIndex: 0)
        }
        // 如果只有一张图片及以下，就没必要滚动了吧
        if (pagesCount <= 1) {
            scrollView.contentOffset = CGPoint(x: self.bounds.size.width * 2, y: 0)
            scrollView.scrollEnabled = false
            pageControl.hidden = true
            return
        }
        
        // 设置scollView偏移
        scrollView.contentOffset = CGPoint(x: self.bounds.size.width, y: 0)
        
        // 设置pageControl的当前页
        pageControl.currentPage = currentIndex;
    }
    
    /** 循环滚动的方法 */
    @objc private func startAutoRecycle() {
        let newOffset = CGPoint(x: scrollView.bounds.size.width * 2, y: 0)
        scrollView.setContentOffset(newOffset, animated: true)
    }
    
    //MARK: - 外部方法
    /** 添加定时器 */
    func addTimer(){
        if pagesCount <= 1 {
            return
        }
        
        if timer != nil {
            return
        }
        
        timer = NSTimer(timeInterval: autoRecycleInterval, target: self, selector: "startAutoRecycle", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    /** 移除定时器 */
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /** 设置数据 */
    func set(imageNames: [String]?, titles: [String]?){
        guard let imgNames = imageNames else {
            return
        }
        
        // 防止重复赋值
        if imgNames.count == self.imageNames.count {
            isDataAdded = true
            for var i = 0; i < imgNames.count; i++ {
                let str1 = imgNames[i];
                let str2 = self.imageNames[i];
                if str1 == str2 {
                    continue
                }
                self.isDataAdded = false
                break
            }
        }
        
        // 如果数据已经添加，直接返回
        if isDataAdded {
            return
        }
        
        // 赋值
        self.imageNames = imgNames
        
        // pageControl的页数就是图片的个数
        pagesCount = imgNames.count;
        pageControl.numberOfPages = pagesCount;
        
        // 先清空数组
        allImageViews.removeAll()
        allTitleLabels.removeAll()
        
        // 循环创建imageView等控件，添加到数组中
        for var i = 0; i < pagesCount; i++ {
            // 创建imageView
            let imageView = UIImageView()
            imageView.image = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource(imgNames[i], ofType: "jpg")!)
            imageView.frame = CGRect(x: 0, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
            
            // 将控件添加到数组
            allImageViews.append(imageView)
            
            if titles == nil || titles?.count < imageNames?.count {
                continue;
            }
            
            // 创建titleLabel
            let titleLabel = UILabel()
            titleLabel.sizeToFit()
            titleLabel.frame = CGRect(x: 0, y: imageView.bounds.size.height-50, width: imageView.bounds.size.width, height: 30)
            titleLabel.textAlignment = NSTextAlignment.Center
            titleLabel.numberOfLines = 0
            titleLabel.font = UIFont.boldSystemFontOfSize(20)
            titleLabel.shadowColor = UIColor.darkGrayColor()
            titleLabel.shadowOffset = CGSize(width: 1, height: 0)
            titleLabel.textColor = UIColor.whiteColor()
            titleLabel.backgroundColor = UIColor.clearColor()
            titleLabel.lineBreakMode = NSLineBreakMode.ByCharWrapping;
            titleLabel.text = titles![i];
            
            imageView.addSubview(titleLabel)
            allTitleLabels.append(titleLabel)
        }
        
        // 更新要进行循环的三张图片
        reloadRecycleImageViews()
        
        // 开始自动循环
        addTimer()
    }
}

// MARK: - scrollView代理
extension JKRecycleView: UIScrollViewDelegate {
    // 根据滚动的偏移量设置当前的索引，并更新要进行循环的三张图片
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x;
        
        if offsetX >= (2 * scrollView.bounds.size.width) {
            currentIndex = getVaildNextPageIndex(self.currentIndex + 1)
            reloadRecycleImageViews()
        }
        
        if offsetX <= 0 {
            currentIndex = getVaildNextPageIndex(self.currentIndex - 1)
            reloadRecycleImageViews()
        }
    }
    
    // 减速完毕 重新设置scrollView的x偏移
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.size.width, y: 0), animated: true)
    }
    
    // 手指拖动 移除定时器
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        removeTimer()
    }
    
    // 手指松开 添加定时器
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        addTimer()
    }
}