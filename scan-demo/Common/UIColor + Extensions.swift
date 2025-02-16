//
//  UIColor + Extensions.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import UIKit

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b: CGFloat
        if hex.count == 6 {
            let scanner = Scanner(string: hex)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                
                self.init(red: r, green: g, blue: b, alpha: 1.0)
                return
            }
        } else {
            let r, g, b, a: CGFloat
            
            if hex.hasPrefix("#") {
                let start = hex.index(hex.startIndex, offsetBy: 1)
                let hexColor = String(hex[start...])
                
                if hexColor.count == 8 {
                    let scanner = Scanner(string: hexColor)
                    var hexNumber: UInt64 = 0
                    
                    if scanner.scanHexInt64(&hexNumber) {
                        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        a = CGFloat(hexNumber & 0x000000ff) / 255
                        
                        self.init(red: r, green: g, blue: b, alpha: a)
                        return
                    }
                }
            }
        }
        
        return nil
    }
}
