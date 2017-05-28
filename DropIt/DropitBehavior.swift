//
//  DropitBehavior.swift
//  DropIt
//
//  Created by Андрей Рыжов on 18.10.15.
//  Copyright © 2015 Lazy Team. All rights reserved.
//

import UIKit

class DropitBehavior: UIDynamicBehavior {
    
    let gravity = UIGravityBehavior()
    
    lazy var collider: UICollisionBehavior = { // причина по которой мы делаем это - не рефернс вьб, который не загрузится, - а чтобы указать дополнительные параметры
        let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true //будет отскакивать от границ вью; чтобы инициализировать это состояние мы используем клозурес. В примере ниже мы используем что инициализировать референс вью, только после референс вью - по вызову аниматора.
        return lazilyCreatedCollider
        } ()
    
    lazy var dropBehavoir: UIDynamicItemBehavior = {
        let lazilyCreatedDropBehavior = UIDynamicItemBehavior()
        lazilyCreatedDropBehavior.allowsRotation = true //кубики не должны поворачиваться
        lazilyCreatedDropBehavior.elasticity = 0.75 //прыжки 1 - отличные
        return lazilyCreatedDropBehavior
    }()
    
    override init() { //теперь UIDynamicBehavior ведет себя как комбинированное гравити и коллайдер
        super.init()
        addChildBehavior(gravity)
        addChildBehavior(collider)
        addChildBehavior(dropBehavoir)
    }
    
    func addBarrier(path:UIBezierPath, named name: String) { //добавим барьер в нашу картинку
        collider.removeBoundaryWithIdentifier(name)
        collider.addBoundaryWithIdentifier(name, forPath: path) //добавляем границу к коллайду
    }
    
    func addDrop(drop: UIView) {
        dynamicAnimator?.referenceView?.addSubview(drop) //dynamicAnimator - это наш аниматор, который связан с поведением, референс вью - это наш главный вью, который связан с аниматором
        gravity.addItem(drop)
        collider.addItem(drop)
        dropBehavoir.addItem(drop)
    }
    
    func removeDrop(drop: UIView) {
        gravity.removeItem(drop)
        collider.removeItem(drop)
        dropBehavoir.removeItem(drop)
        drop.removeFromSuperview()
    }

}
