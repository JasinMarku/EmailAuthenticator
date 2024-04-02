//
//  Home.swift
//  EmailAuthenticator
//
//  Created by Jasin ‎ on 4/1/24.
//

import SwiftUI
import Firebase

struct Home: View {
    @AppStorage("log_status") private var logStatus: Bool = false
    var body: some View {
        NavigationStack {
            Button("Logout") {
                try? Auth.auth().signOut()
                logStatus = false
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    Home()
}
