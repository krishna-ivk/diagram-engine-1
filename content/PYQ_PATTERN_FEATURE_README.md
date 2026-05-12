# PYQ Pattern → Fundamental Question Generator

## Overview

This feature creates **original fundamental questions** based on JEE PYQ patterns, without copying any content directly from external sources. It transforms complex JEE patterns into age-appropriate questions for Class 7-9 students.

## 🎯 Mission Statement

> **Build a fundamentals bank mapped to PYQ patterns, not a PYQ bank.**

We use external JEE repositories **only for pattern discovery**, then create completely original educational content.

## 📁 File Structure

```
content/
├── patterns/
│   └── regular_polygon_patterns.json    # Pattern index (no copied content)
├── questions/
│   └── central_angle_regular_polygon_questions.json  # Original questions
├── topics/
│   └── central_angle_regular_polygon.json           # Updated topic capsule
└── central_angle_regular_polygon_qa_checklist.md     # Quality assurance

content_pipeline/scripts/
├── pyq_pattern_analyzer.dart           # Pattern discovery pipeline
└── question_validator.dart             # Content QA validation
```

## 🔄 Pipeline Process

### 1. Pattern Discovery (Safe)
```text
JEE PYQ repo → identify repeated patterns → map to fundamentals → create pattern index
```

**What we extract:**
- ✅ Pattern frequency and topics
- ✅ Required skills and concepts  
- ✅ Common formulae used
- ✅ Typical misconceptions
- ✅ Difficulty progression

**What we NEVER copy:**
- ❌ Exact question text
- ❌ Multiple choice options
- ❌ Solutions or explanations
- ❌ Diagrams or images
- ❌ Any copyrighted material

### 2. Original Content Creation
```text
Pattern index → create original questions → age-appropriate wording → educational explanations
```

**Each question includes:**
- Original question text
- Original answer options
- Teaching-focused wrong explanations
- Age-appropriate examples
- Proper formula application

### 3. Quality Validation
```text
Generated questions → structural validation → content QA → manual review checklist
```

## 📊 Content Distribution

### Central Angle of Regular Polygon (16 questions)

| Level | Count | Focus | Example |
|-------|-------|-------|---------|
| **Starter** | 5 | Basic concepts, Class 7 | "A square is divided from the center into 4 equal parts. What is each central angle?" |
| **Practice** | 7 | Application problems, Class 7-8 | "A pizza is cut into 6 equal slices. What is the central angle of each slice?" |
| **Challenge** | 3 | Advanced problems, Class 8-9 | "A regular dodecagon has a central angle of 30°. If you connect every other vertex..." |
| **JEE-Style** | 1 | Mixed concepts, Class 10+ | "A regular polygon has 12 sides. The ratio of its central angle to its interior angle is 2:3..." |

## 🎨 Question Quality Standards

Every original question must satisfy:

### ✅ Content Requirements
- **One concept only** (starter questions)
- **Age-appropriate wording** (Class 7-8 focus)
- **No unnecessary JEE jargon** (lower levels)
- **One clear formula** (starter questions)
- **All wrong options map to real misconceptions**
- **Why-wrong explanations teach**
- **Diagram/manipulative support available**
- **Correct answer verified manually**

### ✅ Structural Requirements
- `source_type`: "original_recreated" or "original_authored"
- `source_pattern`: reference to pattern ID
- `question_role`: starter/practice/challenge/jee_style
- `why_wrong_explanations`: excludes correct answer
- `review_status`: "draft" → "approved"

### ✅ Original Content Verification
- Question text is original wording
- Options are original choices  
- Explanations are original teaching content
- No copyrighted material included
- Pattern-based creation only (not direct copying)

## 🛠️ Usage Examples

### Pattern Index Format
```json
{
  "pattern_id": "regular_polygon_central_angle",
  "observed_in": {
    "subject": "Mathematics",
    "chapter": "Geometry", 
    "topic": "Regular Polygon"
  },
  "frequency_in_jee": "high",
  "skills_required": [
    "central_angle_calculation",
    "number_of_sides_relationship"
  ],
  "target_topic_capsule": "central_angle_regular_polygon",
  "do_not_copy_source_text": true
}
```

### Original Question Format
```json
{
  "question_id": "fundamental_central_angle_square_001",
  "source_type": "original_recreated",
  "source_pattern": "regular_polygon_central_angle",
  "class_level": "Class 7",
  "question_role": "starter",
  "question_text": "A square is divided from the center into 4 equal parts. What is each central angle?",
  "options": ["45°", "60°", "90°", "120°"],
  "correct_answer": 2,
  "formulae_used": ["central_angle = 360° / n"],
  "why_wrong_explanations": {
    "0": "45° is the central angle of an octagon (8 sides), not a square.",
    "1": "60° is the central angle of a hexagon (6 sides).",
    "3": "120° is the central angle of a triangle (3 sides)."
  },
  "difficulty": "easy",
  "estimated_time_seconds": 45,
  "diagram_required": true,
  "manipulative": "polygon_sides_slider",
  "review_status": "draft"
}
```

## 🚀 How to Extend

### Adding New Patterns
1. Analyze JEE patterns in external repo
2. Create pattern index in `content/patterns/`
3. Generate original questions using pipeline
4. Validate with content QA
5. Update topic capsule with new questions

### Quality Checklist
For each new question:
- [ ] Question text is clear and age-appropriate
- [ ] Options are plausible and distinct
- [ ] Correct answer is accurate
- [ ] Wrong explanations teach the concept
- [ ] Formula application is correct
- [ ] Diagram/manipulative supports learning
- [ ] Time estimation is reasonable
- [ ] Content is original (no copying)

## ⚠️ Important Safety Notes

### Legal & Ethical Compliance
- **Never copy exact question text** from external sources
- **Never copy multiple choice options** directly
- **Never copy solutions or explanations**
- **Always create original educational content**
- **Always attribute pattern sources only** (not content)

### Technical Safety
- All questions marked with `source_type: "original_recreated"` or `"original_authored"`
- Pattern indices contain metadata only (no copied content)
- QA checklists verify original content compliance
- Validation prevents accidental copying

## 📈 Impact & Benefits

### For Students
- **Age-appropriate progression** from Class 7 to JEE level
- **Strong fundamentals** before advanced topics
- **Clear explanations** for common misconceptions
- **Interactive manipulatives** for visual learning

### For Educators  
- **Curriculum-aligned** content
- **Quality-assured** questions
- **Flexible difficulty** levels
- **Original teaching materials**

### For Platform
- **Scalable content** generation pipeline
- **Legal compliance** with original content
- **High educational quality** standards
- **Sustainable content** creation process

## 🎯 Next Steps

### Immediate (Completed)
- ✅ Create pattern discovery pipeline
- ✅ Generate 16 original fundamental questions
- ✅ Implement content validation and QA
- ✅ Update Topic Capsule with new content
- ✅ Ensure 100% original content compliance

### Future Expansion
- 🔄 Add more pattern topics (interior angles, diagonals, area)
- 🔄 Expand to other JEE subjects (Physics, Chemistry)
- 🔄 Create adaptive difficulty progression
- 🔄 Add interactive manipulatives and visualizations
- 🔄 Implement automated quality scoring

---

## 📞 Support & Questions

For questions about this feature:
1. Review the pattern index files in `content/patterns/`
2. Check the QA checklists for quality standards
3. Examine the original questions in `content/questions/`
4. Run the validation scripts to ensure compliance

**Remember:** We build **fundamentals mapped to patterns**, not copied question banks. This approach ensures legal compliance, educational quality, and sustainable content creation.