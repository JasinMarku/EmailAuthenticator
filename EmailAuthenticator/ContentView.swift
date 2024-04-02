//
//  ContentView.swift
//  EmailAuthenticator
//
//  Created by Jasin ‎ on 4/1/24.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @AppStorage("log_status") private var logStatus: Bool = false

    var body: some View {
        if logStatus {
            // Home View
            Home()
        } else {
            Login()
        }
    }
}

#Preview {
    ContentView()
}
