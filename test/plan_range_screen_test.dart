import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/screens/plan_range_screen.dart';
void main(){ testWidgets('range snapshot stays factual and offers explicit exits',(tester) async { var kept=false; await tester.pumpWidget(MaterialApp(home:PlanRangeScreen(onKeep:()=>kept=true,onExact:(){}))); await tester.tap(find.text('Income range')); await tester.pump(); await tester.tap(find.text('under2500').last); await tester.pump(); expect(find.textContaining('under2500'),findsWidgets); expect(find.textContaining('No exact dollar targets'),findsOneWidget); await tester.tap(find.text('Keep this range-based snapshot')); expect(kept,isTrue); }); }
