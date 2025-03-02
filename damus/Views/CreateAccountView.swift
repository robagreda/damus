//
//  CreateAccountView.swift
//  damus
//
//  Created by William Casarin on 2022-05-20.
//

import SwiftUI

struct CreateAccountView: View {
    @StateObject var account: CreateAccountModel = CreateAccountModel()
    @StateObject var profileUploadViewModel = ProfileUploadingViewModel()
    
    @State var is_done: Bool = false
    
    func SignupForm<FormContent: View>(@ViewBuilder content: () -> FormContent) -> some View {
        return VStack(alignment: .leading, spacing: 10.0, content: content)
    }
    
    func regen_key() {
        let keypair = generate_new_keypair()
        self.account.pubkey = keypair.pubkey
        self.account.privkey = keypair.privkey!
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: SaveKeysView(account: account), isActive: $is_done) {
                EmptyView()
            }
            
            VStack {
                VStack(alignment: .center) {
                    ProfilePictureSelector(pubkey: account.pubkey, viewModel: profileUploadViewModel, callback: uploadedProfilePicture(image_url:))

                    Text(NSLocalizedString("Public Key", comment: "Label to indicate the public key of the account."))
                        .bold()
                        .padding()
                        .onTapGesture {
                            regen_key()
                        }

                    KeyText($account.pubkey)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            regen_key()
                        }
                }
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DamusColors.adaptableGrey, strokeBorder: .gray.opacity(0.5), lineWidth: 1)
                }
                
                SignupForm {
                    FormLabel(NSLocalizedString("Display name", comment: "Label to prompt display name entry."), optional: true)
                    FormTextInput(NSLocalizedString("Satoshi Nakamoto", comment: "Name of Bitcoin creator(s)."), text: $account.real_name)
                        .textInputAutocapitalization(.words)

                    FormLabel(NSLocalizedString("About", comment: "Label to prompt for about text entry for user to describe about themself."), optional: true)
                    FormTextInput(NSLocalizedString("Creator(s) of Bitcoin. Absolute legend.", comment: "Example description about Bitcoin creator(s), Satoshi Nakamoto."), text: $account.about)
                }
                .padding(.top, 10)

                Button(action: {
                    self.is_done = true
                }) {
                    HStack {
                        Text("Create account now", comment:  "Button to create account.")
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 12, alignment: .center)
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(profileUploadViewModel.isLoading)
                .opacity(profileUploadViewModel.isLoading ? 0.5 : 1)
                .padding(.top, 20)

                LoginPrompt()
            }
            .padding()
        }
        .dismissKeyboardOnTap()
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackNav())
    }
    
    func uploadedProfilePicture(image_url: URL?) {
        account.profile_image = image_url?.absoluteString
    }
}

struct LoginPrompt: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        HStack {
            Text("Already on nostr?", comment: "Ask the user if they already have an account on nostr")
                .foregroundColor(Color("DamusMediumGrey"))

            Button(NSLocalizedString("Login", comment: "Button to navigate to login view.")) {
                self.dismiss()
            }

            Spacer()
        }
    }
}

struct BackNav: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Image("chevron-left")
            .foregroundColor(.white)
        .onTapGesture {
            self.dismiss()
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        let model = CreateAccountModel(real: "", nick: "jb55", about: "")
        return CreateAccountView(account: model)
    }
}

func KeyText(_ text: Binding<String>) -> some View {
    let decoded = hex_decode(text.wrappedValue)!
    let bechkey = bech32_encode(hrp: PUBKEY_HRP, decoded)
    return Text(bechkey)
        .textSelection(.enabled)
        .multilineTextAlignment(.center)
        .font(.callout.monospaced())
        .foregroundStyle(DamusLogoGradient.gradient)
}

func FormTextInput(_ title: String, text: Binding<String>) -> some View {
    return TextField("", text: text)
        .placeholder(when: text.wrappedValue.isEmpty) {
            Text(title).foregroundColor(.gray.opacity(0.5))
        }
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.5), lineWidth: 1)
        }
        .font(.body.bold())
}

func FormLabel(_ title: String, optional: Bool = false) -> some View {
    return HStack {
        Text(title)
                .bold()
        if optional {
            Text("- optional", comment: "Label indicating that a form input is optional.")
                .font(.callout)
                .foregroundColor(DamusColors.mediumGrey)
        }
    }
}

