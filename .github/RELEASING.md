# Release Process for Azure Key Vault Manager

This guide documents the complete process for creating and publishing a new release of Azure Key Vault Manager for macOS distribution.

## Prerequisites

Before starting the release process, ensure you have:

- [ ] All changes committed to the `main` branch
- [ ] Version number updated in `pubspec.yaml`
- [ ] Changelog/release notes drafted
- [ ] All tests passing (`flutter test`)
- [ ] Code analyzed with no errors (`flutter analyze`)
- [ ] Access to GitHub repository with release permissions
- [ ] `create-dmg` installed (optional): `npm install -g create-dmg`
- [ ] GitHub CLI installed (optional): `brew install gh`

## Release Checklist

### Step 1: Update Version Number

1. Edit `pubspec.yaml`:
   ```yaml
   version: X.Y.Z+BUILD_NUMBER
   ```

2. Commit the version change:
   ```bash
   git add pubspec.yaml
   git commit -m "chore: Bump version to vX.Y.Z"
   git push origin main
   ```

### Step 2: Create Git Tag

```bash
# Create annotated tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"

# Push tag to GitHub
git push origin vX.Y.Z
```

### Step 3: Build and Package

Run the build script:

```bash
./scripts/build_macos_release.sh
```

The script will:
1. Clean previous builds
2. Install dependencies
3. Build the macOS app
4. Sign with ad-hoc signature
5. Create DMG installer
6. Generate SHA256 checksum
7. Prompt for manual verification

**Manual Verification Steps:**

- [ ] Open the DMG and verify it mounts correctly
- [ ] Check the app icon and visual appearance
- [ ] Drag the app to a test location
- [ ] Remove quarantine: `xattr -cr "/path/to/Azure Key Vault Manager.app"`
- [ ] Launch the app and verify it opens
- [ ] Test Azure CLI detection
- [ ] Test authentication (login flow)
- [ ] Test Key Vault listing
- [ ] Test creating/viewing secrets
- [ ] Verify no errors in Console.app
- [ ] Test on both Intel and Apple Silicon (if available)

### Step 4: Prepare Release Notes

1. Copy `.github/RELEASE_TEMPLATE.md` to a temporary file
2. Replace all placeholders:
   - `{VERSION}` → Actual version (e.g., 1.0.0)
   - `{BUILD_NUMBER}` → Build number from pubspec.yaml
   - `{SHA256_HASH}` → From `dist/AzureKeyVaultManager-vX.Y.Z.dmg.sha256`
   - `{FILE_SIZE}` → From `ls -lh dist/AzureKeyVaultManager-vX.Y.Z.dmg`
   - `{RELEASE_DATE}` → Current date
3. Fill in "What's New" section with actual changes
4. Update "Known Issues" if applicable
5. Remove any sections that don't apply

### Step 5: Create GitHub Release

#### Option A: Using GitHub CLI (Recommended)

```bash
# Ensure you're logged in
gh auth status

# Create release with draft
gh release create vX.Y.Z \
  dist/AzureKeyVaultManager-vX.Y.Z.dmg \
  dist/AzureKeyVaultManager-vX.Y.Z.dmg.sha256 \
  --title "Azure Key Vault Manager vX.Y.Z" \
  --notes-file release-notes.md \
  --draft

# Review the draft release on GitHub
# When ready, publish:
gh release edit vX.Y.Z --draft=false
```

#### Option B: Using GitHub Web Interface

1. Go to `https://github.com/yourusername/keyvault-ui/releases/new`
2. Select tag: `vX.Y.Z`
3. Release title: `Azure Key Vault Manager vX.Y.Z`
4. Paste your prepared release notes
5. Attach files:
   - `dist/AzureKeyVaultManager-vX.Y.Z.dmg`
   - `dist/AzureKeyVaultManager-vX.Y.Z.dmg.sha256`
6. Check "Set as the latest release"
7. **Save as draft** to review
8. When ready, click **Publish release**

### Step 6: Post-Release Verification

After publishing:

- [ ] Verify release appears on GitHub Releases page
- [ ] Download DMG from GitHub (don't use local copy)
- [ ] Verify SHA256 checksum matches
- [ ] Test installation on a clean Mac (or VM)
- [ ] Verify all download links work
- [ ] Check that release notes display correctly

### Step 7: Announce Release (Optional)

If applicable:
- [ ] Update project website
- [ ] Post announcement on social media
- [ ] Notify users via email/Slack/Discord
- [ ] Update documentation links

## Troubleshooting Release Issues

### Build Script Fails

**Issue**: Script exits with error during build

**Solutions**:
- Check `flutter doctor` for Flutter/Dart issues
- Ensure Xcode command line tools are installed: `xcode-select --install`
- Clean and retry: `flutter clean && ./scripts/build_macos_release.sh`

### Code Signing Fails

**Issue**: `codesign` command fails

**Solutions**:
- Verify Xcode is installed
- Check entitlements file exists: `macos/Runner/Release.entitlements`
- Try manual signing: `codesign -s - -f --deep "build/macos/Build/Products/Release/Azure Key Vault Manager.app"`

### DMG Creation Fails

**Issue**: DMG not created or corrupted

**Solutions**:
- If using `create-dmg`, ensure it's installed: `npm install -g create-dmg`
- Try the hdiutil fallback method (automatically used if create-dmg fails)
- Check disk space: `df -h`
- Verify app bundle exists: `ls -la "build/macos/Build/Products/Release/"`

### GitHub Release Upload Fails

**Issue**: Cannot upload files to GitHub

**Solutions**:
- Check file size (GitHub has 2GB limit per file)
- Verify you have write permissions to the repository
- If using `gh` CLI, ensure you're authenticated: `gh auth login`
- Try uploading via web interface instead

## Release Workflow Summary

```
┌─────────────────────┐
│ Update Version      │
│ in pubspec.yaml     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Commit & Push       │
│ to Main Branch      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Create Git Tag      │
│ (vX.Y.Z)            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Run Build Script    │
│ build_macos_        │
│ release.sh          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Manual Testing      │
│ & Verification      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Prepare Release     │
│ Notes from Template │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Create GitHub       │
│ Release (Draft)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Upload DMG &        │
│ Checksum Files      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Review & Publish    │
│ Release             │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Post-Release        │
│ Verification        │
└─────────────────────┘
```

## Files Generated During Release

```
dist/
├── AzureKeyVaultManager-vX.Y.Z.dmg         # Main distribution file
└── AzureKeyVaultManager-vX.Y.Z.dmg.sha256  # Checksum file
```

## Important Notes

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR** (X): Breaking changes
- **MINOR** (Y): New features, backwards compatible
- **PATCH** (Z): Bug fixes, backwards compatible
- **BUILD** (+N): Build number (optional)

Example: `1.2.3+45`

### Security Considerations

- **Never** include secrets or credentials in release notes
- **Always** verify checksums match between local build and uploaded file
- **Test** the downloaded DMG on a clean system before announcing
- **Review** all code changes since last release

### Rollback Procedure

If you need to rollback a release:

1. **Mark release as pre-release** or **delete** it on GitHub
2. **Communicate** the issue to users
3. **Fix** the problem
4. **Create new release** with patch version bump

### Support After Release

- Monitor GitHub Issues for new problems
- Respond to user questions
- Collect feedback for next release
- Update INSTALL.md if new common issues arise

## Automation Opportunities (Future)

Consider automating with GitHub Actions:
- Trigger builds on tag push
- Run tests before building
- Upload artifacts automatically
- Generate release notes from commits
- Notify on successful release

---

**Last Updated**: 2024-11-18
**Maintained By**: Project Maintainers
