# Cool Retro Term - Spanish Keyboard Fix

## 🇪🇸 Fixed for Spanish keyboards!

This is a **one-time fix release** for cool-retro-term that solves the Spanish keyboard issue where `Option+2` didn't produce `@` correctly.

### ✅ What's Fixed:
- **Spanish keyboard**: `Option+2` now produces `@` symbol correctly
- **International keyboards**: Fixed ESC prefix issue with Alt+key combinations
- **Character composition**: Improved Input Method handling

### 📦 Installation (macOS):
1. Download `cool-retro-term.app.zip`
2. Extract and copy to `/Applications/`
3. Launch from Applications or Spotlight

### ⚠️ Disclaimer:
- **Not maintained long-term** - This is a punctual fix
- **Use at your own risk** - Original project appears inactive
- **Based on**: cool-retro-term v1.2.0 by Swordfish90

### 🔧 Technical Details:
Fixed in `qmltermwidget/lib/Vt102Emulation.cpp` - Detection of Alt-generated international characters to skip unnecessary ESC prefix.

### 📋 Original Project:
- GitHub: https://github.com/Swordfish90/cool-retro-term
- Issue: #895 (Spanish keyboard problem)

---
**Built on:** September 29, 2025  
**Fix by:** @eFirewall