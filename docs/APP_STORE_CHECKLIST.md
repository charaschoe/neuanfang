# App Store Release Checklist

## 🚨 Critical Requirements (Must Complete Before Submission)

### ✅ Completed
- [x] Privacy Policy created (`neuanfang-umzugshelfer/Resources/PrivacyPolicy.md`)
- [x] Terms of Service created (`neuanfang-umzugshelfer/Resources/TermsOfService.md`)
- [x] MIT License file exists
- [x] Core Data encryption implemented
- [x] CloudKit integration configured
- [x] Input validation documented
- [x] CodeQL security scanning configured

### ❌ Missing - Required for Submission

#### 1. App Icons
**Status:** 🔴 CRITICAL - NO ICON FILES EXIST  
**Location:** `neuanfang-umzugshelfer/Resources/Assets.xcassets/AppIcon.appiconset/`

Required icon sizes (all PNG format):
- iPhone: 40x40, 60x60, 58x58, 87x87, 80x80, 120x120, 180x180
- iPad: 20x20, 29x29, 40x40, 76x76, 152x152, 167x167
- App Store: 1024x1024 (MANDATORY)

**Action:** Generate or create all icon files with moving/box-themed design.

#### 2. App Store Screenshots
**Status:** 🔴 CRITICAL - REQUIRED FOR SUBMISSION

Requirements:
- iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796px
- iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688px
- iPad Pro 12.9" (6th gen): 2048 x 2732px

Screenshots should show:
1. Room overview with statistics
2. Box management with QR codes
3. Item photography and AI recognition
4. Timeline/planning view
5. Collaboration features

#### 3. App Store Metadata
**Status:** 🔴 CRITICAL

Required in German:
- App title (max 30 chars)
- Subtitle (max 30 chars)
- Keywords (max 100 chars, comma-separated)
- Description (max 4000 chars)
- What's New notes for version 1.0
- Support URL
- Marketing URL

#### 4. Xcode Build Configuration
**Status:** 🟠 VERIFY REQUIRED

Check:
- [ ] Development Team assigned
- [ ] Bundle ID matches App Store Connect
- [ ] CloudKit capability configured with container
- [ ] NFC Tag Reading capability enabled
- [ ] Camera usage capability enabled
- [ ] All required Info.plist usage descriptions present

## 🟡 Recommended Before Release

### 5. Localization
**Status:** 🟠 RECOMMENDED for German market

- Create `Base.lproj/Localizable.strings` with all app text
- Extract hardcoded German strings from SwiftUI views
- Setup for future English localization

### 6. Testing
**Status:** 🟠 EXPAND COVERAGE

- UI tests for critical user flows
- Integration tests for CloudKit sync
- Accessibility testing
- Performance testing for large datasets

### 7. Beta Testing
**Status:** 🟡 RECOMMENDED

- TestFlight setup
- Beta tester recruitment
- Bug reporting template
- Feature feedback collection

## 📋 Next Steps

### Immediate Actions
1. Generate App Icons (especially 1024x1024)
2. Create App Store screenshots mockups
3. Write App Store description and metadata
4. Verify and fix Xcode build configuration

### Before Submission
1. Test on physical devices
2. Run all automated tests
3. Perform accessibility review
4. Create TestFlight beta release
5. Gather beta tester feedback

### Post-Launch
1. Monitor crash reports
2. Collect user feedback
3. Plan version 1.1 improvements
4. Expand localization if needed

## 🎯 Estimated Timeline

- **Phase 1 (Submission Ready):** 1-2 weeks
  - App icons, Screenshots, Metadata, Build config
  
- **Phase 2 (Professional Release):** 2-3 weeks
  - Testing expansion, Beta program
  
- **Phase 3 (Market Optimization):** 3-4 weeks
  - ASO, Marketing materials

---

*Last Updated: October 17, 2025*
