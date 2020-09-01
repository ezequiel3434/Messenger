//
//  ProfileModels.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 01/09/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}


struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let hander: (() -> ())?
}
