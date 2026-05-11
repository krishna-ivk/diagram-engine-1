import 'package:flutter/material.dart';
import '../models/exam_diagnosis.dart';
import '../models/question_data.dart';
import '../models/performance_tracker.dart';
import 'question_screen.dart';

class PostExamDiagnosisScreen extends StatelessWidget {
  final ExamDiagnosis diagnosis;
  final List<QuestionData> questions;
  final PerformanceTracker tracker;
  final VoidCallback onStartRepair;

  const PostExamDiagnosisScreen({
    super.key,
    required this.diagnosis,
    required this.questions,
    required this.tracker,
    required this.onStartRepair,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Diagnosis'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreSummary(context),
            const SizedBox(height: 20),
            if (diagnosis.weakConcepts.isNotEmpty) ...[
              _buildWeakConcepts(context),
              const SizedBox(height: 20),
            ],
            if (diagnosis.strongConcepts.isNotEmpty) ...[
              _buildStrongConcepts(context),
              const SizedBox(height: 20),
            ],
            if (diagnosis.timePressureQuestions.isNotEmpty) ...[
              _buildTimePressure(context),
              const SizedBox(height: 20),
            ],
            if (diagnosis.wrongAnswersByConcept.isNotEmpty) ...[
              _buildWrongAnswers(context),
              const SizedBox(height: 20),
            ],
            if (diagnosis.rescueRecommendations.isNotEmpty) ...[
              _buildRescuePrescription(context),
              const SizedBox(height: 20),
            ],
            _buildRepairButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Score',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '${diagnosis.scorePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diagnosis.grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '${diagnosis.totalQuestions}', Icons.quiz),
              _buildStatItem('Correct', '${diagnosis.correctAnswers}', Icons.check_circle),
              _buildStatItem('Wrong', '${diagnosis.incorrectAnswers}', Icons.cancel),
              _buildStatItem('Time', _formatTime(diagnosis.totalTimeSeconds), Icons.timer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildWeakConcepts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(
              'Areas Needing Work',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...diagnosis.weakConcepts.take(3).map((concept) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.conceptName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${concept.correctAttempts}/${concept.totalAttempts} correct',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                '${(concept.accuracy * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStrongConcepts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              'Strong Areas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...diagnosis.strongConcepts.take(3).map((concept) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.conceptName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${concept.correctAttempts}/${concept.totalAttempts} correct',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                '${(concept.accuracy * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTimePressure(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Time Pressure Detected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'These questions took >80% of expected time but were still wrong:',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ...diagnosis.timePressureQuestions.take(3).map((q) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${q.timeSpent}s',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildWrongAnswers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(
              'Wrong Answers by Concept',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Group by concept
        ..._groupWrongAnswersByConcept().entries.take(3).map((entry) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...entry.value.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        q.questionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        )),
      ],
    );
  }

  Map<String, List<WrongAnswerDetail>> _groupWrongAnswersByConcept() {
    final grouped = <String, List<WrongAnswerDetail>>{};
    for (final wrong in diagnosis.wrongAnswersByConcept) {
      grouped.putIfAbsent(wrong.conceptName, () => []).add(wrong);
    }
    return grouped;
  }

  Widget _buildRescuePrescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.healing, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            Text(
              'Your Repair Plan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...diagnosis.rescueRecommendations.map((rec) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flutter_dash, size: 18, color: Colors.purple.shade600),
                  const SizedBox(width: 8),
                  Text(
                    rec.conceptName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                rec.recommendation,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.replay, size: 14, color: Colors.purple.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${rec.recommendedQuestions.length} practice questions',
                    style: TextStyle(fontSize: 11, color: Colors.purple.shade400),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRepairButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onStartRepair,
        icon: const Icon(Icons.build),
        label: const Text('Start Repair Session'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.purple.shade600,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}