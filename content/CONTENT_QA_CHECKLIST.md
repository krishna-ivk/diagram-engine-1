# Content QA Checklist

## Schema Validation ✅
- [x] JSON structure is valid
- [x] Required fields are present
- [x] Data types are correct
- [x] Question ID format is consistent

## Content Accuracy Checklist ❗

### Question-Answer Consistency
- [ ] `correct_answer` index matches the actual correct option
- [ ] Explanation proves the correct answer
- [ ] Why-wrong explanations match the wrong options
- [ ] No contradictory information between explanation and answer

### Mathematical Accuracy
- [ ] Calculations are correct
- [ ] Units are consistent and appropriate
- [ ] Formulas are applied correctly
- [ ] No rounding errors

### Option Quality
- [ ] All options are plausible distractors
- [ ] Only one option is truly correct
- [ ] Options are similar in complexity
- [ ] No obviously wrong options that give away the answer

### Difficulty Alignment
- [ ] Question difficulty matches class level
- [ ] No JEE-level jumps before foundation is clear
- [ ] Progression from starter → practice → challenge makes sense
- [ ] Time estimates are realistic

### Learning Effectiveness
- [ ] Question text is clear and unambiguous
- [ ] Diagrams (if any) are accurate and helpful
- [ ] Solution steps are logical and easy to follow
- [ ] Why-wrong explanations teach the concept

## Topic Capsule Specific QA
- [ ] Synopsis cards are 3-5 lines maximum
- [ ] Each synopsis card has one main idea
- [ ] Formulae are correctly formatted
- [ ] Common mistakes are actually common
- [ ] Question IDs resolve to real questions
- [ ] Manipulatives are appropriate for the topic

## Foundation Journey QA (for internal use)
- [ ] Level progression makes sense
- [ ] Prerequisites are logical
- [ ] Unlock thresholds are achievable
- [ ] Micro-lessons support the questions

## Automated Validation
- [ ] All question IDs referenced exist in content
- [ ] No duplicate question IDs within topics
- [ ] Manipulative identifiers are valid
- [ ] Content files are valid JSON

## Manual Review Required ❗

### Critical Issues to Check
1. **Mathematical correctness** - Verify every calculation
2. **Answer-option alignment** - Ensure correct_answer matches explanation
3. **Educational value** - Questions should teach, not just test
4. **Age appropriateness** - Content suitable for Class 7 students

### Review Process
1. **Author Review**: Content creator validates their own work
2. **Peer Review**: Another educator checks for accuracy
3. **Student Testing**: Try questions with actual students
4. **Final Sign-off**: Project lead approves for production

## Common Issues Found

### Answer Bugs (Critical)
- `correct_answer` index doesn't match actual correct option
- Explanation proves a different answer than marked correct
- Why-wrong explanations reference wrong option indices

### Content Issues
- Questions too advanced for target class level
- Ambiguous wording that could confuse students
- Missing context or assumptions
- Incorrect formulas or applications

### Technical Issues
- Question IDs don't resolve to actual questions
- Invalid manipulative identifiers
- Missing required fields in JSON structure

## Quality Gates

### Must Pass Before Merge
- [ ] No answer-option mismatches
- [ ] All question IDs resolve
- [ ] Schema validation passes
- [ ] Manual mathematical review completed

### Should Pass Before Release
- [ ] Student testing completed
- [ ] All why-wrong explanations reviewed
- [ ] Difficulty progression validated
- [ ] Time estimates verified

## Tools and Scripts

### Automated Validation
```bash
# Run content validation
dart content_pipeline/scripts/content_validator.dart

# Check for answer-option mismatches
dart content_pipeline/scripts/answer_consistency_check.dart
```

### Manual Review Checklist
- Print this checklist and mark items as you review
- Use a spreadsheet to track question-by-question validation
- Document any issues found and their resolution

## Emergency Fixes

If critical issues are found after merge:

1. **Answer Bug**: Fix immediately, create hotfix PR
2. **Missing Question**: Add fallback or fix reference
3. **Invalid Content**: Remove or replace problematic content
4. **Schema Issues**: Update validation script and fix content

## Contact Information

- **Content Issues**: Contact content team
- **Technical Issues**: Contact development team  
- **Urgent Production Issues**: Contact project lead immediately

---

**Remember**: Schema validation catches structural issues, but only human review can catch mathematical and educational accuracy issues. Always combine automated validation with manual QA!