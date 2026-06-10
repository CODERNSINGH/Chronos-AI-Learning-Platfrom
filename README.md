# Chronos

Master Data Structures and Algorithms, one concept at a time. 

Chronos is an iOS application designed to help developers build their foundational computer science knowledge through an adaptive learning roadmap, AI-generated quizzes, and a gamified experience. 

## Features

- **Adaptive Learning Roadmap**: Navigate through a curated curriculum covering everything from Big-O notation to Advanced Algorithms. Visual skill trees guide your learning path.
- **AI-Generated Quizzes**: Dynamically generated questions powered by Groq and LLaMA models, ensuring unique and challenging assessments.
- **Gamification**: Earn XP, level up, and build streaks to stay motivated. Receive rewards for perfect scores and speed.
- **Personalization**: Choose your avatar, track your progress, and select your preferred AI model from the settings.

## Architecture & Tech Stack

- **Swift & SwiftUI**: Modern, declarative user interface architecture.
- **SwiftData**: Persistent local storage for user profiles, progress tracking, and roadmap nodes.
- **Groq API Integration**: Low-latency AI interactions for dynamic quiz generation and adaptive learning content.

## Getting Started

### Prerequisites

- Mac running macOS 14.0 or later.
- Xcode 15.0 or later.
- iOS 17.0 or later for the target device or simulator.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/CODERNSINGH/Chronos-AI-Learning-Platfrom.git
   ```

2. Navigate to the project directory:
   ```bash
   cd Chronos-AI-Learning-Platfrom
   ```

3. Open the Xcode project:
   ```bash
   open chronos.xcodeproj
   ```

4. Build and run the project using the Play button in Xcode or `Cmd + R`.

### API Configuration

The application utilizes the Groq API to power its AI features. While the app may contain default fallback models, it is highly recommended to use your own API key for the best experience. 

You can add your personal Groq API key directly within the application's Settings screen.

## License

This project is intended for educational purposes. All rights reserved.
