//
//  Portal.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/15/16.
//  Copyright © 2016 Ramadhan Noor. All rights reserved.
//

import Foundation
import MapKit
import AddressBook


class Portal: NSObject, MKAnnotation {
    let title: String?
    let photoURL: String?
    let otherString: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, photoURL: String, otherString: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.photoURL = photoURL
        self.otherString = otherString
        self.coordinate = coordinate
        
        super.init()
    }
    
    class func fromCSV(dict: [String:String]) -> Portal? {
        let stringArray = Array(dict)
        var title, imgurl, otherText: String!
        var lon, lat:Double!
        
        for a in stringArray {
            if a.0 == "other" {
                otherText = a.1
            } else if a.0 == "name" {
                title = a.1
            } else if a.0 == "imgurl" {
                imgurl = a.1
            } else if a.0 == "lon" {
                lon = Double(a.1)!
            } else if a.0 == "lat" {
                lat = Double(a.1)!
            }
        }
        
        let c = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return Portal(title: title, photoURL: imgurl, otherString: otherText, coordinate: c)
    }
    
    
    var subtitle: String? {
        return otherString
    }
    
    // MARK: - MapKit related methods
    
    func pinColor() -> MKPinAnnotationColor  {
        return .Red
    }
    
    // annotation callout opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        let addressDict = [String(kABPersonAddressStreetKey): self.subtitle as! AnyObject]
        let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: addressDict)
        
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.title
        
        return mapItem
    }
    
}
