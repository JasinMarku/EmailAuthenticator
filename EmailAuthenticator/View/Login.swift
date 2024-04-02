//
//  Login.swift
//  EmailAuthenticator
//
//  Created by Jasin ‎ on 4/1/24.
//

import SwiftUI
import Firebase
import Lottie

struct Login: View {
    // View Properties
    @State private var activeTab: Tab = .login
    @State private var isLoading: Bool = false
    @State private var showEmailVerification: Bool = false
    @State private var emailAAddress: String = ""
    @State private var password: String = ""
    @State private var reEnterPassword: String = ""
    @State private var username: String = ""
    
    // Alert Properties
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    // Forgot Password Properties
    @State public var showResetAlert: Bool = false
    @State private var resetEmailAddress: String = ""
    @AppStorage("log_status") private var logStatus: Bool = false
    
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    
                    
                    TextField("Email Address", text: $emailAAddress)
                        .keyboardType(.emailAddress)
                        .customTextField("person")
                    
                    SecureField(activeTab == .login ? "Password" : "Create Password", text: $password)
                        .customTextField("lock", 0, activeTab == .login ?  10 : 0)
                    
                    if activeTab == .SignUp {
                        SecureField("Re-Enter Password", text: $reEnterPassword)
                            .customTextField("lock", 0, activeTab != .login ?  10 : 0)
                    }
                
                } header: {
                    Picker("", selection: $activeTab) {
                        ForEach(Tab.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 15, trailing: 0))
                    .listRowSeparator(.hidden)
                } footer: {
                    VStack(alignment: .trailing, spacing: 12, content: {
                        if activeTab == .login {
                            Button("Forgot Password?") {
                                showResetAlert = true
                            }
                            .font(.caption)
                            .tint(Color.primary)
                            
                        }
                        
                        Button(action: {
                            loginAndSignUp()
                        }, label: {
                            HStack(spacing: 12) {
                                Text(activeTab == .login ? "Login" : "Create Account")
                                    .foregroundStyle(Color.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.callout)
                            }
                            .padding(.horizontal, 10)
                        })
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .showLoadingIndicator(isLoading)
                        .disabled(buttonStatus)
                        .tint(.indigo.opacity(0.9))
                        .shadow(radius: 10)
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 0, trailing: 0))
                }
                .disabled(isLoading)
            }
            .animation(.easeIn, value: activeTab)
            .listStyle(.insetGrouped)
            .navigationTitle("Welcome Back!")
        }
        .sheet(isPresented: $showEmailVerification, content: {
            EmailVerificationView()
                .presentationDetents([.height(350)])
                .presentationCornerRadius(25)
                .interactiveDismissDisabled()
        })
        .alert(alertMessage, isPresented: $showAlert) { }
        .alert("Reset Password", isPresented: $showResetAlert, actions: {
            TextField("Email Address", text: $resetEmailAddress)

            
            Button("Send Reset Link", role: .destructive, action: sendResetLink)
               
            
            Button("Cancel", role: .cancel) {
                resetEmailAddress = ""
            }
        }, message: {
            Text("Enter the email address")
        })
        .onChange(of: activeTab, initial: false) { oldValue, newValue in
            password = ""
            reEnterPassword = ""
        }
    }
    
    // Email Verification View
    @ViewBuilder
    func EmailVerificationView() -> some View {
        VStack(spacing: 6) {
            GeometryReader { _ in
                if let bundle = Bundle.main.path(forResource: "EmailAnimation", ofType: "json") {
                    LottieView {
                        await LottieAnimation.loadedFrom(url: URL(filePath: bundle))
                    }
                    .playing(loopMode: .loop)
                }
            }
            
            Text("Vertification")
                .font(.title.bold())
            
            Text("We have sent a verification email to your address.\nPlease verify in order to continue")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 25)
        }
        .overlay(alignment: .topTrailing, content: {
            Button("Cancel") {
                showEmailVerification = false
                if let user = Auth.auth().currentUser {
                    user.delete { _ in
                            
                    }
                }
                isLoading = false
            }
            .padding(15)
        })
        .padding(.bottom, 15)
        .onReceive(Timer.publish(every: 2, on: .main, in: .default).autoconnect(), perform: { _ in
            if let user = Auth.auth().currentUser {
                user.reload()
                if user.isEmailVerified {
                    // Email Successfully Verified
                    showEmailVerification = false
                    logStatus = true
                }
            }
        })
    }
    
    func sendResetLink() {
        Task {
            do {
                if resetEmailAddress.isEmpty {
                    await presentAlert("Please enter an email address.")
                    return
                }
                
                isLoading = true
                try await Auth.auth().sendPasswordReset(withEmail: resetEmailAddress)
                await presentAlert("Please check your email inbox, and follow steps provided to reset your password.")
                resetEmailAddress = ""
                isLoading = false
            } catch {
                await presentAlert(error.localizedDescription)
            }
        }
    }
    
    func loginAndSignUp() {
        Task {
            isLoading = true
            do {
                if activeTab == .login {
                    // Logging in
                    let result = try await Auth.auth().signIn(withEmail: emailAAddress, password: password)
                    if result.user.isEmailVerified {
                        // Verified User
                        // Redirect to Home View
                        print("User: \(emailAAddress)\nhas successfully logged in!")
                        logStatus = true
                    } else {
                        // Send Verification Email and Presenting Verification View
                        try await result.user.sendEmailVerification()
                        showEmailVerification = true
                    }
                } else {
                    // Creating New Account
                    if password == reEnterPassword {
                        let result = try await Auth.auth().createUser(withEmail: emailAAddress, password: password)
                        // Sending Verification Email
                        try await result.user.sendEmailVerification()
                        // Showing Email Verification View
                        showEmailVerification = true
                    } else {
                        await presentAlert("Mismatching Password")
                    }
                }
            } catch {
                await presentAlert(error.localizedDescription)
            }
        }
    }
    
    // Presenting Alert
    func presentAlert(_ message: String) async {
        await MainActor.run {
            alertMessage = message
            showAlert = true
            isLoading = false
            resetEmailAddress = ""
        }
    }
    
    // Tab Type
    enum Tab: String, CaseIterable {
        case login = "Login"
        case SignUp = "Sign Up"
    }
    
    // Button Status
    var buttonStatus: Bool {
        if activeTab == .login {
            return emailAAddress.isEmpty || password.isEmpty
        }
        
        return emailAAddress.isEmpty || password.isEmpty || reEnterPassword.isEmpty
    }
    
}

fileprivate extension View {
    
    @ViewBuilder
    func showLoadingIndicator(_ status: Bool) -> some View {
        self
            .animation(.snappy) { content in
                content
                    .opacity(status ? 0 : 1)
                }
            .overlay {
                if status {
                    ZStack {
                        Capsule()
                            .fill(.bar)
                        
                        ProgressView()
                    }
                }
            }
    }
    
    @ViewBuilder
    func customTextField(_ icon: String? = nil, _ paddingTop: CGFloat = 0, _ paddingBottom: CGFloat = 0) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.indigo.gradient)
                    .shadow(color: .indigo, radius: 8)
            }
            
            self
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 15)
        .padding(.top, paddingTop)
        .padding(.bottom, paddingBottom)
        .listRowInsets(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    Login()
}
