//
//  CoreDataController.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 21/10/22.
//

import Foundation
import CoreData

class CoreDataController {
    
    let container:NSPersistentContainer
    var viewContext:NSManagedObjectContext {
        return container.viewContext
    }
    
    init(name: String) {
        self.container = NSPersistentContainer(name: name)
    }
    
    func load() {
        container.loadPersistentStores { description, error in
            guard error == nil else {
                fatalError("Error loading Store: \(error!.localizedDescription)")
            }
            self.configureContext()
        }
    }
    
    func configureContext() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    enum CoreDataError: LocalizedError {
        case badSave
        case badFetch
        case badData
        
        var errorDescription: String? {
            switch self {
            case.badSave:
                return "Bad core data save."
            case .badFetch:
                return "Bad data fetch."
            case .badData:
                return "Bad data received."
            }
        }
        var failureReason: String? {
            switch self {
            case .badSave:
                return "Unable to save data."
            case .badFetch:
                return "Unable to retrieve data."
            case .badData:
                return "Bad data received in call."
            }
        }
        var helpAnchor: String? {
            return "Contact developer for prompt and courteous service."
        }
        var recoverySuggestion: String? {
            return "Close app and re-open."
        }
    }
}

extension CoreDataController {

    func performBackgroundOp(completion: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            completion(context)
        }
    }
    
    @discardableResult func saveContext(context:NSManagedObjectContext, completion: @escaping (LocalizedError?) -> Void) -> Bool {
        do {
            try context.save()
            DispatchQueue.main.async {
                completion(nil)
            }
            return true
        } catch {
            DispatchQueue.main.async {
                completion(CoreDataError.badSave)
            }
            return false
        }
    }
    
    func deleteManagedObjects(objects:[NSManagedObject], completion: @escaping (LocalizedError?) -> Void) {
        
        let objectIDs = objects.map {$0.objectID}
        self.performBackgroundOp { context in

            for objectID in objectIDs {
                let privateObject = context.object(with: objectID)
                context.delete(privateObject)
            }
            
            self.saveContext(context: context, completion: completion)
        }
    }
}


extension CoreDataController {
    
    func reloadPin(pin:Pin, completion: @escaping (LocalizedError?) -> Void) {
   
        let objectID = pin.objectID
        performBackgroundOp { context in
            let privatePin = context.object(with: objectID) as! Pin
            privatePin.photoDownloadComplete = false
            privatePin.noPhotosFound = false
            if !self.saveContext(context: context, completion: completion) {
                return
            }
        }

        
        FlickrAPI.geoSearchFlickr(latitude: pin.latitude, longitude: pin.longitude,page:Int.random(in: 1...10)) { searchResults, error in
            
            if let searchResults = searchResults {
                
               
                self.performBackgroundOp { context in
                    let privatePin = context.object(with: objectID) as! Pin
                    
                    
                    if searchResults.isEmpty {
                        privatePin.noPhotosFound = true
                        privatePin.photoDownloadComplete = true
                    } else {
                       
                        for dictionary in searchResults {
                            if let urlString = dictionary.keys.first, let title = dictionary.values.first {
                                
                               
                                let photo = Photo(context: context)
                                photo.urlString = urlString
                                photo.title = title
                                photo.pin = privatePin
                            }
                        }
                    }
                    
                   
                    if self.saveContext(context: context, completion: completion) {
                        if !privatePin.noPhotosFound {
                     
                            self.resumePhotoDownload(pin: privatePin, completion: completion)
                        }
                    } else {
                        return
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(FlickrAPI.FlickerError.badFlickrDownload)
                }
            }
        }
    }
    
  
    func resumePhotoDownload(pin:Pin, completion: @escaping (LocalizedError?) -> Void) {
      
        let objectID = pin.objectID
        self.performBackgroundOp { context in
            
            let privatePin = context.object(with: objectID) as! Pin
            
            
            if var photos = privatePin.photos?.allObjects as? [Photo] {
                photos = photos.sorted(by: {$0.urlString! > $1.urlString!})
                
                for photo in photos {
                    if let urlString = photo.urlString, let url = URL(string: urlString), photo.imageData == nil {
                        do {
                            let data = try Data(contentsOf: url)
                            photo.imageData = data
                            if !self.saveContext(context: context, completion: completion) {
                                return
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion(CoreDataError.badData)
                            }
                            return
                        }
                    }
                }
                
                privatePin.photoDownloadComplete = true
                self.saveContext(context: context, completion: completion)
            }
        }
    }
}

