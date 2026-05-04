import 'package:flutter/material.dart';

import '../models/question_data.dart';

class QuestionPanel extends StatelessWidget {
  final QuestionData question;
  final int? selectedIndex;
  final bool showAnswer;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onCheckAnswer;

  const QuestionPanel({
    super.key,
    required this.question,
    this.selectedIndex,
    required this.showAnswer,
    required this.onOptionSelected,
    required this.onCheckAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject / topic chip
          Row(
            children: [
              _buildChip(question.subject, theme.colorScheme.primary),
              const SizedBox(width: 8),
              _buildChip(question.topic, theme.colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            question.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(question.options.length, (i) {
            final isSelected = selectedIndex == i;
            final isCorrect = showAnswer && i == question.correctIndex;
            final isWrong = showAnswer && isSelected && !isCorrect;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                label: String.fromCharCode(65 + i), // A, B, C, D
                text: question.options[i],
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrong: isWrong,
                showAnswer: showAnswer,
                onTap: showAnswer ? null : () => onOptionSelected(i),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Check answer button
          if (!showAnswer && selectedIndex != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCheckAnswer,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Check Answer'),
              ),
            ),

          // Explanation
          if (showAnswer && question.explanation != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation!,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool showAnswer;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.showAnswer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelBg;

    if (isCorrect) {
      borderColor = Colors.green.shade400;
      bgColor = Colors.green.shade50;
      labelBg = Colors.green;
    } else if (isWrong) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.shade50;
      labelBg = Colors.red;
    } else if (isSelected) {
      borderColor = Colors.blue.shade400;
      bgColor = Colors.blue.shade50;
      labelBg = Colors.blue;
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      labelBg = Colors.grey.shade600;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isCorrect)
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
              if (isWrong)
                const Icon(Icons.cancel, color: Colors.red, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
