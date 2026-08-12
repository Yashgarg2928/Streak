# 🏋️ Workout & Nutrition AI Guide

This document explains the standard JSON schemas used for importing Weekly Workout Plans, logging Meal Macros, and exporting fitness history for AI coaching.

---

## 1. 🏋️ Weekly Workout Plan JSON Schema

Copy & paste the prompt below into ChatGPT, Gemini, or Claude to generate your weekly workout plan:

### 🤖 AI Prompt Template for Workout Plan

```text
Generate a weekly workout plan for me in JSON format.
Please structure your response ONLY as valid JSON (no markdown text, no code block backticks) matching this schema:

{
  "title": "My Weekly Workout Plan",
  "days": [
    {
      "dayName": "Monday",
      "dayOfWeek": 2,
      "title": "Push Day - Chest, Shoulders, Triceps",
      "exercises": [
        {
          "name": "Barbell Bench Press",
          "category": "Chest",
          "targetSets": 4,
          "targetRepsOrDuration": "8-10 reps",
          "youtubeUrl": "https://www.youtube.com/watch?v=rT7DgCr-3pg",
          "notes": "Keep shoulder blades retracted"
        },
        {
          "name": "Incline Dumbbell Press",
          "category": "Chest",
          "targetSets": 3,
          "targetRepsOrDuration": "10-12 reps",
          "youtubeUrl": "https://www.youtube.com/watch?v=8iPEnn-ltC8"
        }
      ]
    },
    {
      "dayName": "Tuesday",
      "dayOfWeek": 3,
      "title": "Pull Day - Back & Biceps",
      "exercises": [
        {
          "name": "Lat Pulldown",
          "category": "Back",
          "targetSets": 4,
          "targetRepsOrDuration": "10-12 reps"
        }
      ]
    }
  ]
}

My Goal: Hypertrophy / Muscle Building
Split: 6-Day Push Pull Legs
Include YouTube video links for exercise form demonstration.
```

---

## 2. 🥗 Meal Macro JSON Schema

Copy & paste the prompt below to generate JSON macros for your meals:

### 🤖 AI Prompt Template for Meal Macros

```text
Calculate the macros for the following meal(s) and provide the output ONLY in valid JSON format:

[
  {
    "mealType": "Lunch",
    "title": "Grilled Chicken & Rice",
    "details": "200g grilled chicken breast, 150g cooked white rice, steamed broccoli",
    "calories": 550,
    "proteinGrams": 48.0,
    "carbGrams": 45.0,
    "fatGrams": 12.0
  }
]
```

---

## 3. 📤 Exporting History for AI Coaching

In the **Workout Tab ➔ Analytics**, tap **`EXPORT FITNESS HISTORY JSON`** to generate a complete summary of your workout volume, set weights, and macro intake across any date range. You can send this exported JSON to ChatGPT/Gemini to get personalized coaching feedback!
