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
        
        weak var weakSelf = self
        recycleView.imageClickBlock = {
            (index: Int) -> ()
            in
            weakSelf?.alertImageIndex(index)
        }
    }
    
    @IBAction func start(_ sender: AnyObject) {
        recycleView.addTimer()
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        recycleView.removeTimer()
    }
    
    //MARK: - <JKRecycleViewDelegate>
    func recycleView(_ recycleView: JKRecycleView, didClickCurrentImageView: Int) {
//        alertImageIndex(didClickCurrentImageView)
    }
    
    private func alertImageIndex(_ index: Int) {
        let message = "点击了第\(index + 1)张图片"//[NSString stringWithFormat:@, ];
        
        let alertVc = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertVc.addAction(UIAlertAction(title: "确定", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alertVc, animated: true, completion: nil)
    }
}

