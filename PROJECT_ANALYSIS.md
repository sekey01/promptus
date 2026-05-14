# Promptus — Codebase Analysis

## Architecture

| Concern | Implementation |
|---|---|
| Pattern | Simple layered (no formal MVVM/Clean) |
| State management | Provider (ChangeNotifier) |
| Navigation | Navigator 1.0 — `MaterialPageRoute` everywhere |
| Storage | SQLite via `sqflite`; singleton `DatabaseService` |
| Notifications | `flutter_local_notifications`; singleton `NotificationService` |
| Theme | `ThemeService` (ChangeNotifier) with static `lightTheme` / `darkTheme` |
| Preferences | `shared_preferences` (user name, dark-mode flag) |

---

## File Map

```
lib/
├── main.dart                        # App entry; double-MaterialApp (anti-pattern)
├── models/
│   ├── expense_model.dart           # Expense data class + SQL serialisation
│   ├── task_model.dart              # Task data class + SQL serialisation
│   └── theme_model.dart            # Thin wrapper around SharedPreferences (partially used)
├── screens/
│   ├── splash_screen.dart          # Gradient + animation, references missing asset
│   ├── main_screen.dart            # Tab host: Expenses | Tasks; FAB
│   ├── expenses_screen.dart        # Expense list + summary + category breakdown
│   ├── task_screen.dart            # Task list + progress card + weekly bar chart
│   ├── add_expenses_screen.dart    # Add / edit expense form
│   ├── add_task_screen.dart        # Add / edit task form + reminder + alarm toggle
│   ├── profile_screen.dart         # Profile header + stats + account management
│   └── demographics_screen.dart   # Analytics: task & expense breakdowns + insights
├── services/
│   ├── database_service.dart       # SQLite CRUD for tasks & expenses; analytics queries
│   ├── notification_service.dart   # Schedule / cancel local notifications
│   └── theme_service.dart          # Static light/dark ThemeData (RobotoMono font)
└── widgets/
    ├── expense_widget.dart          # ExpenseItem card (bottom-sheet options)
    └── task_item.dart              # TaskItem card (popup-menu options)
```

---

## Known Bugs / Issues (pre-redesign)

| # | Location | Issue |
|---|---|---|
| 1 | `main.dart` | Double `MaterialApp` — outer has no theme; inner has no `themeMode` |
| 2 | `splash_screen.dart:259` | Loads `assets/icon/app_logo.png` which was deleted |
| 3 | `demographics_screen.dart:82-83` | Calls `loadTasks()` / `loadExpenses()` (return `void`) and tries to assign the result |
| 4 | `theme_service.dart` | `ThemeModel` saves dark-mode preference but `ThemeService` ignores it; no real toggle |
| 5 | `main_screen.dart:58-68` | FAB opens **wrong** screen per tab (inverted) |

---

## Screens — UI improvement targets

| Screen | Improvements |
|---|---|
| **Splash** | Replace broken image ref with in-code logo widget; update tagline |
| **MainScreen** | Fix FAB swap; improve tab bar visual; add `themeMode` to MaterialApp |
| **ExpensesScreen** | Consolidate hardcoded `Colors.purple` to theme; add filter chips |
| **TaskScreen** | Improve progress card; replace hardcoded weekly bar data |
| **AddExpenseScreen** | Poppins/Inter typography; gradient save button |
| **AddTaskScreen** | Same typography uplift; cleaner reminder UI |
| **ProfileScreen** | Theme toggle UI; clean up orange analytics button |
| **DemographicsScreen** | Fix void-assign bug; improve charts |
| **ExpenseItem** | Richer card with better spacing |
| **TaskItem** | Replace PopupMenu with bottom-sheet (consistent with ExpenseItem) |

---

## Design System Plan

```
lib/core/
├── theme/
│   ├── app_colors.dart       # Light + dark palettes
│   ├── app_typography.dart   # Poppins (headings) + Inter (body)
│   ├── app_spacing.dart      # 8-pt grid
│   ├── app_radius.dart       # Border radius scale
│   ├── app_shadows.dart      # 5 elevation levels
│   └── app_theme.dart        # Assembles ThemeData (replaces theme_service.dart themes)
└── widgets/
    ├── promptus_button.dart
    ├── promptus_card.dart
    ├── promptus_input.dart
    ├── empty_state.dart
    └── loading_shimmer.dart
```

---

## Packages to add

```yaml
flutter_animate: ^4.5.0   # Declarative animations
shimmer: ^3.0.0            # Loading skeleton
```

---

## Assets folder target

```
assets/
├── images/
│   └── logo_placeholder.png  # Will be created as a generated asset
└── lottie/                   # Placeholder — add real Lottie files from lottiefiles.com
```
