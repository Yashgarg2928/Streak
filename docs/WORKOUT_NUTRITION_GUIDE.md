# 🏋️ Workout & Nutrition AI Guide

This document explains the standard JSON schemas used for importing Weekly Workout Plans, logging Meal Macros, and exporting fitness history for AI coaching.

---

## 1. 🏋️ Weekly Workout Plan AI Prompt

Copy & paste the prompt below into ChatGPT, Gemini, or Claude to generate your weekly workout plan:

```text
Generate a weekly workout plan for me in JSON format.

IMPORTANT FORMAT RULES FOR AI OUTPUT:
1. Output ONLY valid raw JSON (no markdown text, no ```json code block backticks).
2. Provide plain direct URLs for youtubeUrl (e.g., "https://www.youtube.com/results?search_query=..."). Do NOT use markdown link syntax like [Text](URL).
3. Use standard dayOfWeek (1 = Sunday, 2 = Monday, 3 = Tuesday, 4 = Wednesday, 5 = Thursday, 6 = Friday, 7 = Saturday).

JSON Schema:
{
  "title": "My Weekly Workout Plan",
  "days": [
    {
      "dayName": "Monday",
      "dayOfWeek": 2,
      "title": "Push Day - Chest, Shoulders & Triceps",
      "exercises": [
        {
          "name": "Barbell Bench Press",
          "category": "Chest",
          "targetSets": 4,
          "targetRepsOrDuration": "8-10 reps",
          "youtubeUrl": "https://www.youtube.com/results?search_query=barbell+bench+press+proper+form",
          "notes": "Retract shoulder blades, touch chest gently"
        },
        {
          "name": "Incline Dumbbell Press",
          "category": "Chest",
          "targetSets": 3,
          "targetRepsOrDuration": "10-12 reps",
          "youtubeUrl": "https://www.youtube.com/results?search_query=incline+dumbbell+press+proper+form"
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
          "targetRepsOrDuration": "10-12 reps",
          "youtubeUrl": "https://www.youtube.com/results?search_query=lat+pulldown+proper+form"
        }
      ]
    }
  ]
}

My Fitness Goal: Build Muscle & Strength
Split Type: 6-Day Push Pull Legs (or customize as requested)
Include YouTube exercise tutorial links for proper form.
```

---

## 2. 🥗 Meal Macro AI Prompt

Copy & paste the prompt below to generate JSON macros for your meals:

```text
Calculate the macros for the following meal(s) and provide the output ONLY in valid JSON format (no markdown code blocks):

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

In the **Workout Tab ➔ Analytics**, tap **`EXPORT FITNESS HISTORY JSON`** to generate a complete summary of your workout volume, set weights, and macro logs across any date range. You can send this exported JSON to ChatGPT/Gemini to get personalized coaching feedback!
