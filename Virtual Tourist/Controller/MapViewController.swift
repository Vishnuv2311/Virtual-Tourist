//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 21/10/22.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController,MKMapViewDelegate {
    
    @IBOutlet weak var mapView:MKMapView!
    
    var dataController:CoreDataController!
    
    var dragAnnotation:PinAnnotaion!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        loadAnnotations()
    }
    
    
    @IBAction func longPressInMapViewDetected(_ sender:Any){
        
        let longPressGr =  sender as! UILongPressGestureRecognizer
        let pressLocation = longPressGr.location(in: mapView)
        let coordinate = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        
        switch longPressGr.state{
        case .began:
            dragAnnotation = PinAnnotaion()
            dragAnnotation.coordinate = coordinate
            mapView.addAnnotation(dragAnnotation)
        case .changed:
            dragAnnotation.coordinate = coordinate
        case .ended:
            configureAnnotation(dragAnnotation)
        default:
            break
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension MapViewController{
    
    func mapView(_ mapView:MKMapView,viewFor annotation:MKAnnotation)->MKAnnotationView?{
        let reUseId = "pinReuseId"
        let pinView:MKMarkerAnnotationView!
        
        if let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reUseId) as? MKMarkerAnnotationView{
            return pinView
        } else {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reUseId)
            
            pinView.canShowCallout = true
            
            let leftAccessory  = UIButton(type: .custom)
            leftAccessory.frame = CGRect(x: 0.0, y: 0.0, width: 22.0, height: 22.0)
            leftAccessory.setImage(UIImage(systemName: "trash.fill"), for: .normal)
            pinView.leftCalloutAccessoryView = leftAccessory
            
            let rightAccessory = UIButton(type: .custom)
            rightAccessory.frame = CGRect(x: 0.0, y: 0.0, width: 22.0, height: 22.0)
            rightAccessory.setImage(UIImage(systemName: "arrowshape.right.fill"), for: .normal)
            pinView.rightCalloutAccessoryView = rightAccessory
            
            pinView.animatesWhenAdded = true
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let annotation = view.annotation as? PinAnnotaion else{
            return
        }
        
        if control == view.leftCalloutAccessoryView{
            dataController.deleteManagedObjects(objects: [annotation.pin]) { error in
                if let error = error {
                    self.showOKAlert(error: error)
                }
            }
            mapView.removeAnnotation(annotation)
        }else{
            performSegue(withIdentifier: "PinSegueID", sender: annotation.pin)
        }
    }
}


extension MapViewController{
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PinSegueID"{
            let controller = segue.destination as! PinViewController
            controller.pin = sender as? Pin
        }
    }
}

extension MapViewController{
    
    fileprivate func loadAnnotations(){
        
        mapView.removeAnnotations(mapView.annotations)
        
        var pins:[Pin]=[]
        let fetchRequest:NSFetchRequest<Pin> = NSFetchRequest(entityName: "Pin")
        do{
            pins = try dataController.viewContext.fetch(fetchRequest)
        }catch{
            showOKAlert(error:CoreDataController.CoreDataError.badFetch)
        }
        
        for pin in pins{
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let annotation = PinAnnotaion()
            annotation.coordinate = coordinate
            annotation.title = pin.name
            annotation.pin = pin
            mapView.addAnnotation(annotation)

            
            if !pin.photoDownloadComplete && !pin.noPhotosFound{
                dataController.resumePhotoDownload(pin:pin){error in
                    if let error = error{
                        self.showOKAlert(error:error)
                    }
                }
            }
        }
    }
    
    
    fileprivate func configureAnnotation(_ annotation:PinAnnotaion){
        
        let coordinate = annotation.coordinate
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        FlickrAPI.reverseGeoCode(location: location) { name, error in
            
            if let name = name{
                annotation.title = name
            }else{
                annotation.title = "Unknown"
            }
            
            let pin = Pin(context:self.dataController.viewContext)
            pin.longitude = coordinate.longitude
            pin.latitude = coordinate.latitude
            pin.name = annotation.title
            annotation.pin = pin
            self.dataController.saveContext(context:self.dataController.viewContext){error in
                if let error = error{
                    self.showOKAlert(error:error)
                }
            }
        }
    }
    
}
