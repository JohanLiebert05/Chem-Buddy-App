# ChemBuddy Design System (v3.0)

This document establishes the authoritative design tokens, atomic component specifications, and layout guidelines for ChemBuddy — the 10/10 Chemistry Study Companion for MSc Chemistry students.

---

## Color Palette & Tokens

ChemBuddy uses a deep, focused dark-mode aesthetic tuned for prolonged academic study without eye fatigue, accented with luminescent chemistry violet and indigo gradients.

### Surface & Background Tokens

| Token | Hex Value | Semantic Purpose |
|:---|:---|:---|
| `bg-0` | `#0A0914` | Deepest canvas background. Base layer beneath all screens. |
| `bg-1` | `#131127` | Standard card and container surface. |
| `bg-2` | `#1E1B38` | Elevated surfaces, floating dialogs, input fields, and active chips. |
| `card` | `rgba(19, 17, 39, 0.88)` | Translucent glassmorphic card fill with blur filter. |

### Border Tokens

| Token | Hex / Value | Semantic Purpose |
|:---|:---|:---|
| `borderSubtle` | `rgba(255, 255, 255, 0.08)` | Standard hairline borders for cards and dividers. |
| `borderHighlight` | `rgba(167, 139, 250, 0.28)` | Focus borders, active cards, and selected state outlines. |
| `borderAccent` | `rgba(139, 92, 246, 0.50)` | Elevated interactive borders and highlighted CTAs. |

### Brand & Accent Tokens

| Token | Hex Value | Semantic Purpose |
|:---|:---|:---|
| `brandPrimary` | `#8B5CF6` | Core vibrant violet. Primary buttons, selected tab indicators. |
| `brandBright` | `#A78BFA` | Bright lavender. Headings, chemical formula highlights, LaTeX symbols. |
| `brandDeep` | `#6B45FA` | Deep royal violet. Background glow gradients, active shadows. |
| `brandGradient` | `LinearGradient([#8B5CF6, #6366F1])` | Signature ChemBuddy button and hero card gradient. |
| `accentCyan` | `#06B6D4` | Secondary science accent. Spectroscopy and lab highlights. |
| `accentGold` | `#F59E0B` | Study streaks, high-accuracy badges, active recall achievements. |

### Semantic Status Tokens

| Token | Hex Value | Semantic Purpose |
|:---|:---|:---|
| `statusSuccess` | `#10B981` | Safe attendance (>= 75%), correct quiz answers, strong topics. |
| `statusWarning` | `#F59E0B` | Attendance warning (65-74%), review due, moderate mastery. |
| `statusDanger` | `#EF4444` | Attendance risk (< 65%), incorrect quiz answers, weak topics. |
| `statusInfo` | `#60A5FA` | Lecture reminders, informational callouts, calendar events. |

---

## Spacing & Grid System

ChemBuddy adheres to a strict 8-pixel base grid:
- space-1: 4px (micro-padding, badge insets)
- space-2: 8px (chip spacing, compact gaps)
- space-3: 12px (form field gaps, card sub-headers)
- space-4: 16px (standard card padding, screen gutters)
- space-5: 20px (screen margins, major section dividers)
- space-6: 24px (bottom nav clearance, section titles)
- space-8: 32px (hero bottom clearance, modal margins)

---

## Corner Radii
- radius-sm: 8px (buttons, badge chips, code blocks)
- radius-md: 12px (input fields, mini stat tiles)
- radius-lg: 16px (standard cards: AppCard, StatCard)
- radius-xl: 24px (bottom nav bar, modal sheets)
- radius-full: 999px (circular badges, pills, FABs)

---

## Typography Hierarchy
- Headings: System Geometric Sans (Inter, Segoe UI)
- Body: System Sans (Inter, Roboto)
- Math: TeX via flutter_math_fork

---

## Navigation Architecture (4 Flat + 1 Elevated Center)

```
[  Home  ]   [  Classes  ]   {  Ask AI  }   [  Library  ]   [  Profile  ]
  Tab 0         Tab 1           Center         Tab 3          Tab 4
```

1. Tab 0: Home
2. Tab 1: Classes & Attendance (Schedule + Attendance internal tabs)
3. Center Elevated: Ask ChemBuddy (AI Chemistry Companion)
4. Tab 3: Library (PDFs, Notes, Quizzes, Flashcard Decks)
5. Tab 4: Profile (Mastery Analytics, Weak Topics, Streak)
