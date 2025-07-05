# Krishika (कृषिका) - Agricultural Solutions App

<div align="center">
  <img src="assets/images/logo.png" alt="Krishika Logo" width="200" height="200">
  
  <p align="center">
    <strong>Empowering Farmers with Modern Agricultural Solutions</strong>
  </p>
  
  <p align="center">
    <a href="https://flutter.dev">
      <img src="https://img.shields.io/badge/Flutter-3.6.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
    </a>
    <a href="https://dart.dev">
      <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
    </a>
    <a href="https://github.com/SumitGupta9752/Krishika/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
    </a>
  </p>
  
  <p align="center">
    <a href="#-features">Features</a> •
    <a href="#-installation">Installation</a> •
    <a href="#-usage">Usage</a> •
    <a href="#-contributing">Contributing</a> •
    <a href="#-contact">Contact</a>
  </p>
</div>

---

## 🌱 About Krishika

Krishika, meaning "related to agriculture" in Hindi, is a comprehensive cross-platform e-commerce application specifically designed for the agricultural sector. The app serves as a bridge between farmers and agricultural product suppliers, providing a seamless shopping experience with multilingual support.

### Why Krishika?
- 🎯 **Farmer-Focused**: Designed specifically for agricultural needs
- 🌍 **Multilingual**: Native Hindi and English support
- 📱 **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux
- 🛡️ **Secure**: JWT-based authentication and secure transactions
- 🚀 **Modern**: Built with Flutter and Material Design 3

## ✨ Features

<table>
  <tr>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/shopping-cart.png" width="40">
      <br><strong>E-Commerce Platform</strong>
      <br>Browse products, advanced search, reviews & ratings
    </td>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/globe.png" width="40">
      <br><strong>Multilingual Support</strong>
      <br>English & Hindi with seamless switching
    </td>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/user.png" width="40">
      <br><strong>User Management</strong>
      <br>Registration, authentication, order history
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/smartphone.png" width="40">
      <br><strong>Modern UI/UX</strong>
      <br>Material Design 3, responsive design
    </td>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/shopping-bag.png" width="40">
      <br><strong>Shopping Experience</strong>
      <br>Real-time stock, cart persistence, sharing
    </td>
    <td align="center">
      <img src="https://img.icons8.com/color/48/000000/support.png" width="40">
      <br><strong>Customer Support</strong>
      <br>Multiple contact options, help center
    </td>
  </tr>
</table>

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.6.1+ |
| **Language** | Dart |
| **State Management** | Provider |
| **HTTP Client** | Dio |
| **Local Storage** | SharedPreferences |
| **Authentication** | JWT |
| **UI Components** | Material Design 3 |
| **Animations** | Shimmer |
| **Icons** | Font Awesome Flutter |

## 🚀 Installation

### Prerequisites
- Flutter SDK (3.6.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/SumitGupta9752/Krishika.git
   cd Krishika
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   ```bash
   # Copy the template file
   cp lib/constants.dart.template lib/constants.dart
   
   # Edit lib/constants.dart and update the API base URL
   # static const String apiBaseUrl = 'YOUR_API_BASE_URL_HERE';
   ```

4. **Generate launcher icons**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Screenshots

> **Note**: Add screenshots of your app here to showcase the UI and features

<table>
  <tr>
    <td><img src="screenshots/home.png" width="250" alt="Home Screen"></td>
    <td><img src="screenshots/products.png" width="250" alt="Products"></td>
    <td><img src="screenshots/cart.png" width="250" alt="Cart"></td>
  </tr>
  <tr>
    <td align="center"><strong>Home Screen</strong></td>
    <td align="center"><strong>Product Catalog</strong></td>
    <td align="center"><strong>Shopping Cart</strong></td>
  </tr>
</table>

## 📊 Project Structure

```
lib/
├── main.dart                      # App entry point
├── constants.dart                 # API configuration (ignored by git)
├── models/                        # Data models
│   ├── product.dart              # Product model with localization
│   ├── review.dart               # Review model
│   ├── signup_request.dart       # Authentication models
│   └── auth_response.dart
├── screens/                       # UI screens
│   ├── home_screen.dart          # Main dashboard
│   ├── product_details_screen.dart # Product information
│   ├── cart_screen.dart          # Shopping cart
│   ├── signup_screen.dart        # User registration
│   ├── login_screen.dart         # User authentication
│   ├── profile_screen.dart       # User profile
│   ├── customer_support_screen.dart # Support center
│   ├── about_screen.dart         # App information
│   └── language_settings_screen.dart # Language preferences
├── services/                      # API services
│   └── api_service.dart          # HTTP client wrapper
├── providers/                     # State management
│   └── language_provider.dart    # Language state
├── translations/                  # Localization
│   └── app_translations.dart     # Translation strings
└── assets/                        # Static resources
    └── images/
        └── logo.png              # App logo
```

## 🌐 API Integration

The app integrates with a backend API for:
- User authentication (JWT)
- Product catalog management
- Shopping cart operations
- Order processing
- Review and rating system

**Note**: `lib/constants.dart` is excluded from version control to protect sensitive API configurations.

## 🔧 Configuration

### Environment Setup

1. **Create `lib/constants.dart`** (ignored by Git):
   ```dart
   class Constants {
     static const String apiBaseUrl = 'https://your-api-url.com/api';
   }
   ```

2. **Alternative: Use environment variables**:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://your-api-url.com/api
   ```

## 🎯 Roadmap

- [ ] Push notifications for order updates
- [ ] Offline mode support
- [ ] Advanced analytics dashboard
- [ ] Multi-vendor support
- [ ] AI-powered crop recommendations
- [ ] Weather integration
- [ ] Community forums

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter best practices
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure code is properly formatted (`flutter format .`)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

<div align="center">
  <img src="https://avatars.githubusercontent.com/u/SumitGupta9752?v=4" width="100" style="border-radius: 50%;">
  <br>
  <strong>Sumit Gupta</strong>
  <br>
  <em>Full Stack Developer</em>
  <br><br>
  
  <a href="https://github.com/SumitGupta9752">
    <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
  <a href="mailto:sumitguptacse187@gmail.com">
    <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email">
  </a>
  <a href="https://www.linkedin.com/in/sumit-gupta-4776a627a/">
    <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
  </a>
</div>

## 📞 Support

For support and queries:

<div align="center">
  <a href="mailto:support@krishika.com">
    <img src="https://img.shields.io/badge/Email-support@krishika.com-red?style=for-the-badge&logo=gmail&logoColor=white" alt="Email">
  </a>
  <a href="tel:+919508708003">
    <img src="https://img.shields.io/badge/Phone-+91%2095087%2008003-green?style=for-the-badge&logo=phone&logoColor=white" alt="Phone">
  </a>
  <a href="https://wa.me/919508708003">
    <img src="https://img.shields.io/badge/WhatsApp-+91%2095087%2008003-brightgreen?style=for-the-badge&logo=whatsapp&logoColor=white" alt="WhatsApp">
  </a>
  <a href="https://agro-galaxy.vercel.app/">
    <img src="https://img.shields.io/badge/Website-agro--galaxy.vercel.app-blue?style=for-the-badge&logo=vercel&logoColor=white" alt="Website">
  </a>
</div>

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Agricultural community for inspiration
- Open source contributors
- [Icons8](https://icons8.com) for beautiful icons
- All the farmers who inspire this project

---

<div align="center">
  <strong>Built with ❤️ for farmers and agricultural innovation</strong>
  <br>
  <em>Version 1.0.0 - © 2024 Krishika. All rights reserved.</em>
</div>

<div align="center">
  
  **[⬆ Back to Top](#krishika-कृषिका---agricultural-solutions-app)**
  
</div>
