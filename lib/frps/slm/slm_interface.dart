import '../models/tool_outputs.dart';
import '../models/user_profile.dart';

class ExtractedData {
  const ExtractedData({required this.category, required this.amount, this.raw});
  final String category;
  final double amount;
  final String? raw;
}

abstract class SlmInterface {
  String generateReportNarrative({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  });
  ExtractedData parseFreeText(String answer);
}
