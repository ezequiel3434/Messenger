//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 31/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> ())?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    private let map: MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        
        if coordinates != nil  {
            self.coordinates = coordinates
            self.isPickable = false
            
        }
        
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            print("Entre al else")
            // just showing location
            guard let coordinates = self.coordinates else { return  }
            // drop a pin on that location
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
        
        
    }
    
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else { return }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    @objc func didTapMap(_ gesture: UITapGestureRecognizer){
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        // drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    
    
    
}
