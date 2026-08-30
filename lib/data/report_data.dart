import 'package:flutter/material.dart';

import '../models/models.dart';

/// One "Where it went" row (design.md §Report): the label's fill fraction
/// (0..1), its track colour, and an optional inline note.
class WhereItWentRow {
  const WhereItWentRow({
    required this.fraction,
    required this.color,
    this.note,
  });

  final double fraction;
  final Color color;

  /// Optional inline note, e.g. "+$180".
  final String? note;
}

/// The summary-card body (README "Report" — "THE SHORT OF IT").
const String kReportSummary =
    'Your month came in at \$6,240 and went out at \$4,118 — 66% spent, so '
    'the rest stacked up. Groceries climbed \$180 to \$742, your biggest '
    'drift, and it\u2019s the one number worth a second look. Debt kept '
    'leaking at \$410 a month, but savings held at \$8,150.';

/// The three "What the hive suggests" cards (README "Report").
const List<Suggestion> kSuggestions = [
  Suggestion(
    id: 'suggestion-1',
    body:
        'Groceries hit \$742 in August — up \$180 from July. Most of it is one '
        'bigger weekly shop, not more shops.',
    source: 'from 12 check-ins + Chase',
    taskTitle: 'Cap groceries at \$560',
    taskSub: 'From your Aug report',
    taskReward: 35,
  ),
  Suggestion(
    id: 'suggestion-2',
    body:
        'You\u2019ve got 4 subscriptions you haven\u2019t opened in 60 days. '
        'That\u2019s \$164 leaving the hive on autopilot.',
    source: 'from 2 accounts',
    taskTitle: 'Cancel the app you never open',
    taskSub: 'From your Aug report',
    taskReward: 20,
  ),
  Suggestion(
    id: 'suggestion-3',
    body:
        'The debt pot leaks \$410 a month. One extra \$50 payment a month '
        'would close it a full season earlier.',
    source: 'from 24 check-ins',
    taskTitle: 'Add \$50 to the debt leak',
    taskSub: 'From your Aug report',
    taskReward: 15,
  ),
];

/// "Where it went" rows (README "Report"). Note: the "+$180" inline note sits
/// on Groceries per the README (the design lists it on the Groceries label,
/// not Subscriptions).
const Map<String, WhereItWentRow> kWhereItWent = {
  'Groceries': WhereItWentRow(
    fraction: 0.78,
    color: Color(0xFF6E4826), // brown
    note: '+\$180',
  ),
  'Subscriptions': WhereItWentRow(
    fraction: 0.41,
    color: Color(0xFFC4634C), // clay
  ),
  'Transport': WhereItWentRow(
    fraction: 0.14,
    color: Color(0xFF8B6039), // brownLight
  ),
};
