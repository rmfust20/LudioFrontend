//
//  RegisterView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/19/26.
//

import SwiftUI

struct RegisterView: View {
    let userID: Int
    @EnvironmentObject var auth : Auth
    @EnvironmentObject var userViewModel : UserViewModel
    @State private var username: String = "rmfust309"
    @State private var email : String = "robertfusting@gmail.com5"
    @State private var password: String = "bobee"
    var body: some View {
        Button {
            Task {
                await userViewModel.register(username: username, email: email, password: password, authStore: auth)
            }
        } label: {
            Text("Register")
        }
        
        Button {
            Task {
                await userViewModel.login(username: username, password: password, authStore: auth)
            }
        }
        label : {
            Text("Login")
        }
        
        Button {
            auth.printUsername()
        } label: {
            Text("Press me")
        }
    }
}

#Preview {
    RegisterView(userID: 1)
}
