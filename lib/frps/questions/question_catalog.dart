import 'package:moneymoneymoney/frps/models/question.dart';

const List<Question> questionCatalog = [
  Question(id: 'income', text: 'What is your monthly income?', type: QuestionType.numeric),
  Question(id: 'fixed-expenses', text: 'What are your fixed monthly expenses?', type: QuestionType.numeric),
  Question(id: 'savings-goal', text: 'What is your monthly savings goal?', type: QuestionType.numeric),
  Question(id: 'risk-preference', text: 'How do you feel about investment risk?', type: QuestionType.multipleChoice, options: ['conservative', 'balanced', 'growth']),
  Question(id: 'financial-goal', text: 'What is your primary financial goal?', type: QuestionType.multipleChoice, options: ['emergency fund', 'reduce spending', 'save for purchase', 'invest', 'debt control']),
  Question(id: 'spending-pressure', text: 'How much spending pressure do you feel?', type: QuestionType.multipleChoice, options: ['low', 'medium', 'high']),
  Question(id: 'has-debt', text: 'Do you currently have debt?', type: QuestionType.multipleChoice, options: ['yes', 'no']),
  Question(id: 'debt-details', text: 'Describe your debts (name, balance, interest rate, minimum payment).', type: QuestionType.freeText),
  Question(id: 'assets', text: 'Describe your assets and their values.', type: QuestionType.freeText),
  Question(id: 'liabilities', text: 'Describe your liabilities and their values.', type: QuestionType.freeText),
];
