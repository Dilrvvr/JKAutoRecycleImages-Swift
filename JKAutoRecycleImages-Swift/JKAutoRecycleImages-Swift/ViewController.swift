//
//  ViewController.swift
//  JKAutoRecycleImages-Swift
//
//  Created by albert on 16/9/5.
//  Copyright © 2016年 albert. All rights reserved.
//

import UIKit

class ViewController: UIViewController, JKRecycleViewDelegate {
    
    @IBOutlet weak var recycleView: JKRecycleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recycleView.delegate = self
        
        recycleView.setDataSource(dataSource: [
            [JKRecycleImageUrlKey : "kenan01.jpg" as AnyObject, JKRecycleTitleKey : "kenan01-柯兰" as AnyObject],
            [JKRecycleImageUrlKey : "kenan02.jpg" as AnyObject, JKRecycleTitleKey : "kenan02-柯哀" as AnyObject],
            [JKRecycleImageUrlKey : "kenan03.jpg" as AnyObject, JKRecycleTitleKey : "kenan03-柯兰" as AnyObject],
            [JKRecycleImageUrlKey : "kenan04.jpg" as AnyObject, JKRecycleTitleKey : "kenan04-新兰" as AnyObject],
            [JKRecycleImageUrlKey : "kenan05.jpg" as AnyObject, JKRecycleTitleKey : "kenan05-全家福" as AnyObject]])
        
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
    
    // MARK: - JKRecycleViewDelegate
    
    func recycleView(_ recycleView: JKRecycleView, didClickImageWith dict: [String : AnyObject]) {
        
//        alertImageWith(dict)
    }
    
    private func alertImageWith(_ dict: [String : AnyObject]) {
        
        guard let message = dict[JKRecycleTitleKey] else { return }
        
        let alertVc = UIAlertController(title: nil, message: message as? String, preferredStyle: UIAlertControllerStyle.alert)
        
        alertVc.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertVc, animated: true, completion: nil)
    }
}

