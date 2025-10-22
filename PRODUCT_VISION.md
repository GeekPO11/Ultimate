# Ultimate - Product Vision & Strategy

> **Version:** 1.0.0  
> **Last Updated:** January 2025  
> **Product Owner:** Sanchay Gumber  
> **License:** Apache-2.0

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Market Analysis](#market-analysis)
4. [Solution Overview](#solution-overview)
5. [Product Vision](#product-vision)
6. [Target Users](#target-users)
7. [Value Proposition](#value-proposition)
8. [User Personas](#user-personas)
9. [User Journey Maps](#user-journey-maps)
10. [Product Principles](#product-principles)
11. [Feature Roadmap](#feature-roadmap)
12. [Success Metrics](#success-metrics)
13. [Competitive Analysis](#competitive-analysis)
14. [Go-to-Market Strategy](#go-to-market-strategy)

---

## Executive Summary

**Ultimate** is a comprehensive iOS fitness and habit tracking application designed to help users build lasting life-changing habits through structured challenges, intelligent tracking, and beautiful visualizations. 

### Key Highlights

- **Native iOS Experience**: Built entirely with SwiftUI and SwiftData for optimal performance
- **Privacy-First Design**: All data stays on the user's device
- **Comprehensive Tracking**: Multiple measurement types for diverse habit tracking needs
- **Visual Progress**: Beautiful analytics and progress photo comparison tools
- **Smart Automation**: HealthKit integration for automatic workout tracking
- **Modern UI**: VisionOS-inspired glass morphism design language

### Why Ultimate?

While many habit tracking apps exist, most fall into two categories:
1. **Overly Simple**: Basic checkbox apps that lack depth and engagement
2. **Overly Complex**: Feature-bloated apps that overwhelm users

Ultimate strikes the perfect balance: powerful enough for serious fitness enthusiasts, yet intuitive enough for habit-tracking beginners.

---

## Problem Statement

### The Challenge of Habit Formation

Building and maintaining habits is one of the most challenging aspects of personal development. Research shows:

- **90% of people** who set New Year's resolutions abandon them by February
- **Only 8%** of people achieve their yearly goals
- **Average of 66 days** needed to form a new habit
- **Consistency is key**, yet it's the hardest aspect to maintain

### Existing Solution Gaps

Current fitness and habit tracking solutions suffer from:

#### 1. Lack of Structure
```
❌ Generic to-do lists without context
❌ No predefined challenge templates
❌ Users left to figure out optimal strategies
```

#### 2. Poor Tracking Flexibility
```
❌ Binary completion (done/not done) only
❌ Can't track quantities (e.g., 8 glasses of water)
❌ No duration tracking (e.g., 30 minutes of reading)
❌ Missing checklist support for multi-step tasks
```

#### 3. Limited Progress Visualization
```
❌ Basic charts that don't tell the full story
❌ No photo progress tracking integration
❌ Missing consistency scoring
❌ Can't compare time periods effectively
```

#### 4. Inconsistent User Experience
```
❌ Cluttered interfaces
❌ Inconsistent design patterns
❌ Poor mobile optimization
❌ Uninspiring visual design
```

#### 5. Privacy Concerns
```
❌ Data stored on external servers
❌ Unclear data usage policies
❌ Required accounts and logins
❌ Potential data breaches
```

### The Impact

When people fail to build habits:
- **Physical Health Suffers**: Lack of consistent exercise and proper nutrition
- **Mental Health Declines**: Reduced self-efficacy and motivation
- **Goals Remain Unmet**: Dreams of transformation never realized
- **Money Wasted**: Gym memberships, programs, and apps go unused

---

## Market Analysis

### Market Size & Opportunity

```
┌────────────────────────────────────────────────┐
│ Global Fitness App Market                      │
├────────────────────────────────────────────────┤
│ 2023 Market Size:      $14.7 Billion          │
│ 2030 Projection:       $120.4 Billion         │
│ CAGR:                  23.5%                   │
│ Primary Growth Driver: Health awareness        │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│ Habit Tracking App Market                      │
├────────────────────────────────────────────────┤
│ 2023 Market Size:      $4.2 Billion           │
│ 2030 Projection:       $15.8 Billion          │
│ CAGR:                  20.1%                   │
│ Primary Growth Driver: Mental health focus     │
└────────────────────────────────────────────────┘
```

### Market Trends

1. **Privacy-First Applications**: Growing demand for on-device data storage
2. **Holistic Health**: Integration of physical and mental wellness
3. **Challenge-Based Programs**: Rise of 75 Hard and similar challenges
4. **Visual Progress**: Increased demand for photo and chart-based tracking
5. **Automation**: Users want less manual input, more automatic tracking

### Target Market Segments

#### Primary Market
- **Age**: 25-45
- **Demographics**: Health-conscious individuals
- **Tech Savviness**: Comfortable with smartphone apps
- **Income**: Middle to upper-middle class
- **Pain Point**: Struggling with consistency in fitness/habits

#### Secondary Market
- **Age**: 18-24
- **Demographics**: College students, young professionals
- **Tech Savviness**: Digital natives
- **Income**: Entry-level to middle class
- **Pain Point**: Building foundational habits

---

## Solution Overview

Ultimate solves the habit formation problem through five key pillars:

### 1. Structured Challenges

```
┌─────────────────────────────────────────┐
│          Challenge Templates             │
├─────────────────────────────────────────┤
│ • 75 Hard Challenge                     │
│   - 5 daily tasks                       │
│   - 75-day commitment                   │
│   - No exceptions                       │
│                                         │
│ • Water Fasting                         │
│   - Customizable durations              │
│   - Meal timing tracking                │
│   - Hydration monitoring                │
│                                         │
│ • 31 Modified                           │
│   - 31-day habit building               │
│   - Flexible task selection             │
│   - Beginner-friendly                   │
│                                         │
│ • Custom Challenges                     │
│   - User-defined parameters             │
│   - Flexible task combinations          │
│   - Any duration                        │
└─────────────────────────────────────────┘
```

### 2. Flexible Task Tracking

```
Task Measurement Types:

Binary
├─ Simple completion checkbox
├─ Perfect for: Meditation, photo taking
└─ Example: "Take progress photo" ✓

Quantity
├─ Numerical target with units
├─ Perfect for: Water intake, reading pages
└─ Example: "Drink 8 glasses" (6/8) 🥤

Duration
├─ Time-based measurement
├─ Perfect for: Exercise, reading, meditation
└─ Example: "Read 30 minutes" (25/30) 📖

Checklist
├─ Multiple sub-items
├─ Perfect for: Morning routines, meal prep
└─ Example: "Morning routine" (3/5 items) ☑️
```

### 3. Intelligent Progress Analytics

```
┌─────────────────────────────────────────┐
│          Analytics Dashboard             │
├─────────────────────────────────────────┤
│                                         │
│  Completion Rate                        │
│  ████████░░ 80%                        │
│                                         │
│  Consistency Score                      │
│  ███████░░░ 72/100                     │
│                                         │
│  Current Streak                         │
│  🔥 15 days                            │
│                                         │
│  Longest Streak                         │
│  🏆 32 days                            │
│                                         │
│  [View Detailed Charts]                 │
│                                         │
└─────────────────────────────────────────┘
```

### 4. Visual Progress Tracking

```
Photo Progress System:

Capture
├─ Multiple angles (front, side, back)
├─ Organized by date and session
└─ Privacy-first (local storage only)

Compare
├─ Side-by-side view
├─ Timeline visualization
└─ Date selection tools

Analyze
├─ Photo timeline
├─ Progress milestones
└─ Visual transformation tracking
```

### 5. Smart Automation

```
HealthKit Integration:

Automatic Tracking
├─ Workout detection
├─ Exercise minute tracking
├─ Auto-complete workout tasks
└─ Background monitoring

Privacy Respected
├─ User grants permission
├─ Read-only access
├─ No data sent externally
└─ Optional feature
```

---

## Product Vision

### Vision Statement

> "Empower every person to build life-changing habits through structured challenges, intelligent tracking, and beautiful experiences—all while respecting their privacy."

### Mission

Transform habit formation from a struggle into a journey of consistent progress, celebrating every milestone along the way.

### 3-Year Vision

```
Year 1 (2025): Foundation & Growth
├─ Launch open-source version
├─ Build community of contributors
├─ Reach 10,000+ users
└─ Establish as credible alternative

Year 2 (2026): Enhancement & Scale
├─ Add CloudKit sync
├─ Launch watchOS companion
├─ Implement widget extensions
└─ Grow to 100,000+ users

Year 3 (2027): Ecosystem & Impact
├─ Build developer platform
├─ Enable third-party integrations
├─ Launch community challenges
└─ Reach 1,000,000+ users
```

---

## Target Users

### Primary User Segments

#### 1. The Fitness Enthusiast

**Profile:**
- Age: 28-42
- Already exercises regularly
- Wants structured programs
- Values data and progress tracking
- Willing to commit to challenges

**Needs:**
- Comprehensive workout tracking
- Progress photo comparison
- Integration with health data
- Challenge structure for motivation

**Quote:** *"I work out regularly, but I need structure and accountability to take it to the next level."*

#### 2. The Habit Builder

**Profile:**
- Age: 25-35
- Wants to improve daily routines
- Struggles with consistency
- Appreciates visual design
- Seeks simple but effective tools

**Needs:**
- Easy task management
- Flexibility in tracking
- Visual progress feedback
- Motivation and reminders

**Quote:** *"I know what I should do, but I need help staying consistent."*

#### 3. The Transformation Seeker

**Profile:**
- Age: 30-45
- Wants significant life change
- Committed to challenges like 75 Hard
- Values accountability
- Seeks comprehensive solutions

**Needs:**
- Pre-built challenge templates
- Strict tracking enforcement
- Progress documentation
- All-in-one solution

**Quote:** *"I'm ready to commit fully, but I need a tool that can keep up with my ambition."*

#### 4. The Privacy Advocate

**Profile:**
- Age: 25-50
- Concerned about data privacy
- Prefers open-source solutions
- Tech-savvy
- Values transparency

**Needs:**
- On-device data storage
- No external servers
- Open-source code
- Full control over data

**Quote:** *"I want a powerful app that respects my privacy and doesn't sell my data."*

---

## User Personas

### Persona 1: Alex - The Fitness Enthusiast

```
┌───────────────────────────────────────┐
│          ALEX JOHNSON                 │
│          Age: 32                      │
│          Occupation: Software Engineer│
├───────────────────────────────────────┤
│ Goals:                                │
│ • Complete 75 Hard Challenge          │
│ • Track workouts automatically        │
│ • Document physical transformation    │
│                                       │
│ Frustrations:                         │
│ • Other apps don't integrate health   │
│ • Manual tracking is tedious          │
│ • Poor data visualization             │
│                                       │
│ Motivations:                          │
│ • Personal growth                     │
│ • Physical transformation             │
│ • Data-driven improvement             │
└───────────────────────────────────────┘
```

### Persona 2: Sarah - The Habit Builder

```
┌───────────────────────────────────────┐
│          SARAH MARTINEZ               │
│          Age: 28                      │
│          Occupation: Marketing Manager│
├───────────────────────────────────────┤
│ Goals:                                │
│ • Build morning routine               │
│ • Drink more water                    │
│ • Read daily                          │
│                                       │
│ Frustrations:                         │
│ • Inconsistent with habits            │
│ • Apps are too complex                │
│ • Lacks motivation                    │
│                                       │
│ Motivations:                          │
│ • Feel more organized                 │
│ • Improve wellness                    │
│ • Beautiful, enjoyable app            │
└───────────────────────────────────────┘
```

### Persona 3: Marcus - The Privacy Advocate

```
┌───────────────────────────────────────┐
│          MARCUS CHEN                  │
│          Age: 35                      │
│          Occupation: Security Engineer│
├───────────────────────────────────────┤
│ Goals:                                │
│ • Track fitness privately             │
│ • Avoid data collection               │
│ • Support open source                 │
│                                       │
│ Frustrations:                         │
│ • Apps sell user data                 │
│ • Unclear privacy policies            │
│ • Closed-source code                  │
│                                       │
│ Motivations:                          │
│ • Data sovereignty                    │
│ • Transparency                        │
│ • Community-driven development        │
└───────────────────────────────────────┘
```

---

## User Journey Maps

### Journey 1: First-Time User - Starting 75 Hard

```
1. DISCOVERY
   User: Hears about app from friend doing 75 Hard
   Emotion: 😊 Curious, hopeful
   Action: Downloads app from App Store / GitHub

2. ONBOARDING
   User: Goes through welcome screens
   Emotion: 😃 Excited, motivated
   Action: Enters name, grants notifications permission

3. CHALLENGE SELECTION
   User: Browses challenge templates
   Emotion: 😮 Impressed by structure
   Action: Selects "75 Hard Challenge"

4. TASK REVIEW
   User: Reviews 5 daily tasks
   Emotion: 😰 Slightly overwhelmed but determined
   Action: Confirms challenge start date

5. DAY 1
   User: Completes first workout
   Emotion: 🎉 Accomplished
   Action: Marks task complete, sees progress ring update

6. FIRST PHOTO
   User: Takes first progress photos
   Emotion: 😳 Nervous but committed
   Action: Captures front/side/back photos

7. STREAK BUILDING
   User: Completes first week
   Emotion: 💪 Proud, motivated
   Action: Checks analytics daily

8. MILESTONE
   User: Reaches day 30
   Emotion: 🏆 Confident, unstoppable
   Action: Compares photos, shares progress

9. COMPLETION
   User: Finishes 75 Hard
   Emotion: 😭😄 Emotional, transformed
   Action: Views final statistics, starts new challenge
```

### Journey 2: Daily User - Morning Routine

```
Morning Routine Flow:

7:00 AM - NOTIFICATION
├─ User receives morning reminder
├─ Emotion: 😴 Groggy but ready
└─ Action: Opens app from notification

7:05 AM - TODAY VIEW
├─ User sees daily task list
├─ Emotion: 😊 Organized, clear
└─ Action: Reviews 5 tasks for the day

7:30 AM - TASK COMPLETION
├─ User completes morning workout
├─ Emotion: 💪 Energized
└─ Action: Marks workout complete, logs duration

8:00 AM - PROGRESS CHECK
├─ User checks weekly stats
├─ Emotion: 📈 Motivated by progress
└─ Action: Sees 85% completion rate

8:15 AM - HABIT COMPLETE
├─ User finishes morning routine
├─ Emotion: ✅ Accomplished
└─ Action: Closes app, starts work day
```

---

## Product Principles

### 1. Privacy First, Always

```
✓ All data stored on device
✓ No user accounts required
✓ No analytics tracking
✓ No data collection
✓ Optional cloud sync (future)
✗ Never sell user data
✗ No third-party trackers
✗ No advertising
```

### 2. Beauty Meets Function

```
Design Philosophy:
├─ VisionOS-inspired aesthetics
├─ Glass morphism effects
├─ Smooth animations
├─ Intuitive interactions
└─ Accessibility compliance
```

### 3. Simplicity Over Features

```
"A feature not used is worse than no feature."

Approach:
├─ Core features done excellently
├─ Avoid feature bloat
├─ Clear user paths
├─ Hide complexity
└─ Progressive disclosure
```

### 4. Respect User Time

```
Time-Saving Features:
├─ HealthKit auto-tracking
├─ Smart notifications
├─ Quick task completion
├─ Minimal required input
└─ Efficient workflows
```

### 5. Build for Consistency

```
Success = Small Actions × Time

Support Through:
├─ Daily reminders
├─ Streak tracking
├─ Visual progress
├─ Positive reinforcement
└─ No guilt-tripping
```

---

## Feature Roadmap

### Version 1.0 (Current) - Foundation

**Status:** ✅ Complete

- ✅ Challenge management (75 Hard, Water Fasting, Custom)
- ✅ Daily task tracking (Binary, Quantity, Duration, Checklist)
- ✅ Progress analytics with charts
- ✅ Progress photo tracking
- ✅ HealthKit integration
- ✅ Smart notifications
- ✅ Glass morphism UI

### Version 1.1 (Q2 2025) - Polish

**Status:** 🔄 In Planning

- ⬜ Widget extensions (Home Screen, Lock Screen)
- ⬜ Siri Shortcuts integration
- ⬜ Enhanced photo editing tools
- ⬜ Export progress reports (PDF)
- ⬜ Dark mode optimizations
- ⬜ iPad support

### Version 2.0 (Q3 2025) - Expansion

**Status:** 📋 Backlog

- ⬜ CloudKit sync (optional)
- ⬜ Family sharing
- ⬜ Challenge templates marketplace
- ⬜ Advanced analytics (ML insights)
- ⬜ Social features (opt-in)
- ⬜ Integration with Apple Fitness+

### Version 3.0 (Q4 2025) - Ecosystem

**Status:** 💭 Vision

- ⬜ watchOS companion app
- ⬜ Mac Catalyst version
- ⬜ API for third-party integrations
- ⬜ Community challenges
- ⬜ Achievement system
- ⬜ Habit streaks across devices

---

## Success Metrics

### North Star Metric

**Daily Active Users Completing At Least One Task**

This metric captures:
- User engagement
- Product value delivery
- Habit formation success

### Key Performance Indicators (KPIs)

#### 1. Engagement Metrics

```
┌──────────────────────────────────────┐
│ Daily Active Users (DAU)             │
│ Target: 60% of MAU                   │
├──────────────────────────────────────┤
│ Average Session Duration             │
│ Target: 3-5 minutes                  │
├──────────────────────────────────────┤
│ Tasks Completed per User per Day     │
│ Target: 3.5 tasks                    │
└──────────────────────────────────────┘
```

#### 2. Retention Metrics

```
┌──────────────────────────────────────┐
│ Day 1 Retention                      │
│ Target: 70%                          │
├──────────────────────────────────────┤
│ Day 7 Retention                      │
│ Target: 45%                          │
├──────────────────────────────────────┤
│ Day 30 Retention                     │
│ Target: 30%                          │
├──────────────────────────────────────┤
│ Day 75 Retention (75 Hard)           │
│ Target: 15%                          │
└──────────────────────────────────────┘
```

#### 3. Product Quality Metrics

```
┌──────────────────────────────────────┐
│ App Store Rating                     │
│ Target: 4.5+ stars                   │
├──────────────────────────────────────┤
│ Crash-Free Sessions                  │
│ Target: 99.5%                        │
├──────────────────────────────────────┤
│ Average Load Time                    │
│ Target: < 1 second                   │
└──────────────────────────────────────┘
```

#### 4. Community Metrics (Future)

```
┌──────────────────────────────────────┐
│ GitHub Stars                         │
│ Target: 1,000+ (Year 1)              │
├──────────────────────────────────────┤
│ Active Contributors                  │
│ Target: 20+ (Year 1)                 │
├──────────────────────────────────────┤
│ Community Forum Members              │
│ Target: 5,000+ (Year 1)              │
└──────────────────────────────────────┘
```

---

## Competitive Analysis

### Direct Competitors

#### 1. Way of Life
- **Strengths**: Simple, established
- **Weaknesses**: Outdated UI, limited features
- **Differentiation**: Ultimate has better UI, more features, photo tracking

#### 2. Streaks
- **Strengths**: Beautiful design, popular
- **Weaknesses**: Paid app, no challenges, limited tracking types
- **Differentiation**: Ultimate is free, has challenges, more tracking flexibility

#### 3. Habitica
- **Strengths**: Gamification, community
- **Weaknesses**: Cartoonish design, overwhelming features
- **Differentiation**: Ultimate is cleaner, fitness-focused, privacy-first

### Indirect Competitors

#### 1. MyFitnessPal
- **Strengths**: Comprehensive, huge database
- **Weaknesses**: Complex, ad-heavy, privacy concerns
- **Differentiation**: Ultimate is simpler, privacy-first, habit-focused

#### 2. Strava
- **Strengths**: Social features, athlete community
- **Weaknesses**: Exercise-only, requires accounts
- **Differentiation**: Ultimate supports all habit types, no account needed

### Competitive Advantages

```
┌─────────────────────────────────────────┐
│ Ultimate's Unique Position              │
├─────────────────────────────────────────┤
│ ✓ Free & Open Source                    │
│ ✓ Privacy-First (on-device)             │
│ ✓ Modern UI (VisionOS-inspired)         │
│ ✓ Flexible Tracking (4 types)           │
│ ✓ Built-in Challenges                   │
│ ✓ Photo Progress Tracking               │
│ ✓ HealthKit Integration                 │
│ ✓ No Ads, No Accounts                   │
└─────────────────────────────────────────┘
```

---

## Go-to-Market Strategy

### Phase 1: Open Source Launch (Q1 2025)

#### Objectives
- Establish credibility
- Build initial user base
- Gather feedback
- Attract contributors

#### Tactics
```
1. GitHub Release
   ├─ Complete documentation
   ├─ Video demo
   ├─ Clear setup instructions
   └─ Contributor guidelines

2. Community Outreach
   ├─ Post on Reddit (r/fitness, r/getdisciplined)
   ├─ Share on Hacker News
   ├─ Tweet to iOS dev community
   └─ Product Hunt launch

3. Content Marketing
   ├─ Blog: "Building a Privacy-First Fitness App"
   ├─ Blog: "The Architecture of Ultimate"
   ├─ Blog: "Why We Chose SwiftData"
   └─ Technical tutorials

4. Developer Engagement
   ├─ Host "good first issue" tasks
   ├─ Weekly contributor updates
   ├─ Code review livestreams
   └─ Feature bounty program
```

### Phase 2: App Store Launch (Q2 2025)

#### Objectives
- Reach mainstream users
- Generate downloads
- Build app store presence
- Collect reviews

#### Tactics
```
1. App Store Optimization
   ├─ Keyword research
   ├─ Screenshot optimization
   ├─ Preview video
   └─ Localization (top 5 languages)

2. PR & Media
   ├─ Reach out to iOS blogs
   ├─ Fitness app review sites
   ├─ Podcast appearances
   └─ Press releases

3. Influencer Partnerships
   ├─ Fitness YouTubers
   ├─ 75 Hard community leaders
   ├─ Habit-building influencers
   └─ Privacy advocates

4. Content Series
   ├─ User success stories
   ├─ "How I built it" series
   ├─ Feature deep dives
   └─ Behind-the-scenes
```

### Phase 3: Growth & Scale (Q3-Q4 2025)

#### Objectives
- Scale user base
- Build community
- Increase retention
- Drive word-of-mouth

#### Tactics
```
1. Community Building
   ├─ Discord server
   ├─ Monthly challenges
   ├─ User showcase
   └─ Ambassador program

2. Product-Led Growth
   ├─ Share progress images
   ├─ Challenge invites
   ├─ Referral system
   └─ Template sharing

3. Platform Expansion
   ├─ Widget launch
   ├─ Siri integration
   ├─ Apple Watch app
   └─ Mac version

4. Partnership Strategy
   ├─ Gym partnerships
   ├─ Fitness brands
   ├─ Health tech companies
   └─ Developer integrations
```

---

## Risk Analysis & Mitigation

### Technical Risks

```
Risk: SwiftData bugs or limitations
Severity: Medium
Likelihood: Medium
Mitigation:
├─ Comprehensive error handling
├─ Fallback to CoreData if needed
└─ Regular data backups

Risk: HealthKit data accuracy
Severity: Low
Likelihood: Medium
Mitigation:
├─ Clear disclaimers
├─ User verification option
└─ Manual override capability

Risk: Photo storage space
Severity: Medium
Likelihood: High
Mitigation:
├─ Image compression
├─ User storage limits
└─ Optional cloud storage (future)
```

### Market Risks

```
Risk: Low user adoption
Severity: High
Likelihood: Medium
Mitigation:
├─ Strong marketing strategy
├─ Community building
└─ Iterate based on feedback

Risk: Competitor cloning features
Severity: Medium
Likelihood: High
Mitigation:
├─ Rapid iteration
├─ Focus on unique value
└─ Community loyalty

Risk: App Store rejection
Severity: High
Likelihood: Low
Mitigation:
├─ Strict guideline compliance
├─ Pre-submission review
└─ Open source alternative
```

---

## Conclusion

Ultimate represents a unique opportunity in the fitness and habit tracking market. By combining:

- **Powerful features** with **simple UX**
- **Privacy-first approach** with **smart automation**
- **Beautiful design** with **practical functionality**
- **Open source transparency** with **commercial viability**

We're positioned to become the go-to habit tracking solution for privacy-conscious, fitness-focused individuals.

### Call to Action

Whether you're a:
- **User**: Download and start your transformation journey
- **Contributor**: Help build the future of habit tracking
- **Partner**: Collaborate on expanding our impact
- **Investor**: Support our mission (future consideration)

Join us in empowering millions to build life-changing habits.

---

**Document Version:** 1.0.0  
**Last Updated:** January 2025  
**Author:** Sanchay Gumber  
**License:** Apache-2.0  
**Questions?** Open an issue on GitHub

