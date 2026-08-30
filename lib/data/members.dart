import '../models/models.dart';

/// The five hive-mates (README "Hive-mates").
///
/// "You" is the signed-in user with the live honey balance (1,240 — matches
/// the home screen's starting balance, design.md state model) and a live
/// streak of 18 days.
const List<Member> kMembers = [
  Member(
    id: 'mara',
    name: 'Mara',
    honey: 2480,
    streak: 31,
    status: '31 days of one-liners · 2,480 honey',
  ),
  Member(
    id: 'dev',
    name: 'Dev',
    honey: 1240,
    streak: 18,
    status: '18 days of early check-ins · 1,240 honey',
  ),
  Member(
    id: 'you',
    name: 'You',
    honey: 1240,
    streak: 18,
    isYou: true,
    status: '18 days · 1,240 honey — live balance',
  ),
  Member(
    id: 'priya',
    name: 'Priya',
    honey: 520,
    streak: 0,
    status: 'Missed two days — be kind about it',
  ),
  Member(
    id: 'tom',
    name: 'Tom',
    honey: 180,
    streak: 4,
    status: '4 days in · 180 honey',
  ),
];
