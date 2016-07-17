//
//  Player.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/16/16.
//  Copyright © 2016 Ramadhan Noor. All rights reserved.
//

import Foundation
import MapKit
import AddressBook

protocol PlayerDelegate{
    func onPlayerMoving (player: Player)
    func onPlayerMovingStart (player: Player)
    func onPlayerMovingFinish (player: Player)
}

class Player: NSObject, MKAnnotation {
    
    var delegate:PlayerDelegate!
    var playerOverlay:MKCircle!
    
    let name:String?
    var isMoving:Bool
    var moveTick:NSTimer?
    
    dynamic var coordinate: CLLocationCoordinate2D
    var targetCoordinate:CLLocationCoordinate2D!
    var imageName:String!
    
    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
        self.isMoving = false
        
        super.init()
    }
    
    func moveToLocation (targetLoc:CLLocationCoordinate2D) {
        self.targetCoordinate = targetLoc
        
        self.resetTimer()
        self.startTimer()
    }
    
    func jumpToLocation (targetLoc:CLLocationCoordinate2D) {
        self.targetCoordinate = targetLoc
        self.resetTimer()
        coordinate = targetLoc
        delegate.onPlayerMovingFinish(self)
    }
    
    func stop () {
        resetTimer()
        delegate.onPlayerMovingFinish(self)
    }
    
    func resetTimer () {
        self.moveTick?.invalidate()
        isMoving = false
    }
    
    func startTimer () {
        self.moveTick = NSTimer.scheduledTimerWithTimeInterval(0.5,
                                                                    target: self,
                                                                    selector: #selector(Player.tick),
                                                                    userInfo: nil,
                                                                    repeats: true)
        isMoving = true
        delegate.onPlayerMovingStart(self)
    }
    
    @objc func tick() {
        
        if !isMoving {
            return
        }
        let targetPoint:MKMapPoint = MKMapPointForCoordinate(targetCoordinate)
        let currentPoint:MKMapPoint = MKMapPointForCoordinate(coordinate)
        
        let dist:CLLocationDistance = MKMetersBetweenMapPoints(targetPoint, currentPoint);
        if dist < 2 {
            stop()
            return
        }
        
        let hDist: CLLocationDistance = targetPoint.x - currentPoint.x
        let vDist: CLLocationDistance = targetPoint.y - currentPoint.y
        
        let angleRad = atan2(vDist, hDist)
        let vx = cos(angleRad) * 20
        let vy = sin(angleRad) * 20
        
        let nextPoint:MKMapPoint = MKMapPointMake(currentPoint.x + vx, currentPoint.y + vy)
        coordinate = MKCoordinateForMapPoint(nextPoint)
        delegate.onPlayerMoving(self)
    }
    
    var title: String? {
        return name
    }
    
    func pinColor() -> MKPinAnnotationColor  {
        return .Red
    }
    
    func mapItem() -> MKMapItem {
        let addressDict = [String(kABPersonNicknameProperty): self.name as! AnyObject]
        let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.name
        return mapItem
    }
}