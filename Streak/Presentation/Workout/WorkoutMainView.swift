// Presentation/Workout/WorkoutMainView.swift

import SwiftUI
import Charts

enum WorkoutSubTab: String, CaseIterable, Identifiable {
    case workout = "WORKOUT"
    case nutrition = "NUTRITION"
    case analytics = "ANALYTICS"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .workout:   return "🏋️"
        case .nutrition: return "🥗"
        case .analytics: return "📊"
        }
    }
}

struct WorkoutMainView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var vm: WorkoutViewModel? = nil

    @State private var subTab: WorkoutSubTab = .workout
    @State private var selectedDate: Date = Date()

    @State private var showPlanImportSheet: Bool = false
    @State private var showAIPromptGuideSheet: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var showAddMealSheet: Bool = false
    @State private var showMealJSONImportSheet: Bool = false
    @State private var showMacroGoalsSheet: Bool = false

    @State private var newExerciseName: String = ""
    @State private var showAddExerciseDialog: Bool = false

    private func getViewModel() -> WorkoutViewModel {
        if let existing = vm {
            return existing
        }
        let newVM = WorkoutViewModel(env: env)
        newVM.load(date: selectedDate)
        return newVM
    }

    var body: some View {
        let activeVM = getViewModel()

        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, AppLayout.itemSpacing)

            subTabPicker
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, AppLayout.itemSpacing)

            datePickerBar
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, AppLayout.itemSpacing)

            if let errorMsg = activeVM.errorMessage {
                HStack {
                    Text("⚠️ \(errorMsg)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.red)
                    Spacer()
                    Button("✕") { activeVM.errorMessage = nil }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(8)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.red, lineWidth: 1.5))
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, 8)
            }

            if let successMsg = activeVM.successMessage {
                HStack {
                    Text("✅ \(successMsg)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.green)
                    Spacer()
                    Button("✕") { activeVM.successMessage = nil }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(8)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.green, lineWidth: 1.5))
                .padding(.horizontal, AppLayout.screenMargin)
                .padding(.top, 8)
            }

            ScrollView {
                VStack(spacing: AppLayout.itemSpacing) {
                    switch subTab {
                    case .workout:
                        workoutLoggingView(vm: activeVM)
                    case .nutrition:
                        nutritionLoggingView(vm: activeVM)
                    case .analytics:
                        analyticsView(vm: activeVM)
                    }
                }
                .padding(AppLayout.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            activeVM.load(date: selectedDate)
        }
        .sheet(isPresented: $showPlanImportSheet) {
            WorkoutPlanImportSheet { jsonStr in
                try activeVM.importWorkoutPlanJSON(jsonStr)
            }
        }
        .sheet(isPresented: $showAIPromptGuideSheet) {
            WorkoutAIPromptGuideSheet()
        }
        .sheet(isPresented: $showExportSheet) {
            WorkoutDataExportSheet(env: env)
        }
        .sheet(isPresented: $showAddMealSheet) {
            AddMealSheet(date: selectedDate) { meal in
                activeVM.saveMealLog(meal)
            }
        }
        .sheet(isPresented: $showMealJSONImportSheet) {
            MealMacroImportSheet(date: selectedDate) { jsonStr in
                activeVM.importMealMacroJSON(jsonStr)
            }
        }
        .sheet(isPresented: $showMacroGoalsSheet) {
            MacroGoalsSheet(currentGoals: activeVM.macroGoals) { goals in
                activeVM.saveMacroGoals(goals)
            }
        }
        .alert("Add Custom Exercise", isPresented: $showAddExerciseDialog) {
            TextField("Exercise Name (e.g. Incline Bench)", text: $newExerciseName)
            Button("Add") {
                activeVM.addCustomExercise(name: newExerciseName)
                newExerciseName = ""
            }
            Button("Cancel", role: .cancel) {
                newExerciseName = ""
            }
        }
    }

    // MARK: - Header & Navigation Bar

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT & NUTRITION")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(AppColor.textSecondary)
                Text("FITNESS TRACKER")
                    .font(.system(.title2, design: .monospaced).weight(.black))
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()

            HStack(spacing: 8) {
                Button {
                    showAIPromptGuideSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("🤖 AI PROMPTS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(AppColor.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColor.green)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(8)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var subTabPicker: some View {
        HStack(spacing: 6) {
            ForEach(WorkoutSubTab.allCases) { tab in
                let isSelected = subTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        subTab = tab
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(tab.emoji)
                            .font(.system(size: 12))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(isSelected ? AppColor.background : AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppColor.textPrimary : AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColor.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var datePickerBar: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                vm?.load(date: selectedDate)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(8)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(formattedDate(selectedDate))
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                vm?.load(date: selectedDate)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(8)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sub-Tab 1: Workout Logging

    private func workoutLoggingView(vm: WorkoutViewModel) -> some View {
        VStack(spacing: AppLayout.itemSpacing) {
            // Weekly Plan Summary Card
            BrutalistCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ACTIVE WEEKLY PLAN")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            Text(vm.activePlan?.title ?? "No Weekly Plan Configured")
                                .font(.system(.headline).weight(.bold))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        Spacer()

                        HStack(spacing: 6) {
                            if vm.activePlan != nil {
                                Button {
                                    vm.syncTodayFromPlan()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("RE-SYNC TODAY")
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColor.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(AppColor.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.green, lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                showPlanImportSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("IMPORT JSON")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let plan = vm.activePlan {
                        Text("\(plan.days.count) Days Scheduled • \(vm.dailyWorkoutLog.exercises.count) Exercises for Today")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }

            // Exercise List & Frictionless Set Tracker
            HStack {
                Text("TODAY'S EXERCISES (\(vm.dailyWorkoutLog.exercises.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button {
                    showAddExerciseDialog = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("ADD EXERCISE")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColor.green)
                }
                .buttonStyle(.plain)
            }

            if vm.dailyWorkoutLog.exercises.isEmpty {
                BrutalistCard {
                    VStack(spacing: 8) {
                        Text("No exercises logged for today.")
                            .font(.system(.subheadline))
                            .foregroundStyle(AppColor.textDisabled)
                        Text("Tap + ADD EXERCISE or Import a Weekly JSON Plan above to auto-load your daily split.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            } else {
                ForEach(vm.dailyWorkoutLog.exercises) { exercise in
                    exerciseCard(exercise: exercise, vm: vm)
                }
            }
        }
    }

    private func exerciseCard(exercise: ExerciseLog, vm: WorkoutViewModel) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.category.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                        Text(exercise.exerciseName)
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    Spacer()

                    if let rawUrl = cleanURLString(exercise.youtubeUrl), let url = URL(string: rawUrl) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.tv.fill")
                                Text("TUTORIAL")
                            }
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AppColor.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.red, lineWidth: 1))
                        }
                    }

                    Button {
                        vm.deleteExercise(id: exercise.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textDisabled)
                    }
                    .buttonStyle(.plain)
                }

                if let notes = exercise.notes, !notes.isEmpty {
                    Text("💡 \(notes)")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColor.textSecondary)
                }

                // Handling Cardio / Step Count
                if let steps = exercise.stepCount {
                    HStack {
                        Text("🚶 Step Count:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        TextField("0", value: Binding(
                            get: { steps },
                            set: { vm.updateStepCount(exerciseId: exercise.id, steps: $0) }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.blank)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
                        Text("steps")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                } else {
                    // Set Table (Frictionless Weight & Rep Logger)
                    VStack(spacing: 6) {
                        HStack {
                            Text("SET")
                                .frame(width: 35, alignment: .leading)
                            Text("WEIGHT (KG)")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("REPS")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("DONE")
                                .frame(width: 45, alignment: .trailing)
                        }
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textDisabled)

                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, setLog in
                            setRowView(exerciseId: exercise.id, setIndex: index, setLog: setLog, vm: vm)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            vm.addSet(to: exercise.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("ADD SET")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColor.green)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if exercise.sets.count > 1 {
                            Button {
                                vm.removeSet(from: exercise.id)
                            } label: {
                                Text("- REMOVE SET")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColor.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func setRowView(exerciseId: UUID, setIndex: Int, setLog: WorkoutSetLog, vm: WorkoutViewModel) -> some View {
        HStack {
            Text("#\(setLog.setNumber)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 35, alignment: .leading)

            TextField("0", value: Binding(
                get: { setLog.weight },
                set: { vm.updateSet(exerciseId: exerciseId, setIndex: setIndex, weight: $0) }
            ), format: .number)
            .keyboardType(.decimalPad)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(.vertical, 4)
            .background(AppColor.blank)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))

            TextField("0", value: Binding(
                get: { setLog.reps },
                set: { vm.updateSet(exerciseId: exerciseId, setIndex: setIndex, reps: $0) }
            ), format: .number)
            .keyboardType(.numberPad)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(.vertical, 4)
            .background(AppColor.blank)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))

            Button {
                vm.updateSet(exerciseId: exerciseId, setIndex: setIndex, isCompleted: !setLog.isCompleted)
            } label: {
                Image(systemName: setLog.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(setLog.isCompleted ? AppColor.green : AppColor.textDisabled)
            }
            .buttonStyle(.plain)
            .frame(width: 45, alignment: .trailing)
        }
    }

    // MARK: - Sub-Tab 2: Nutrition & Macros

    private func nutritionLoggingView(vm: WorkoutViewModel) -> some View {
        VStack(spacing: AppLayout.itemSpacing) {
            // Daily Macro Progress Card
            BrutalistCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DAILY MACRONUTRIENTS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppColor.textSecondary)
                            Text("\(vm.totalDailyCalories) / \(vm.macroGoals.targetCalories) KCAL")
                                .font(.system(.title3, design: .monospaced).weight(.black))
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        Spacer()

                        Button {
                            showMacroGoalsSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text("GOALS")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }

                    // Progress Bars for Calories, Protein, Carbs, Fat
                    macroProgressBar(title: "🔥 CALORIES", current: Double(vm.totalDailyCalories), target: Double(vm.macroGoals.targetCalories), unit: "kcal", color: AppColor.green)
                    macroProgressBar(title: "🥩 PROTEIN", current: vm.totalDailyProtein, target: vm.macroGoals.targetProteinGrams, unit: "g", color: AppColor.green)
                    macroProgressBar(title: "🌾 CARBS", current: vm.totalDailyCarbs, target: vm.macroGoals.targetCarbGrams, unit: "g", color: AppColor.textPrimary)
                    macroProgressBar(title: "🥑 FATS", current: vm.totalDailyFat, target: vm.macroGoals.targetFatGrams, unit: "g", color: AppColor.textSecondary)
                }
            }

            // Actions Bar
            HStack(spacing: 8) {
                Button {
                    showAddMealSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("ADD MEAL")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColor.green)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button {
                    showMealJSONImportSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("IMPORT JSON")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }

            // Meal Logs List
            HStack {
                Text("LOGGED MEALS (\(vm.dailyMealLogs.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
            }

            if vm.dailyMealLogs.isEmpty {
                BrutalistCard {
                    Text("No meals logged for today.\nTap + ADD MEAL or IMPORT JSON to track your nutrition.")
                        .font(.system(.subheadline))
                        .foregroundStyle(AppColor.textDisabled)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            } else {
                ForEach(vm.dailyMealLogs) { meal in
                    mealCard(meal: meal, vm: vm)
                }
            }
        }
    }

    private func macroProgressBar(title: String, current: Double, target: Double, unit: String, color: Color) -> some View {
        let safeTarget = max(1.0, target)
        let fraction = min(1.5, current / safeTarget)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text("\(Int(current)) / \(Int(target)) \(unit)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColor.blank)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1.0, fraction)))
                }
            }
            .frame(height: 6)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(AppColor.border, lineWidth: 1))
        }
    }

    private func mealCard(meal: MealLog, vm: WorkoutViewModel) -> some View {
        BrutalistCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Text(meal.mealType.emoji)
                        Text(meal.mealType.rawValue.uppercased())
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()

                    Text("\(meal.calories) KCAL")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(AppColor.green)

                    Button {
                        vm.deleteMealLog(id: meal.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.textDisabled)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 6)
                }

                Text(meal.title)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(AppColor.textPrimary)

                if !meal.details.isEmpty {
                    Text(meal.details)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColor.textSecondary)
                }

                if let photoData = meal.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColor.border, lineWidth: 1))
                }

                HStack(spacing: 12) {
                    macroTag(label: "P", value: meal.proteinGrams, unit: "g", color: AppColor.green)
                    macroTag(label: "C", value: meal.carbGrams, unit: "g", color: AppColor.textPrimary)
                    macroTag(label: "F", value: meal.fatGrams, unit: "g", color: AppColor.textSecondary)
                }
                .padding(.top, 2)
            }
        }
    }

    private func macroTag(label: String, value: Double, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(color)
            Text("\(Int(value))\(unit)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppColor.border, lineWidth: 1))
    }

    // MARK: - Sub-Tab 3: Analytics & Progress

    private func analyticsView(vm: WorkoutViewModel) -> some View {
        VStack(spacing: AppLayout.itemSpacing) {
            // Volume Progress Chart
            BrutalistCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("30-DAY WORKOUT VOLUME (KG LIFTED)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)

                    if vm.historicalWorkoutLogs.isEmpty {
                        Text("No workout history logged yet.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textDisabled)
                            .frame(height: 120)
                    } else {
                        Chart(vm.historicalWorkoutLogs) { log in
                            BarMark(
                                x: .value("Date", log.date, unit: .day),
                                y: .value("Volume", log.totalDailyVolume)
                            )
                            .foregroundStyle(AppColor.green)
                        }
                        .frame(height: 140)
                    }
                }
            }

            // Calorie & Protein History Chart
            BrutalistCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DAILY CALORIE & PROTEIN INTAKE TRENDS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textSecondary)

                    if vm.historicalMealLogs.isEmpty {
                        Text("No meal history logged yet.")
                            .font(.system(.caption))
                            .foregroundStyle(AppColor.textDisabled)
                            .frame(height: 120)
                    } else {
                        let groupedMeals = Dictionary(grouping: vm.historicalMealLogs) { Calendar.current.startOfDay(for: $0.date) }
                        let dailyTotals = groupedMeals.map { (date, meals) in
                            (date: date, calories: meals.reduce(0) { $0 + $1.calories })
                        }.sorted { $0.date < $1.date }

                        Chart(dailyTotals, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(AppColor.green)
                        }
                        .frame(height: 140)
                    }
                }
            }

            // Date Range Data Export Card
            BrutalistCard(borderColor: AppColor.green) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📤 EXPORT DATA FOR AI REVIEW")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Export your complete workout volume, set weights, and macro logs to feed into ChatGPT / Gemini for personalized AI fitness coaching!")
                        .font(.system(.caption))
                        .foregroundStyle(AppColor.textSecondary)

                    Button {
                        showExportSheet = true
                    } label: {
                        Text("EXPORT FITNESS HISTORY JSON")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(AppColor.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColor.green)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date).uppercased()
    }
}
