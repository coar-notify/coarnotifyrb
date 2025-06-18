# COAR Notify Ruby - Testing Guide

## 🧪 **Running Tests**

### **Unit Tests Only (Recommended)**

To run all unit tests without integration tests:

```bash
# Run all unit tests (excludes integration tests)
rspec spec/ --exclude-pattern="spec/integration/**/*"

# Or use the rake task
rake test
```

This runs **120 unit tests** that test all functionality without requiring external services.

### **Specific Test Categories**

```bash
# Main functionality tests
rspec spec/coarnotify_spec.rb

# Factory pattern recognition tests  
rspec spec/factory_spec.rb

# HTTP client tests
rspec spec/client_spec.rb

# Server framework tests
rspec spec/server_spec.rb

# Validation framework tests
rspec spec/validate_spec.rb

# Model object tests
rspec spec/models_spec.rb
```

## 🌐 **Integration Tests**

Integration tests require a **real COAR Notify inbox** to send HTTP requests to.

### **Setting Up Integration Tests**

#### **Option 1: Use Mock Integration Tests (Recommended)**
```bash
# Set the environment variable to example.com for mock testing
export COAR_NOTIFY_INBOX_URL=http://example.com/inbox

# Run all tests including integration (uses mock HTTP)
rspec spec/
```

#### **Option 2: Use a Real COAR Notify Inbox**
```bash
# Set the environment variable to a real inbox URL
export COAR_NOTIFY_INBOX_URL=https://your-real-inbox.com/inbox

# Run all tests including integration
rspec spec/
```

#### **Option 3: Skip Integration Tests**
```bash
# Unset the environment variable to skip integration tests
unset COAR_NOTIFY_INBOX_URL

# Run only unit tests
rspec spec/ --exclude-pattern="spec/integration/**/*"
```

## ⚠️ **Common Issues**

### **Issue: Want to Test with example.com**

**Solution**: This now works! The integration tests automatically use mock HTTP when you set the URL to example.com:

```bash
# Set to example.com for mock integration testing
export COAR_NOTIFY_INBOX_URL=http://example.com/inbox

# Run all tests (127 tests: 120 unit + 7 integration)
rspec spec/

# Expected result: 127 examples, 0 failures
```

### **Issue: Integration Tests Skipped**

**Problem**: Integration tests are being skipped.

**Cause**: No valid COAR Notify inbox URL is configured.

**Solution**: This is normal behavior. Integration tests require a real inbox:
```bash
# Only run integration tests if you have a real inbox
export COAR_NOTIFY_INBOX_URL=https://your-real-inbox.com/inbox
rspec spec/integration/
```

## 📊 **Test Results**

### **Expected Output for Unit Tests**
```
120 examples, 0 failures
```

### **Expected Output for All Tests (with example.com)**
```
127 examples, 0 failures
```

### **Test Categories**
- **Main Module**: 18 tests
- **Factory**: 15 tests
- **Client**: 10 tests
- **Server**: 14 tests
- **Validation**: 31 tests
- **Models**: 34 tests
- **Integration**: 7 tests (when COAR_NOTIFY_INBOX_URL is set)

## 🔧 **Rake Tasks**

```bash
# Run unit tests only
rake test

# Run all tests including integration (if inbox available)
rake test_all

# Run integration tests only
rake test_integration

# Show test statistics
rake test_stats

# Run RuboCop linting
rake rubocop

# Default task (unit tests + linting)
rake
```

## 🎯 **Best Practices**

1. **Always run unit tests first** to verify core functionality
2. **Only use integration tests** when you have a real COAR Notify inbox
3. **Set COAR_NOTIFY_INBOX_URL to example.com** for mock testing or real URLs for live testing
4. **Use `unset COAR_NOTIFY_INBOX_URL`** to disable integration tests
5. **Check test output** for the expected 120 passing unit tests

## 🚀 **Quick Start**

```bash
# Clone and setup
cd coarnotify-ruby

# Install dependencies (if using bundler)
bundle install

# Run all unit tests
rspec spec/ --exclude-pattern="spec/integration/**/*"

# Expected result: 120 examples, 0 failures
```

## 🔍 **Debugging Tests**

### **Verbose Output**
```bash
# Run with detailed output
rspec spec/ --exclude-pattern="spec/integration/**/*" --format documentation
```

### **Run Single Test File**
```bash
# Test specific functionality
rspec spec/factory_spec.rb --format documentation
```

### **Run Single Test**
```bash
# Test specific example
rspec spec/factory_spec.rb:15 --format documentation
```

---

**Remember**: The unit tests (120 examples) provide complete coverage of all COAR Notify functionality without requiring external services. Integration tests are optional and only needed for end-to-end validation with real inboxes.
