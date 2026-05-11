# Test Suite

These tests cover the current app models and content pipeline wiring.

## Files

- `widget_test.dart` checks that the Flutter app launches and can navigate from the home screen into practice.
- `content_validation_test.dart` validates content-pipeline sample questions against `content_pipeline/schemas/question_item.json` and checks app sample assets through `tools/validate_content.dart`.
- `rescue_flow_test.dart` tests the current `QuestionData`, `ConceptGraph`, `RescueSystem`, and `ContentLoader` APIs.

## Run

```bash
flutter test
```

Flutter and Dart must be installed in the environment running the tests.
