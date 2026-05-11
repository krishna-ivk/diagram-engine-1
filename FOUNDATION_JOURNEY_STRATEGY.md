# Foundation Journey Implementation Strategy

## Branch & Merge Strategy

Based on current branch analysis, here's the recommended merge order:

### Current Branches Status
- `main` - Stable base
- `feature/content-pipeline-integration` - Content loading system
- `feature/post-exam-diagnosis` - Post-exam analysis
- `feature/foundation-journey` - **NEW** - Foundation Journey implementation

### Recommended Merge Order

#### Phase 1: Foundation Infrastructure
1. **Create `feature/foundation-journey` branch** from latest `main`
2. Implement Foundation Journey core files (already created):
   - `lib/models/foundation_journey.dart`
   - `lib/models/journey_progression_engine.dart`
   - `lib/models/journey_state.dart`
   - `lib/models/student_profile.dart`
   - `content/journeys/geometry_foundation_journey.json`

#### Phase 2: UI Integration
3. Update `lib/models/practice_mode.dart` to add `foundationJourney`
4. Implement screens:
   - `lib/screens/foundation_journey_screen.dart`
   - `lib/screens/foundation_journey_question_screen.dart`
   - Update `lib/screens/home_screen.dart`

#### Phase 3: Interactive Components
5. Add manipulatives:
   - `lib/widgets/diagram_manipulatives.dart`
   - Integration with question screens

#### Phase 4: Merge Sequence
```bash
# Step 1: Merge content pipeline first (foundation)
git checkout main
git merge feature/content-pipeline-integration
git push origin main

# Step 2: Merge post-exam diagnosis
git checkout main
git merge feature/post-exam-diagnosis
git push origin main

# Step 3: Merge Foundation Journey
git checkout main
git merge feature/foundation-journey
git push origin main
```

#### Phase 5: Integration Testing
6. Test complete flow:
   - Home → Foundation Journey → Level → Questions → Progress
   - Content loading from JSON
   - Progression engine logic
   - UI responsiveness

### Conflict Resolution Guidelines

#### Expected Conflicts
- `practice_mode.dart` enum changes
- `home_screen.dart` UI layout
- Import statements in screens

#### Resolution Strategy
1. **Enum conflicts**: Keep `foundationJourney` addition
2. **UI conflicts**: Prioritize Foundation Journey hero section
3. **Import conflicts**: Add new Foundation Journey imports
4. **Model conflicts**: Foundation models should coexist with existing ones

### Rollback Plan
- Keep each phase in separate commits
- Tag releases: `v1.0-content-pipeline`, `v1.1-diagnosis`, `v1.2-foundation`
- Feature flags for Foundation Journey (optional)

## Testing Strategy

### Unit Tests

#### JourneyProgressionEngine Tests
```dart
// test/models/journey_progression_engine_test.dart
void main() {
  group('JourneyProgressionEngine', () {
    test('should unlock next level after 2 correct answers', () {
      // Test progression rule: correct twice → unlock next
    });
    
    test('should show micro-lesson for wrong + low confidence', () {
      // Test intervention rule
    });
    
    test('should go down level after 2 wrong answers', () {
      // Test regression rule
    });
    
    test('should jump forward for correct + fast + high confidence', () {
      // Test acceleration rule
    });
  });
}
```

#### FoundationJourney Model Tests
```dart
// test/models/foundation_journey_test.dart
void main() {
  group('FoundationJourney', () {
    test('should deserialize from JSON correctly', () {
      // Test JSON parsing
    });
    
    test('should validate required fields', () {
      // Test schema validation
    });
    
    test('should calculate total duration correctly', () {
      // Test duration aggregation
    });
  });
}
```

#### StudentProfile Tests
```dart
// test/models/student_profile_test.dart
void main() {
  group('StudentProfile', () {
    test('should recommend Foundation Journey for Class 7', () {
      final profile = StudentProfile(currentClass: 7, ...);
      expect(profile.getRecommendedMode(), PracticeMode.foundationJourney);
    });
    
    test('should recommend Learner Mode for Class 10', () {
      final profile = StudentProfile(currentClass: 10, ...);
      expect(profile.getRecommendedMode(), PracticeMode.learner);
    });
  });
}
```

### Integration Tests

#### Journey Loading Tests
```dart
// test_integration/journey_loading_test.dart
void main() {
  group('Journey Loading', () {
    testWidgets('should load journey from content JSON', (tester) async {
      // Test complete loading flow
    });
    
    testWidgets('should handle missing journey gracefully', (tester) async {
      // Test error handling
    });
  });
}
```

#### Progression Flow Tests
```dart
// test_integration/progression_flow_test.dart
void main() {
  group('Progression Flow', () {
    testWidgets('should complete full journey progression', (tester) async {
      // Test end-to-end journey
    });
    
    testWidgets('should handle micro-lesson intervention', (tester) async {
      // Test intervention flow
    });
  });
}
```

### UI Tests

#### Home Screen Tests
```dart
// test_ui/home_screen_test.dart
void main() {
  group('Home Screen Foundation Journey', () {
    testWidgets('should show Foundation Journey hero', (tester) async {
      // Test hero section visibility
    });
    
    testWidgets('should prioritize Foundation Journey mode', (tester) async {
      // Test mode selection UI
    });
    
    testWidgets('should navigate to Foundation Journey on tap', (tester) async {
      // Test navigation flow
    });
  });
}
```

#### Foundation Journey Screen Tests
```dart
// test_ui/foundation_journey_screen_test.dart
void main() {
  group('Foundation Journey Screen', () {
    testWidgets('should display journey progress', (tester) async {
      // Test progress visualization
    });
    
    testWidgets('should show current level prominently', (tester) async {
      // Test current level highlighting
    });
    
    testWidgets('should lock future levels appropriately', (tester) async {
      // Test level access control
    });
  });
}
```

### Performance Tests

#### Content Loading Performance
```dart
// test_performance/content_loading_test.dart
void main() {
  group('Content Loading Performance', () {
    test('should load journey within 500ms', () async {
      final stopwatch = Stopwatch()..start();
      await engine.loadJourney('geometry_foundation_journey');
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
```

### Content Validation Tests

#### Journey Schema Validation
```dart
// test_content/journey_validation_test.dart
void main() {
  group('Journey Schema Validation', () {
    test('should validate L0-L5 progression structure', () {
      // Test required levels exist
    });
    
    test('should validate micro-lesson completeness', () {
      // Test each level has micro-lesson
    });
    
    test('should validate unlock thresholds', () {
      // Test threshold configurations
    });
  });
}
```

## Success Criteria

### Functional Requirements
- [ ] Foundation Journey loads from JSON content
- [ ] Progression engine applies all rules correctly
- [ ] Student profiles recommend appropriate modes
- [ ] Home screen prioritizes Foundation Journey
- [ ] Micro-lessons display before questions
- [ ] Confidence tracking works end-to-end
- [ ] Manipulatives update calculations dynamically
- [ ] Journey completion triggers appropriate flow

### Performance Requirements
- [ ] Journey loads in < 500ms
- [ ] UI transitions are smooth (60fps)
- [ ] Memory usage remains stable
- [ ] Battery usage is reasonable

### Quality Requirements
- [ ] All unit tests pass (>90% coverage)
- [ ] All integration tests pass
- [ ] UI tests cover critical user flows
- [ ] Content validation prevents broken journeys
- [ ] Error handling is graceful

### User Experience Requirements
- [ ] Clear visual hierarchy for Foundation Journey
- [ ] Intuitive progression indicators
- [ ] Helpful micro-lessons
- [ ] Engaging manipulatives
- [ ] Motivating completion flow

## Next Steps

1. **Immediate**: Create `feature/foundation-journey` branch
2. **Week 1**: Implement core models and progression engine
3. **Week 2**: Build UI screens and home screen integration
4. **Week 3**: Add manipulatives and confidence tracking
5. **Week 4**: Comprehensive testing and bug fixes
6. **Week 5**: Merge and deployment preparation

## Dependencies

### Required
- Content pipeline integration (must merge first)
- Post-exam diagnosis (for complete learning loop)
- Updated practice mode enum

### Optional
- Parent dashboard (for progress viewing)
- Advanced analytics (for progression insights)
- A/B testing framework (for journey optimization)

## Risk Mitigation

### Technical Risks
- **Content loading failures**: Graceful fallbacks and error states
- **Performance issues**: Lazy loading and caching
- **State management complexity**: Clear separation of concerns

### Product Risks
- **User confusion**: Clear onboarding and tooltips
- **Content gaps**: Comprehensive validation
- **Engagement issues**: Gamification elements and progress visualization

### Timeline Risks
- **Merge conflicts**: Early integration testing
- **Scope creep**: Clear MVP definition
- **Resource constraints**: Phased rollout approach