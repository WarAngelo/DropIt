//
//  BezierPathsView.swift
//  DropIt
//
//  Created by Андрей Рыжов on 19.10.15.
//  Copyright © 2015 Lazy Team. All rights reserved.
//

import UIKit

class BezierPathsView: UIView {

    private var bezierPaths = [String:UIBezierPath]()
    
    func setPath(path: UIBezierPath?, named name: String) {
        bezierPaths[name] = path
        setNeedsDisplay() // мы только что изменили модель, давайте установим дисплей
    }
    
    override func drawRect(rect: CGRect) {
        for (_, path) in bezierPaths {
            path.stroke()
        }
    }

}
