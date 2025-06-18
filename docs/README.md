# COAR Notify Ruby - Extras

This folder contains additional files that are useful for development, testing, and documentation but are not part of the core gem.

## 📁 **Contents**

### **Example Files**
- **`example.rb`** - Complete usage example showing all library features
- **`test_basic.rb`** - Basic functionality test script
- **`test_compatibility.rb`** - Python-Ruby compatibility tests
- **`test_full.rb`** - Comprehensive test script

### **Documentation**
- **`TESTING_GUIDE.md`** - Complete guide for running tests
- **`TEST_SUMMARY.md`** - Summary of test coverage and results
- **`EXAMPLE_COM_INTEGRATION.md`** - Guide for testing with example.com
- **`REGEX_WARNINGS_FIXED.md`** - Documentation of regex warning fixes

## 🚀 **Usage**

### **Run Example**
```bash
cd extras
ruby example.rb
```

### **Run Basic Tests**
```bash
cd extras
ruby test_basic.rb
```

### **Run Compatibility Tests**
```bash
cd extras
ruby test_compatibility.rb
```

## 📋 **Why These Files Are Here**

These files were moved to `extras/` to keep the main gem directory clean and focused on the core library files. This follows Ruby gem best practices where only essential files are in the root directory.

### **Main Gem Structure (Clean)**
```
coarnotifyrb/
├── lib/                    # Core library code
├── spec/                   # RSpec tests
├── Gemfile                 # Dependencies
├── coarnotify.gemspec      # Gem specification
├── Rakefile               # Build tasks
├── README.md              # Main documentation
└── extras/                # Additional files (this folder)
```

## 🎯 **For Developers**

If you're working on the gem or want to see examples:

1. **Core development**: Work in `lib/` and `spec/`
2. **See examples**: Check files in this `extras/` folder
3. **Run tests**: Use `rspec` in the main directory
4. **See documentation**: Check the various `.md` files here

---

**Note**: These files are not included in the published gem but are available in the source repository for developers and users who want examples and additional documentation.
