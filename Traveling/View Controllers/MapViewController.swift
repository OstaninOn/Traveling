 

import Foundation
import CoreLocation
import MapKit
import UIKit
import RealmSwift


// MARK: - Map View Controller

@available(iOS 14.0, *)
class MapViewController: UIViewController, UISearchBarDelegate {

   let realm = try! Realm()
    
    @IBOutlet weak var searchButtunCastom: UIButton!
    
    @IBAction func searchButton(_ sender: Any) {
      
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Ignoring user
        UIApplication.shared.beginBackgroundTask()
        
        // Activity indicator
        var activityIndicator = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        // Hide search bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
       
        
        // Create search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start {(response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endReceivingRemoteControlEvents()
            
            if response == nil
            {
                print("error")
            }
            else
            {
                // renove annotations
                let annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
                // Getting data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                // Create annotation
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapView.addAnnotation(annotation)
                
                // Zoominng in on annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
   // MARK: - IBOutlets
    //
    @IBOutlet weak var mapView: MKMapView!
    
    var angle = 0
    var timer: Timer!
    var userPinView: MKAnnotationView!
    
    
    // MARK: - Constants
    
    let kDistanceMeters: CLLocationDistance = 500
    
    
    // MARK: - Variables And Properties
    
    var lastAnnotation: MKAnnotation!
    var locationManager = CLLocationManager()
    var userLocated = false
    
    var specimens = try! Realm().objects(Specimen.self)
    
    
    
    // MARK: - IBActions
    //
    @IBAction func addNewEntryTapped() {
        addNewPin()
        
    }
    
    @IBAction func centerToUserLocationTapped() {
        centerToUsersLocation()
        
    }
    
    
    @IBAction func unwindFromAddNewEntry(segue: UIStoryboardSegue) {
        let addNewEntryController = segue.source as! AddNewEntryViewController
        let addedSpecimen = addNewEntryController.specimen!
        let addedSpecimenCoordinate = CLLocationCoordinate2D(
            latitude: addedSpecimen.latitude,
            longitude: addedSpecimen.longitude)
        
        if let lastAnnotation = lastAnnotation {
            mapView.removeAnnotation(lastAnnotation)
        } else {
            for annotation in mapView.annotations {
                if let currentAnnotation = annotation as? SpecimenAnnotation {
                    
                    if currentAnnotation.coordinate.latitude == addedSpecimenCoordinate.latitude &&
                        currentAnnotation.coordinate.longitude == addedSpecimenCoordinate.longitude {
                        mapView.removeAnnotation(currentAnnotation)
                        break
                    }
                }
            }
        }
        
        let annotation = SpecimenAnnotation(
            coordinate: addedSpecimenCoordinate,
            title: addedSpecimen.name,
            subtitle: addedSpecimen.category.name, // icon
            specimen: addedSpecimen)
        
        mapView.addAnnotation(annotation)
        lastAnnotation = nil
        // Here, you remove the last annotation added to the map and replace it with one that shows the specimen’s name and category.
        
    }
    
    
    //
    // MARK: - Private Methods
    
    func populateMap() {
        mapView.removeAnnotations(mapView.annotations)
        // Clear out all the existing annotations on the map to start fresh.
        
        specimens = try! Realm().objects(Specimen.self) // Refresh your specimens property
        
        // Create annotations for each one
        for specimen in specimens { // loop throught them'll
            let coord = CLLocationCoordinate2D(
                latitude: specimen.latitude,
                longitude: specimen.longitude);
            let specimenAnnotation = SpecimenAnnotation(
                coordinate: coord,
                title: specimen.name,
                subtitle: specimen.category.name,
                specimen: specimen)
            mapView.addAnnotation(specimenAnnotation) // Add each specimenAnnotation to the MKMapView.
            
        }
    }
    
    func addNewPin() {

            let specimen = SpecimenAnnotation(coordinate: mapView.centerCoordinate, title: "Пустой", subtitle: "Перетяните в нужную точку")
            
            mapView.addAnnotation(specimen)
            lastAnnotation = specimen

    }
    
    func centerToUsersLocation() {
        let center = mapView.userLocation.coordinate
        let zoomRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: kDistanceMeters, longitudinalMeters: kDistanceMeters)
        
        mapView.setRegion(zoomRegion, animated: true)
    }
    
    //
    // MARK: - View Controller
    //
    override func viewDidLoad() {
        super.viewDidLoad()
       
        populateMap()
        
        title = "Map"
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        locationManager.requestWhenInUseAuthorization()

        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(rotateMe), userInfo: nil, repeats: true)
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        populateMap()
        
        title = "Map"
        
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.startUpdatingLocation()
        }
    
    }

    @objc func rotateMe() {
            angle = angle + 10
            userPinView?.transform = CGAffineTransformMakeRotation( CGFloat( (Double(angle) / 360.0) * 1 ) )
        }
    

    @IBAction func mapTyoesStandart(_ sender: Any) {
    
        let messageMap = UIAlertController(title: "Стиль карты", message: "", preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "Стандарт", style: .default) { [self] (_) in
            mapView.mapType = .standard
            print("Стандарт!")
        }
        let cancelAction = UIAlertAction(title: "Спутник", style: .default) { [self] (_) in
            mapView.mapType = .hybrid
            print("Спутник!")
        }
        messageMap.addAction(okAction)
        messageMap.addAction(cancelAction)
        self.present(messageMap, animated: true)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "NewEntry") {
            let controller = segue.destination as! AddNewEntryViewController
            let specimenAnnotation = sender as! SpecimenAnnotation
            controller.selectedAnnotation = specimenAnnotation
        
        }
    }
 }

 //MARK: - LocationManager Delegate
@available(iOS 14.0, *)
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        status != .notDetermined ? mapView.showsUserLocation = true : print("Authorization to use location data denied")
    }
 }
 
 //MARK: - Map View Delegate
@available(iOS 14.0, *)
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let specimenAnnotation =  annotationView.annotation as? SpecimenAnnotation {
            performSegue(withIdentifier: "NewEntry", sender: specimenAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        
        if newState == .ending {
            view.dragState = .none
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for annotationView in views {
            if (annotationView.annotation is SpecimenAnnotation) {
                annotationView.transform = CGAffineTransform(translationX: 0, y: -500)
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveLinear, animations: {
                    
                    annotationView.transform = CGAffineTransform(translationX: 0, y: 0)
                    
                }, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKUserLocation {
//            let pin = mapView.view(for: annotation) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
//                    pin.image = UIImage(named: "circleColor1")
//                    userPinView = pin
//                    return pin
//
//                } else {
//                    // handle other annotations
//                }
        
        guard let subtitle = annotation.subtitle! else {
            return nil
            
        }
        
        if (annotation is SpecimenAnnotation) {
            
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: subtitle) {
                
                UIView.animate(withDuration: 0.3, delay: 0.3, animations: {
                    annotationView.transform = CGAffineTransform(scaleX: 10, y: 1)
                })
                
                return annotationView
            } else {
                let currentAnnotation = annotation as! SpecimenAnnotation
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: subtitle)
                
                switch subtitle {
                case "Деревья":
                    annotationView.image = UIImage(named: "IconDerevo2")
                case "Дом":
                    annotationView.image = UIImage(named: "IconHome")
                case "Насекомые":
                    annotationView.image = UIImage(named: "IconInsects")
                case "Флора":
                    annotationView.image = UIImage(named: "IconFlora")
                case "Животные":
                    annotationView.image = UIImage(named: "IconAnimals")
                case "Птицы":
                    annotationView.image = UIImage(named: "IconBird")
                case "Синагога":
                    annotationView.image = UIImage(named: "IconSinag")
                case "Часовня":
                    annotationView.image = UIImage(named: "IconHasovnja")
                case "Кастел":
                    annotationView.image = UIImage(named: "IconCastel")
                case "Кафедральный собор":
                    annotationView.image = UIImage(named: "IconSabor")
                case "Православная церковь":
                    annotationView.image = UIImage(named: "IconPravoslavnaja")
                case "Замок":
                    annotationView.image = UIImage(named: "IconZamok2")
                case "Другое":
                    annotationView.image = UIImage(named: "IconUncategorizedd")
                case "Усадьба":
                    annotationView.image = UIImage(named: "IconUsadba")
                case "Парк":
                    annotationView.image = UIImage(named: "IconPark")
                case "Монастырь":
                    annotationView.image = UIImage(named: "IconMonastyr1")
                case "Памятник":
                    annotationView.image = UIImage(named: "IconPamjatnic")
                case "Руины":
                    annotationView.image = UIImage(named: "IconRuiny")
                default:
                    annotationView.image = UIImage(named: "IconUncategorized")
                }
                
                UIView.animate(withDuration: 0.3, delay: 0.3, animations: {
                    annotationView.transform = CGAffineTransform(scaleX: 10, y: 1)
                })
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
                
                let detailDisclosure = UIButton(type: .custom)
                annotationView.rightCalloutAccessoryView = detailDisclosure
                
                if currentAnnotation.title == "Пустой" {
                    let detailDisclosure = UIButton(type: .detailDisclosure)
                    detailDisclosure.tintColor = UIColor.systemRed
                    annotationView.rightCalloutAccessoryView = detailDisclosure
                    annotationView.isDraggable = true
                    
                    UIView.animate(withDuration: 0.3, delay: 0.3, options: .autoreverse, animations: {
                        annotationView.transform = CGAffineTransform(scaleX: 10, y: 1)
                    })

                }
                
                return annotationView
            }
        }
        
        return nil
        
    }
    
 }
