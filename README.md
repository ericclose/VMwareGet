# VMwareGet (io.github.vmwareget)

> **VMware Download & Account Companion App**  
> Cross-Platform Desktop & Mobile Client engineered with Flutter (v3.47.7) and Material Design 3.

---

## 1. Overview & Capabilities

**VMwareGet** provides a streamlined, native interface for authenticating with the Broadcom ecosystem, managing user sessions, browsing software catalogs, and downloading/verifying official installation packages for **VMware Workstation Pro** and **VMware Fusion**, complete with detailed metadata (**File Name**, **Release Date**, **Last Updated**, **SHA2 (SHA-256)**, and **MD5**).

- **App ID / Bundle ID:** `io.github.vmwareget`
- **Framework SDK:** Flutter strictly pinned to `3.47.7`
- **Design System:** Material Design 3 (MD3) with dynamic color seed generation, responsive `NavigationRail`/`NavigationBar`, and smooth Light & Dark mode support.
- **Platforms Supported:** macOS, Windows, Linux, and Android.

---

## 2. Key Features

### 2.1 First-Time Launch & Authentication Flow
- **Splash & Onboarding Gate:** Checks for active session tokens on startup. If unauthenticated, directs user to the onboarding gate.
- **Broadcom Authentication:** Direct buttons to launch official Broadcom login and account registration portals.
- **Session Persistence:** Successfully authenticated session cookies and OAuth tokens are securely stored using encrypted local storage (`flutter_secure_storage` with fallback persistence).
- **Instant Demo Session:** Allows immediate exploration and testing of product catalogs and verification flows.

### 2.2 100% Dynamic Online Catalog & Broadcom API Sync
- **Zero Hardcoded Catalog:** The application contains zero hardcoded release metadata or static fallback entries. All releases and checksums are fetched 100% dynamically from Broadcom's servers upon session connection.
- **Live Online Sync:** Dynamically queries official Broadcom API endpoints:
  - `POST /group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50`
  - Retrieves real-time release versions, build numbers, file sizes, SHA2 (SHA-256), and MD5 checksums.
- **Product Toggle:** Switch between **VMware Workstation Pro** (Windows `.exe`, Linux `.bundle`) and **VMware Fusion** (macOS Universal `.dmg`).
- **Comprehensive Metadata Panel:** Displays:
  - **File Name**
  - **Release Date**
  - **Last Updated**
  - **SHA2 Checksum (SHA-256)** with one-click copy
  - **MD5 Checksum** with one-click copy
  - Build numbers, installer sizes, and licensing notes.
  - "Live Cloud" status badge for items fetched in real-time.

### 2.3 Download Manager & Dynamic Order Generation
- **Dynamic Download Order Generation:** Integrates official Broadcom endpoint:
  - `POST /group/ecx/productfiles/-/productFiles/createProductDownloadOrder`
  - Automatically generates authorized signed CDN URLs with EULA acknowledgment (`eulaId: 17290717`) and CSRF validation (`x-csrf-token`).
- **Live Transfer Metrics:** Real-time downloaded bytes, total size, percentage progress, speed (MB/s), and ETA.
- **Pause & Resume:** Resume interrupted downloads using HTTP `Range` headers.
- **Automated Checksum Verification:** Streamed chunked calculation of SHA-256 and MD5 upon download completion, immediately validating against official Broadcom hashes.
- **File Management:** "Show in Folder", "Open Installer", and "Re-verify Hash" actions.

---

## 3. Project Structure

```
VMwareGet/
├── .github/
│   └── workflows/
│       └── build.yml               # Multi-platform CI/CD (macOS, Win, Linux .deb/.rpm, Android)
├── lib/
│   ├── main.dart                   # Application entry point with Provider and MD3 setup
│   ├── models/
│   │   ├── vmware_product.dart     # Product family, version, platform, & metadata attributes
│   │   ├── download_item.dart      # Download transfer state & verification status
│   │   └── auth_session.dart       # Encrypted user session model
│   ├── services/
│   │   ├── auth_service.dart       # Broadcom authentication & secure storage
│   │   ├── catalog_service.dart    # Official releases with SHA256 & MD5 checksums
│   │   ├── download_service.dart   # Dio download manager with pause/resume & verification
│   │   └── checksum_service.dart   # Stream-based SHA256 & MD5 verification
│   ├── providers/
│   │   ├── auth_provider.dart      # Authentication state notifier
│   │   ├── catalog_provider.dart   # Product toggle & search filters
│   │   ├── download_provider.dart  # Active transfers & file actions
│   │   └── theme_provider.dart     # Material 3 light/dark mode switcher
│   ├── views/
│   │   ├── auth_gate.dart          # Session verification on launch
│   │   ├── onboarding_view.dart    # Welcome & sign-in gate
│   │   ├── login_dialog.dart       # Broadcom credentials / session dialog
│   │   ├── dashboard_view.dart     # Primary shell with NavigationRail / NavigationBar
│   │   ├── catalog_view.dart       # Responsive catalog list & split view
│   │   ├── metadata_panel.dart     # Detailed technical metadata inspector
│   │   ├── downloads_view.dart     # Active transfers & history
│   │   └── settings_view.dart      # Account details & appearance settings
│   ├── widgets/
│   │   ├── app_logo.dart           # Branded MD3 logo
│   │   ├── checksum_badge.dart     # Hash display with copy button
│   │   ├── product_card.dart       # Release selector card
│   │   └── download_progress_tile.dart # Live progress tile with actions
│   └── utils/
│       ├── constants.dart          # App endpoints, keys, and IDs
│       └── formatters.dart         # Byte & date formatters
├── scripts/
│   └── build_host.sh               # Local build script targeting current host OS
├── test/
│   ├── catalog_service_test.dart   # Validates metadata presence and searching
│   └── checksum_service_test.dart  # Validates cryptographic hash verification
├── pubspec.yaml                    # Pinned to Flutter 3.47.7 with latest dependencies
└── analysis_options.yaml           # Linting rules
```

---

## 4. Local Build & Host OS Targeting

Executing local builds automatically compiles exclusively for the host operating system:

```bash
# Run host OS build script
./scripts/build_host.sh

# Or directly:
./build.sh
```

| Current Host OS | Compile Target Run | Output Location |
| :--- | :--- | :--- |
| **macOS** | `flutter build macos --release` | `build/macos/Build/Products/Release/VMwareGet.app` |
| **Windows** | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| **Linux** | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

---

## 5. Automated CI/CD Pipeline (GitHub Actions)

The repository includes `.github/workflows/build.yml` configured to trigger on version tags (`v*`) and manual workflow dispatches:

1. **macOS (`.dmg`)**: Builds native `.app` and packages a mountable `.dmg`.
2. **Windows (`.exe`)**: Builds Windows x64 binary and bundles into installer/zip.
3. **Linux - Debian (`.deb`)**: Builds Linux desktop binary and creates standard Debian package with desktop launcher and icons.
4. **Linux - Fedora (`.rpm`)**: Builds Linux desktop binary and builds native `.rpm` via `rpmbuild`.
5. **Android (`.apk`)**: Compiles signed release APK.
6. **Publish Release**: Gathers all artifacts and publishes a GitHub Release under the pushed version tag.
