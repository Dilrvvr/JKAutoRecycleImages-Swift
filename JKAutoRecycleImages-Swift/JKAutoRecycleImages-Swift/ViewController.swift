//
//  ViewController.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

class ViewController: UIViewController, JKCycleBannerViewDelegate {
    
    @IBOutlet weak var recycleView: JKCycleBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recycleView.delegate = self
        
        recycleView.cornerRadius = 8
        recycleView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        recycleView.setDataSource(dataSource: [
            [JKCycleBannerImageUrlKey : "kenan01.jpg" as AnyObject, JKCycleBannerTitleKey : "kenan01-柯兰" as AnyObject],
            [JKCycleBannerImageUrlKey : "kenan02.jpg" as AnyObject, JKCycleBannerTitleKey : "kenan02-柯哀" as AnyObject],
            [JKCycleBannerImageUrlKey : "kenan03.jpg" as AnyObject, JKCycleBannerTitleKey : "kenan03-柯兰" as AnyObject],
            [JKCycleBannerImageUrlKey : "kenan04.jpg" as AnyObject, JKCycleBannerTitleKey : "kenan04-新兰" as AnyObject],
            [JKCycleBannerImageUrlKey : "kenan05.jpg" as AnyObject, JKCycleBannerTitleKey : "kenan05-全家福" as AnyObject]])
        
        weak var weakSelf = self
        recycleView.imageClickBlock = { (dict) in
            
            weakSelf?.alertImageWith(dict)
        }
    }
    
    @IBAction func start(_ sender: AnyObject) {
        
        recycleView.addTimer()
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        
        recycleView.removeTimer()
    }
    
    // MARK: - JKCycleBannerViewDelegate
    
    func cycleBannerView(_ cycleBannerView: JKCycleBannerView, didClickImageWith dict: [String : AnyObject]) {
        
//        alertImageWith(dict)
    }
    
    private func alertImageWith(_ dict: [String : AnyObject]) {
        
        guard let message = dict[JKCycleBannerTitleKey] else { return }
        
        let alertVc = UIAlertController(title: nil, message: message as? String, preferredStyle: UIAlertControllerStyle.alert)
        
        alertVc.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertVc, animated: true, completion: nil)
    }
}

