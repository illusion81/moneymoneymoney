import '../models/models.dart';

/// Today's five check-in tasks (design.md §Hive "Check-ins").
///
/// Two start done, three start todo. Copy is in the app voice — specific,
/// second-person, never moralising.
const List<Task> kInitialTasks = [
  Task(
    id: 'cap-groceries',
    title: 'Cap groceries at \$560',
    sub: 'August averaged \$602 — trim the gap',
    reward: 35,
    done: true,
  ),
  Task(
    id: 'move-savings',
    title: 'Move \$50 to savings',
    sub: 'Straight after payday',
    reward: 15,
    done: true,
  ),
  Task(
    id: 'log-coffee',
    title: 'Log yesterday\u2019s coffee run',
    sub: 'Two oat lattes, one pastry',
    reward: 10,
  ),
  Task(
    id: 'cancel-app',
    title: 'Cancel the app you never open',
    sub: 'The one you downloaded in March',
    reward: 20,
  ),
  Task(
    id: 'weekend-fund',
    title: 'Set aside \$80 for the weekend',
    sub: 'Before Friday evening',
    reward: 15,
  ),
];
