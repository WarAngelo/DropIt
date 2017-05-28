//
//  DropitViewController.swift
//  DropIt
//
//  Created by Андрей Рыжов on 18.10.15.
//  Copyright © 2015 Lazy Team. All rights reserved.
//

import UIKit

class DropitViewController: UIViewController, UIDynamicAnimatorDelegate
{
    @IBOutlet weak var gameView: BezierPathsView!
    
//    let gravity = UIGravityBehavior()
//    
//    lazy var collider: UICollisionBehavior = { // причина по которой мы делаем это - не рефернс вьб, который не загрузится, - а чтобы указать дополнительные параметры
//        let lazilyCreatedCollider = UICollisionBehavior()
//        lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true //будет отскакивать от границ вью; чтобы инициализировать это состояние мы используем клозурес. В примере ниже мы используем что инициализировать референс вью, только после референс вью - по вызову аниматора.
//        return lazilyCreatedCollider
//        } ()
    
    
    //var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: gameView) //мы не можем сделать так, потому что гейм вью должен сначала инициализироваться, поэтому используем лейзи вар (делать инициализацию переменной только когда потребуется).
    
    lazy var animator: UIDynamicAnimator = { //lazy значит, что эта переменная не должна инициализироваться в init time, но когда она встретится в коде, тогда обязана установиться
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView) //гейм вью должно быть установлено, поэтому переменную аниматор вызываем только во вью дид лоад, когда гейм вью точно установится
        lazilyCreatedDynamicAnimator.delegate = self //чтобы удалить ячейки мы должны сделать паузу в анимации, для этого вызываем делегат с двумя методами, которые имелментируем ниже
        return lazilyCreatedDynamicAnimator
    }()
    
    let dropitBehavior = DropitBehavior()
    
    //Присоединяем поведение кубика к жесту. nil может быть, потому что мы хотим, чтобы это принимало значение при жесте pan только когда мы прижали палец, а если отпустили, то это станет nil.
    var attachment: UIAttachmentBehavior? { //для рисования
        willSet { //удаляем старый аттачмент
            if attachment != nil {
                animator.removeBehavior(attachment!)
            }
            gameView.setPath(nil, named: PathNames.Attachment) // мы должны удалить старый путь
        }
        didSet { // добовляем в анимирование новый attachment
            if attachment != nil {
                animator.addBehavior(attachment!)
                //создаем линию между точкой привязки (нашим паном) и центром кубика, актион = клозуре, будет обновляться в момент сдвига в реальном времени
                //у нас тут мемори ворнинг!! аттачмент через акцион замыкает вечные указатели друг на друга!!! пишем [unowned self] in - это значит, что система не будет хранить селф в мемори, пока клозуре работает
                attachment?.action = { [unowned self] in
                    if let attachedView = self.attachment?.items.first as? UIView {
                        let path = UIBezierPath()
                        path.moveToPoint(self.attachment!.anchorPoint)
                        path.addLineToPoint(attachedView.center)
                        self.gameView.setPath(path, named: PathNames.Attachment)
                    }
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(dropitBehavior)
//        animator.addBehavior(gravity) //добавляем гравитационное поле в аниматор, теперь он будет анимировать все айтемы там.
//        animator.addBehavior(collider) //в аниматор мы добовляем поведение, которое он сможет делать. Теперь к этим поведениям прикрепим итемы и все =)
    }
    
    struct PathNames {
        static let MiddleBarier = "Middle Barrier"
        static let Attachment = "Attachment"
    }
    override func viewDidLayoutSubviews() { //когда мы поворачиваем экран например будем устанавливать барьер
        super.viewDidLayoutSubviews()
        let barrierSize = dropSize
        let barrierOrigin = CGPoint(x: gameView.bounds.midX-barrierSize.width/2, y: gameView.bounds.midY-barrierSize.height/2)
        let path = UIBezierPath(ovalInRect: CGRect(origin: barrierOrigin, size: barrierSize)) //создаем круг в центре с размером квадрата
        dropitBehavior.addBarrier(path, named: PathNames.MiddleBarier) //будет отталкиваться от этого барьера
        gameView.setPath(path, named: PathNames.MiddleBarier) //будет рисовать, потому что мы изменили вьюху и сделали у нее метод setPath
        
    }
    
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) { //метод делегата
        removeComplitedRow()
    }
    
    var dropsPerRow = 10 //сколько будет падать кубиков
    
    var dropSize: CGSize { //размеры кубиков
        let size = gameView.bounds.size.width / CGFloat(dropsPerRow)
        return CGSize (width: size, height: size)
    }
    
    @IBAction func drop(sender: UITapGestureRecognizer) {//вставляем жест из сториборда с экшеном, что-то будет падать при тапе
        drop()
    }
    
    @IBAction func grabDrop(sender: UIPanGestureRecognizer) {
        let gesturePoint = sender.locationInView(gameView)
        
        switch sender.state {
        case .Began:
            if let viewToAttachTo = lastDroppedView {
                attachment = UIAttachmentBehavior(item: viewToAttachTo, attachedToAnchor: gesturePoint)
                lastDroppedView = nil //делаем так, чтобы только один раз можно было использовать пэн на последнюю вьюху
            }
        case .Changed:
            attachment?.anchorPoint = gesturePoint //если изменяется жест, то мы привязываем точку привязки к нему
        case .Ended:
            attachment = nil
        default: break
        }
    }
    
    var lastDroppedView: UIView?
    
    func drop() {
        var frame = CGRect(origin: CGPointZero, size: dropSize) //создали кубик в нуле
        frame.origin.x = CGFloat.random(dropsPerRow) * dropSize.width //изменяем положение кубика икс рандомно
        
        let dropView = UIView(frame: frame) //создаем новую вью
        dropView.backgroundColor = UIColor.random
        
        lastDroppedView = dropView
        
        dropitBehavior.addDrop(dropView)
//        gameView.addSubview(dropView) //добовляем новую вьюху как сабвью к нашей главной вьюхе
//        
//        gravity.addItem(dropView) //определяем какие айтамы мы кладем в гравитационное поле!
//        collider.addItem(dropView)
    }
    
    func removeComplitedRow() {
        var dropsToRemove = [UIView]()
        var dropFrame = CGRect(x: 0, y: gameView.frame.maxY, width: dropSize.width, height: dropSize.height)
        
        repeat {
            dropFrame.origin.y -= dropSize.height
            dropFrame.origin.x = 0
            var dropsFound = [UIView]()
            var rowIsComplete = true
            for _ in 0 ..< dropsPerRow {
                if let hitView = gameView.hitTest(CGPoint(x: dropFrame.midX, y: dropFrame.midY), withEvent: nil) {
                    if hitView.superview == gameView {
                        dropsFound.append(hitView)
                    } else {
                        rowIsComplete = false
                    }
                }
                dropFrame.origin.x += dropSize.width
            }
            if rowIsComplete {
                dropsToRemove += dropsFound
            }
        } while dropsToRemove.count == 0 && dropFrame.origin.y > 0
        
        for drop in dropsToRemove {
            dropitBehavior.removeDrop(drop)
        }
    }
}

private extension CGFloat { //возвращает рандомное значение сижифлоата между 0 и max - 1
    static func random (max: Int) -> CGFloat {
        return CGFloat(arc4random() % UInt32(max))
    }
}

private extension UIColor { //экстеншены используем прямо на тип переменных - колор или флопт
    class var random: UIColor {
        switch arc4random()%5 {
        case 0: return UIColor.greenColor()
        case 1: return UIColor.blueColor()
        case 2: return UIColor.orangeColor()
        case 3: return UIColor.redColor()
        case 4: return UIColor.purpleColor()
        default: return UIColor.blackColor()
        }
    }
}