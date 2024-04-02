//
//  EmailAuthenticatorApp.swift
//  EmailAuthenticator
//
//  Created by Jasin ‎ on 4/1/24.
//

import SwiftUI
import Firebase

@main
struct EmailAuthenticatorApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
