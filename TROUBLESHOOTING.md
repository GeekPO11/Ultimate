# Troubleshooting Guide

Common issues and solutions for the Ultimate project.

---

## Upload/Publishing Issues

### Error: "File '.DS_Store' is incomplete"

**Problem**: macOS creates hidden `.DS_Store` files in every folder to store view preferences. These files can cause upload failures.

**Solution**: ✅ **FIXED**

```bash
# Remove all .DS_Store files
find . -name ".DS_Store" -type f -delete

# Verify they're gone
find . -name ".DS_Store" -type f
```

**Prevention**: The `.gitignore` file already includes `.DS_Store`, so new ones won't be committed.

**To prevent macOS from creating them globally** (optional):
```bash
# Disable .DS_Store creation on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable .DS_Store creation on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
```

---

## Build Issues

### Error: "Development Team not found"

**Problem**: The project file contains a placeholder Development Team ID.

**Solution**: See [SETUP.md](SETUP.md#step-3-configure-development-team) for detailed instructions.

Quick fix:
1. Open project in Xcode
2. Select Ultimate target
3. Signing & Capabilities tab
4. Select your Team from dropdown

---

## Git Issues

### Error: "Large files in repository"

**Problem**: Binary files (like compiled builds) accidentally committed.

**Solution**:
```bash
# Remove from git but keep local file
git rm --cached path/to/large/file

# Add to .gitignore
echo "path/to/large/file" >> .gitignore

# Commit the removal
git commit -m "chore: remove large file from repository"
```

---

## Common macOS Hidden Files

The following files are automatically excluded by `.gitignore`:

- `.DS_Store` - Folder view settings
- `.AppleDouble` - Resource fork files
- `.LSOverride` - Launch Services override
- `._*` - Metadata files
- `.Spotlight-V100` - Spotlight index
- `.Trashes` - Trash folder
- `.VolumeIcon.icns` - Custom folder icons

---

## Upload Checklist

Before uploading to any platform (figshare, zenodo, GitHub, etc.):

- [ ] Remove all `.DS_Store` files
- [ ] Check for other hidden files: `ls -la`
- [ ] Verify `.gitignore` is working
- [ ] Test build compiles
- [ ] Run tests
- [ ] Review file list before upload

---

## Platform-Specific Issues

### Figshare Upload

**Issue**: Files marked as "incomplete"

**Common Causes**:
- Hidden macOS files (`.DS_Store`, `._*`)
- Zero-byte files
- Symbolic links
- Files with special characters in names

**Solution**:
```bash
# Find potentially problematic files
find . -type f -size 0          # Zero-byte files
find . -type l                   # Symbolic links
find . -name "._*"              # Metadata files
find . -name ".DS_Store"        # macOS files
```

---

## Quick Reference Commands

```bash
# Clean all macOS hidden files
find . -name ".DS_Store" -type f -delete
find . -name "._*" -type f -delete

# Check what would be uploaded (git)
git status
git ls-files

# Verify .gitignore is working
git check-ignore -v filename

# Force remove from git history (use with caution)
git filter-branch --tree-filter 'rm -f .DS_Store' --prune-empty HEAD
```

---

## Getting Help

If you encounter an issue not listed here:

1. **Check Documentation**:
   - [README.md](README.md) - General overview
   - [SETUP.md](SETUP.md) - Development setup
   - [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guide

2. **Search Issues**: Check [GitHub Issues](https://github.com/sanchaygumber/Ultimate/issues)

3. **Ask for Help**: [Open a new issue](https://github.com/sanchaygumber/Ultimate/issues/new)

---

**Last Updated**: January 2025  
**Maintainer**: Sanchay Gumber

