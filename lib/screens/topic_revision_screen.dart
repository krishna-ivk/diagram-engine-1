import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/question_data.dart';
import '../models/diagram_element.dart';

class TopicRevisionScreen extends StatefulWidget {
  final List<QuestionData> questions;

  const TopicRevisionScreen({super.key, required this.questions});

  @override
  State<TopicRevisionScreen> createState() => _TopicRevisionScreenState();
}

class _TopicRevisionScreenState extends State<TopicRevisionScreen>
    with TickerProviderStateMixin {
  late List<String> _topics;
  late Map<String, List<QuestionData>> _topicQuestions;
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _buildTopics();
  }

  void _buildTopics() {
    final Map<String, List<QuestionData>> topicMap = {};
    for (final q in widget.questions) {
      topicMap.putIfAbsent(q.topic, () => []).add(q);
    }
    _topicQuestions = topicMap;
    _topics = topicMap.keys.toList();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectTopic(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Revision'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Topic chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                final count = _topicQuestions[_topics[index]]?.length ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${_topics[index]} ($count)'),
                    selected: isSelected,
                    onSelected: (_) => _selectTopic(index),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Animated content
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * _animation.value),
                  child: Opacity(
                    opacity: _animation.value,
                    child: child,
                  ),
                );
              },
              child: _buildTopicContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicContent() {
    if (_topics.isEmpty) {
      return const Center(child: Text('No topics available'));
    }
    final topic = _topics[_selectedIndex];
    final questions = _topicQuestions[topic] ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Topic header with animation
        _AnimatedTopicHeader(topic: topic),
        const SizedBox(height: 20),
        // Question cards with diagrams
        ...questions.asMap().entries.map((entry) {
          return _AnimatedQuestionCard(
            question: entry.value,
            index: entry.key,
          );
        }),
      ],
    );
  }
}

class _AnimatedTopicHeader extends StatefulWidget {
  final String topic;

  const _AnimatedTopicHeader({required this.topic});

  @override
  State<_AnimatedTopicHeader> createState() => _AnimatedTopicHeaderState();
}

class _AnimatedTopicHeaderState extends State<_AnimatedTopicHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  child: child,
                ),
              );
            },
            child: const Icon(Icons.functions, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to learn with interactive diagrams',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedQuestionCard extends StatefulWidget {
  final QuestionData question;
  final int index;

  const _AnimatedQuestionCard({required this.question, required this.index});

  @override
  State<_AnimatedQuestionCard> createState() => _AnimatedQuestionCardState();
}

class _AnimatedQuestionCardState extends State<_AnimatedQuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showDiagram = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500 + (widget.index * 100)),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _getDifficultyColor(widget.question.difficulty),
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.question.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _showDiagram ? Icons.visibility_off : Icons.visibility,
                        key: ValueKey(_showDiagram),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showDiagram = !_showDiagram;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Animated diagram preview
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: _showDiagram
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 80),
              secondChild: _buildAnimatedDiagram(),
            ),
            // Options
            if (_showDiagram)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.question.options.asMap().entries.map((e) {
                    return Chip(
                      label: Text(
                        e.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: e.key == widget.question.correctIndex
                          ? Colors.green.withOpacity(0.2)
                          : null,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDiagram() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _DiagramAnimationPainter(
          question: widget.question,
          progress: _showDiagram ? 1.0 : 0.0,
        ),
        size: const Size(double.infinity, 120),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }
}

class _DiagramAnimationPainter extends CustomPainter {
  final QuestionData question;
  final double progress;

  _DiagramAnimationPainter({required this.question, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Use actual diagram elements if available
    final elements = question.diagram.elements;
    
    if (elements.isNotEmpty) {
      _paintActualDiagram(canvas, size, elements);
    } else {
      // Fall back to generic topic-based animation
      _paintGenericAnimation(canvas, size);
    }
  }

  void _paintActualDiagram(Canvas canvas, Size size, List<DiagramElement> elements) {
    final scaleX = (size.width - 40) / 300;
    final scaleY = (size.height - 40) / 300;
    final offsetX = 20.0;
    final offsetY = size.height - 20;

    for (final element in elements) {
      _paintElement(canvas, element, scaleX, scaleY, offsetX, offsetY);
    }
  }

  void _paintElement(Canvas canvas, DiagramElement element, double scaleX, double scaleY, double offsetX, double offsetY) {
    final paint = Paint()
      ..color = _getElementColor(element.type).withOpacity(0.7 * progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    switch (element.type) {
      case ElementType.point:
        final pos = element.position;
        if (pos != null) {
          final x = offsetX + pos.dx * scaleX;
          final y = offsetY - pos.dy * scaleY;
          canvas.drawCircle(Offset(x, y), 4 * progress, paint..style = PaintingStyle.fill);
          
          // Draw label
          final label = element.properties['text']?.toString();
          if (label != null) {
            final textPainter = TextPainter(
              text: TextSpan(text: label, style: TextStyle(color: Colors.black87, fontSize: 12)),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(x + 6, y - 6));
          }
        }
        break;
        
      case ElementType.line:
        final fromX = element.properties['fromX'];
        final fromY = element.properties['fromY'];
        final toX = element.properties['toX'];
        final toY = element.properties['toY'];
        if (fromX != null && fromY != null && toX != null && toY != null) {
          final path = Path()
            ..moveTo(offsetX + (fromX as num).toDouble() * scaleX, offsetY - (fromY as num).toDouble() * scaleY)
            ..lineTo(offsetX + (toX as num).toDouble() * scaleX, offsetY - (toY as num).toDouble() * scaleY);
          canvas.drawPath(path, paint);
        }
        break;
        
      case ElementType.polygon:
      case ElementType.region:
        final points = element.properties['points'];
        if (points is List && points.isNotEmpty) {
          final path = Path();
          for (var i = 0; i < points.length; i++) {
            final pt = points[i];
            if (pt is Map && pt['x'] != null && pt['y'] != null) {
              final x = offsetX + (pt['x'] as num).toDouble() * scaleX;
              final y = offsetY - (pt['y'] as num).toDouble() * scaleY;
              if (i == 0) {
                path.moveTo(x, y);
              } else {
                path.lineTo(x, y);
              }
            }
          }
          path.close();
          canvas.drawPath(path, paint..style = PaintingStyle.fill);
        }
        break;
        
      case ElementType.label:
        final text = element.properties['text']?.toString();
        final x = element.properties['x'];
        final y = element.properties['y'];
        if (text != null && x != null && y != null) {
          final textPainter = TextPainter(
            text: TextSpan(text: text, style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(offsetX + (x as num).toDouble() * scaleX, offsetY - (y as num).toDouble() * scaleY));
        }
        break;
        
      default:
        break;
    }
  }

  Color _getElementColor(ElementType type) {
    switch (type) {
      case ElementType.point:
        return Colors.blue;
      case ElementType.line:
        return Colors.grey.shade700;
      case ElementType.polygon:
      case ElementType.region:
        return Colors.orange;
      case ElementType.circle:
      case ElementType.arc:
        return Colors.purple;
      case ElementType.vector:
        return Colors.green;
      case ElementType.label:
        return Colors.black87;
      case ElementType.angle:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  void _paintGenericAnimation(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    // Draw axes
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 20, size.height - 20),
      axisPaint,
    );
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20, 20),
      axisPaint,
    );

    // Animate curve drawing based on question topic
    final path = Path();
    final points = _getDiagramPoints(question.topic);
    
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final animatedY = size.height - 20 - (point.dy * progress);
      if (i == 0) {
        path.moveTo(point.dx, animatedY);
      } else {
        path.lineTo(point.dx, animatedY);
      }
    }
    
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  List<Offset> _getDiagramPoints(String topic) {
    // Generate different diagram patterns based on topic
    final List<Offset> points = [];
    final width = 260.0;
    final height = 80.0;
    
    if (topic.toLowerCase().contains('integral') || 
        topic.toLowerCase().contains('calculus')) {
      // Parabola for integration
      for (var x = 0.0; x <= width; x += 10) {
        final y = math.sin(x * 0.03) * height * 0.5 + height * 0.5;
        points.add(Offset(20 + x, y));
      }
    } else if (topic.toLowerCase().contains('vector')) {
      // Vectors
      points.add(const Offset(40, 60));
      points.add(const Offset(100, 30));
      points.add(const Offset(160, 50));
      points.add(const Offset(220, 20));
    } else if (topic.toLowerCase().contains('trig')) {
      // Sine wave
      for (var x = 0.0; x <= width; x += 5) {
        final y = math.sin(x * 0.05) * height * 0.4 + height * 0.5;
        points.add(Offset(20 + x, y));
      }
    } else {
      // Default linear
      for (var x = 0.0; x <= width; x += 20) {
        final y = height * 0.8 - (x / width) * height * 0.6;
        points.add(Offset(20 + x, y));
      }
    }
    return points;
  }

  @override
  bool shouldRepaint(covariant _DiagramAnimationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}