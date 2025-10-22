# Security Policy

## Reporting a Vulnerability

The Ultimate team takes the security of our software seriously. If you believe you have found a security vulnerability in Ultimate, we encourage you to report it to us privately.

**Please do not report security vulnerabilities through public GitHub issues.**

### How to Report

1. **GitHub Security Advisories** (Preferred)
   - Go to the [Security tab](https://github.com/sanchaygumber/Ultimate/security/advisories)
   - Click "New draft security advisory"
   - Provide detailed information about the vulnerability

2. **Email** (Alternative)
   - Contact the maintainer through GitHub
   - Use the subject line: "SECURITY: [Brief description]"
   - Include detailed information as described below

### What to Include

Please provide the following information:

- **Type of vulnerability** (e.g., data exposure, injection, authentication bypass)
- **Affected component** (e.g., specific file, feature, or module)
- **Steps to reproduce** the issue
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your name/handle** for credit (optional)

### Example Report

```
Type: Data Exposure
Component: Photo storage (PhotoService.swift)
iOS Version: 17.2
App Version: 1.0.0

Description:
Progress photos are saved without encryption, potentially exposing
sensitive user data if device is compromised.

Steps to Reproduce:
1. Take a progress photo
2. Access device filesystem
3. Photos are visible in plain format

Impact:
User privacy could be compromised if device is lost or accessed
by unauthorized parties.

Suggested Fix:
Implement iOS Data Protection API or encrypt photos before storage.
```

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (see below)

## Severity Levels

### Critical
**Response Time**: 24-48 hours  
**Fix Timeline**: 1-7 days

- Remote code execution
- Unauthorized data access
- Authentication bypass
- Privilege escalation

### High
**Response Time**: 2-7 days  
**Fix Timeline**: 7-14 days

- Local data exposure
- Sensitive information disclosure
- Authorization issues
- Security misconfiguration

### Medium
**Response Time**: 7-14 days  
**Fix Timeline**: 14-30 days

- Information leakage
- Missing security headers
- Weak cryptography
- Known vulnerable dependencies

### Low
**Response Time**: 14-30 days  
**Fix Timeline**: 30-90 days

- Security best practice violations
- Low-impact information disclosure
- Minor security improvements

## Security Update Process

1. **Vulnerability Confirmed**: We validate the reported issue
2. **Fix Developed**: We develop and test a fix
3. **Security Advisory**: We publish a security advisory (if appropriate)
4. **Release**: We release an updated version
5. **Disclosure**: We publicly disclose the issue (after fix is available)

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Best Practices

### For Users

- **Keep Updated**: Always use the latest version
- **Device Security**: Use device passcode/biometrics
- **iOS Updates**: Keep iOS updated to the latest version
- **Permissions**: Only grant necessary permissions
- **Backups**: Enable encrypted backups

### For Contributors

- **Code Review**: All code must be reviewed
- **Dependency Updates**: Keep dependencies current
- **Secure Coding**: Follow secure coding practices
- **Testing**: Include security tests
- **Sensitive Data**: Never commit secrets or keys

## Known Security Considerations

### Data Storage

Ultimate stores data locally using SwiftData, which provides:
- Automatic encryption at rest (iOS Data Protection)
- Sandboxed storage
- No cloud storage by default

**What we store:**
- Challenge and task data
- Progress photos (local filesystem)
- User preferences
- Analytics data (local only)

**What we DON'T store:**
- User credentials (no accounts)
- Payment information (app is free)
- External server data (fully offline)
- Tracking or analytics (privacy-first)

### Permissions

Ultimate requests the following permissions:

```
Required:
- None (app works without any permissions)

Optional:
- Camera: For progress photos
- Photo Library: To save/retrieve photos
- Notifications: For task reminders
- HealthKit: For automatic workout tracking
```

All permissions are:
- Requested only when needed
- Clearly explained to users
- Optional (app works without them)
- Used only for stated purposes

### Network Access

- **No External Servers**: Ultimate operates entirely offline
- **No User Tracking**: No analytics or tracking
- **No Data Collection**: All data stays on device
- **No Third-Party SDKs**: No external dependencies for tracking

### Photo Privacy

Progress photos are:
- Stored locally in app's Documents directory
- Protected by iOS filesystem encryption
- Not backed up to iCloud by default
- Not shared without explicit user action
- Deletable at any time

**Optional Privacy Features:**
- Photo blurring for privacy
- Local-only storage
- No EXIF data extraction
- No facial recognition

### HealthKit Integration

HealthKit data:
- Read-only access (we don't write data)
- Used only for workout tracking
- Never sent to external servers
- Protected by iOS HealthKit privacy
- Optional (app works without it)

## Security Architecture

### Key Security Features

1. **Sandboxed Environment**
   - iOS app sandbox
   - Limited filesystem access
   - Process isolation

2. **Data Protection**
   - SwiftData encryption
   - iOS Data Protection API
   - Secure file storage

3. **No Authentication Required**
   - No passwords to compromise
   - No user accounts
   - No server-side vulnerabilities

4. **Privacy by Design**
   - Local-first architecture
   - No telemetry
   - No user tracking
   - No data mining

### Threat Model

**In Scope:**
- Device compromise
- Local data access
- Photo privacy
- Permission abuse

**Out of Scope:**
- Server-side attacks (no servers)
- Network attacks (offline-first)
- Account takeovers (no accounts)

## Dependency Management

We monitor dependencies for known vulnerabilities:

**Apple Frameworks:**
- SwiftUI (iOS 17+)
- SwiftData (iOS 17+)
- HealthKit (iOS 17+)
- UserNotifications (iOS 17+)

**No Third-Party Dependencies:**
- No external SDKs
- No package dependencies
- Reduced attack surface

## Vulnerability Disclosure Policy

### Our Commitments

- **Acknowledgment**: We acknowledge receipt within 48 hours
- **Investigation**: We investigate all reports thoroughly
- **Communication**: We keep reporters updated
- **Credit**: We credit security researchers (if desired)
- **Transparency**: We publicly disclose fixed vulnerabilities

### Legal Safe Harbor

We support responsible disclosure. Security researchers who:
- Report vulnerabilities privately
- Allow reasonable time for fixes
- Do not exploit vulnerabilities
- Do not access user data
- Follow this policy

Will not face legal action from the Ultimate project.

## Security Checklist for Contributors

Before submitting code:

- [ ] No hardcoded secrets or keys
- [ ] No SQL injection vulnerabilities
- [ ] Proper input validation
- [ ] Secure data storage
- [ ] Appropriate error handling
- [ ] No sensitive data in logs
- [ ] Permissions properly scoped
- [ ] Dependencies are up-to-date
- [ ] Security tests included
- [ ] Documentation updated

## Contact

For security concerns:
- **GitHub**: Use Security tab for advisories
- **General Issues**: Regular GitHub issues (non-security)

---

## Acknowledgments

We thank the following security researchers:

*(This section will be updated as security issues are reported and fixed)*

---

## Updates to This Policy

This security policy may be updated from time to time. Changes will be:
- Documented in git history
- Announced in release notes
- Posted in GitHub Discussions

---

**Last Updated:** January 2025  
**Version:** 1.0.0  
**Project:** Ultimate  
**Maintainer:** Sanchay Gumber  
**License:** Apache-2.0

---

## References

- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Apple Platform Security](https://support.apple.com/guide/security/welcome/web)
- [iOS Security Guide](https://www.apple.com/business/docs/site/iOS_Security_Guide.pdf)

