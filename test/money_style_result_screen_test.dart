import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_result_screen.dart';
void main(){ testWidgets('insufficient result explains coverage and exposes recovery actions',(tester) async { var more=false; await tester.pumpWidget(MaterialApp(home:MoneyStyleResultScreen(completion:MoneyStyleCompletion(session:AnswerSession(userId:'u',sessionId:'s',selectedAnswers:{1:0}),result:null),onAnswerMore:()=>more=true,onStartOver:(){}))); expect(find.text('1 of 12 questions answered'),findsOneWidget); expect(find.textContaining('each area'),findsOneWidget); await tester.tap(find.text('Answer a few more')); expect(more,isTrue); }); }
