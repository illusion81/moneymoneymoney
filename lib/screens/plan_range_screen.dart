import 'package:flutter/material.dart';
enum IncomeRange { under2500, from2500To5000, from5000To8000, over8000, preferNotToSay }
enum FixedCostShareRange { underHalf, aboutHalf, overHalf, unsure, preferNotToSay }
enum PlanningPriority { breathingRoom, upcomingCost, reduceSpending, debtOrganisation, explore }
class PlanRangeScreen extends StatelessWidget { const PlanRangeScreen({super.key,required this.onKeep,required this.onExact}); final VoidCallback onKeep,onExact; @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Plan with ranges')),body:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Choose broad ranges only. No exact amounts are calculated or sent.'),const Spacer(),OutlinedButton(onPressed:onKeep,child:const Text('Keep this range-based snapshot')),FilledButton(onPressed:onExact,child:const Text('Use exact numbers for a daily calculation'))]))); }
