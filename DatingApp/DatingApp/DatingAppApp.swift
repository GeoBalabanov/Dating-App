//
//  DatingAppApp.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

@main
struct DatingAppApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MessagingHomeView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}


