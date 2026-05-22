# FlashLearn — Widget & Method Implementation Reference

---

## USER DASHBOARD — `fields_screen.dart`

### 1. Day Goal

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_dailyGoalsCard()` | Builder method returning the full day-goal card | `fields_screen.dart` |
| 2 | `Container` | Outer card with `LinearGradient` background | `_dailyGoalsCard()` |
| 3 | `LinearProgressIndicator` | Progress bar showing done/goal ratio | `_dailyGoalsCard()` |
| 4 | `ClipRRect` | Rounds corners of the progress bar | `_dailyGoalsCard()` |
| 5 | `AlwaysStoppedAnimation` | Keeps progress bar color white (static) | `_dailyGoalsCard()` |
| 6 | `prov.todayCardCount` | Number of cards studied today | `AppProvider` |
| 7 | `prov.dayGoal` | Target number of cards for the day | `AppProvider` |
| 8 | `prov.dayGoalReached` | Boolean — true when goal is met | `AppProvider` |
| 9 | `_showDayGoalSheet()` | Opens bottom sheet to change goal value | `fields_screen.dart` |
| 10 | `showModalBottomSheet` | Displays the `_DayGoalSheet` widget | `_showDayGoalSheet()` |
| 11 | `_QuickActionBtn` | "Day Goal" shortcut button in Quick Actions row | `fields_screen.dart` |

---

### 2. Bottom App Bar

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_bottomNav()` | Builder method returning the entire nav bar | `fields_screen.dart` |
| 2 | `Container` | Outer bar with white background and top border shadow | `_bottomNav()` |
| 3 | `SizedBox(height: 60)` | Fixed height for the nav bar row | `_bottomNav()` |
| 4 | `Row` | Lays out all nav items horizontally | `_bottomNav()` |
| 5 | `Material` + `InkWell` | Provides ripple feedback on tap | `_bottomNav()` |
| 6 | `AnimatedContainer` | Animates active tab highlight (gradient pill) | `_bottomNav()` |
| 7 | `Icon` | Tab icon (active / inactive pair per item) | `_bottomNav()` |
| 8 | `Text` | Tab label below icon | `_bottomNav()` |
| 9 | `Stack` + `Positioned` | Places the notification badge dot over the bell icon | `_bottomNav()` |
| 10 | `Container` (circle) | Red circular notification badge | `_bottomNav()` |
| 11 | `_onNavTap()` | Routes each tab to the correct screen/sheet | `fields_screen.dart` |
| 12 | `_navItems` const list | Stores `(activeIcon, inactiveIcon, label)` for all 5 tabs | `fields_screen.dart` |

---

### 3. Search

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_heroHeader()` | Contains the search bar at the bottom of the header | `fields_screen.dart` |
| 2 | `TextField` | Main search input field | `_heroHeader()` |
| 3 | `TextEditingController _searchCtrl` | Manages text input and clear action | `fields_screen.dart` |
| 4 | `String _searchQuery` | State variable updated on every `onChanged` | `fields_screen.dart` |
| 5 | `Container` | White rounded wrapper around the search field | `_heroHeader()` |
| 6 | `Icon(Icons.search_rounded)` | Prefix search icon | `_heroHeader()` |
| 7 | `GestureDetector` | Wraps the clear (×) icon | `_heroHeader()` |
| 8 | `Icon(Icons.close_rounded)` | Clears text when tapped | `_heroHeader()` |
| 9 | `_filteredFields()` | Filters field list by name, desc, or title | `fields_screen.dart` |
| 10 | `_searchResultsSection()` | Renders search results when query is non-empty | `fields_screen.dart` |
| 11 | `_searchResultCard()` | Card widget for each matching field result | `fields_screen.dart` |

---

### 4. Your Dashboard

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_mobileDashboard()` | Builder method for the dashboard section | `fields_screen.dart` |
| 2 | `CustomPaint` | Renders the circular achievement donut chart | `_mobileDashboard()` |
| 3 | `_DonutPainter` | `CustomPainter` — draws arcs with `canvas.drawArc` | `fields_screen.dart` |
| 4 | `Center` | Centers the percentage text inside the donut | `_mobileDashboard()` |
| 5 | `_miniStat()` | Helper widget — icon + value + label card | `_mobileDashboard()` |
| 6 | `Row` | Lays out donut + 3 mini-stat cards side-by-side | `_mobileDashboard()` |
| 7 | `prov.achievements` | List of all achievements (unlocked/locked) | `AppProvider` |
| 8 | `prov.totalCardsThisWeek` | Cards studied this week | `AppProvider` |
| 9 | `prov.fieldFinalsPassed` | List of course IDs where final exam was passed | `AppProvider` |

---

### 5. Profile

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_openProfileSheet()` | Shows the profile modal bottom sheet | `fields_screen.dart` |
| 2 | `showModalBottomSheet` | Displays the profile `Container` sheet | `_openProfileSheet()` |
| 3 | `_buildProfileAvatar()` | Builds `CircleAvatar` with `CachedNetworkImage` | `fields_screen.dart` |
| 4 | `CachedNetworkImage` | Loads Google photo or UI-Avatars fallback | `_buildProfileAvatar()` |
| 5 | `CircleAvatar` | Fallback avatar with initial letter | `_buildProfileAvatar()` |
| 6 | `_profileStatTile()` | Helper widget — icon + value + label for stats row | `_openProfileSheet()` |
| 7 | `Switch.adaptive` | Dark mode toggle inside profile sheet | `_openProfileSheet()` |
| 8 | `ElevatedButton.icon` | "Sign Out" button — calls `prov.auth.signOut()` | `_openProfileSheet()` |
| 9 | `OutlinedButton.icon` | "Weekly Report" button → `/weekly-report` | `_openProfileSheet()` |
| 10 | `GestureDetector` | Wraps avatar in header to open the profile sheet | `_heroHeader()` |
| 11 | `prov.auth.displayName` | Gets the logged-in user's display name | `AppProvider` |
| 12 | `prov.toggleDarkMode()` | Switches between light and dark theme | `AppProvider` |

---

### 6. Flip Cards (Study Cards & Flash Mind Cards)

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_FlipFieldCard` | `StatefulWidget` — the "Flash Mind" subject flip card | `fields_screen.dart` |
| 2 | `AnimationController _ctrl` | Controls the 0→1 flip animation (400 ms) | `_FlipFieldCardState` |
| 3 | `CurvedAnimation(Curves.easeInOut)` | Smooth easing on the flip | `_FlipFieldCardState` |
| 4 | `_flip()` | Toggles `_ctrl.forward()` / `_ctrl.reverse()` | `_FlipFieldCardState` |
| 5 | `AnimatedBuilder` | Rebuilds the card on every animation tick | `_FlipFieldCard.build()` |
| 6 | `Transform` (outer) | Applies `Matrix4..rotateY(val * pi)` for 3-D rotation | `_FlipFieldCard.build()` |
| 7 | `Transform` (inner back) | Applies `Matrix4.rotationY(pi)` to un-mirror back face | `_FlipFieldCard.build()` |
| 8 | `Matrix4.identity()..setEntry(3,2,0.001)` | Adds perspective depth to the 3-D flip | `_FlipFieldCard.build()` |
| 9 | `GestureDetector(onTap: _flip)` | Triggers the card flip on user tap | `_FlipFieldCard.build()` |
| 10 | `StudyCardWidget` | Custom widget for study-mode flip cards | `lib/widgets/study_card_widget.dart` |
| 11 | `AnimationController _flipCtrl` | Flip animation controller inside `StudyCardWidget` | `study_card_widget.dart` |
| 12 | `AnimationController _entranceCtrl` | Scale-in entrance animation when card loads | `study_card_widget.dart` |
| 13 | `ScaleTransition` | Wraps the card for entrance scale animation | `study_card_widget.dart` |
| 14 | `InkWell(onTap: widget.onCorrect)` | Marks card as correct on tap | `study_card_widget.dart` |
| 15 | `InkWell(onTap: widget.onWrong)` | Marks card as wrong on tap | `study_card_widget.dart` |
| 16 | `_upcomingSection()` | Renders the horizontal `ListView` of `_FlipFieldCard` | `fields_screen.dart` |

---

### 7. Exam Levels

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `LevelCard` | Custom `StatelessWidget` for each difficulty level | `lib/widgets/level_card.dart` |
| 2 | `for` loop | Iterates `['easy', 'normal', 'hard']` to build 3 `LevelCard`s | `field_home_screen.dart` |
| 3 | `AnimatedOpacity` | Fades the Final Exam card (locked = 0.5 opacity) | `field_home_screen.dart` |
| 4 | `Container` (Final Exam) | Holds the final exam card UI | `field_home_screen.dart` |
| 5 | `GestureDetector` (Study) | Calls `prov.setLevel()` + `Navigator.pushNamed('/study')` | `LevelCard` |
| 6 | `GestureDetector` (Assess) | Calls `prov.startAssessment()` + `Navigator.pushNamed('/quiz')` | `LevelCard` |
| 7 | `GestureDetector` (Final Exam) | Calls `prov.startFinalExam()` + `Navigator.pushNamed('/quiz')` | `field_home_screen.dart` |
| 8 | `GestureDetector` (View Cert) | Calls `prov.loadCertificateFor()` + `Navigator.pushNamed('/certificate')` | `field_home_screen.dart` |
| 9 | `LinearGradient` | Field-colored gradient on the header banner | `field_home_screen.dart` |
| 10 | `isLocked` condition | `i > 0 && !prov.completedLevels.contains(_levels[i-1])` | `field_home_screen.dart` |
| 11 | `_confirmRetake()` | `showDialog` → `AlertDialog` to confirm course reset | `field_home_screen.dart` |
| 12 | `prov.allLevelsComplete` | True when all 3 levels are done — unlocks final exam | `AppProvider` |

---

### 8. Time Countdown (Assessment / Quiz Screen)

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `Timer.periodic` | Decrements `_timeLeft` every 1 second | `quiz_screen.dart` |
| 2 | `Timer? _questionTimer` | Holds the reference to the countdown timer | `quiz_screen.dart` |
| 3 | `int _timeLeft` | State variable for seconds remaining | `quiz_screen.dart` |
| 4 | `_startQuestionTimer()` | Resets and starts the countdown timer | `quiz_screen.dart` |
| 5 | `_handleTimeout()` | Called when `_timeLeft <= 0` — auto-marks timeout | `quiz_screen.dart` |
| 6 | `AnimationController _pulseCtrl` | Drives pulse scale animation in final 8 seconds | `quiz_screen.dart` |
| 7 | `Tween<double>(1.0 → 1.18)` | Defines the pulse scale range | `quiz_screen.dart` |
| 8 | `ScaleTransition(scale: _pulse)` | Wraps the timer widget to apply the pulse | `quiz_screen.dart` |
| 9 | `CircularProgressIndicator` | Circular arc showing time left visually | `quiz_screen.dart` |
| 10 | `Text('$_timeLeft')` | Large countdown number displayed inside timer | `quiz_screen.dart` |
| 11 | `Container` | Pill-shaped wrapper for the timer display | `quiz_screen.dart` |
| 12 | `Timer? _feedbackTimer` | Delays auto-advance after an answer is selected | `quiz_screen.dart` |
| 13 | `_scheduleAdvance()` | Waits 1800 ms then calls `prov.answerQuestion()` | `quiz_screen.dart` |

---

### 9. Certificates

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `CertificateScreen` | Root `StatelessWidget` for the certificate screen | `certificate_screen.dart` |
| 2 | `Scaffold` | Base screen container | `certificate_screen.dart` |
| 3 | `Column` | Stacks header banner + scrollable cert body | `certificate_screen.dart` |
| 4 | `Container` + `LinearGradient` | Field-colored gradient header banner | `certificate_screen.dart` |
| 5 | `prov.lastCertificate` | Holds the certificate data model | `AppProvider` |
| 6 | `prov.loadCertificateFor(fieldId)` | Populates `lastCertificate` before navigating | `AppProvider` |
| 7 | `fieldGradient(cert.fieldId)` | Returns gradient colors for the cert's subject | `fields_data.dart` |
| 8 | `ElevatedButton` | "Download PDF" button | `certificate_screen.dart` |
| 9 | `Printing.layoutPdf()` | Generates and shares the PDF (from `printing` package) | `certificate_screen.dart` |
| 10 | `pw.Document` | PDF document builder (from `pdf` package) | `certificate_screen.dart` |
| 11 | `GestureDetector` | Back button to pop the screen | `certificate_screen.dart` |
| 12 | `Navigator.pushNamed('/certificate')` | Navigation trigger from `field_home_screen.dart` | `field_home_screen.dart` |

---

---

## ADMIN DASHBOARD — `admin_screen.dart`

### 1. 7-Day Activity (Bar Chart)

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_ActivityBarChart` | `StatefulWidget` rendering the bar chart | `admin_screen.dart` |
| 2 | `AnimationController _ctrl` | Drives bar grow-in animation (900 ms) | `_ActivityBarChartState` |
| 3 | `CurvedAnimation(Curves.easeOut)` | Smooth easing on bar growth | `_ActivityBarChartState` |
| 4 | `AnimatedBuilder` | Rebuilds bars on each animation frame | `_ActivityBarChart.build()` |
| 5 | `Row` | Lays out the 7 day-bars horizontally | `_ActivityBarChart.build()` |
| 6 | `AnimatedContainer` | Each bar — height animated by `frac * _anim.value` | `_ActivityBarChart.build()` |
| 7 | `LinearGradient` | Green gradient for today's bar, blue for past days | `_ActivityBarChart.build()` |
| 8 | `StreamBuilder<QuerySnapshot>` | Listens to Firestore users collection in real-time | `_OverviewSection.build()` |
| 9 | `FirestoreService().usersStream` | Firestore stream of all user documents | `FirestoreService` |
| 10 | `dailyCards` map | Per-user Firestore field storing cards-per-date | `Firestore user doc` |
| 11 | `_PulsingDot` | Animated "Live" indicator next to the chart title | `_OverviewSection` |
| 12 | `_GlassCard` | Wraps the chart in a frosted-glass styled card | `_OverviewSection` |

---

### 2. Recently Active Users

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_UserRowCompact` | `StatelessWidget` — compact user row card | `admin_screen.dart` |
| 2 | `_GlassCard` | Frosted-glass card container for each row | `_UserRowCompact` |
| 3 | `Material` + `InkWell` | Tap feedback on the user row | `_UserRowCompact` |
| 4 | `Row` | Lays out avatar, name/email, stats, chevron | `_UserRowCompact` |
| 5 | `Container` (avatar) | Circular gradient avatar with initial letter | `_UserRowCompact` |
| 6 | `LinearGradient` | Purple-violet gradient on the avatar | `_UserRowCompact` |
| 7 | `_MiniStat` | Small icon + value chip for streak and cards | `_UserRowCompact` |
| 8 | `_showDetailSheet()` | Opens `_UserDetailSheet` via `showModalBottomSheet` | `_UserRowCompact` |
| 9 | `_UserDetailSheet` | Full-detail bottom sheet with stats grid | `admin_screen.dart` |
| 10 | `docs.take(5)` | Limits recently active list to 5 users | `_OverviewSection` |
| 11 | `_timeAgo()` | Helper — converts `DateTime` to "X min ago" string | `admin_screen.dart` |
| 12 | `_PulsingDot` | "Live sync" animated dot in the users header | `_UsersSection` |

---

### 3. Field Management

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_FieldsSection` | `StatelessWidget` — root of the Fields tab | `admin_screen.dart` |
| 2 | `Stack` | Layers the `ListView` and the floating Add button | `_FieldsSection` |
| 3 | `ListView` | Scrollable list of `_FieldCard` widgets | `_FieldsSection` |
| 4 | `_FieldCard` | `StatefulWidget` — individual expandable field card | `admin_screen.dart` |
| 5 | `AnimatedSize` | Animates expand/collapse of the detail section | `_FieldCard` |
| 6 | `AnimatedRotation` | Rotates the chevron icon 180° when expanded | `_FieldCard` |
| 7 | `Material` + `InkWell` | Tap feedback to toggle expand/collapse | `_FieldCard` |
| 8 | `Container` (gradient icon) | Field icon box with `LinearGradient` + shadow | `_FieldCard` |
| 9 | `_GlassIconBtn` | Small icon button for Edit and Delete actions | `_FieldCard` |
| 10 | `_FieldExpandedDetail` | Shows card/MCQ breakdown by level when expanded | `admin_screen.dart` |
| 11 | `_showEditDialog()` | `showDialog` → `StatefulBuilder` → `AlertDialog` with `_DialogField` | `_FieldCard` |
| 12 | `_showDeleteConfirm()` | `showDialog` → `AlertDialog` → `prov.deleteField()` | `_FieldCard` |
| 13 | `_PremiumFab` | Floating "Add Field" action button | `_FieldsSection` |
| 14 | `_showFieldDialog()` | Opens dialog to add a new field | `_FieldsSection` |
| 15 | `_DarkChip` | Small label chip showing card/MCQ/level counts | `_FieldCard` |
| 16 | `prov.isUserDeck(f.id)` | Detects user-created decks for separate grouping | `AppProvider` |

---

### 4. Content (Cards & Questions)

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_ContentSection` | `StatefulWidget` — root of the Content tab | `admin_screen.dart` |
| 2 | `TabController` | Controls 3-tab navigation (Study / MCQ / Final) | `_ContentSectionState` |
| 3 | `TabBar` | Renders the 3 tab labels with green indicator | `_ContentSection` |
| 4 | `TabBarView` | Swipeable tab content area | `_ContentSection` |
| 5 | `ListView` (field selector) | Horizontal scrollable field pill selector | `_ContentSection` |
| 6 | `AnimatedContainer` (pill) | Active pill gets gradient; inactive gets border only | `_ContentSection` |
| 7 | `_StudyCardsTab` | Tab widget listing study cards by level | `admin_screen.dart` |
| 8 | `_MCQTab` | Tab widget listing MCQ questions by level | `admin_screen.dart` |
| 9 | `_FinalExamTab` | Tab widget listing final exam questions | `admin_screen.dart` |
| 10 | `_StudyCardRow` | `_GlassCard` row with question/answer + edit/delete | `admin_screen.dart` |
| 11 | `_MCQRow` | Similar to `_StudyCardRow` with correct-answer badge | `admin_screen.dart` |
| 12 | `StreamBuilder<QuerySnapshot>` | Live-syncs admin-added cards from Firestore | `_StudyCardsTab`, `_MCQTab` |
| 13 | `_showCardDialog()` | `showDialog` → `StatefulBuilder` → `AlertDialog` with `_LevelPicker` + `_DialogField` | `_StudyCardsTab` |
| 14 | `_LevelPicker` | Row of 3 tap-to-select level buttons (Easy/Normal/Hard) | `admin_screen.dart` |
| 15 | `FirestoreService().saveAdminCard()` | Writes/updates study card to Firestore | `FirestoreService` |
| 16 | `FirestoreService().saveAdminQuestion()` | Writes/updates MCQ question to Firestore | `FirestoreService` |
| 17 | `FirestoreService().saveAdminFinalQuestion()` | Writes/updates final exam question to Firestore | `FirestoreService` |
| 18 | `BackdropFilter(ImageFilter.blur)` | Glass blur effect on the Final Exam info card | `_FinalExamTab` |

---

### 5. Users & Alerts

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `_UsersSection` | `StatefulWidget` — root of the Users tab | `admin_screen.dart` |
| 2 | `StreamBuilder<QuerySnapshot>` | Real-time Firestore stream of all users | `_UsersSection` |
| 3 | `TextField` | Search bar filtering users by name or email | `_UsersSection` |
| 4 | `ListView.builder` | Builds one `_UserCard` per filtered user | `_UsersSection` |
| 5 | `_UserCard` | `StatelessWidget` — full user card with activity chart | `admin_screen.dart` |
| 6 | `ClipRRect` + `BackdropFilter` | Glass-blur frosted background on each user card | `_UserCard` |
| 7 | `Material` + `InkWell` | Tap to open user detail sheet | `_UserCard` |
| 8 | `_StatPill` | Small stat chip (streak, cards, quizzes, badges, certs) | `_UserCard` |
| 9 | `SizedBox` + `Row` | Mini 7-day bar chart per user | `_UserCard` |
| 10 | `AnimatedContainer` | Individual bars in the mini user activity chart | `_UserCard` |
| 11 | `_GlassIconBtn` | Edit, Suspend, Delete action buttons per user | `_UserCard` |
| 12 | `FirestoreService().setUserSuspended()` | Toggles user suspension flag in Firestore | `_UserCard` |
| 13 | `_showRemoveDialog()` | `showDialog` → `AlertDialog` → `FirestoreService().removeUserRecord()` | `_UserCard` |
| 14 | `_UserDetailSheet` | `DraggableScrollableSheet` with full user stats | `admin_screen.dart` |
| 15 | `DraggableScrollableSheet` | Draggable bottom sheet for user detail view | `_UserDetailSheet` |
| 16 | `GridView.count` | 3-column stat grid inside user detail sheet | `_UserDetailSheet` |
| 17 | `_NotificationsSection` | 5th tab — compose & send push notifications | `admin_screen.dart` |
| 18 | `FirestoreService().sendNotification()` | Writes notification document to Firestore | `FirestoreService` |

---

### 6. Toggle Dark Mode

| # | Widget / Method | Description | Location |
|---|---|---|---|
| 1 | `GestureDetector` | Detects tap on the toggle pill | `_AdminAppBar` |
| 2 | `AnimatedContainer` | 64×32 pill that animates background color on toggle | `_AdminAppBar` |
| 3 | `AnimatedAlign` | Slides the thumb left (light) or right (dark) | `_AdminAppBar` |
| 4 | `Container` (thumb) | 26×26 circle with `Icons.dark_mode_rounded` / `Icons.light_mode_rounded` | `_AdminAppBar` |
| 5 | `BoxShadow` | Green glow behind the active thumb | `_AdminAppBar` |
| 6 | `prov.isDarkMode` | Boolean state for current theme | `AppProvider` |
| 7 | `prov.toggleDarkMode()` | Switches the theme in `AppProvider` | `AppProvider` |
| 8 | `Switch.adaptive` | Used for the same toggle in the user Profile sheet | `fields_screen.dart` |

---

## SHARED HELPER WIDGETS — `admin_screen.dart`

| Widget | Type | Purpose |
|---|---|---|
| `_GlassCard` | `StatelessWidget` | Reusable frosted-glass card container |
| `_GlowOrb` | `StatelessWidget` | Radial gradient ambient background orb |
| `_PulsingDot` | `StatefulWidget` | Animated live-indicator dot using `AnimationController` + `AnimatedBuilder` |
| `_BottomNav` | `StatelessWidget` | 5-tab admin bottom navigation bar |
| `_AppLogo` | `StatelessWidget` | Green gradient logo box with school icon |
| `_AdminAvatar` | `StatelessWidget` | Admin profile avatar — opens `showModalBottomSheet` |
| `_GlassIconBtn` | `StatelessWidget` | Small rounded icon button (edit / delete) |
| `_SectionLabel` | `StatelessWidget` | Bold section header `Text` widget |
| `_KpiCard` | `StatelessWidget` | Overview KPI tile with animated counter |
| `_ShimmerBox` | `StatelessWidget` | Loading placeholder shimmer rectangle |
| `_DonutPainter` | `CustomPainter` | Draws subject distribution donut arcs on `Canvas` |
| `_OverviewHero` | `StatelessWidget` | Gradient hero card at top of Overview section |
| `_StatusCard` | `StatelessWidget` | Firebase service status panel with pulsing dots |
| `_ProfileInfoRow` | `StatelessWidget` | Single info row (icon + label + value) in profile sheet |
| `_LetterAvatar` | `StatelessWidget` | Fallback avatar with initial letter |
| `_DialogField` | `StatelessWidget` | Styled `TextField` used inside all `AlertDialog` forms |
| `_LevelPicker` | `StatelessWidget` | Easy/Normal/Hard selector row used in card dialogs |
| `_AdminBadge` | `StatelessWidget` | "Admin" label badge on admin-added cards |
| `_PremiumFab` | `StatelessWidget` | Gradient floating action button |
