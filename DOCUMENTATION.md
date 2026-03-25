# PUnova — Campus Connect

## Overview

| Property               | Value |
|---                     |    ---|
| **App Name (display)** | PUnova |
| **Package name**       | `campus_connect` |
| **Version**            | 1.0.0+1 |
| **Framework**          | Flutter (Dart SDK `^3.6.0`) |
| **Target Platforms**   | Android (min SDK 21), iOS, Web, Windows,macOS Linux |
| **Purpose**            | All-in-one university companion app for Pondicherry University students |

---

## Architecture

```
lib/
├── main.dart               # App entry, theme system, navigation shell
├── theme/
│   └── app_theme.dart      # Design system (colors, gradients, typography, ThemeData)
├── widgets/
│   └── glass_widgets.dart  # Reusable glassmorphism components
└── screens/                # 13 feature screens
```

**State Management**: Custom `InheritedNotifier` pattern — `ThemeNotifier` (a `ChangeNotifier`) is propagated via `ThemeProvider` (`InheritedNotifier<ThemeNotifier>`). No external state management library is used.

**Navigation**: `AppEntry` → `WelcomeScreen` → `DashboardShell`. The dashboard uses a hand-rolled bottom navigation bar with an `IndexedStack`-free tab model (only the active tab is built). "My ID" is the center action button and navigates via `MaterialPageRoute` (modal, not a persistent tab).

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `google_fonts` | ^6.2.1 | Outfit (headings) & Inter (body) typefaces |
| `flutter_map` | ^7.0.2 | OpenStreetMap tile-based campus map |
| `latlong2` | ^0.9.1 | Geographic coordinates for map |
| `qr_flutter` | ^4.1.0 | QR code on the digital student ID |
| `image_picker` | ^1.1.2 | Profile photo from camera or gallery |
| `flutter_lints` | ^5.0.0 | Lint rules |
| `flutter_launcher_icons` | ^0.14.3 | Auto-generates launcher icons from `assets/images/app_icon.png` |

---

## Design System — `lib/theme/app_theme.dart`

**Glassmorphism** aesthetic with two modes toggled at runtime.

### Color Palette

| Token | Dark Value | Light Value |
|---|---|---|
| `bgDark` / `bgLight` | `#0A0E21` | `#F1F5F9` |
| `bgCard` | `#161B33` | `#FFFFFF` |
| `accentTeal` | `#00D2FF` | — (shared) |
| `accentCyan` | `#00F0B5` | — |
| `accentPurple` | `#7C3AED` | — |
| `accentPink` | `#EC4899` | — |
| `accentOrange` | `#FF8C00` | — |
| `accentGreen` | `#22C55E` | — |
| `accentRed` | `#EF4444` | — |

### Gradients

| Name | Colors | Usage |
|---|---|---|
| `primaryGradient` | Teal → Cyan | Buttons, active nav, highlights |
| `purpleGradient` | Purple → Pink | Secondary accents |
| `warmGradient` | Orange → Deep Orange | Avatar borders, warm highlights |
| `bgGradient` | Dark navy (top) → Medium navy (bottom) | Screen backgrounds |

### Typography

- **Headings**: `Outfit` (weights 700–800)
- **Body / Labels**: `Inter` (weights 400–600)
- `GoogleFonts.config.allowRuntimeFetching = false` — fonts are bundled; no network fetch at runtime.

### Theme Resolver — `Tc`

```dart
final tc = Tc.of(context); // auto-detects dark/light from brightness
tc.textPrimary  // adapts to current mode
tc.bgGradient   // adapts to current mode
tc.glassBorder  // adapts to current mode
```

---

## Reusable Widgets — `lib/widgets/glass_widgets.dart`

| Widget | Description |
|---|---|
| `GlassCard` | Semi-transparent container with border; uses opacity instead of expensive `BackdropFilter` blur |
| `GlassIconTile` | Gradient icon + label tile used in quick-access grids |
| `SectionHeader` | Title row with optional trailing action link |
| `GlassButton` | Gradient-filled tappable button with optional leading icon |

---

## Screens

### 1. WelcomeScreen — `lib/screens/welcome_screen.dart`

- One-time splash/onboarding shown on first launch.
- Displays the app logo (`assets/images/app_logo.png`), app tagline, and four feature pills: **Digital ID**, **Bus Tracking**, **Forum**, **Events**.
- "Get Started" button fires the `onGetStarted` callback, transitioning to `DashboardShell`.
- Decorative radial gradient orbs (teal top-right, purple bottom-left) for depth effect.

---

### 2. HomeScreen — `lib/screens/home_screen.dart`

- **Greeting card** — student name (`Balakumaran`), department (`Computer Science`), semester (`5`), notification bell icon.
- **Quick Access** row — 4 `GlassIconTile`s navigating to:
  - Forum, Services, Events, Circulars
- **Academics** section — Timetable and Results tiles.
- **Latest Updates** feed — scrollable cards for academic and event notices with timestamps.

---

### 3. MapScreen — `lib/screens/map_screen.dart`

- Full `flutter_map` interactive tile map centered on **Pondicherry University** (`12.0180°N, 79.8555°E`).
- Map panning is restricted to campus bounding box (`12.007–12.035°N`, `79.840–79.872°E`).

#### Campus Landmarks (9)

| Name | Coordinates | Icon | Color |
|---|---|---|---|
| Library | 12.0155, 79.8565 | `local_library` | Teal |
| Cafeteria | 12.0140, 79.8590 | `restaurant` | Orange |
| Sports Complex | 12.0120, 79.8555 | `sports_soccer` | Green |
| Admin Block | 12.0170, 79.8575 | `business` | Purple |
| Main Gate | 12.0098, 79.8545 | `door_front_door` | Pink |
| Hostels | 12.0210, 79.8530 | `hotel` | Cyan |
| Silver Jubilee | 12.0080, 79.8520 | `account_balance` | Orange |
| Stadium | 12.0115, 79.8500 | `stadium` | Green |
| Gate 2 | 12.0075, 79.8505 | `door_sliding` | Red |

#### Navigation Mode
- Tap any landmark → animated polyline route drawn via **Haversine-based waypoints** (10 interpolated steps).
- Info panel shows: landmark name, detail (hours), distance (m / km), and walking time (~80 m/min).
- "End Navigation" button resets map to campus center at zoom 15.

---

### 4. MyIdScreen — `lib/screens/my_id_screen.dart`

- Digital student identity card opened as a **modal route** from the center nav button.
- **Blue gradient header** with university name and school icon.
- Student photo avatar, full name, roll number, department, year, batch.
- **QR code** (`qr_flutter`) encoding the student's ID data.
- Active/valid status badge, share button stub.

---

### 5. AlertsScreen — `lib/screens/alerts_screen.dart`

- **4-tab layout** (`TabController`):

| Tab | Content |
|---|---|
| All | Combined chronological alerts feed |
| Academics | Exam schedules, registration notices |
| Lost & Found | Item listings + "Report Item" button → `LostFoundScreen` |
| Emergency | Campus security and health contact cards |

---

### 6. ProfileScreen — `lib/screens/profile_screen.dart`

- **Profile photo** — pick from camera or gallery via `ImagePicker`; path stored in `ThemeNotifier.profileImagePath` and shared app-wide.
- Editable name and bio via modal bottom sheets.
- **Settings**:
  - Dark / Light theme toggle → calls `ThemeNotifier.toggleTheme()`
  - Font size selector: Small / Medium / Large
  - App lock toggle (UI state only)
- Academic info strip, social links, contact details section.

---

### 7. ForumScreen — `lib/screens/forum_screen.dart`

- Student discussion board displaying post cards with: author, timestamp, title, body excerpt, like count, reply count.
- Floating Action Button (gradient) for composing new posts (stub).

**Sample posts:**
- "Best study spots on campus?" — Sarah K.
- "Anyone interested in Python study group?" — Mike R.
- "Cafeteria food review" — Priya S.

---

### 8. EventsScreen — `lib/screens/events_screen.dart`

Upcoming campus event cards with date badge, title, description, and venue.

| Event | Date | Venue |
|---|---|---|
| Tech Fest 2024 | Mar 15 | Main Auditorium |
| Cultural Night | Mar 20 | Open Air Theatre |
| Sports Day | Mar 25 | Sports Complex |
| Alumni Meet | Apr 05 | Convention Hall |

---

### 9. ServicesScreen — `lib/screens/services_screen.dart`

Six campus service cards in a scrollable list:

| Service | Description | Gradient |
|---|---|---|
| **Papido** | Food Ordering | Orange |
| **Plink It** | Digital Payments | Indigo |
| Laundry | Schedule Pickup | Teal |
| Stationery | Order Supplies | Pink |
| Print Shop | Print & Copy | Amber |
| Health | Medical Services | Green |

---

### 10. LostFoundScreen — `lib/screens/lost_found_screen.dart`

**5-step report wizard** for lost or found items:

| Step | Content |
|---|---|
| 1 | Item type selector: Lost / Found |
| 2 | Category picker |
| 3 | Item description |
| 4 | Location where lost/found |
| 5 | Reporter contact details |

- Progress bar at the top fills step-by-step with `primaryGradient`.
- Back / Next bottom bar; submit on final step.

---

### 11. TimetableScreen — `lib/screens/timetable_screen.dart`

- **Horizontal day selector** (Mon – Sat) with highlighted active day.
- Class cards show: subject name, time slot, faculty, room number, accent color.

**Sample schedule (Monday):**

| Subject | Time | Faculty | Room |
|---|---|---|---|
| Data Structures | 09:00 – 10:00 | Dr. Kumar | Room 301 |
| Operating Systems | 10:15 – 11:15 | Dr. Patel | Room 204 |
| DBMS Lab | 11:30 – 13:00 | Prof. Singh | Lab B2 |
| Computer Networks | 14:00 – 15:00 | Dr. Sharma | Room 102 |

---

### 12. ResultScreen — `lib/screens/result_screen.dart`

- Semester selector chip row.
- **GPA summary card** at the top.
- Per-subject grade cards: subject name, letter grade, grade point, color-coded strip.

**Sample — Semester 4:**

| Subject | Grade | Points |
|---|---|---|
| Data Structures | A+ | 10 |
| Operating Systems | A | 9 |
| DBMS | A+ | 10 |
| Computer Networks | B+ | 8 |
| Mathematics III | A | 9 |

---

### 13. CircularsScreen — `lib/screens/circulars_screen.dart`

- University notice board displaying circular cards: title, description, date.
- **Unread badge** on new/unseen circulars.

**Sample circulars:**
- Exam Schedule Notice (Feb 18) — *unread*
- Library Rules Update (Feb 15) — *unread*
- Hostel Maintenance (Feb 12)
- Fee Payment Reminder (Feb 10)
- Workshop Registration — AI/ML by Google DevRel (Feb 08)

---

## Bottom Navigation Structure

```
┌──────────────────────────────────────────────────────┐
│  🏠 Home   🗺 Map   [ 🪪 My ID ]   🔔 Alerts   👤 Profile │
│    0         1       (center CTA)      3              4   │
└──────────────────────────────────────────────────────┘
```

- Indexes 0, 1, 3, 4 switch the active tab in `DashboardShell`.
- Index 2 (center button) pushes `MyIdScreen` as a **modal route** without switching tabs.
- Active tab: `accentTeal` icon color + label weight + small dot indicator below icon.

---

## Assets

```
assets/images/
├── app_icon.png   # Launcher icon (auto-generated for Android, iOS, Web)
└── app_logo.png   # Displayed on WelcomeScreen
```

---

## Platform Configuration

| Platform | Notes |
|---|---|
| **Android** | Min SDK 21, Gradle Kotlin DSL (`build.gradle.kts`), release APK → `build/app/outputs/` |
| **iOS** | Standard Runner target, Swift `AppDelegate` |
| **Web** | PWA `manifest.json` included |
| **Windows / macOS / Linux** | CMake build system scaffolded |

---

## Key Design Decisions

1. **No backend / no auth** — all data (schedule, grades, alerts, circulars) is currently hardcoded static data; the architecture is intentionally ready for API integration by swapping data sources.

2. **No external state management library** — `InheritedNotifier<ThemeNotifier>` is sufficient for the single piece of global state (theme mode + profile image path).

3. **Performance over visual fidelity** — `GlassCard` uses `withValues(alpha: 0.10)` opacity instead of `BackdropFilter` blur to avoid rendering jank on mid-range Android devices.

4. **Font bundling** — `GoogleFonts.config.allowRuntimeFetching = false` ensures offline-first behavior and eliminates layout shift from late font loads.

5. **Efficient tab rendering** — `DashboardShell` builds only the currently active tab widget rather than keeping all four alive in an `IndexedStack`, reducing memory footprint.

6. **Map routing is fully local** — distance (Haversine formula) and walking-time estimates are computed on-device; no routing API call is needed.

---

## File Reference

| File | Lines | Description |
|---|---|---|
| `lib/main.dart` | 235 | App root, `ThemeNotifier`, `ThemeProvider`, `DashboardShell` |
| `lib/theme/app_theme.dart` | 237 | Full design system |
| `lib/widgets/glass_widgets.dart` | 256 | Shared UI components |
| `lib/screens/welcome_screen.dart` | 159 | Onboarding splash |
| `lib/screens/home_screen.dart` | 253 | Main dashboard feed |
| `lib/screens/map_screen.dart` | 498 | Interactive campus map |
| `lib/screens/my_id_screen.dart` | 361 | Digital student ID + QR |
| `lib/screens/alerts_screen.dart` | 363 | Tabbed alerts feed |
| `lib/screens/profile_screen.dart` | 1086 | Profile & settings |
| `lib/screens/forum_screen.dart` | 142 | Student discussion board |
| `lib/screens/events_screen.dart` | 133 | Upcoming events list |
| `lib/screens/services_screen.dart` | 119 | Campus services grid |
| `lib/screens/lost_found_screen.dart` | 447 | Lost & found wizard |
| `lib/screens/timetable_screen.dart` | 194 | Weekly class schedule |
| `lib/screens/result_screen.dart` | 216 | Academic results viewer |
| `lib/screens/circulars_screen.dart` | 153 | University notice board |
