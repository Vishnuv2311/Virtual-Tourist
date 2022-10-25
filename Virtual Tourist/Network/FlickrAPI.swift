//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 20/10/22.
//

import Foundation
import CoreLocation

class FlickrAPI{
    
    static let MAX_PHOTOS = 50
    
    struct ApiInfo {
        
        static let API_KEY = "a6066c26667e77d91d9780188e17149d"
        static let API_SECRET = "f111975edc8bcc6d"
        
        static let scheme = "https"
        static let host = "www.flickr.com"
        static let path = "/services/rest/"
        
        static let urlHostBase = "https://live.staticflickr.com/"
    }
    
    enum Endpooints{
        
        case searchGeo(lat: Double, lon: Double)
        
        var url:URL?{
            
            var urlComponents = URLComponents()
            urlComponents.scheme = ApiInfo.scheme
            urlComponents.host = ApiInfo.host
            urlComponents.path = ApiInfo.path
            
            var items : [URLQueryItem] = []
            items.append(URLQueryItem(name: "method", value: "flickr.photos.search"))
            items.append(URLQueryItem(name: "api_key", value: ApiInfo.API_KEY))
            items.append(URLQueryItem(name: "format", value: "json"))
            items.append(URLQueryItem(name: "nojsoncallback", value: "1"))
            
            switch self{
            case .searchGeo(let lat,let lon):
                items.append(URLQueryItem(name: "lat", value: "\(lat)"))
                items.append(URLQueryItem(name: "lon", value: "\(lon)"))
                break
            }
            
            urlComponents.queryItems = items
            
            return urlComponents.url
            
        }
        
    }
    
    
    enum FlickerError:LocalizedError {
        case urlError
        case badFlickrDownload
        case geoError
        
        var errorDescription:String?{
            switch self{
            case .urlError:
                return "Bad Url"
            case .badFlickrDownload:
                return "Flicker Url Not Avilable"
            case .geoError:
                return "Wrong geo location"
                
            }
        }
        
        var failureReason: String? {
            switch self {
            case .urlError:
                return "Possbile bad text formatting."
            case .badFlickrDownload:
                return "Bad data/response from Flickr."
            case .geoError:
                return "Possible invalid coordinates."
            }
        }
        var helpAnchor: String? {
            return "Contact developer for prompt and courteous service."
        }
        var recoverySuggestion: String? {
            return "Close App and re-open."
        }
    }
    
}

extension FlickrAPI{
    
    class func geoSearchFlickr(latitude:Double,longitude:Double,completion: @escaping ([[String:String]]?,LocalizedError?) -> Void){
        
        guard let url = Endpooints.searchGeo(lat: latitude, lon: longitude).url else {
            completion(nil, FlickerError.urlError)
            return
        }
        
        taskGET(url: url, responseType: SearchResponse.self) { response, error in
            guard let response = response else {
                completion(nil, FlickerError.urlError)
                return
            }
            
            completion(createRandomURLStringArray(response: response), nil)
        }
        
        
    }
}

extension FlickrAPI{
    
    class func taskGET<ResponseType:Decodable>(url:URL,responseType:ResponseType.Type,completion: @escaping
                                               (ResponseType?,LocalizedError?)-> Void){
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil,FlickerError.badFlickrDownload)
                }
                return
            }
            
            do{
                let response = try JSONDecoder().decode(responseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response,nil)
                }
            }catch{
                DispatchQueue.main.async {
                    completion(nil,FlickerError.badFlickrDownload)
                }
                return
            }
        }
        
        task.resume()
        
    }
}


extension FlickrAPI{
    
    class func createRandomURLStringArray(response:SearchResponse)->[[String:String]]{
        
        var photos = response.photos.photo
        
        var randomPhotoArray: [PhotoResponse] = []
        
        while(photos.count > 0) && (randomPhotoArray.count < MAX_PHOTOS){
            let randomIndex = Int.random(in: 0..<photos.count)
            randomPhotoArray.append(photos.remove(at: randomIndex))
        }
        
        var dictionary:[String:String] = [:]
        
        for (index, randomPhoto) in randomPhotoArray.enumerated() {
            
            let urlString = ApiInfo.urlHostBase + randomPhoto.server + "/" + randomPhoto.id + "_" + randomPhoto.secret + ".jpg"
            
            let title = (randomPhoto.title == "") ? ("Flick: \(index)") : randomPhoto.title
            
            dictionary[urlString] = title
        }
        
        var urlStringArray:[[String:String]] = []
        for key in dictionary.keys.sorted() {
            if let value = dictionary[key] {
                urlStringArray.append([key:value])
            }
        }
        return urlStringArray
    }
}


extension FlickrAPI {
   
    class func reverseGeoCode(location: CLLocation, completion: @escaping (String?, LocalizedError?) -> Void) {
       
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            
            guard let placeMark = placemarks?.first else {
                DispatchQueue.main.async {
                    completion(nil, FlickerError.geoError)
                }
                return
            }
            
            var name = "Unknown"
            if let local = placeMark.locality {
                name = local
            } else if let local = placeMark.administrativeArea {
                name = local
            } else if let local = placeMark.country {
                name = local
            } else if let local = placeMark.ocean {
                name = local
            }
            DispatchQueue.main.async {
                completion(name, nil)
            }
        }
    }
    
   
    class func getPhotoData(url: URL, completion: @escaping (Data?, LocalizedError?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                
                completion(nil, FlickerError.badFlickrDownload)
                return
            }
            
            completion(data, nil)
        }
        task.resume()
    }
}
