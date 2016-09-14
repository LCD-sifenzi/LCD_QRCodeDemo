//
//  ViewController.swift
//  LCD_QRCodeDemo
//
//  Created by 刘才德 on 16/9/13.
//  Copyright © 2016年 sifenzi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func qrClick(sender: AnyObject) {
        
        //一句代码搞定二维码/条形码扫描
        LCD_QRCode.show(self) { (strQR) in
            print(strQR)
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

