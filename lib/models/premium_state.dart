import 'package:flutter/material.dart';

enum PremiumTier { free, premium }

class PremiumState extends ChangeNotifier {
  PremiumTier _tier = PremiumTier.free;

  PremiumTier get tier => _tier;
  bool get isPremium => _tier == PremiumTier.premium;

  void upgradeToPremium() {
    _tier = PremiumTier.premium;
    notifyListeners();
  }

  void downgradeToFree() {
    _tier = PremiumTier.free;
    notifyListeners();
  }

  void toggle() {
    _tier = isPremium ? PremiumTier.free : PremiumTier.premium;
    notifyListeners();
  }
}

// Features gated by premium
class PremiumFeatures {
  static bool tapInsight(PremiumTier tier) => tier == PremiumTier.premium;
  static bool guideMe(PremiumTier tier) => tier == PremiumTier.premium;
  static bool smartHighlighting(PremiumTier tier) => tier == PremiumTier.premium;
  static bool drawingTools(PremiumTier tier) => tier == PremiumTier.premium;
  static bool weakAreaTracking(PremiumTier tier) => tier == PremiumTier.premium;
  static bool similarQuestions(PremiumTier tier) => tier == PremiumTier.premium;

  // Free features
  static bool viewDiagram(PremiumTier tier) => true;
  static bool solveQuestion(PremiumTier tier) => true;
  static bool basicExplanation(PremiumTier tier) => true;
  static bool zoomPan(PremiumTier tier) => true;
  static bool layerToggles(PremiumTier tier) => true;
}
