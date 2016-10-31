//
//  MapVC.swift
//  VirtualTourist
//
//  Created by Corey Baines on 31/10/16.
//  Copyright © 2016 Corey Baines. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UINavigationItem!
    
    
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    
    // Flag for editing mode
    var editingPins = false
    
    // Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
    
        // Create the fetch request
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        
        // Execute the fetch request
        do {
            return try sharedContext.fetch(fetchRequest)
        } catch {
            print("error in fetch")
            return [Pin]()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Flickr Geo-Search"
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.handleLongPress(_:)))
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        // Set the map view delegate
        mapView.delegate = self
        
        addSavedPinsToMap()
    }
    
    // Find all the saved pins and show it on the mapView
    func addSavedPinsToMap() {
        
        pins = fetchAllPins()
        print("Pin count in core data is \(pins.count)")
        
        for pin in pins {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = pin.pinTitle
            mapView.addAnnotation(annotation)
        }
    }
    
    // When the edit button is clicked, show the 'Done' button and flag the editingPins to true
    @IBAction func editClicked(_ sender: UIBarButtonItem) {
        
        if editingPins == false {
            editingPins = true
            navigationItem.rightBarButtonItem?.title = "Done"
            let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.red]
            navigationController?.navigationBar.titleTextAttributes = titleDict as! [String : Any]
            navigationItem.title = "Tap pins to remove"
            
        }
            
        else if editingPins {
            navigationItem.rightBarButtonItem?.title = "Edit"
            navigationItem.title = "Flickr Geo-Search"
            let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.black]
            navigationController?.navigationBar.titleTextAttributes = titleDict as! [String : Any]
            editingPins = false
        }
        
    }
    
    
    // Pressing and holding a point on the map creates a new Pin object and adds it to the map
    // Reference: http://stackoverflow.com/questions/5182082/mkmapview-drop-a-pin-on-touch
    func handleLongPress(_ getstureRecognizer : UIGestureRecognizer){
        
        // If it's in editing mode, do nothing
        if (editingPins) {
            return
        } else {
            
            if getstureRecognizer.state != .began { return }
            
            let touchPoint = getstureRecognizer.location(in: self.mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            let newPin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
            
            // Saving to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Adding the newPin to the pins array
            pins.append(newPin)
            
            // Adding the newPin to the map
            mapView.addAnnotation(annotation)
            
            // Downloading photos for new pin (only download it if it's a new pin)
            FlickrClient.sharedInstance().downloadPhotosForPin(newPin) { (success, error) in print("downloadPhotosForPin is success:\(success) - error:\(error)") }
            
            // Find out the location name based on the coordinates
            let coordinates = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            let geoCoder = CLGeocoder()
            
            geoCoder.reverseGeocodeLocation(coordinates, completionHandler: { (placemark, error) -> Void in
                if error != nil {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                if placemark!.count > 0 {
                    let pm = placemark![0] as CLPlacemark
                    if (pm.locality != nil) && (pm.country != nil) {
                        // Assigning the city and country to the annotation's title
                        annotation.title = "\(pm.locality!), \(pm.country!)"
                    }
                } else {
                    print("Error with placemark")
                }
            })
            
        }
    }
    
    // Mark: - When a pin is tapped, it will transition to the Phone Album View Controller
    
    // Start by updating the view for the annotation. This is necessary because it allows you to intercept taps on the annotation's view (the pin).
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let annotation = view.annotation else { /* no annotation */ return }
        
        let title = annotation.title!
        print(annotation.title!)
        
        selectedPin = nil
        
        for pin in pins {
            
            if annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude {
                
                selectedPin = pin
                
                if editingPins {
                    print("Deleting pin - verify core data is deleting as well")
                    sharedContext.delete(selectedPin!)
                    
                    // Deleting selected pin on map
                    self.mapView.removeAnnotation(annotation)
                    
                    // Save the chanages to core data
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                } else {
                    
                    if title != nil {
                        pin.pinTitle = title!
                        
                    } else {
                        pin.pinTitle = "This pin has no name"
                    }
                    // Move to the Phone Album View Controller
                    self.performSegue(withIdentifier: "PhotoAlbum", sender: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "PhotoAlbum") {
            let viewController = segue.destination as! PhotoVC
            viewController.pin = selectedPin
        }
    }
    
    // Reference: http://stackoverflow.com/questions/33200161/change-map-type-hybrid-satellite-via-segmented-control
    // Change map type (satellite) via segmented control
    @IBAction func segmentedControlAction(_ sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex) {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            mapView.mapType = .standard
        }
        
    }
    
}
