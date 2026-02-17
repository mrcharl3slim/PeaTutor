//
//  UserProfileExt.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

//
//  UserProfile+Extensions.swift
//  PeaTutorApp
//

import Foundation

extension UserProfile {
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
}
