import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/check_in_tasks.dart';
import '../data/market_catalog.dart';
import '../models/models.dart';

/// Which detail sheet is open (design.md §4.6 — the shared sheet).
enum SheetKind { income, expense, pot }

/// The whole app's state, owned by [HiveNotifier].
class HiveState {
  const HiveState({
    this.sheet,
    this.potLayer = 'cash',
    this.honey = 1240,
    this.level = 7,
    this.income = 6240.0,
    this.expense = 4118.0,
    this.tasks = const <Task>[],
    this.ownedMarketIds = const <String>{},
    this.acceptedSuggestionIds = const <String>{},
    this.marketTab = MarketTab.boosts,
    this.flash,
    this.generatingReport = false,
    this.reportRun = 0,
    this.banks = const {'chase': true, 'ally': true, 'amex': false},
    this.nudgeSettings = const {'morning': true, 'drift': true, 'streakVisible': false},
    this.reportCadence = 'Monthly',
    this.nudgedFriends = const <String>{},
    this.invites = 0,
    this.beeSkinId = 'classic',
    this.onboarded = false,
  });

  /// Which detail sheet is currently open, if any.
  final SheetKind? sheet;

  /// Selected honey-pot layer: 'cash' | 'savings' | 'invested' | 'debt'.
  final String potLayer;

  /// Honey balance.
  final int honey;

  /// Current level.
  final int level;

  /// Monthly income, in dollars.
  final double income;

  /// Monthly expense, in dollars.
  final double expense;

  /// Today's check-in tasks.
  final List<Task> tasks;

  /// Market item ids the user owns.
  final Set<String> ownedMarketIds;

  /// Suggestion ids the user has accepted.
  final Set<String> acceptedSuggestionIds;

  /// Active Market tab.
  final MarketTab marketTab;

  /// One-line toast; auto-clears after 3.2 s.
  final String? flash;

  /// True while the "Reading the hive…" report is regenerating.
  final bool generatingReport;

  /// How many times the report has been regenerated.
  final int reportRun;

  /// Connected banks: chase, ally, amex.
  final Map<String, bool> banks;

  /// Nudge settings: morning, drift, streakVisible.
  final Map<String, bool> nudgeSettings;

  /// Report cadence, e.g. 'Monthly'.
  final String reportCadence;

  /// Hive-mate ids the user has nudged.
  final Set<String> nudgedFriends;

  /// Number of friends invited.
  final int invites;

  /// The selected bee-skin id (see `lib/data/bee_skins.dart`).
  final String beeSkinId;

  /// True once the first-run onboarding (survey + Chase) has been completed.
  final bool onboarded;

  /// Sentinel so [copyWith] can distinguish "not provided" from "set to null".
  static const Object _unset = Object();

  HiveState copyWith({
    Object? sheet = _unset,
    String? potLayer,
    int? honey,
    int? level,
    double? income,
    double? expense,
    List<Task>? tasks,
    Set<String>? ownedMarketIds,
    Set<String>? acceptedSuggestionIds,
    MarketTab? marketTab,
    Object? flash = _unset,
    bool? generatingReport,
    int? reportRun,
    Map<String, bool>? banks,
    Map<String, bool>? nudgeSettings,
    String? reportCadence,
    Set<String>? nudgedFriends,
    int? invites,
    String? beeSkinId,
    bool? onboarded,
  }) {
    return HiveState(
      sheet: identical(sheet, _unset) ? this.sheet : sheet as SheetKind?,
      potLayer: potLayer ?? this.potLayer,
      honey: honey ?? this.honey,
      level: level ?? this.level,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      tasks: tasks ?? this.tasks,
      ownedMarketIds: ownedMarketIds ?? this.ownedMarketIds,
      acceptedSuggestionIds: acceptedSuggestionIds ?? this.acceptedSuggestionIds,
      marketTab: marketTab ?? this.marketTab,
      flash: identical(flash, _unset) ? this.flash : flash as String?,
      generatingReport: generatingReport ?? this.generatingReport,
      reportRun: reportRun ?? this.reportRun,
      banks: banks ?? this.banks,
      nudgeSettings: nudgeSettings ?? this.nudgeSettings,
      reportCadence: reportCadence ?? this.reportCadence,
      nudgedFriends: nudgedFriends ?? this.nudgedFriends,
      invites: invites ?? this.invites,
      beeSkinId: beeSkinId ?? this.beeSkinId,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}

/// All app state mutations.
class HiveNotifier extends Notifier<HiveState> {
  /// Tracks whether this notifier is still live; guards delayed callbacks
  /// (riverpod 2.x has no public `Ref.mounted`).
  bool _mounted = true;

  @override
  HiveState build() {
    ref.onDispose(() => _mounted = false);
    return HiveState(tasks: List.of(kInitialTasks));
  }

  /// Flips a task's [Task.done] flag, crediting/debiting its reward.
  void toggleTask(String id) {
    final Task task = state.tasks.firstWhere((Task t) => t.id == id);
    final bool nowDone = !task.done;
    state = state.copyWith(
      tasks: state.tasks
          .map((Task t) => t.id == id ? t.copyWith(done: nowDone) : t)
          .toList(),
      honey: state.honey + (nowDone ? task.reward : -task.reward),
    );
  }

  void openSheet(SheetKind kind) => state = state.copyWith(sheet: kind);

  void closeSheet() => state = state.copyWith(sheet: null);

  void selectPotLayer(String id) => state = state.copyWith(potLayer: id);

  /// Buys a market item (honey or real-money), or starts a dream.
  void buyItem(String id) {
    final MarketItem? item = _findItem(id);
    if (item == null || state.ownedMarketIds.contains(id)) {
      return;
    }

    final int? honeyCost = item.honeyCost;
    if (honeyCost != null) {
      if (state.honey >= honeyCost) {
        state = state.copyWith(
          honey: state.honey - honeyCost,
          ownedMarketIds: {...state.ownedMarketIds, id},
          beeSkinId: item.beeSkinId ?? state.beeSkinId,
          flash: 'Unlocked. \u2212$honeyCost honey.',
        );
      } else {
        final int short = honeyCost - state.honey;
        state = state.copyWith(
          flash: 'Not enough honey \u2014 $short short. Check in, or buy a jar.',
        );
      }
      _clearFlashAfter();
      return;
    }

    if (item.moneyCost != null) {
      final int gained = _honeyFromMoneyId(id);
      state = state.copyWith(
        honey: state.honey + gained,
        ownedMarketIds: {...state.ownedMarketIds, id},
        flash:
            '\$${item.moneyCost} charged \u00b7 +${_withCommas(gained)} honey in the pot.',
      );
      _clearFlashAfter();
    }
  }

  /// Starts a dream (free): marks it owned.
  void startDream(String id) {
    final MarketItem? item = _findItem(id);
    if (item == null) {
      return;
    }
    state = state.copyWith(
      ownedMarketIds: {...state.ownedMarketIds, id},
      flash: '"${item.title}" started \u2014 its check-ins begin tomorrow.',
    );
  }

  /// Accepts a suggestion: records it and appends its task to today's list.
  void acceptSuggestion(Suggestion suggestion) {
    if (state.acceptedSuggestionIds.contains(suggestion.id)) {
      return;
    }
    state = state.copyWith(
      acceptedSuggestionIds: {...state.acceptedSuggestionIds, suggestion.id},
      tasks: [
        ...state.tasks,
        Task(
          id: 'sug-${suggestion.id}',
          title: suggestion.taskTitle,
          sub: suggestion.taskSub,
          reward: suggestion.taskReward,
        ),
      ],
    );
  }

  /// Regenerates the report: 2 s "Reading the hive…" then refreshed meta.
  void regenerateReport() {
    state = state.copyWith(generatingReport: true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (_mounted) {
        state = state.copyWith(
          generatingReport: false,
          reportRun: state.reportRun + 1,
        );
      }
    });
  }

  void toggleBank(String key) {
    state = state.copyWith(
      banks: {...state.banks, key: !(state.banks[key] ?? false)},
    );
  }

  void setCadence(String cadence) =>
      state = state.copyWith(reportCadence: cadence);

  void toggleNudge(String key) {
    state = state.copyWith(
      nudgeSettings: {...state.nudgeSettings, key: !(state.nudgeSettings[key] ?? false)},
    );
  }

  void nudgeFriend(String id) {
    state = state.copyWith(nudgedFriends: {...state.nudgedFriends, id});
  }

  void inviteFriend() {
    state = state.copyWith(honey: state.honey + 100, invites: state.invites + 1);
  }

  void setMarketTab(MarketTab tab) => state = state.copyWith(marketTab: tab);

  /// Marks the first-run onboarding complete.
  void completeOnboarding() => state = state.copyWith(onboarded: true);

  /// Re-applies an owned bee skin (its Market item's [MarketItem.beeSkinId]).
  void activateSkin(String marketId) {
    final MarketItem? item = _findItem(marketId);
    final String? skinId = item?.beeSkinId;
    if (item == null ||
        skinId == null ||
        !state.ownedMarketIds.contains(marketId)) {
      return;
    }
    state = state.copyWith(
      beeSkinId: skinId,
      flash: '"${item.title}" applied \u2014 the swarm is flying it now.',
    );
    _clearFlashAfter();
  }

  /// Links a bank (mock Chase sign-in and the settings toggle both use this).
  void linkBank(String key) {
    state = state.copyWith(banks: {...state.banks, key: true});
  }

  /// Credits the honey balance (mock survey completion).
  void addHoney(int amount) =>
      state = state.copyWith(honey: state.honey + amount);

  MarketItem? _findItem(String id) {
    for (final MarketItem item in kMarketCatalog) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// Honey credited by each real-money jar. Pro activates nothing else for now.
  int _honeyFromMoneyId(String id) {
    switch (id) {
      case 'small-jar':
        return 500;
      case 'full-jar':
        return 1500;
      case 'cellar-jar':
        return 4000;
      default:
        return 0;
    }
  }

  /// Clears the flash toast after 3.2 s, guarded by the notifier still live.
  void _clearFlashAfter() {
    Future<void>.delayed(const Duration(milliseconds: 3200), () {
      if (_mounted) {
        state = state.copyWith(flash: null);
      }
    });
  }

  /// "1500" -> "1,500".
  String _withCommas(int value) {
    final String digits = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        out.write(',');
      }
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// The single source of truth for app state.
final hiveStateProvider = NotifierProvider<HiveNotifier, HiveState>(HiveNotifier.new);
