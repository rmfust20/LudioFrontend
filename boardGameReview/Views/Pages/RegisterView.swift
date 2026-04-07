//
//  RegisterView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/19/26.
//

import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @EnvironmentObject var auth: Auth
    @EnvironmentObject var userViewModel: UserViewModel

    private enum AuthMode { case signUp, logIn, forgotPassword, resetPassword }
    private enum SignUpStep { case credentials, username }

    @State private var mode: AuthMode = .signUp
    @State private var signUpStep: SignUpStep = .credentials

    // Sign Up
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""

    // Log In
    @State private var loginUsername: String = ""
    @State private var loginPassword: String = ""

    // Apple Sign In (pending username completion)
    @State private var pendingAppleID: String? = nil
    @State private var pendingAppleEmail: String? = nil

    // Forgot / Reset Password
    @State private var forgotEmail: String = ""
    @State private var forgotPasswordSent: Bool = false
    @State private var resetToken: String? = nil
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var resetSuccess: Bool = false

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {

                    // MARK: Branding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color("PrimaryButton").opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "dice.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color("PrimaryButton"))
                        }
                        Text("Ludio")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Track games. Share nights.\nBuild memories.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color("MutedText"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    // MARK: Mode Picker
                    if mode == .forgotPassword || mode == .resetPassword {
                        EmptyView()
                    } else {
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = .signUp
                                errorMessage = nil
                                signUpStep = .credentials
                            }
                        } label: {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(mode == .signUp ? .white : Color("MutedText"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(mode == .signUp ? Color("PrimaryButton") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = .logIn
                                errorMessage = nil
                            }
                        } label: {
                            Text("Log In")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(mode == .logIn ? .white : Color("MutedText"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(mode == .logIn ? Color("PrimaryButton") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Color("CardSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 20)
                    } // end mode picker visibility

                    // MARK: Form Content
                    if mode == .signUp {
                        if signUpStep == .credentials {
                            credentialsStep
                        } else {
                            usernameStep
                        }
                    } else if mode == .logIn {
                        logInForm
                    } else if mode == .forgotPassword {
                        forgotPasswordForm
                    } else {
                        resetPasswordForm
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onOpenURL { url in
            guard url.scheme == "tabulus",
                  url.host == "resetPassword",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "token" })?.value
            else { return }
            resetToken = token
            newPassword = ""
            confirmPassword = ""
            errorMessage = nil
            withAnimation(.easeInOut(duration: 0.2)) { mode = .resetPassword }
        }
    }

    // MARK: - Sign Up: Credentials Step

    private var credentialsStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create your account")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Step 1 of 2")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Email field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(email.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }

                // Password field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    SecureField("", text: $password)
                        .textContentType(.newPassword)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(password.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }
            }

            errorBanner

            // Continue button
            Button {
                validateCredentials()
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("PrimaryButton"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            appleSignInDivider

            appleButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sign Up: Username Step

    private var usernameStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose a username")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("This is how other players will find you")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Username field
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("MutedText"))
                TextField("", text: $username)
                    .textInputAutocapitalization(.never)
                    .textContentType(.username)
                    .foregroundStyle(.white)
                    .tint(Color("PrimaryButton"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color("CardSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(username.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                    )
            }

            errorBanner

            // Create Account button
            Button {
                Task { await registerUser() }
            } label: {
                ZStack {
                    Text("Create Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryButton"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            // Back link
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    signUpStep = .credentials
                    errorMessage = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color("MutedText"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Log In Form

    private var logInForm: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Sign in to continue")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Username field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    TextField("", text: $loginUsername)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(loginUsername.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }

                // Password field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    SecureField("", text: $loginPassword)
                        .textContentType(.password)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(loginPassword.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }
            }

            errorBanner

            // Log In button
            Button {
                Task { await loginUser() }
            } label: {
                ZStack {
                    Text("Log In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryButton"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = .forgotPassword
                    errorMessage = nil
                    forgotEmail = ""
                    forgotPasswordSent = false
                }
            } label: {
                Text("Forgot password?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("MutedText"))
            }
            .buttonStyle(.plain)

            appleSignInDivider

            appleButton
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Forgot Password Form

    private var forgotPasswordForm: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reset password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enter your email and we'll send you a reset link")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if forgotPasswordSent {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Check your email for a reset link")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color.green.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    TextField("", text: $forgotEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(forgotEmail.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }

                errorBanner

                Button {
                    Task { await sendForgotPassword() }
                } label: {
                    ZStack {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .opacity(isLoading ? 0 : 1)
                        if isLoading { ProgressView().tint(.white) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("PrimaryButton"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = .logIn
                    errorMessage = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back to log in")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color("MutedText"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Reset Password Form

    private var resetPasswordForm: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose a new password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enter a new password for your account")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    SecureField("", text: $newPassword)
                        .textContentType(.newPassword)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(newPassword.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("MutedText"))
                    SecureField("", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(confirmPassword.isEmpty ? Color.clear : Color("PrimaryButton").opacity(0.3), lineWidth: 1)
                        )
                }
            }

            errorBanner

            Button {
                Task { await submitResetPassword() }
            } label: {
                ZStack {
                    Text("Reset Password")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryButton"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Shared Apple Components

    private var appleSignInDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color("MutedText").opacity(0.3))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 13))
                .foregroundStyle(Color("MutedText"))
            Rectangle()
                .fill(Color("MutedText").opacity(0.3))
                .frame(height: 1)
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                guard
                    let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                    let tokenData = credential.identityToken,
                    let token = String(data: tokenData, encoding: .utf8)
                else {
                    errorMessage = "Sign in with Apple failed."
                    return
                }
                Task { await handleAppleSignIn(identityToken: token) }
            case .failure:
                errorMessage = "Sign in with Apple failed."
            }
        }
        .signInWithAppleButtonStyle(.whiteOutline)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                Text(error)
                    .font(.system(size: 13))
            }
            .foregroundStyle(Color.red.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func validateCredentials() {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) { signUpStep = .username }
    }

    private func sendForgotPassword() async {
        errorMessage = nil
        let trimmed = forgotEmail.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.contains("@"), trimmed.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        isLoading = true
        defer { isLoading = false }
        _ = await userViewModel.forgotPassword(email: trimmed)
        // Always show success — backend never reveals if email exists
        withAnimation(.easeInOut(duration: 0.2)) { forgotPasswordSent = true }
    }

    private func submitResetPassword() async {
        errorMessage = nil
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard let token = resetToken else {
            errorMessage = "Invalid reset link."
            return
        }
        isLoading = true
        defer { isLoading = false }
        let success = await userViewModel.resetPassword(token: token, newPassword: newPassword)
        if success {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = .logIn
                errorMessage = nil
            }
        } else {
            errorMessage = "Reset link is invalid or has expired."
        }
    }

    private func loginUser() async {
        errorMessage = nil
        guard !loginUsername.trimmingCharacters(in: .whitespaces).isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        defer { isLoading = false }
        await userViewModel.login(username: loginUsername, password: loginPassword, authStore: auth)
        if auth.accessToken == nil {
            errorMessage = "Invalid username or password."
        }
    }

    private func handleAppleSignIn(identityToken: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        let result = await userViewModel.appleSignIn(identityToken: identityToken, authStore: auth)
        switch result {
        case .success:
            break
        case .needsUsername(let appleID, let email):
            pendingAppleID = appleID
            pendingAppleEmail = email
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = .signUp
                signUpStep = .username
            }
        case .failed:
            errorMessage = "Sign in with Apple failed. Please try again."
        }
    }

    private func registerUser() async {
        errorMessage = nil
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please enter a username."
            return
        }
        isLoading = true
        defer { isLoading = false }

        if let appleID = pendingAppleID {
            // Complete Apple sign-in registration
            let success = await userViewModel.appleCompleteRegistration(
                appleID: appleID,
                username: trimmedUsername,
                email: pendingAppleEmail,
                authStore: auth
            )
            if !success {
                errorMessage = "Username already taken. Please choose another."
            }
        } else {
            // Standard email/password registration
            await userViewModel.register(username: trimmedUsername, email: email, password: password, authStore: auth)
            if auth.accessToken == nil {
                errorMessage = "Registration failed. Try a different email or username."
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(Auth())
        .environmentObject(UserViewModel())
}
