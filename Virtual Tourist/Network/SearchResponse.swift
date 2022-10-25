//
//  SearchResponse.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 20/10/22.
//

import Foundation

struct SearchResponse: Codable {
    let stat: String
    let photos: PhotosResponse
    
    enum CodingKeys: String, CodingKey {
        case stat
        case photos
    }
}

struct PhotosResponse: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    let photo: [PhotoResponse]

    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photo
    }
}

struct PhotoResponse: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
}
