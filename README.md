![OWND Project Logo](https://raw.githubusercontent.com/OWND-Project/.github/main/media/ownd-project-logo.png)

# OWND Project

The OWND Project is a non-profit project that aims to realize more trustworthy communication through the social implementation of individual-centered digital identities.

This project was created as part of the "Trusted Web" use case demonstration project promoted by the Digital Market Competition Headquarters, Cabinet Secretariat.

We will develop a white-label digital identity wallet that complies with international standards and a federated messaging application that supports E2E encryption as open source software, and discuss governance to ensure trust.

[OWND Project Briefing Material](https://github.com/OWND-Project/.github/blob/main/profile/ownd-project.pdf)

[Learn more about Trusted Web](https://trustedweb.go.jp/)

## Project List

### Digital Identity Wallet
- [OWND Wallet Android](https://github.com/datasign-inc/tw2023-wallet-android)
- [OWND Wallet iOS](https://github.com/datasign-inc/tw2023-wallet-ios)

### Issuance of Verifiable Credentials
- [OWND Project VCI](https://github.com/datasign-inc/tw2023-demo-vci)

### Messaging Services
- [OWND Messenger Server](https://github.com/datasign-inc/synapse)
- [OWND Messenger Client](https://github.com/datasign-inc/element-web)
- [OWND Messenger React SDK](https://github.com/datasign-inc/matrix-react-sdk)

# OWND Wallet iOS

## Overview
OWND Wallet iOS is an implementation of a white-label digital identity wallet that complies with international standards. It aims to serve as a foundation for creating various wallet applications and use cases based on the OWND wallet framework, with a strong emphasis on ensuring interoperability among different wallets. The goal is to enable seamless integration and interaction across a diverse range of digital identity applications, fostering innovation and utility in the digital identity space.

## Terminology
- **Verifiable Credential (VC):** A digital identity that can be cryptographically verified.
- **Verifiable Presentation (VP):** A data format used to present VCs to a verifier.
- **OpenID for Verifiable Credential Issuance (OID4VCI):** A standard protocol for issuing VCs. For more information, visit [OID4VCI Specification](https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0-12.html).
- **Self-Issued OpenID Provider v2 (SIOPv2):** A standard protocol for issuing self-signed identities. More details can be found at [SIOPv2 Specification](https://openid.net/specs/openid-connect-self-issued-v2-1_0-13.html).
- **OpenID for Verifiable Presentations (OID4VP):** A standard protocol for issuing VPs. Read more at [OID4VP Specification](https://openid.net/specs/openid-4-verifiable-presentations-1_0-18.html).

## Features
OWND Wallet iOS incorporates a wide array of functionalities designed to enhance the interoperability and usability of digital identities. Below are some of the key features:

- **VC Issuance through OID4VCI Compliance:** Integrates with services compliant with OpenID for Verifiable Credential Issuance (OID4VCI) to issue Verifiable Credentials, ensuring adherence to established digital identity standards.

- **SIOPv2 Compliant Login:** Facilitates login operations with services that are compliant with Self-Issued OpenID Provider v2 (SIOPv2), offering users a secure and standardized method for identity verification and authentication.

- **VP Provision through OID4VP Compliance:** Works with services following the OpenID for Verifiable Presentations (OID4VP) standards to provide Verifiable Presentations, enhancing the trustworthiness and verifiability of shared digital credentials.

- **Account Export/Import for SIOPv2 Logged-in Accounts:** Allows users to export or import their accounts logged in via SIOPv2, enabling easy migration between devices or wallets without compromising the security of the digital identity.

These features underscore OWND Wallet iOS's commitment to security, interoperability, and user-centric design, providing a solid foundation for building diverse digital identity ecosystems.

## Installation and Building

### Cloning the Repository

First, clone the repository to your local machine:

```bash
git clone https://github.com/datasign-inc/tw2023-wallet-ios
cd tw2023-wallet-ios
```

Building the Project
### To build the project, you can use the built-in build functionality of Xcode:

1. Select the target device or simulator from the device dropdown menu at the top of the Xcode window.
2. Click the "Build and run" icon (represented by a play button) or press Command (⌘) + R to build and run the project.

## Running the App
After successfully building the project, the app will automatically run on the selected emulator or connected physical device:

- If using a simulator, choose your preferred device from the device dropdown menu in Xcode.
- If using a physical device, ensure the device is connected to your computer and selected in the device dropdown menu.

## Contributing
Contributions are welcome! The contribution guidelines are currently under consideration. Please check back soon for updates on how you can contribute to this project.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

The MIT License is a permissive license that is short and to the point. It lets people do anything they want with your code as long as they provide attribution back to you and don’t hold you liable.

For more information on the MIT License, please visit [MIT License](https://opensource.org/licenses/MIT).
