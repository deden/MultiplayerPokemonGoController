//
//  ViewController.swift
//  PokemonController
//
//  Created by Ramadhan Noor on 7/16/16.
//  Copyright © 2016 Ramadhan Noor. All rights reserved.
//

import UIKit
import MapKit
import GCDWebServer

class ViewController: UIViewController, MKMapViewDelegate, PlayerDelegate, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var selectPlayerButton: UIButton!
    
    var mapCenterCoordinate:CLLocationCoordinate2D!
    var targetLocation:CLLocationCoordinate2D!
    
    var currentMapType = 0

    var autoMoveTimer:NSTimer?
    
    var portals = [Portal]()
    var players = [Player]()
    var nearbyCircles = [MKCircle]()
    
    var currentPlayer:Player?
    var webServer:GCDWebServer = GCDWebServer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCSV()
        getSavedLocation() ? showMapOnLocation() : ()
        getSavedMapType()
        
        startWebServer()
        
        mapView.addAnnotations(portals)
        mapView.delegate = self
        
        let ulpgr = UILongPressGestureRecognizer(target: self, action:#selector(ViewController.routeMapLongPressSelector(_:)))
        ulpgr.minimumPressDuration = 0.3
        mapView.addGestureRecognizer(ulpgr)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapCenterCoordinate = mapView.centerCoordinate
        saveLocation()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var returnedAnnotationView: MKAnnotationView? = nil
        
        if (annotation is Portal) {
            let portal = annotation as! Portal
            let identifier = "Pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                let destinationImage = UIImage(named: "destination")! as UIImage
                let btn = UIButton(type: .Custom)
                btn.frame = CGRectMake(0, 0, 50, 42);
                btn.setBackgroundImage(destinationImage, forState: .Normal)
                view.rightCalloutAccessoryView = btn
            }
            
            view.pinColor = portal.pinColor()
            
            if #available(iOS 9.0, *) {
                if let url = portal.photoURL {
                    let imageView = UIImageView()
                    imageView.frame = CGRectMake(0, 0, 50, 50);
                    imageView.imageFromUrl(url)
                    view.detailCalloutAccessoryView = imageView
                }
            } else {
                // Fallback on earlier versions
            };
            return view
            
        } else if (annotation is Player) {
            let player = annotation as! Player
            let identifier = "Player"
            var playerView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            if playerView == nil {
                playerView = MKAnnotationView(annotation: player, reuseIdentifier: identifier)
                playerView!.canShowCallout = true
                
                let menuImage = UIImage(named: "cleft")! as UIImage
                let btn = UIButton(type: .Custom)
                btn.frame = CGRectMake(0, 0, 40, 40);
                btn.setBackgroundImage(menuImage, forState: .Normal)
                playerView!.rightCalloutAccessoryView = btn
            }
            playerView!.image = UIImage(named:player.imageName)
            return playerView
            
        } else if (annotation is Flag){
            returnedAnnotationView = Flag.createViewAnnotationForMapView(self.mapView, annotation: annotation)
            returnedAnnotationView!.image = UIImage(named: "flag")
            
            let menuImage = UIImage(named: "menu")! as UIImage
            let btn = UIButton(type: .Custom)
            btn.frame = CGRectMake(0, 0, 40, 40);
            btn.setBackgroundImage(menuImage, forState: .Normal)
            returnedAnnotationView!.rightCalloutAccessoryView = btn
            
            let destinationImage = UIImage(named: "cplus")! as UIImage
            let lbtn = UIButton(type: .Custom)
            lbtn.frame = CGRectMake(0, 0, 40, 40);
            lbtn.setBackgroundImage(destinationImage, forState: .Normal)
            returnedAnnotationView!.leftCalloutAccessoryView = lbtn
        }
        
        return returnedAnnotationView
    }

    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.mapView.deselectAnnotation(view.annotation, animated: true)
        
        if (view.annotation is Portal) {
            let location = view.annotation as! Portal
            if (currentPlayer != nil) {
                currentPlayer?.moveToLocation(location.coordinate)
            }
            
        } else if (view.annotation is Flag) {
            let flag = view.annotation as! Flag
            
            if control == view.rightCalloutAccessoryView {
                let alert = UIAlertController(title: currentPlayer?.name, message:flag.title, preferredStyle: .Alert)
                if currentPlayer != nil {
                    alert.addAction(UIAlertAction(title: "Walk here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.currentPlayer?.moveToLocation(flag.coordinate)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Jump here", style: .Default, handler: { (action: UIAlertAction!) in
                        self.currentPlayer?.jumpToLocation(flag.coordinate)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Add Nearby marker", style: .Default, handler: { (action: UIAlertAction!) in
                        self.createNearbyCircle(flag.coordinate)
                        mapView.removeAnnotation(view.annotation!)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction!) in
                    mapView.removeAnnotation(view.annotation!)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true){}
                
            } else {
                if currentPlayer != nil {
                    self.currentPlayer?.moveToLocation(flag.coordinate)
                }
            }
        } else if (view.annotation is Player) {
            let player = view.annotation as! Player
            selectPlayer(player)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1
        circleRenderer.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.2)
        circleRenderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.85)
        
        return circleRenderer
    }
    
    func showMapOnLocation() {
        mapView.setCamera(MKMapCamera(lookingAtCenterCoordinate: mapCenterCoordinate, fromEyeCoordinate: mapCenterCoordinate, eyeAltitude: 500.0), animated: false)
    }
    
    //MARK: NSUserDefaults
    func saveLocation() {
        NSUserDefaults.standardUserDefaults().setObject(["lat":"\(mapCenterCoordinate.latitude)", "lng":"\(mapCenterCoordinate.longitude)"], forKey: "savedLocation")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getSavedMapType() {
        let savedType = NSUserDefaults.standardUserDefaults().integerForKey("mapType")
        currentMapType = savedType
        switch (currentMapType) {
        case 0:
            mapView.mapType = MKMapType.Standard
        case 2:
            mapView.mapType = MKMapType.Satellite
        default:
            mapView.mapType = MKMapType.Hybrid
        }
        mapTypeSegmentedControl.selectedSegmentIndex = currentMapType
    }
    
    func getSavedLocation() -> Bool {
        guard let savedLocation = NSUserDefaults.standardUserDefaults().objectForKey("savedLocation") else {
            return false
        }
        return putCurrentLocationFromDict(savedLocation as! [String : String])
    }
    
    func getPlayersLocationDict() -> [[String:String]] {
        
        var locations = [[String:String]]()
        for player in players {
            locations.append(["lat":"\(player.coordinate.latitude)", "lng":"\(player.coordinate.longitude)"])
        }
        return locations
        //return ["lat":"\(mapCenterCoordinate.latitude)", "lng":"\(mapCenterCoordinate.longitude)"]
    }
    
    func putCurrentLocationFromDict(dict: [String:String]) -> Bool {
        mapCenterCoordinate = CLLocationCoordinate2D(latitude: Double(dict["lat"]!)!, longitude: Double(dict["lng"]!)!)
        return true
    }
    
    //MARK: GestureRecognizer
    func routeMapLongPressSelector(sender: UIPanGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.Began) {
            
            let touchPoint = sender.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = Flag(coordinate: newCoordinates)
            mapView.addAnnotation(annotation)
        }
        
    }
    
    func createNearbyCircle (coord:CLLocationCoordinate2D) {
        let circle:MKCircle = MKCircle(centerCoordinate: mapCenterCoordinate, radius: 1000)
        nearbyCircles.append(circle)
        self.mapView.addOverlay(circle)
    }
    
    @IBAction func removeNearbyCircles () {
        mapView.removeOverlays(nearbyCircles)
    }
    
    func createPlayer (playerName:String) {
        
        if (playerName ?? "").isEmpty {
            let alert = UIAlertController(title: "", message:"Player name required!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true){}
            return
        }
        
        if (players.count >= 2 ) {
            let alert = UIAlertController(title: "", message:"Can't add more player?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true){}
            return
        }
        
        let player = Player(name: playerName, coordinate: mapCenterCoordinate)
        player.delegate = self
        player.imageName = self.players.count % 2 == 0 ? "playerblue" : "playergreen"
        self.players.append(player)

        selectPlayer(player)
        
        mapView.addAnnotation(player)
    }
    
    //MARK: IBActions
    @IBAction func mapTypeChange (sender:AnyObject) {
        let mapType = MKMapType(rawValue: UInt(mapTypeSegmentedControl.selectedSegmentIndex))
        switch (mapType!) {
        case .Standard:
            mapView.mapType = MKMapType.Standard
            currentMapType = 0
        case .Hybrid:
            mapView.mapType = MKMapType.Satellite
            currentMapType = 2
        default:
            mapView.mapType = MKMapType.Hybrid
            currentMapType = 1
        }
        NSUserDefaults.standardUserDefaults().setInteger(currentMapType, forKey: "mapType")
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    @IBAction func addPlayer (sender:AnyObject) {
        let alert = UIAlertController(title: "Add Player?", message:"Add new player on map?", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = "Player name goes here..";
        })
        
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            let textField = alert.textFields![0] as UITextField
            let playerName = textField.text!
            self.createPlayer(playerName)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        
        self.presentViewController(alert, animated: true){}
    }
    
    @IBAction func selectPlayerButtonPressed(sender: UIButton) {
        let tableViewController = UITableViewController()
        let tableView = UITableView()
        
        tableViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
        tableViewController.preferredContentSize = CGSizeMake(300, 100)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableViewController.tableView = tableView
        
        presentViewController(tableViewController, animated: true, completion: nil)
        
        let popoverPresentationController = tableViewController.popoverPresentationController
        popoverPresentationController?.sourceView = sender
        popoverPresentationController?.sourceRect = CGRectMake(0, 0, sender.frame.size.width, sender.frame.size.height)
        popoverPresentationController?.delegate = self
    }
    
    @IBAction func stopPlayer(sender: UIButton) {
        currentPlayer?.stop()
    }
    
    //MARK: UIPopoverPresentationControllerDelegate
    
    func prepareForPopoverPresentation(popoverPresentationController: UIPopoverPresentationController) {
    }
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
    }
    
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
    //MARK: UITableView Delegate & Source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.players.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        cell.textLabel?.text = self.players[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedPlayer = self.players[indexPath.row]
        selectPlayer(selectedPlayer)
    }
    
    //MARK: GCDWebServer
    
    func startWebServer(){
        webServer.addDefaultHandlerForMethod("GET", requestClass: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse.init(JSONObject: self.getPlayersLocationDict())
        })
        webServer.startWithPort(80, bonjourName: "pokemonController")
    }
    
    //MARK: CSVLoader
    func loadCSV() {
        do {
            let csvURL = NSBundle(forClass: ViewController.self).URLForResource("bogor3", withExtension: "csv")!
            let contents = try String(contentsOfURL: csvURL, encoding: NSUTF8StringEncoding)
            let csv = CSwiftV(string: contents)
            let keyedRows = csv.keyedRows!
            
            for dict in keyedRows {
                if let portal = Portal.fromCSV(dict) {
                    self.portals.append(portal)
                }
            }
            
            //let csv = try CSV(url: csvURL)
            
            /*
            csv.enumerateAsDict { dict in
                if let portal = Portal.fromCSV(dict) {
                    self.portals.append(portal)
                }                
            }
            */
        } catch {
            // Catch errors or something
        }
    }
    
    //MARK: Player & PlayerDelegate
    func selectPlayer (player:Player) {
        currentPlayer = player
        selectPlayerButton.setTitle(currentPlayer?.name, forState: .Normal)
    }
    
    func onPlayerMoving (player: Player) {
        self.mapView.viewForAnnotation(player)
    }
    
    func onPlayerMovingStart (player: Player) {

    }
    func onPlayerMovingFinish (player: Player) {

    }

}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if let imageData = data as NSData? {
                    self.image = UIImage(data: imageData)
                }
            }
        }
    }
}

