# 💧 Water Buddy

> Hourly hydration reminder — an animated character walks across your screen every hour asking **"Have you had water?"**

Built with Swift using `Cocoa` + `SceneKit`. Runs as a lightweight menu bar app.

---

## ✨ Features

- 💧 Animated 3D character drops from the top and walks across the screen every hour
- 🔔 Alert popup — **"Yes, I drank water ✅"** or **"Remind me in 10 min ⏰"**
- 🖥️ Menu bar `💧` icon — trigger reminder manually or quit
- 😴 Sleep/wake aware — pauses when screen sleeps, resumes on wake
- 🚀 Auto-starts at login via LaunchAgent

---

## 🛠️ Requirements

- Swift compiler (`xcode-select --install` if missing)
- Runs on desktop operating systems with Swift support

---

## 🚀 Install

```bash
cd waterbuddy_mac
chmod +x Install.command Uninstall.command
./Install.command
```

If Swift compiler is missing:
```bash
xcode-select --install
```
Then run `./Install.command` again.

---

## 🗑️ Uninstall

```bash
./Uninstall.command
```

---

## 📁 Project Structure

```
waterbuddy_mac/
├── WaterBuddy.swift      # Main app — menu bar, animation, alerts
├── character.usdz        # 3D animated character model
├── doraemon.gif          # Reference asset
├── Install.command       # Build + install LaunchAgent
├── Uninstall.command     # Remove LaunchAgent + binary
└── README.md
```

---

## ⚙️ How It Works

```
App Launches
    │
    ▼
Every 60 minutes (or on wake)
    │
    ▼
Animated character drops from top → walks across screen
    │
    ▼
Alert: "Have you had water?"
    ├── Yes ✅  → dismissed, next reminder in 60 min
    └── Snooze ⏰ → reminder in 10 min
```

---

## 👨‍💻 Author

**Dungroth Srinivas**
- 📧 dungrothsreenivas143@gmail.com
- 📍 Hyderabad, India
- 🔗 [GitHub](https://github.com/srinivasdungroth)

---

## 📄 License

MIT License — free to use, modify and distribute.
