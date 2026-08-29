// Risk-tolerance grades.
//
// The scored questionnaire that used to derive these was removed; the level
// is currently a fixed default. The scale itself is kept because the report
// and the backend's riskAppetite still speak in these terms.

/// The five bank-standard risk-tolerance grades, lowest to highest.
enum RiskLevel { cautious, steady, balanced, growth, aggressive }

String riskLevelLabel(RiskLevel level) {
  switch (level) {
    case RiskLevel.cautious:
      return 'Cautious';
    case RiskLevel.steady:
      return 'Steady';
    case RiskLevel.balanced:
      return 'Balanced';
    case RiskLevel.growth:
      return 'Growth';
    case RiskLevel.aggressive:
      return 'Aggressive';
  }
}

String riskLevelLabelZh(RiskLevel level) {
  switch (level) {
    case RiskLevel.cautious:
      return '谨慎型';
    case RiskLevel.steady:
      return '稳健型';
    case RiskLevel.balanced:
      return '平衡型';
    case RiskLevel.growth:
      return '进取型';
    case RiskLevel.aggressive:
      return '激进型';
  }
}
