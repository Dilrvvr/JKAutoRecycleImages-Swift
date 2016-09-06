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
        
        recycleView.set(["kenan01", "kenan02", "kenan03", "kenan04", "kenan05"], titles: ["kenan01-柯兰", "kenan02-柯哀", "kenan03-柯兰", "kenan04-新兰", "kenan05-全家福"])
    }
    
    @IBAction func start(sender: AnyObject) {
        recycleView.addTimer()
    }
    
    @IBAction func stop(sender: AnyObject) {
        recycleView.removeTimer()
    }
    
    //MARK: - <JKRecycleViewDelegate>
    func recycleView(recycleView: JKRecycleView, didClickCurrentImageView: Int) {
        let message = "点击了第\(didClickCurrentImageView + 1)张图片"//[NSString stringWithFormat:@, ];
        
        let alertVc = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertVc.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertVc, animated: true, completion: nil)
    }
}

