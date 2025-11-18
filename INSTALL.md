# Installing Azure Key Vault Manager on macOS

## Important Security Notice

**This application is not signed with an Apple Developer ID certificate or notarized by Apple.**

This is an open-source project distributed **free of charge** without the Apple Developer Program membership ($99/year). The complete source code is publicly available for inspection and verification on GitHub.

### Why Trust This App?

✅ **Open Source**: All code is publicly available
✅ **No Hidden Functionality**: You can review what the app does
✅ **Active Community**: Changes are reviewed and tracked
✅ **Build From Source**: You can compile it yourself if preferred

### What This Means for You

- macOS Gatekeeper will **block the app** by default
- You'll need to **manually bypass** the security warning
- This is a **one-time setup** - subsequent launches work normally
- The app is **safe to use** but macOS can't verify it automatically

---

## System Requirements

### Required

- **macOS**: 10.15 (Catalina) or later

  - Tested on: macOS 11 (Big Sur), 12 (Monterey), 13 (Ventura), 14 (Sonoma), 15 (Sequoia)
  - Works on both Intel and Apple Silicon (M1/M2/M3) Macs

- **Azure CLI**: Version 2.0 or later

  - Required for all Azure operations
  - See installation instructions below

- **Azure Subscription**: With appropriate permissions
  - Key Vault Contributor role or higher
  - Valid Azure AD credentials

### Recommended

- **Modern macOS**: macOS 13 (Ventura) or later for best experience
- **8GB RAM** minimum, 16GB recommended
- **Active Internet Connection** for Azure API communication

---

## Installation Steps

### Step 1: Install Azure CLI

Azure Key Vault Manager requires Azure CLI to be installed and authenticated.

#### Option A: Install via Homebrew (Recommended)

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Azure CLI
brew install azure-cli

# Verify installation
az --version
```

#### Option B: Download from Microsoft

1. Visit [Azure CLI Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos)
2. Download the installer package
3. Follow the installation wizard
4. Verify installation: `az --version`

#### Authenticate with Azure

```bash
# Login to your Azure account
az login

# Verify you're logged in
az account show

# (Optional) Set default subscription
az account set --subscription "Your Subscription Name"
```

---

### Step 2: Download Azure Key Vault Manager

1. Go to the [**Releases page**](https://github.com/yourusername/azure-keyvault-manager/releases)
2. Download the latest **`AzureKeyVaultManager-v{VERSION}.dmg`** file
3. Optionally, download the **`.sha256`** checksum file for verification

#### Verify Download (Optional but Recommended)

```bash
# Compare checksums to ensure file integrity
shasum -a 256 ~/Downloads/AzureKeyVaultManager-v*.dmg

# The output should match the checksum in the .sha256 file
cat ~/Downloads/AzureKeyVaultManager-v*.dmg.sha256
```

---

### Step 3: Install the Application

1. **Open the DMG file** by double-clicking it
2. **Drag "Azure Key Vault Manager"** to the **Applications** folder
3. **Eject the DMG** (right-click and select "Eject")

---

### Step 4: Bypass macOS Gatekeeper (Required)

Since the app is not notarized by Apple, you must bypass Gatekeeper security. Choose one of the methods below:

#### Method A: Remove Quarantine Flag (RECOMMENDED - Works on All macOS Versions)

This is the most reliable method and works even on macOS Sequoia 15.1+.

**Steps:**

1. Open **Terminal** (Applications → Utilities → Terminal)

2. Run this command:

   ```bash
   xattr -cr "/Applications/Azure Key Vault Manager.app"
   ```

3. Press **Enter** (no output means success)

4. **Launch the app** from Applications by double-clicking

**What this does:**
Removes the quarantine attribute that tells macOS the file was downloaded from the internet, allowing the app to run without Gatekeeper checks.

#### Method B: System Settings Approval (May Not Work on macOS 15.1+)

**Steps:**

1. Try to **open the app** from Applications (it will fail)
2. You'll see: _"Azure Key Vault Manager cannot be opened because the developer cannot be verified"_
3. Click **"Cancel"** or dismiss the dialog
4. Open **System Settings** (or System Preferences on older macOS)
5. Go to **Privacy & Security**
6. Scroll down to the **Security** section
7. You should see a message about Azure Key Vault Manager being blocked
8. Click **"Open Anyway"**
9. Enter your **admin password**
10. Click **"Open"** in the confirmation dialog

**Note:** This method may not work reliably on macOS Sequoia 15.1 due to a system bug. Use Method A if this doesn't work.

#### Method C: Right-Click to Open (Works on macOS 14 and Earlier)

**Steps:**

1. In **Finder**, navigate to **Applications**
2. Find **Azure Key Vault Manager**
3. **Right-click** (or Control-click) the app
4. Select **"Open"** from the menu
5. Click **"Open"** in the confirmation dialog

**Note:** This method was removed in macOS 15.1 Sequoia. Use Method A instead.

---

### Step 5: First Launch

After bypassing Gatekeeper, launch the app:

1. **Open the app** from Applications (double-click normally)
2. The app will check for **Azure CLI installation**
3. If Azure CLI is found and authenticated, you'll see the **dashboard**
4. If not authenticated, follow the **device code authentication flow**

#### Expected First Launch Behavior

- **Azure CLI Check**: The app verifies Azure CLI is installed
- **Authentication Status**: Shows if you're logged into Azure
- **Permission Validation**: Checks if you have Key Vault access
- **Subscription Info**: Displays your current Azure subscription

---

## Troubleshooting

### Issue: "App is damaged and can't be opened"

**Cause:** This is a false positive from macOS Gatekeeper for unsigned apps.

**Solution:**

```bash
# Remove quarantine flag
xattr -cr "/Applications/Azure Key Vault Manager.app"
```

Then launch the app again.

---

### Issue: "Finder does not have permission to open (null)"

**Cause:** macOS Sequoia 15.1 bug when trying right-click → Open method.

**Solution:** Use Method A (Remove Quarantine Flag) instead:

```bash
xattr -cr "/Applications/Azure Key Vault Manager.app"
```

---

### Issue: "Azure CLI not found"

**Cause:** Azure CLI is not installed or not in the system PATH.

**Solution:**

1. **Verify installation:**

   ```bash
   which az
   az --version
   ```

2. **If not installed**, install via Homebrew:

   ```bash
   brew install azure-cli
   ```

3. **If installed but not found**, the app checks these paths:

   - `/usr/local/bin/az`
   - `/opt/homebrew/bin/az` (Apple Silicon)
   - `/usr/bin/az`

4. **Create a symlink** if Azure CLI is in a different location:

   ```bash
   # Find Azure CLI
   which az

   # Create symlink (adjust paths as needed)
   sudo ln -s /path/to/az /usr/local/bin/az
   ```

---

### Issue: "Azure CLI not authenticated"

**Cause:** You haven't logged into Azure CLI.

**Solution:**

```bash
# Login to Azure
az login

# Verify authentication
az account show
```

---

### Issue: App won't open - no error message

**Cause:** Potential permission or entitlement issue.

**Solution:**

1. **Check Console.app for errors:**

   - Open **Console.app** (Applications → Utilities)
   - Filter for "Azure Key Vault Manager"
   - Look for error messages

2. **Verify app signature:**

   ```bash
   codesign -vvv "/Applications/Azure Key Vault Manager.app"
   ```

3. **Try re-installing:**
   - Delete the app from Applications
   - Empty Trash
   - Re-download and install

---

### Issue: "Insufficient permissions to access Key Vault"

**Cause:** Your Azure account doesn't have the required permissions.

**Solution:**

1. **Check your role assignment:**

   ```bash
   az role assignment list --assignee your-email@example.com
   ```

2. **Required permissions:**

   - Key Vault Contributor (recommended)
   - Or specific Key Vault access policies

3. **Request access** from your Azure administrator

---

### Issue: Network connection errors

**Cause:** Firewall or network restrictions blocking Azure API calls.

**Solution:**

1. **Verify Azure CLI connectivity:**

   ```bash
   az account show
   ```

2. **Check required endpoints are accessible:**

   - `login.microsoftonline.com`
   - `management.azure.com`
   - `vault.azure.net`

3. **Check firewall/proxy settings**

---

## Uninstalling

To completely remove Azure Key Vault Manager:

```bash
# Remove the application
rm -rf "/Applications/Azure Key Vault Manager.app"

# Remove application support files (if any)
rm -rf "$HOME/Library/Application Support/Azure Key Vault Manager"

# Remove preferences
rm -f "$HOME/Library/Preferences/com.espaceai.keyvault-manager.plist"

# Remove secure storage (authentication tokens)
# Note: This will log you out
rm -rf "$HOME/Library/Containers/com.espaceai.keyvault-manager"
```

---

## Security Considerations

### What This App Can Access

The app requires the following permissions:

✅ **Network Access** (`com.apple.security.network.client`)

- **Why**: Communication with Azure APIs
- **Scope**: `login.microsoftonline.com`, `management.azure.com`, `vault.azure.net`

✅ **File Access** (`com.apple.security.files.user-selected.read-write`)

- **Why**: Import/export secrets, keys, certificates
- **Scope**: Only files you explicitly select in file dialogs

✅ **Azure CLI Execution** (No App Sandbox)

- **Why**: Execute Azure CLI commands for Key Vault operations
- **Scope**: Only allow-listed Azure CLI commands (no arbitrary shell access)

### What This App Does NOT Access

❌ **No Microphone or Camera**
❌ **No Location Services**
❌ **No Contacts or Calendar**
❌ **No Background Execution** (only runs when open)
❌ **No Analytics or Tracking**
❌ **No Arbitrary Shell Commands** (only allow-listed Azure CLI commands)

### Security Features Built Into The App

🔐 **Input Validation**: All inputs validated before processing
🔐 **Command Injection Prevention**: Azure CLI commands are strictly validated
🔐 **Output Sanitization**: Sensitive data redacted from logs
🔐 **Secure Storage**: Session tokens encrypted in macOS Keychain
🔐 **Allow-listing**: Only pre-approved Azure CLI commands can be executed

### Verifying App Integrity

If you want to verify the app hasn't been tampered with:

1. **Check SHA256 hash** matches the official release:

   ```bash
   shasum -a 256 ~/Downloads/AzureKeyVaultManager-v*.dmg
   ```

2. **Verify signature** (will show ad-hoc):

   ```bash
   codesign -dvvv "/Applications/Azure Key Vault Manager.app"
   ```

3. **Build from source** (ultimate verification):
   ```bash
   git clone https://github.com/yourusername/azure-keyvault-manager
   cd azure-keyvault-manager
   ./scripts/build_macos_release.sh
   ```

---

## Building from Source (Advanced)

If you prefer to build the app yourself:

### Prerequisites

- Xcode Command Line Tools
- Flutter SDK (latest stable)
- Node.js (for create-dmg, optional)

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yourusername/azure-keyvault-manager
cd azure-keyvault-manager

# Install dependencies
flutter pub get

# Build and package
./scripts/build_macos_release.sh

# The DMG will be in the dist/ folder
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development setup.

---

## Frequently Asked Questions

### Why isn't this app notarized?

Apple requires a $99/year Developer Program membership to notarize apps. As an open-source project, we've chosen to distribute without notarization to keep the project free and accessible. The code is fully available for inspection on GitHub.

### Is this app safe to use?

Yes. The app is open source, and you can review all the code. It uses standard Flutter/Dart frameworks and only executes pre-approved Azure CLI commands. The app does not have any hidden functionality, tracking, or malicious code.

### Can I use this app in production?

Yes, but with the understanding that you're bypassing some macOS security features. Review the source code, test thoroughly in your environment, and follow your organization's security policies. Consider building from source for additional assurance.

### Will Apple ever allow this app?

macOS will always show warnings for unsigned apps. This is expected behavior and is the same for all apps distributed without Apple Developer Program membership. The app is safe to use once you bypass Gatekeeper.

### Does this work on Apple Silicon (M1/M2/M3)?

Yes! The app is built as a universal binary and includes native support for Apple Silicon. The ad-hoc signing ensures it runs properly on ARM64 architecture.

### Can I distribute this app to my team?

Yes! This is open source software. You can distribute it to your team, but each user will need to follow the Gatekeeper bypass steps. Consider creating an internal guide with your organization's specific setup requirements.

### How do I update to a new version?

1. Download the new DMG from Releases
2. Drag the new version to Applications (replace old version)
3. Run the quarantine removal command again:
   ```bash
   xattr -cr "/Applications/Azure Key Vault Manager.app"
   ```

---

## Getting Help

### Support Resources

1. **Check this installation guide** for common issues
2. **Review [Troubleshooting](#troubleshooting)** section above
3. **Check existing issues** on GitHub
4. **Open a new issue** if your problem isn't covered
5. **Review Azure CLI documentation** for Azure-specific issues

### Before Reporting an Issue

Please collect this information:

```bash
# macOS version
sw_vers

# Azure CLI version
az --version

# App signature info
codesign -dvvv "/Applications/Azure Key Vault Manager.app"

# Check for errors in Console.app
# (Applications → Utilities → Console)
# Filter for "Azure Key Vault Manager"
```

---

## Privacy

This application:

- **Does not collect** any personal information
- **Does not send** any data to third-party servers (only Azure APIs)
- **Does not include** analytics or tracking
- **Does not phone home** - all operations are local and Azure-only
- **Stores authentication tokens** locally in macOS Keychain (encrypted)

All network communication is exclusively with Azure services using your authenticated Azure CLI credentials.

---

## License

Azure Key Vault Manager is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

---

**Need more help?** [Open an issue on GitHub](https://github.com/yourusername/azure-keyvault-manager/issues)
