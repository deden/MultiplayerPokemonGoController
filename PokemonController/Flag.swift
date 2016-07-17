//
//  Flag.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/17/16.
//  Copyright © 2016 Ramadhan Noor. All rights reserved.
//

import Foundation
import MapKit

class Flag:NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
    
    var title: String? {
        let twoDecimalLat = String(format: "%.2f", coordinate.latitude)
        let twoDecimalLon = String(format: "%.2f", coordinate.longitude)
        return "\(twoDecimalLat), \(twoDecimalLon)"
    }
    
    class func createViewAnnotationForMapView(mapview: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
        var returnedAnnotationView =
            mapview.dequeueReusableAnnotationViewWithIdentifier(String(Flag.self))
        if returnedAnnotationView == nil {
            returnedAnnotationView =
                MKAnnotationView(annotation: annotation, reuseIdentifier: String(Flag.self))
            
            returnedAnnotationView!.canShowCallout = true            
            returnedAnnotationView!.centerOffset = CGPointMake(returnedAnnotationView!.centerOffset.x + (returnedAnnotationView!.image?.size.width ?? 0)/2, returnedAnnotationView!.centerOffset.y - (returnedAnnotationView!.image?.size.height ?? 0)/2)
        } else {
            returnedAnnotationView!.annotation = annotation
        }
        return returnedAnnotationView!
    }
}