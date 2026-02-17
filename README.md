# 🫛 PeaTutor

An AI-powered math tutoring platform for Singapore's Primary 1–3 mathematics curriculum, built with SwiftUI and AWS Amplify.

PeaTutor connects teachers, students, and parents through intelligent worksheet analysis, personalised feedback, adaptive practice generation, and comprehensive analytics — all aligned to the Singapore MOE Primary Mathematics Syllabus.

---

## Features

### For Teachers
- **Classroom Management** — Create classes, invite students via join codes, and manage rosters
- **Homework Assignments** — Upload worksheets, assign to classes with due dates, and track submissions
- **Worksheet Scanning** — AI-powered extraction of questions, marks, and metadata from uploaded worksheets (PDF and image)
- **Class Analytics** — View aggregated performance data, error patterns, and concept mastery across students
- **Curriculum Browser** — Browse MOE-aligned curriculum standards and assign targeted practice
- **AI Recommendations** — Get data-driven suggestions for areas needing attention

### For Students
- **Homework Submission** — View assigned homework, submit solutions via camera or image upload
- **AI Feedback** — Receive step-by-step feedback with hints, explanations, and marking
- **Practice Hub** — Generate adaptive practice problems targeting weak areas
- **Curriculum Progress** — Track mastery across curriculum strands and topics
- **Performance Analytics** — View personal progress, difficulty breakdowns, and trend indicators

### For Parents
- **Child Linking** — Securely link to children's accounts to monitor progress
- **Homework Monitoring** — View assigned homework, submissions, and AI feedback
- **Analytics Overview** — Track child's performance, error patterns, and concept mastery
- **Curriculum Progress** — See how your child is progressing through the MOE syllabus

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | SwiftUI, SwiftData |
| **Authentication** | AWS Cognito |
| **Database** | AWS DynamoDB (via Amplify DataStore) |
| **API** | AWS AppSync (GraphQL) |
| **Storage** | AWS S3 |
| **AI/ML** | OpenAI GPT-4o Vision API |
| **Backend Framework** | AWS Amplify Gen 1 |

---

## Architecture

The app follows an offline-first architecture using AWS Amplify DataStore, which syncs automatically with the cloud when connectivity is available.

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
│  (Teacher / Student / Parent Dashboards)│
├─────────────────────────────────────────┤
│            Service Layer                │
│  HomeworkService · AnalyticsService     │
│  CurriculumService · PracticeService    │
│  DataStoreService · AWSService          │
├─────────────────────────────────────────┤
│         AWS Amplify DataStore           │
│     (Offline-first + Auto Sync)         │
├─────────────────────────────────────────┤
│  Cognito │ AppSync │ DynamoDB │   S3    │
└─────────────────────────────────────────┘
              │
              ▼
      ┌───────────────┐
      │ OpenAI GPT-4o │
      │  Vision API   │
      └───────────────┘
```

### Data Models

The app uses 22 Amplify models organised across these domains:

- **User Management** — UserProfile, UserStats, UserRole
- **Classroom** — Classroom, ClassroomMembership
- **Content** — Worksheet, Question, WorksheetMetadata, QuestionMetadata
- **Assignments** — Homework, HomeworkSubmission, HomeworkAnalytics
- **Feedback** — SolutionFeedback, FullWorksheetSolution
- **Practice** — PracticeAssignment, PracticeProblem
- **Analytics** — StudentProgress, StudentAnalyticsSummary, ConceptMastery, ErrorPattern
- **Curriculum** — CurriculumStandard, CurriculumTopicSummary, StudentCurriculumProgress
- **Family** — ParentChildRelationship

---

## Getting Started

### Prerequisites

- **Xcode 15+**
- **iOS 17+**
- **AWS Account** with Amplify CLI configured
- **OpenAI API Key** with GPT-4o access
- **Node.js** (for Amplify CLI)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mrcharl3slim/PeaTutor.git
   cd PeaTutor
   ```

2. **Install Amplify CLI** (if not already installed)
   ```bash
   npm install -g @aws-amplify/cli
   amplify configure
   ```

3. **Initialise the Amplify backend**
   ```bash
   amplify init
   amplify push
   ```

4. **Set your OpenAI API key**

   In Xcode, go to **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables** and add:
   ```
   OPENAI_API_KEY = your-api-key-here
   ```

5. **Open in Xcode and build**
   ```bash
   open PeaTutorApp.xcodeproj
   ```

6. **Seed curriculum data**

   The app automatically seeds Singapore MOE P1–P3 curriculum data on first launch from the bundled `SG_MOE_Mathematics_P1_P3_Seed_Data.json`.

---

## Curriculum Alignment

PeaTutor is aligned to the **Singapore MOE Primary Mathematics Syllabus (2021)**, covering Primary 1 through Primary 3. Curriculum codes follow the format:

```
P[grade]-[strand]-[substrand]-[topic].[subtopic]
```

**Strands covered:**
- Number and Algebra
- Measurement and Geometry
- Statistics

---

## Project Structure

```
PeaTutorApp/
├── PeaTutorApp.swift              # App entry point
├── ContentView.swift              # Main navigation router
├── AuthenticationView.swift       # Login / signup flow
│
├── Models/                        # Amplify DataStore models
│   ├── schema.graphql             # GraphQL schema definition
│   ├── Worksheet.swift
│   ├── Question.swift
│   ├── Homework.swift
│   └── ...                        # 22 model files + schemas
│
├── Services/
│   ├── AWSService.swift           # Auth, S3, user management
│   ├── DataStoreService.swift     # DataStore operations
│   ├── HomeworkService.swift      # Homework CRUD
│   ├── AnalyticsService.swift     # Performance analytics
│   ├── CurriculumService.swift    # Curriculum data management
│   ├── CurriculumMappingService.swift
│   ├── PracticeAssignmentService.swift
│   ├── PracticeGenerationService.swift
│   └── OpenAIClient.swift         # GPT-4o Vision integration
│
├── Views/
│   ├── Teacher/
│   │   ├── TeacherDashboardView.swift
│   │   ├── ClassDetailView.swift
│   │   ├── CreateHomeworkView.swift
│   │   └── ClassAnalyticsDashboardView.swift
│   ├── Student/
│   │   ├── StudentDashboardView.swift
│   │   ├── StudentHomeworkView.swift
│   │   ├── PracticeHubView.swift
│   │   └── StudentCurriculumProgressView.swift
│   ├── Parent/
│   │   ├── ParentDashboardView.swift
│   │   ├── ParentChildAnalyticsView.swift
│   │   └── ChildHomeworkListView.swift
│   └── Shared/
│       ├── LatexRenderer.swift
│       ├── CurriculumBrowserView.swift
│       └── ProfileView.swift
│
└── Resources/
    └── SG_MOE_Mathematics_P1_P3_Seed_Data.json
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI API key for GPT-4o Vision |

AWS configuration is managed automatically by Amplify through `amplifyconfiguration.json` (gitignored).

---

## Privacy & Compliance

- **FERPA/COPPA considerations** — DataStore is cleared on logout to prevent cached student data from being accessible to subsequent users on shared devices
- **Owner-based authorisation** — All data models use Amplify's owner-based auth rules to ensure users can only access their own data
- **No hardcoded secrets** — API keys are loaded from environment variables at runtime

---

## License

This project is proprietary. All rights reserved.

---

## Acknowledgements

- [AWS Amplify](https://docs.amplify.aws/) — Backend infrastructure
- [OpenAI](https://platform.openai.com/) — AI-powered worksheet analysis and feedback
- Singapore Ministry of Education — Primary Mathematics Syllabus (2021)
