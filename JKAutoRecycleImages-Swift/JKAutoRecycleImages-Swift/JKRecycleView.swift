//
//  JKRecycleView.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


// MARK: - 代理方法
@objc
protocol JKRecycleViewDelegate: NSObjectProtocol {
    /** 点击添加照片按钮 */
    @objc optional func recycleView(_ recycleView: JKRecycleView, didClickCurrentImageView: Int)
}

class JKRecycleView: UIView {
    //MARK: - 私有属性
    /** scrollView */
    fileprivate lazy var scrollView: UIScrollView = {
        let sc = UIScrollView(frame: self.bounds)
        sc.delegate = self
        sc.backgroundColor = UIColor.clear
        sc.isPagingEnabled = true
        sc.contentSize = CGSize(width: 3 * self.bounds.size.width, height: 0)
        return sc
    }()
    
    /** pageControl */
    fileprivate lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.frame = CGRect(x: 0, y: self.bounds.size.height - 30, width: self.bounds.size.width, height: 37)
        pc.isUserInteractionEnabled = false
        pc.pageIndicatorTintColor = UIColor.darkGray
        return pc
    }()
    
    /** 点击图片的闭包回调，不想用代理可以用这个 */
    public var imageClickBlock : ((_ index: Int)->())?
    
    /** 中间的label */
    fileprivate var middleLabel: UILabel?
    
    /** 定时器 */
    fileprivate var timer: Timer?
    
    /** 要循环的imageView */
    fileprivate var recycleImageViews = [UIImageView]()
    
    /** 所有的imageView */
    fileprivate var allImageViews = [UIImageView]()
    
    /** 所有的label */
    fileprivate var allTitleLabels = [UILabel]()
    
    /** 当前的索引 */
    fileprivate var currentIndex = 0
    
    /** 图片页数 */
    fileprivate var pagesCount = 0
    
    /** 数据是否应添加 */
    fileprivate var isDataAdded = false
    
    //MARK: - 外部属性
    /** 自动滚动的时间间隔（单位为s）默认3s */
    var autoRecycleInterval: TimeInterval = 3 {
        didSet{
            removeTimer()
            addTimer()
        }
    }
    
    /** 是否自动开始循环 默认true */
    var isAutoRecycle: Bool = true{
        didSet{
            removeTimer()
            addTimer()
        }
    }
    
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
    
    fileprivate func initialization() {
        
        addSubview(scrollView)
        addSubview(pageControl)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(JKRecycleView.clickMiddleImageView)))
    }
    
    //MARK: - 内部方法
    /** 点击了中间的ImageView即当前显示的ImageView */
    @objc fileprivate func clickMiddleImageView(){
        if imageClickBlock != nil {
            imageClickBlock!(currentIndex)
        }
        
        guard let _ = delegate else {
            return
        }
        
        if (delegate?.responds(to: #selector(JKRecycleViewDelegate.recycleView(_:didClickCurrentImageView:))))! {
            delegate?.recycleView!(self, didClickCurrentImageView: currentIndex)
        }
    }
    
    /** 传入一个index来获取下一个正确的index */
    fileprivate func getVaildNextPageIndex(_ index: Int) -> Int{
        if (index == -1) {
            return pagesCount - 1;
        } else if (index == pagesCount) {
            return 0;
        }
        return index;
    }
    
    /** 更新recycleImageViews */
    fileprivate func updaterecycleImageViews (){
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
    fileprivate func reloadRecycleImageViews() {
        // 先让scrollView移除所有控件
        for view: UIView in scrollView.subviews {
            view.removeFromSuperview()
        }
        
        // 更新要循环的三张图片
        updaterecycleImageViews()
        
        // 将这三张图片添加到scrollView
        for i in 0 ..< recycleImageViews.count {
            let imageView = recycleImageViews[i]
            let rect = imageView.frame;
            imageView.frame = CGRect(x: scrollView.bounds.size.width * CGFloat(i), y: rect.origin.y, width: rect.size.width, height: rect.size.height)
            scrollView.insertSubview(imageView, at: 0)
        }
        // 如果只有一张图片及以下，就没必要滚动了吧
        if (pagesCount <= 1) {
            scrollView.contentOffset = CGPoint(x: self.bounds.size.width * 2, y: 0)
            scrollView.isScrollEnabled = false
            pageControl.isHidden = true
            return
        }
        
        // 设置scollView偏移
        scrollView.contentOffset = CGPoint(x: self.bounds.size.width, y: 0)
        
        // 设置pageControl的当前页
        pageControl.currentPage = currentIndex;
    }
    
    /** 循环滚动的方法 */
    @objc fileprivate func startAutoRecycle() {
        let newOffset = CGPoint(x: scrollView.bounds.size.width * 2, y: 0)
        scrollView.setContentOffset(newOffset, animated: true)
    }
    
    //MARK: - 外部方法
    /** 添加定时器 */
    func addTimer(){
        if isAutoRecycle == false {
            return
        }
        
        if pagesCount <= 1 {
            return
        }
        
        if timer != nil {
            return
        }
        
        timer = Timer(timeInterval: autoRecycleInterval, target: self, selector: #selector(JKRecycleView.startAutoRecycle), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    /** 移除定时器 */
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /** 设置数据 */
    func set(_ imageNames: [String]?, titles: [String]?){
        guard let imgNames = imageNames else {
            return
        }
        
        isDataAdded = false
        
        // 防止重复赋值
        if imgNames.count == self.imageNames.count {
            isDataAdded = true
            for i in 0 ..< imgNames.count {
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
        for i in 0 ..< pagesCount {
            // 创建imageView
            let imageView = UIImageView()
            imageView.image = UIImage(contentsOfFile: Bundle.main.path(forResource: imgNames[i], ofType: "jpg")!)
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
            titleLabel.textAlignment = NSTextAlignment.center
            titleLabel.numberOfLines = 0
            titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
            titleLabel.shadowColor = UIColor.darkGray
            titleLabel.shadowOffset = CGSize(width: 1, height: 0)
            titleLabel.textColor = UIColor.white
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.lineBreakMode = NSLineBreakMode.byCharWrapping;
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
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.size.width, y: 0), animated: true)
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
