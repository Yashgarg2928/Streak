# Streak Setup & Deployment Guide

This guide provides step-by-step instructions to set up the **Streak** application and its **Home Screen Widgets** on a new Mac and deploy it to a physical iPhone. It covers everything from installing Xcode to configuring signing certificates, bundle IDs, App Groups, and enabling Developer Mode on iOS.

---

## Part 1: Setting up the Mac

### Step 1: Install Xcode
Xcode is Apple's official IDE for iOS development. If the Mac does not have Xcode installed:
1. Open the **App Store** on the Mac.
2. Search for **Xcode** and click **Get** to install it.
   > [!NOTE]
   > Xcode is a large download (around 12-15 GB). Make sure you have at least 40 GB of free disk space and a stable internet connection.
3. Once downloaded, open Xcode to complete the installation of the system components and agree to the license agreement.

### Step 2: Install Xcode Command Line Tools
Open the terminal app on your Mac (`Applications > Utilities > Terminal`) and run the following command:
```bash
xcode-select --install
```
A prompt will appear. Click **Install** to download and configure the essential command line utilities.

### Step 3: Clone the Repository
Clone the codebase to the local machine. In the terminal:
```bash
git clone <repository-url>
cd self-improvement-app/Streak
```

---

## Part 2: Xcode Project Configuration

Since Bundle Identifiers and App Groups must be globally unique across the Apple ecosystem, you **cannot** compile the app on a new developer account using the existing bundle identifier (`com.yash.Streak`) and App Group (`group.com.madhvan.streak`). You must customize these identifiers.

### Step 1: Add your Apple ID to Xcode
1. Open Xcode.
2. In the menu bar, go to **Xcode > Settings...** (or press `Cmd + ,`).
3. Click on the **Accounts** tab.
4. Click the **+** (plus) button in the bottom left, select **Apple ID**, and click **Continue**.
5. Log in with your personal Apple ID (you do not need a paid Developer Account for on-device testing).

### Step 2: Open the Project
Double-click [Streak.xcodeproj](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak.xcodeproj) or run the following in terminal:
```bash
open Streak.xcodeproj
```

### Step 3: Configure Signing & Team
You must configure signing for both targets: **Streak** (the main app) and **StreakWidgetsExtension** (the widget extension).

1. In the Xcode left sidebar (Project Navigator), select the top-level **Streak** project icon.
2. In the main panel, under the **Targets** list on the left, select the **Streak** target.
3. Click the **Signing & Capabilities** tab at the top.
4. Check **Automatically manage signing**.
5. Under the **Team** dropdown, select your name/Apple ID (e.g., *Your Name (Personal Team)*).
6. Repeat this process: Select the **StreakWidgetsExtension** target under **Targets** and assign the same **Team**.

### Step 4: Customize Bundle Identifiers
To prevent conflicts, choose a custom prefix (e.g., your name or initials like `com.johnsmith`).

1. Select the **Streak** target under **Targets**.
2. Change the **Bundle Identifier** from `com.yash.Streak` to `com.yourname.Streak`.
3. Select the **StreakWidgetsExtension** target.
4. Change its **Bundle Identifier** to `com.yourname.Streak.StreakWidgets`.
   > [IMPORTANT]
   > The widget's bundle identifier MUST start with the main app's bundle identifier as its prefix. For example, if the app is `com.john.Streak`, the widget must be `com.john.Streak.StreakWidgets`.

### Step 5: Configure App Groups
App Groups enable the main app and widget extension to share data securely.

1. Select the **Streak** target under **Targets** > **Signing & Capabilities**.
2. Scroll down to the **App Groups** section.
3. Click the **-** (minus) button to remove the existing `group.com.madhvan.streak`.
4. Click the **+** (plus) button and add a new App Group named `group.com.yourname.streak` (replace `yourname` with the prefix you used for your bundle identifier).
5. Repeat for the **StreakWidgetsExtension** target: Select it, remove the old App Group, and add/enable your new App Group `group.com.yourname.streak`.

---

## Part 3: Updating the Codebase

You must update the App Group identifier in the source code so the app reads and writes from your new shared container.

### Step 1: Update App Group Constants
Update the App Group ID string in the following files:

1. **[WidgetDataStore.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/WidgetDataStore.swift#L54)**:
   ```swift
   // Change:
   static let appGroupID = "group.com.madhvan.streak"
   // To:
   static let appGroupID = "group.com.yourname.streak"
   ```

2. **[UserDefaultsSettingsRepository.swift](file:///Users/madhvan07icloud.coom/self-improvment-app/Streak/Streak/Infrastructure/Persistence/UserDefaultsSettingsRepository.swift#L32)**:
   ```swift
   // Change:
   let appGroupID = "group.com.madhvan.streak"
   // To:
   let appGroupID = "group.com.yourname.streak"
   ```

---

## Part 4: Preparing your iPhone

### Step 1: Enable Developer Mode on iOS
To run apps built from Xcode, you must enable Developer Mode on the physical iPhone:
1. Open **Settings** on the iPhone.
2. Navigate to **Privacy & Security**.
3. Scroll to the bottom and tap **Developer Mode**.
4. Toggle **Developer Mode** ON.
5. Tap **Restart** when prompted.
6. After the iPhone restarts, unlock it, and tap **Turn On** in the system alert, then enter your device passcode.

### Step 2: Connect to your Mac
1. Connect your iPhone to the Mac using a USB/Lightning cable.
2. If prompted on the iPhone, tap **Trust This Computer** and enter your device passcode.

---

## Part 5: Deploying and Running the App

### Step 1: Select the Destination in Xcode
1. In the top toolbar of Xcode, click the run destination selector (located to the right of the scheme name `Streak`).
2. Select your connected physical **iPhone** under the *iOS Devices* list.

### Step 2: Build and Run
1. Press the **Run** button (play icon) in the top-left or use the shortcut `Cmd + R`.
2. Xcode will compile the code and install it onto the iPhone.

### Step 3: Trust the Developer Profile on iPhone
On the first launch, the iPhone might display an "Untrusted Developer" alert and refuse to open the app. To resolve this:
1. On the iPhone, open **Settings**.
2. Go to **General > VPN & Device Management**.
3. Under *Developer App*, tap on your Apple ID email.
4. Tap **Trust "your.email@example.com"** and confirm.
5. You can now launch the **Streak** app from your home screen!

---

## Part 6: Adding Widgets to Home Screen

1. Unlock the iPhone and go to the Home Screen.
2. Tap and hold a blank area until the icons start to jiggle.
3. Tap the **+** (plus) button in the top left corner.
4. Scroll down or search for **Streak**.
5. Swipe through the available widgets (Streak, Goal, Tasks, etc.), select the desired size, and tap **Add Widget**.
6. Tap **Done** in the top right.

> [TIP]
> If a widget shows empty or placeholder data immediately after installation, launch the main **Streak** app once. Checking off a task or changing a category will trigger a data sync to the App Group container and immediately update the widget.
