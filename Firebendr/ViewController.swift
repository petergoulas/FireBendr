//
//  ViewController.swift
//  Firebendr
//
//  Created by Kimberley Nikolaevna on 28/7/18.
//  Copyright © 2018 Kimberley Chan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import Foundation

class ViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    MKMapViewDelegate
    {

    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var addFireButton: UIButton!
    @IBOutlet weak var sosButton: UIButton!
    @IBOutlet weak var evacuationButton: UIButton!
    @IBOutlet weak var obstacleButton: UIButton!
    
    var databaseReference: DatabaseReference!
    var coordinates = [EvacuationLocation]()
    var location: CLLocation!
    
    let locationManager = CLLocationManager()
    let imagePicker = UIImagePickerController()
    let closestLocation = EvacuationLocation()
    
    @IBOutlet var evacuationLocations: UIView!
    
    @IBAction func evacuationButtonPressed(_ sender: Any) {
        retrieveEvacLocations()
    }
    
    
    @IBAction func addFireButtonPressed(_ sender: Any) {
        
        //ask user to confirm
        let timestamp = NSDate().timeIntervalSince1970

        let alert = UIAlertController(title: "Confirm Fire Sighting", message: "Are you sure? Making a false report is a criminal offence and can result in persecution", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            self.databaseReference = Database.database().reference()

            let key = self.databaseReference.child("reports").childByAutoId()
            let values = ["latitude": self.location.coordinate.latitude, "longitude": self.location.coordinate.longitude, "timestamp": timestamp] as [String: Any]

            self.databaseReference.child("reports").child(key.key).setValue(values, withCompletionBlock: { (error, reference) in
                
                if error == nil {
                    //annotates location
                    let annotation = MKPointAnnotation()
                    let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(self.location.coordinate.latitude, self.location.coordinate.longitude)
                
                    annotation.coordinate = location
                    annotation.title = "Wild Fire Reported"
                    annotation.subtitle = "Evacuate Immediately"
                
                    self.mapView.addAnnotation(annotation)
                    self.mapView.showsUserLocation = false
                    
                    self.retrieveEvacLocations()
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBOutlet var tipsView: UIView!
    @IBOutlet var someoneIsInjured: UIView!
    @IBOutlet var selfInjury: UIView!
    
    @IBAction func backButtonPressed(_ sender: Any) {
        tipsView.removeFromSuperview()
        someoneIsInjured.removeFromSuperview()
        selfInjury.removeFromSuperview()
        evacuationLocations.removeFromSuperview()
    }
    
    @IBAction func informationButtonPressed(_ sender: Any) {
        self.view.addSubview(self.evacuationLocations)
    }
    
    @IBAction func obstacleButtonPressed(_ sender: Any) {

        let obstacle = CLLocationCoordinate2DMake(self.location.coordinate.latitude, self.location.coordinate.longitude)
        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = obstacle
        dropPin.title = "fallen tree"
        mapView.addAnnotation(dropPin)

    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKPointAnnotation {
//            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "")
//            annotationView.image = #imageLiteral(resourceName: "barrier (2).png")
//            return annotationView
//        } else {
//            return nil
//        }
//    }
    
    @IBAction func sosButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Choose Next Step", message: "What are you sending help for?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "I am trapped.", style: .default, handler: {(action) in
            
            let confirmation = UIAlertController(title: "Confirm Action", message: "Are you sure? Making a false report is a criminal offence and can result in persecution.", preferredStyle: .alert)
            
            confirmation.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                
                let reference = Database.database().reference().child("SOS")
                let sosID = reference.childByAutoId().key
                
                reference.child(sosID).setValue(["latitude": self.location.coordinate.latitude,
                                                 "longitude": self.location.coordinate.longitude,
                                                 "message": "SOS, injury."] as [String: AnyObject], withCompletionBlock: { (error, reference) in
                                                    if error == nil {
                                                        self.view.addSubview(self.tipsView)
                                                        self.tipsView.center = self.view.center
                                                    }
                })
            }))
            
            confirmation.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(confirmation, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Someone is injured.", style: .default, handler: {(action) in
            
            let confirmation = UIAlertController(title: "Confirm Action", message: "Are you sure? Making a false report is a criminal offence and can result in persecution.", preferredStyle: .alert)
            
            confirmation.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                
                let reference = Database.database().reference().child("SOS")
                let sosID = reference.childByAutoId().key
                
                reference.child(sosID).setValue(["latitude": self.location.coordinate.latitude,
                                                 "longitude": self.location.coordinate.longitude,
                                                 "message": "SOS, someone is injured. Need assistance asap."] as [String: AnyObject], withCompletionBlock: { (error, reference) in
                                                    if error == nil {
                                                        self.view.addSubview(self.someoneIsInjured)
                                                        self.someoneIsInjured.center = self.view.center
                                                    }
                })
                
            }))
            
            confirmation.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(confirmation, animated: true, completion: nil)
            
            }))
        
        alert.addAction(UIAlertAction(title: "I am injured.", style: .default, handler: {(action) in
            
            let confirmation = UIAlertController(title: "Confirm Action", message: "Are you sure? Making a false report is a criminal offence and can result in persecution.", preferredStyle: .alert)
            
            confirmation.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                let reference = Database.database().reference().child("SOS")
                let sosID = reference.childByAutoId().key
                
                reference.child(sosID).setValue(["latitude": self.location.coordinate.latitude,
                                                 "longitude": self.location.coordinate.longitude,
                                                 "message": "SOS, victim is injured."] as [String: AnyObject], withCompletionBlock: { (error, reference) in
                                                    if error == nil {
                                                        self.view.addSubview(self.selfInjury)
                                                        self.selfInjury.center = self.view.center
                                                    }
                })
            }))
            
            confirmation.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(confirmation, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func cameraSelected() { //if user chooses the camera as a picture source
        imagePicker.allowsEditing = false
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.modalPresentationStyle = .fullScreen
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        self.location = locations[0]
        
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
        
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        mapView.setRegion(region, animated: true)
        
        self.mapView.showsUserLocation = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    func calculateDistance(x1: CLLocationDegrees!, x2: CLLocationDegrees!, y1: CLLocationDegrees!, y2: CLLocationDegrees!) -> CLLocationDegrees {
        
        let distance = sqrt(pow(x2-x1, 2) + pow(y2-y1, 2))
        
        return distance
    }
    
    func retrieveEvacLocations() {
        
        let reference = Database.database().reference().child("evacuation locations")
        
        reference.observeSingleEvent(of: .value) { (snapshot) in
            
            if let entries = snapshot.value as? [String: AnyObject] {
                for (_, properties) in entries {
                    let currentEvacLocation = EvacuationLocation()
                    
                    currentEvacLocation.name = properties["location"] as! String
                    currentEvacLocation.latitude = properties["latitude"] as! CLLocationDegrees
                    currentEvacLocation.longitude = properties["longitude"] as! CLLocationDegrees
                    
                    self.coordinates.append(currentEvacLocation)
                }
                
                var minDist = 1000.000
                for item in self.coordinates {
                    let distance = self.calculateDistance(x1: -37.176802, x2: item.latitude, y1: 142.521794, y2: item.longitude)
                    
                    item.distance = distance
                    
                    if item.distance < minDist {
                        minDist = item.distance

                        let annotation = MKPointAnnotation()
                        
                        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(item.latitude, item.longitude)
                        
                        annotation.coordinate = location
                        annotation.title = "Evacuation Centre"
                        self.mapView.addAnnotation(annotation)
                        
                        let alert = UIAlertController(title: "Evacuation Location Found", message: "We found you the closest evacuation location based on your location. Depart as soon as possible as wildfires can be very unpredictable!", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
            }
        }
    }

}

