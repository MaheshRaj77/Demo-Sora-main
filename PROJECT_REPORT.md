# PUnova — Campus Connect
## Project Report

**Application Name:** PUnova (Campus Connect)  
**Version:** 1.0.0  
**Platform:** Flutter (Android, iOS, Web)  
**Institution:** Pondicherry University  
**Technology Stack:** Dart · Flutter · OpenStreetMap · QR Code

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Problem Statement and Objectives](#2-problem-statement-and-objectives)
3. [System Analysis](#3-system-analysis)
4. [System Design](#4-system-design)
   - 4.1 Architecture Diagram
   - 4.2 Data Flow Diagrams (DFD)
   - 4.3 UML Diagrams
5. [List of Modules](#5-list-of-modules)
6. [Output of Module 1 — Onboarding & Welcome](#6-output-of-module-1--onboarding--welcome)

---

## 1. Introduction

### 1.1 Background

University campuses are complex environments where students interact with multiple administrative and academic systems daily. At Pondicherry University, students need to access their timetable, exam results, circulars, campus maps, events, and various services — all of which exist in separate, disconnected systems. This fragmentation forces students to switch between multiple portals, physical notice boards, and manual processes to get things done.

**PUnova** (Campus Connect) is a modern, cross-platform mobile application designed to unify all essential student-facing university services into a single, intuitive interface. Built with Flutter, the app targets Android and iOS devices and provides a consistent, performant experience across platforms.

### 1.2 Project Scope

PUnova covers the following domains:

- **Identity** — Digital student ID card with QR code
- **Academics** — Timetable viewer, results/grade tracker, circulars
- **Campus** — Interactive campus map with navigation
- **Communication** — Push alerts, lost & found board, student forum
- **Services** — Food ordering, payments, laundry, print shop, health

### 1.3 Technology Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Dart SDK ^3.6.0) |
| Language | Dart |
| Mapping | flutter_map + OpenStreetMap |
| QR Generation | qr_flutter |
| Typography | Google Fonts (Outfit, Inter) |
| Image Handling | image_picker |
| Build (Android) | Gradle with Kotlin DSL |
| Build (iOS) | Xcode / Swift |

### 1.4 Design Philosophy

The application follows a **Glassmorphism** design language — a modern aesthetic using semi-transparent surfaces, subtle borders, and layered depth on dark/light gradient backgrounds. The UI is theme-adaptive, supporting both dark mode (default) and light mode, toggled by the user at runtime.

---

## 2. Problem Statement and Objectives

### 2.1 Problem Statement

Students at Pondicherry University currently face the following challenges:

1. **Fragmented Information** — Timetables, results, and circulars are distributed across multiple portals with no unified access point.
2. **No Digital Identity** — Physical ID cards are prone to loss or damage. There is no digital alternative for verification.
3. **Campus Navigation Difficulty** — New students and visitors frequently struggle to locate buildings, labs, hostels, and facilities on the large campus.
4. **Delayed Notifications** — Students miss important academic deadlines, events, and emergency alerts because notice boards are physical and scattered.
5. **Inefficient Lost & Found** — Lost items are reported informally with no structured tracking mechanism.
6. **Disconnected Services** — Campus services (food, laundry, print, etc.) have no centralized digital access.
7. **Lack of Community Platform** — There is no structured digital forum where students can post questions, share resources, and interact academically.

### 2.2 Objectives

The primary objectives of PUnova are:

| # | Objective |
|---|---|
| O1 | Provide a **single unified platform** for all student-facing campus services |
| O2 | Implement a **digital student ID** with QR code for contactless verification |
| O3 | Deliver an **interactive campus map** with landmark navigation and distance estimation |
| O4 | Create a **real-time alert system** for academic, emergency, and event notifications |
| O5 | Build a **structured lost & found reporting** workflow |
| O6 | Offer a **student forum** for academic and social communication |
| O7 | Present **academic records** (timetable, results) in a clear, accessible UI |
| O8 | Integrate **campus service access** (food, laundry, payments) in one place |
| O9 | Support **dark and light themes** for accessibility and user preference |
| O10 | Deliver a **performant, offline-capable** experience on mid-range devices |

### 2.3 Functional Requirements

- FR1: Display student identity card with QR code
- FR2: Show weekly class timetable with day-wise navigation
- FR3: Display semester-wise academic results and GPA
- FR4: Render an interactive map centered on Pondicherry University campus
- FR5: Provide point-to-point navigation between campus landmarks
- FR6: Show categorized alerts (academic, lost & found, emergency)
- FR7: Allow students to report lost or found items via a step-by-step form
- FR8: List upcoming campus events with venue and date
- FR9: Display university circulars with unread indicators
- FR10: Allow profile photo upload from camera or gallery
- FR11: Support dark/light theme toggle

### 2.4 Non-Functional Requirements

- NFR1: App launch time < 2 seconds on mid-range devices
- NFR2: Map should load within 3 seconds on a 4G connection
- NFR3: UI must be responsive across screen sizes (5" to 7")
- NFR4: Fonts must be bundled (no runtime network fetch)
- NFR5: Support Android API 21+ and iOS 12+

---

## 3. System Analysis

### 3.1 Existing System

#### Current State at Pondicherry University

| Service | Current Method | Drawbacks |
|---|---|---|
| Student ID | Physical card | Easily lost; no digital backup |
| Timetable | PDF / notice board | Not personalized; hard to search |
| Exam Results | University web portal | Poor mobile UX; multiple logins |
| Circulars | Physical boards / email | Easily missed; no push notification |
| Campus Navigation | Word of mouth / printed maps | Inaccurate; not interactive |
| Lost & Found | Manual register at admin | No tracking; limited visibility |
| Events | Posters / WhatsApp groups | No centralized discovery |
| Campus Services | Individual counters | Requires physical presence |

### 3.2 Proposed System

PUnova replaces and improves each of the above with a digital, mobile-first solution:

| Service | PUnova Solution |
|---|---|
| Student ID | Digital ID card screen with QR code |
| Timetable | Day-selectable schedule viewer |
| Results | Semester-wise grade cards with GPA |
| Circulars | Scrollable feed with unread badges |
| Campus Navigation | flutter_map with 9 landmarks + routing |
| Lost & Found | 5-step report wizard + item listings |
| Events | Structured event cards with date/venue |
| Campus Services | Service grid (Papido, Plink It, etc.) |

### 3.3 Feasibility Study

#### Technical Feasibility
Flutter is a mature, production-ready framework used by millions of apps. All major dependencies (`flutter_map`, `qr_flutter`, `image_picker`) are well-maintained open-source packages. The app requires no proprietary SDKs.

#### Operational Feasibility
The app targets Android and iOS smartphones which are universally owned by university students. No additional hardware is required. Offline content (bundled fonts, static data) ensures usability in low-connectivity campus zones.

#### Economic Feasibility
All frameworks and libraries used are free and open-source. Distribution via Google Play Store and Apple App Store requires only one-time developer account fees. Hosting costs are negligible for the current static-data architecture.

### 3.4 Hardware and Software Requirements

#### Development Requirements
| Requirement | Specification |
|---|---|
| OS | Windows 10 / macOS 13+ |
| IDE | Visual Studio Code / Android Studio |
| Flutter SDK | 3.x (Dart SDK ^3.6.0) |
| Android Emulator | API 21+ |
| Git | Version control |

#### Runtime Requirements (End User)
| Requirement | Specification |
|---|---|
| Android | API 21 (Android 5.0+) |
| iOS | iOS 12+ |
| RAM | 2 GB minimum |
| Storage | ~50 MB |
| Internet | Required for map tiles only |

---

## 4. System Design

### 4.1 Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        PUnova Application                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    Presentation Layer                      │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │
│  │  │  Welcome │  │  Home    │  │  Map     │  │  My ID   │  │  │
│  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │
│  │  │  Alerts  │  │ Profile  │  │  Forum   │  │  Events  │  │  │
│  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │
│  │  │ Services │  │Lost Found│  │Timetable │  │  Result  │  │  │
│  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │  │
│  │                  ┌──────────────┐                          │  │
│  │                  │  Circulars   │                          │  │
│  │                  │   Screen     │                          │  │
│  │                  └──────────────┘                          │  │
│  └────────────────────────────────────────────────────────────┘  │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                 State & Navigation Layer                   │  │
│  │   ThemeNotifier (ChangeNotifier)                           │  │
│  │   ThemeProvider (InheritedNotifier)                        │  │
│  │   DashboardShell (Bottom Navigation Controller)            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                  Shared Components Layer                   │  │
│  │   GlassCard │ GlassIconTile │ GlassButton │ SectionHeader  │  │
│  │   AppTheme  │ AppColors     │ LightColors │ Tc (resolver)  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                             │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    External Services                       │  │
│  │   OpenStreetMap Tile Server (flutter_map)                  │  │
│  │   Device Camera / Gallery (image_picker)                   │  │
│  │   Google Fonts (bundled, offline)                          │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

### 4.2 Data Flow Diagrams (DFD)

#### DFD Level 0 — Context Diagram

```
                        ┌─────────────────┐
                        │                 │
    ┌───────────┐        │    PUnova       │        ┌───────────────────┐
    │           │──────▶│    Campus       │──────▶│  Map Tile Server  │
    │  Student  │        │    Connect      │        │  (OpenStreetMap)  │
    │  (User)   │◀──────│    System       │◀──────│                   │
    └───────────┘        │                 │        └───────────────────┘
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │  Device Storage │
                        │ (Profile Image) │
                        └─────────────────┘
```

#### DFD Level 1 — Main Processes

```
┌─────────────┐
│   Student   │
└──────┬──────┘
       │
       ├──── Launch App ──────────────────▶ ┌─────────────────────────┐
       │                                    │  P1: Onboarding Process  │
       │◀─── Show Welcome + Get Started ─── │  (WelcomeScreen)         │
       │                                    └─────────────────────────┘
       │
       ├──── Navigate Dashboard ────────────▶ ┌─────────────────────────┐
       │                                      │  P2: Home Dashboard      │
       │◀─── Greeting, Quick Access, Feed ─── │  (HomeScreen)            │
       │                                      └─────────────────────────┘
       │
       ├──── Open Map ────────────────────────▶ ┌─────────────────────────┐
       │                                        │  P3: Campus Navigation   │
       │◀─── Map Tiles + Landmarks + Route ───  │  (MapScreen)             │
       │                                        └──────────┬──────────────┘
       │                                                   │ Request Tiles
       │                                        ┌──────────▼──────────────┐
       │                                        │   OpenStreetMap Server  │
       │                                        └─────────────────────────┘
       │
       ├──── View ID ─────────────────────────▶ ┌─────────────────────────┐
       │                                        │  P4: Digital ID Card     │
       │◀─── ID Card + QR Code ──────────────── │  (MyIdScreen)            │
       │                                        └─────────────────────────┘
       │
       ├──── View Alerts ─────────────────────▶ ┌─────────────────────────┐
       │                                        │  P5: Alert Management    │
       │◀─── Categorized Alerts ──────────────  │  (AlertsScreen)          │
       │                                        └─────────────────────────┘
       │
       ├──── Open Profile ────────────────────▶ ┌─────────────────────────┐
       │                                        │  P6: Profile & Settings  │
       │◀─── Profile View / Theme Updated ───── │  (ProfileScreen)         │
       │                                        └──────────┬──────────────┘
       │                                                   │ Read/Write
       │                                        ┌──────────▼──────────────┐
       │                                        │    Device Storage        │
       │                                        │   (Profile Image Path)   │
       │                                        └─────────────────────────┘
       │
       ├──── Report Lost Item ────────────────▶ ┌─────────────────────────┐
       │◀─── Step Wizard + Confirmation ──────  │  P7: Lost & Found        │
       │                                        └─────────────────────────┘
       │
       └──── Browse Forum / Events /  ────────▶ ┌─────────────────────────┐
             Services / Results /               │  P8: Content Screens     │
             Timetable / Circulars              │  (6 feature screens)     │
             ◀── Static Content ─────────────── └─────────────────────────┘
```

#### DFD Level 2 — Campus Map Process (P3)

```
 Student Input                Process                     Output
─────────────                ────────                   ─────────
                       ┌────────────────────┐
  [Tap Map Tab] ──────▶│ P3.1 Load Map      │──────▶  Render OSM tiles
                       │ (flutter_map init) │          at zoom 15
                       └────────┬───────────┘
                                │
                       ┌────────▼───────────┐
  [Render Screen] ────▶│ P3.2 Plot Landmarks│──────▶  9 landmark markers
                       │ (9 LatLng pins)    │          on map canvas
                       └────────┬───────────┘
                                │
                       ┌────────▼───────────┐
  [Tap Landmark] ─────▶│ P3.3 Navigate      │──────▶  Draw route polyline
                       │ (Haversine calc)   │          Show distance + ETA
                       └────────┬───────────┘
                                │
                       ┌────────▼───────────┐
  [End Navigation]────▶│ P3.4 Reset Map     │──────▶  Return to campus
                       │ (move to center)   │          center view
                       └────────────────────┘
```

#### DFD Level 2 — Lost & Found Process (P7)

```
 Student Input                Process                     Output
─────────────                ────────                   ─────────
                       ┌────────────────────┐
  [Open L&F] ─────────▶│ P7.1 Init Wizard   │──────▶  Show Step 1
                       │ (step = 0)         │          Progress bar
                       └────────┬───────────┘
                                │
  [Select Type] ───────▶┌───────▼───────────┐
  Lost / Found          │ P7.2 Item Type    │──────▶  Step 1 Complete
                        └────────┬──────────┘
                                 │
  [Select Category] ───▶┌────────▼──────────┐
                        │ P7.3 Category     │──────▶  Step 2 Complete
                        └────────┬──────────┘
                                 │
  [Enter Description] ─▶┌────────▼──────────┐
                        │ P7.4 Description  │──────▶  Step 3 Complete
                        └────────┬──────────┘
                                 │
  [Enter Location] ────▶┌────────▼──────────┐
                        │ P7.5 Location     │──────▶  Step 4 Complete
                        └────────┬──────────┘
                                 │
  [Enter Contact ] ────▶┌────────▼──────────┐
                        │ P7.6 Contact Info │──────▶  Step 5 / Submit
                        └────────┬──────────┘
                                 │
                        ┌────────▼──────────┐
                        │ P7.7 Confirmation │──────▶  Report Confirmation
                        └───────────────────┘
```

---

### 4.3 UML Diagrams

#### 4.3.1 Use Case Diagram

```
                          ┌────────────────────────────────────────────────┐
                          │                  PUnova System                  │
                          │                                                  │
                          │  ○ View Welcome Screen                          │
                          │  ○ Navigate Dashboard                           │
                          │  ○ View Home Feed                               │
                          │  ○ View Digital ID Card                         │
                          │  ○ Scan QR Code (ID)                           │
         ┌──────────┐     │  ○ Browse Campus Map                           │
         │          │─────│  ○ Navigate to Landmark                         │
         │ Student  │     │  ○ View Timetable                              │
         │  (User)  │─────│  ○ View Exam Results                           │
         │          │     │  ○ View Circulars                               │
         └──────────┘     │  ○ Receive Alerts                              │
                          │  ○ Browse Events                               │
                          │  ○ Participate in Forum                        │
                          │  ○ Report Lost / Found Item                    │
                          │  ○ Browse Campus Services                      │
                          │  ○ Upload Profile Photo                        │
                          │  ○ Toggle Dark / Light Theme                   │
                          │  ○ Adjust Font Size                            │
                          │  ○ Enable App Lock                             │
                          │                                                  │
                          └────────────────────────────────────────────────┘
                                           │
                               ┌───────────▼──────────┐
                               │   OpenStreetMap       │
                               │   (External Actor)    │
                               │   Provides Map Tiles  │
                               └──────────────────────┘
```

#### 4.3.2 Class Diagram

```
┌─────────────────────────┐         ┌──────────────────────────┐
│    ThemeNotifier         │         │       ThemeProvider       │
│─────────────────────────│         │──────────────────────────│
│ - _isDarkMode: bool      │◀────────│ + notifier: ThemeNotifier│
│ - _profileImagePath: str?│         │ + child: Widget          │
│─────────────────────────│         │──────────────────────────│
│ + toggleTheme(): void    │         │ + of(ctx): ThemeNotifier │
│ + setProfileImage(): void│         └──────────────────────────┘
└──────────┬──────────────┘
           │ uses
           │
┌──────────▼──────────────┐
│     DashboardShell       │
│─────────────────────────│
│ - _currentIndex: int     │
│─────────────────────────│
│ + _onTabTapped(): void   │
│ + _buildGlassNavBar()    │
└──────────┬──────────────┘
           │ hosts
  ┌────────┼──────────────────────────┐
  ▼        ▼            ▼             ▼
HomeScreen  MapScreen  AlertsScreen  ProfileScreen

┌─────────────────┐     ┌─────────────────────┐
│    MapScreen     │     │      _Landmark       │
│─────────────────│     │─────────────────────│
│ - _mapController│     │ + name: String       │
│ - _destination  │────▶│ + position: LatLng   │
│ - _isNavigating │     │ + icon: IconData     │
│─────────────────│     │ + color: Color       │
│ + _navigate()   │     │ + detail: String     │
│ + _buildRoute() │     └─────────────────────┘
│ + _distanceM()  │
└─────────────────┘

┌──────────────────────────┐
│       AppColors           │
│──────────────────────────│
│ + bgDark: Color           │
│ + accentTeal: Color       │
│ + primaryGradient: Grad.  │
│ + bgGradient: Gradient    │
│ + ...                     │
└──────────────────────────┘

┌──────────────────────────┐
│          Tc               │
│──────────────────────────│
│ + isDark: bool            │
│──────────────────────────│
│ + Tc.of(ctx): Tc          │
│ + textPrimary: Color      │
│ + bgGradient: Gradient    │
│ + glassBorder: Color      │
└──────────────────────────┘

┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│    GlassCard      │    │  GlassIconTile   │    │   GlassButton    │
│──────────────────│    │──────────────────│    │──────────────────│
│ + child: Widget  │    │ + icon: IconData  │    │ + text: String   │
│ + padding        │    │ + label: String   │    │ + gradient       │
│ + borderRadius   │    │ + gradient        │    │ + onPressed()    │
│ + opacity        │    │ + onTap()         │    │ + icon           │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

#### 4.3.3 Sequence Diagram — Campus Map Navigation

```
  Student          MapScreen        MapController      OSM Server
    │                  │                  │                │
    │── Open Map Tab──▶│                  │                │
    │                  │── initState() ──▶│                │
    │                  │── move(center,15)│                │
    │                  │                  │── Fetch Tiles─▶│
    │                  │                  │◀── Tile Data ──│
    │◀─ Render map with landmarks ────────│                │
    │                  │                  │                │
    │── Tap Landmark──▶│                  │                │
    │                  │── _navigate(lm)──│                │
    │                  │               setState()          │
    │                  │── move(lm.pos, 17.0) ────────────▶│
    │                  │                  │── Fetch Tiles─▶│
    │                  │                  │◀── Tile Data ──│
    │◀─ Route line + Distance panel shown  │                │
    │                  │                  │                │
    │── End Navigation▶│                  │                │
    │                  │── _clearNav() ───│                │
    │                  │── move(center,15)│                │
    │◀─ Map reset to campus view ──────────                │
```

#### 4.3.4 Sequence Diagram — Theme Toggle

```
  Student         ProfileScreen      ThemeProvider      MaterialApp
    │                  │                  │                 │
    │── Toggle switch─▶│                  │                 │
    │                  │── ThemeProvider  │                 │
    │                  │   .of(context)──▶│                 │
    │                  │                  │                 │
    │                  │── toggleTheme()─▶│                 │
    │                  │              _isDarkMode = !dark   │
    │                  │              notifyListeners()──────────────────▶│
    │                  │                  │              rebuild with     │
    │                  │                  │              new ThemeData    │
    │◀─────────── Entire app re-rendered in new theme ──────────────────│
```

#### 4.3.5 Activity Diagram — Lost & Found Report

```
    [Start]
       │
       ▼
  Open Alerts Screen
       │
       ▼
  Tap "Lost & Found" Tab
       │
       ▼
  Tap "Report Item" Button
       │
       ▼
  LostFoundScreen Loaded
  (step = 0, progress bar shown)
       │
       ▼
  ┌─ Step 1: Select "Lost" or "Found" ─┐
  └──────────────────┬─────────────────┘
                     │ Tap Next
                     ▼
  ┌─ Step 2: Select Category ──────────┐
  └──────────────────┬─────────────────┘
                     │ Tap Next
                     ▼
  ┌─ Step 3: Enter Description ────────┐
  └──────────────────┬─────────────────┘
                     │ Tap Next
                     ▼
  ┌─ Step 4: Enter Location ───────────┐
  └──────────────────┬─────────────────┘
                     │ Tap Next
                     ▼
  ┌─ Step 5: Enter Contact Info ───────┐
  └──────────────────┬─────────────────┘
                     │ Tap Submit
                     ▼
             Confirmation shown
                     │
                     ▼
                  [End]
```

#### 4.3.6 State Diagram — App Theme

```
         ┌──────────────────────────────────┐
         │                                  │
         ▼                                  │
┌──────────────────┐   toggleTheme()  ┌─────┴────────────┐
│   Dark Mode       │ ───────────────▶ │   Light Mode      │
│  (Default State)  │                  │                   │
│  bg: #0A0E21      │ ◀─────────────── │  bg: #F1F5F9      │
│  text: #F1F5F9    │   toggleTheme()  │  text: #1E293B    │
│  glass: 10% white │                  │  glass: 10% black │
└──────────────────┘                  └──────────────────┘
         ▲                                  │
         │     Persists in ThemeNotifier     │
         └──────────────────────────────────┘
```

---

## 5. List of Modules

The application is organized into **8 functional modules**, each encapsulating a cohesive set of features:

| Module No. | Module Name | Description | Screen(s) |
|---|---|---|---|
| 1 | **Onboarding & Welcome** | First launch splash with app introduction and feature highlights | `WelcomeScreen` |
| 2 | **Home Dashboard** | Central hub with quick access to all features and latest updates feed | `HomeScreen` |
| 3 | **Campus Map & Navigation** | Interactive map with 9 landmarks, Haversine routing, and distance estimation | `MapScreen` |
| 4 | **Digital Identity** | QR-code-enabled digital student ID card | `MyIdScreen` |
| 5 | **Alerts & Notifications** | Tabbed alert feed covering academics, lost & found, and emergencies | `AlertsScreen`, `LostFoundScreen` |
| 6 | **Academic Records** | Timetable viewer and semester-wise results/GPA tracker | `TimetableScreen`, `ResultScreen` |
| 7 | **Community & Content** | Student forum, events calendar, and university circulars | `ForumScreen`, `EventsScreen`, `CircularsScreen` |
| 8 | **Profile & Settings** | User profile management, photo upload, theme toggle, and app settings | `ProfileScreen` |

### Module Breakdown

#### Module 1 — Onboarding & Welcome
- **File:** `lib/screens/welcome_screen.dart` (159 lines)
- **Type:** `StatelessWidget`
- **Entry point:** Shown on every cold launch before the dashboard
- **Features:** App logo, tagline, feature pills (Digital ID, Bus Tracking, Forum, Events), "Get Started" CTA

#### Module 2 — Home Dashboard
- **File:** `lib/screens/home_screen.dart` (253 lines)
- **Type:** `StatelessWidget`
- **Features:** Personalized greeting card, quick access grid (4 items), academics grid (Timetable + Results), latest updates feed

#### Module 3 — Campus Map & Navigation
- **File:** `lib/screens/map_screen.dart` (498 lines)
- **Type:** `StatefulWidget`
- **Features:** OSM tile map, 9 landmark markers, tap-to-navigate, Haversine distance, walking-time estimate, route polyline

#### Module 4 — Digital Identity
- **File:** `lib/screens/my_id_screen.dart` (361 lines)
- **Type:** `StatelessWidget`
- **Features:** Styled ID card, university branding, QR code, student details, active status badge

#### Module 5 — Alerts & Notifications
- **Files:** `lib/screens/alerts_screen.dart` (363 lines), `lib/screens/lost_found_screen.dart` (447 lines)
- **Type:** `StatefulWidget`
- **Features:** 4-tab alerts view, 5-step lost & found wizard

#### Module 6 — Academic Records
- **Files:** `lib/screens/timetable_screen.dart` (194 lines), `lib/screens/result_screen.dart` (216 lines)
- **Type:** `StatefulWidget`
- **Features:** Day-selector timetable, semester-selector results, GPA summary

#### Module 7 — Community & Content
- **Files:** `lib/screens/forum_screen.dart` (142 lines), `lib/screens/events_screen.dart` (133 lines), `lib/screens/circulars_screen.dart` (153 lines)
- **Type:** `StatelessWidget`
- **Features:** Post cards with like/reply counts, event listings, notice board with unread badges

#### Module 8 — Profile & Settings  (Campus Services also accessible here via Quick Access)
- **Files:** `lib/screens/profile_screen.dart` (1086 lines), `lib/screens/services_screen.dart` (119 lines)
- **Type:** `StatefulWidget`
- **Features:** Avatar picker, editable fields, theme toggle, font size, app lock, service grid

---

## 6. Output of Module 1 — Onboarding & Welcome

### 6.1 Module Overview

**Module Name:** Onboarding & Welcome  
**File:** `lib/screens/welcome_screen.dart`  
**Widget Type:** `StatelessWidget`  
**Lines of Code:** 159

This is the **first screen** a student sees when they launch PUnova. Its purpose is to introduce the app, communicate its value proposition, and guide the user into the main dashboard.

### 6.2 UI Components

| Component | Description |
|---|---|
| Background | Full-screen dark gradient (`#0A0E21` → `#0D1234` → `#111631`) |
| Teal Orb | Radial gradient circle (top-right, 250×250 px, 15% teal opacity) — depth effect |
| Purple Orb | Radial gradient circle (bottom-left, 300×300 px, 12% purple opacity) — depth effect |
| App Logo | 100×100 px rounded-corner image from `assets/images/app_logo.png` with cyan glow shadow |
| App Name | "PUnova" — 40 px, Outfit font, weight 800, letter-spacing −1 |
| Tagline | "Your complete university companion. Everything you need, one tap away." — Inter, muted color |
| Feature Pills | 4 horizontal chip badges with icon + label |
| CTA Button | Full-width "Get Started" `GlassButton` with arrow icon and `primaryGradient` fill |

### 6.3 Feature Pills

| Pill | Icon | Label |
|---|---|---|
| 1 | `badge_outlined` | Digital ID |
| 2 | `directions_bus_outlined` | Bus Tracking |
| 3 | `forum_outlined` | Forum |
| 4 | `event_outlined` | Events |

Each pill is a `Container` with:
- Background: `AppColors.glassWhite` (10% white opacity)
- Border: `AppColors.glassBorder` (20% white, 0.5 px)
- Border radius: 20 px (fully rounded)
- Icon color: `AppColors.accentTeal` (`#00D2FF`)

### 6.4 Layout Structure

```
Scaffold
└── Container (full-screen gradient)
    └── Stack
        ├── Positioned (Teal orb — top right)
        ├── Positioned (Purple orb — bottom left)
        └── SafeArea
            └── Padding (horizontal: 32)
                └── Column
                    ├── Spacer (flex: 2)
                    ├── App Logo (100×100, rounded, glow shadow)
                    ├── SizedBox (32)
                    ├── Text "PUnova" (40px, Outfit, w800)
                    ├── SizedBox (16)
                    ├── Text tagline (Inter, muted, centered)
                    ├── Spacer (flex: 2)
                    ├── Wrap (feature pills — 4 chips)
                    ├── Spacer (flex: 1)
                    ├── GlassButton "Get Started"
                    └── SizedBox (40)
```

### 6.5 Navigation Flow

```
  App Launch
      │
      ▼
  AppEntry._showWelcome == true
      │
      ▼
  WelcomeScreen rendered
      │
      │  User taps "Get Started"
      ▼
  onGetStarted() callback fired
      │
      ▼
  setState(() => _showWelcome = false)
      │
      ▼
  DashboardShell rendered (Home tab active)
```

### 6.6 Code Walkthrough

```dart
// Entry in AppEntry — decides which screen to show
class _AppEntryState extends State<AppEntry> {
  bool _showWelcome = true;

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomeScreen(
        onGetStarted: () => setState(() => _showWelcome = false),
      );
    }
    return const DashboardShell();
  }
}
```

```dart
// Feature pill helper widget
Widget _featurePill(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.glassWhite,               // 10% white
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentTeal),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12)),
      ],
    ),
  );
}
```

### 6.7 Expected Screen Output

```
┌────────────────────────────────────┐
│                            ●●●     │  ← Teal glow orb (top-right)
│                                    │
│                                    │
│                                    │
│           ┌──────────┐             │
│           │  [LOGO]  │             │  ← Rounded logo with cyan shadow
│           └──────────┘             │
│                                    │
│              PUnova                │  ← 40px Outfit Bold
│                                    │
│   Your complete university         │
│   companion. Everything you        │  ← Inter, muted color
│   need, one tap away.              │
│                                    │
│                                    │
│  🪪 Digital ID   🚌 Bus Tracking  │
│  💬 Forum        📅 Events        │  ← Feature pills
│                                    │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  →  Get Started              │  │  ← Teal→Cyan gradient button
│  └──────────────────────────────┘  │
│                                    │
│  ●●                                │  ← Purple glow orb (bottom-left)
└────────────────────────────────────┘
```

### 6.8 Design Decisions for Module 1

1. **Stateless design** — The welcome screen holds no state of its own; the `_showWelcome` flag lives in the parent `AppEntry` keeping the screen pure and testable.
2. **Callback-based navigation** — Instead of using `Navigator.push`, the screen fires a callback, decoupling it from the navigation stack and making it reusable.
3. **Decorative orbs without blur** — Radial gradient `Container`s simulate depth/atmosphere without `BackdropFilter`, preserving performance.
4. **Feature pills as marketing copy** — The four pills serve a dual purpose: introduce features and set user expectations before they enter the app.
5. **Logo glow shadow** — A `BoxShadow` with `accentTeal` color at 35% opacity reinforces the brand identity immediately on first launch.

---

*Document generated for PUnova v1.0.0 · Pondicherry University · February 2026*
