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
        let lazyMapCollection = dict.values
        let stringArray = Array(lazyMapCollection)
        
        let title = stringArray[3]
        let imgurl = stringArray[4]
        let otherText = stringArray[0]
        let c = CLLocationCoordinate2D(latitude: Double(stringArray[2])!, longitude: Double(stringArray[1])!)
        
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
