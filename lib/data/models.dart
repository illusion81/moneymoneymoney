import '../data/money_style_questions.dart';
import '../models/money_style.dart';

// Dart mirrors of the backend contract (docs/API.md).
// Field names match the JSON exactly — if you rename one here, it breaks.
// Owner: Lane A (data). Talk to Mike before changing a field.

class Allocation {
  final double invest, stable, living, reward;
  const Allocation({
    required this.invest,
    required this.stable,
    required this.living,
    required this.reward,
  });

  factory Allocation.fromJson(Map<String, dynamic> j) => Allocation(
        invest: (j['invest'] as num).toDouble(),
        stable: (j['stable'] as num).toDouble(),
        living: (j['living'] as num).toDouble(),
        reward: (j['reward'] as num).toDouble(),
      );
}

class Profile {
  final String userId, archetype, archetypeBlurb;
  final Allocation allocation;
  final double monthlyIncome, discretionary;
  final String? guardrailNote;

  const Profile({
    required this.userId,
    required this.archetype,
    required this.archetypeBlurb,
    required this.allocation,
    required this.monthlyIncome,
    required this.discretionary,
    this.guardrailNote,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userId: j['user_id'] as String,
        archetype: j['archetype'] as String,
        archetypeBlurb: j['archetype_blurb'] as String,
        allocation: Allocation.fromJson(j['allocation'] as Map<String, dynamic>),
        monthlyIncome: (j['monthly_income'] as num).toDouble(),
        discretionary: (j['discretionary'] as num).toDouble(),
        guardrailNote: j['guardrail_note'] as String?,
      );
}

class SurveyAnswers {
  final double monthlyIncome, fixedCosts;
  final int riskAppetite, horizonMonths;
  final bool hasEmergencyFund;
  final String topWorry; // subscriptions | food | impulse | rent | none

  const SurveyAnswers({
    required this.monthlyIncome,
    required this.fixedCosts,
    required this.riskAppetite,
    required this.horizonMonths,
    required this.hasEmergencyFund,
    required this.topWorry,
  });

  Map<String, dynamic> toJson() => {
        'monthly_income': monthlyIncome,
        'fixed_costs': fixedCosts,
        'risk_appetite': riskAppetite,
        'horizon_months': horizonMonths,
        'has_emergency_fund': hasEmergencyFund,
        'top_worry': topWorry,
      };
}

class MoneyStyleSubmission {
  const MoneyStyleSubmission({required this.sessionId, required this.questionVersion, required this.selectedAnswers, required this.skippedQuestionIds, required this.answeredCount, this.confidenceTier, this.archetypeId});
  final String sessionId, questionVersion;
  final Map<String, String> selectedAnswers;
  final List<int> skippedQuestionIds;
  final int answeredCount;
  final String? confidenceTier, archetypeId;
  Map<String, dynamic> toJson() => {'session_id': sessionId, 'question_version': questionVersion, 'selected_answers': selectedAnswers, 'skipped_question_ids': skippedQuestionIds, 'answered_count': answeredCount, 'confidence_tier': confidenceTier, 'archetype_id': archetypeId};
  factory MoneyStyleSubmission.fromJson(Map<String, dynamic> j) => MoneyStyleSubmission(sessionId: j['session_id'] as String, questionVersion: j['question_version'] as String, selectedAnswers: (j['selected_answers'] as Map).map((k,v) => MapEntry('$k','$v')), skippedQuestionIds: (j['skipped_question_ids'] as List).cast<int>(), answeredCount: j['answered_count'] as int, confidenceTier: j['confidence_tier'] as String?, archetypeId: j['archetype_id'] as String?);

  factory MoneyStyleSubmission.fromCompletion(MoneyStyleCompletion completion) {
    final result = completion.result;
    final tier = switch (result?.confidenceTier) {
      ConfidenceTier.earlySnapshot => 'early_snapshot',
      ConfidenceTier.standard => 'standard',
      ConfidenceTier.fullClarity => 'full_clarity',
      null => null,
    };
    final archetype = switch (result?.archetype.pattern) {
      'Steady Pause Self-Directed' => 'steady_pause_self',
      'Steady Pause Collaborative' => 'steady_pause_collaborative',
      'Steady Momentum Self-Directed' => 'steady_momentum_self',
      'Steady Momentum Collaborative' => 'steady_momentum_collaborative',
      'Responsive Pause Self-Directed' => 'responsive_pause_self',
      'Responsive Pause Collaborative' => 'responsive_pause_collaborative',
      'Responsive Momentum Self-Directed' => 'responsive_momentum_self',
      'Responsive Momentum Collaborative' => 'responsive_momentum_collaborative',
      _ => null,
    };
    return MoneyStyleSubmission(sessionId: completion.session.sessionId, questionVersion: 'money-style-v1', selectedAnswers: completion.session.answerIdsFor(moneyStyleQuestions), skippedQuestionIds: completion.session.skippedQuestions.toList(), answeredCount: completion.session.totalAnswered, confidenceTier: tier, archetypeId: archetype);
  }
}

class Account {
  final String id, name, kind, currency;
  final double balance;
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.currency,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String,
        balance: (j['balance'] as num).toDouble(),
        currency: (j['currency'] ?? 'AUD') as String,
      );
}

class Txn {
  final String id, accountId, postDate, description, category, bucket;
  final double amount;
  const Txn({
    required this.id,
    required this.accountId,
    required this.postDate,
    required this.description,
    required this.amount,
    required this.category,
    required this.bucket,
  });

  bool get isSpend => amount < 0;

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        accountId: j['account_id'] as String,
        postDate: j['post_date'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        bucket: j['bucket'] as String,
      );
}

class ConnectionStatus {
  final String provider; // basiq | mock
  final bool connected;
  final String? institution, persona;
  /// Open this in a browser to link a bank. Null when already connected.
  final String? consentUrl;
  final String message;

  const ConnectionStatus({
    required this.provider,
    required this.connected,
    this.institution,
    this.persona,
    this.consentUrl,
    required this.message,
  });

  /// True when we're on simulated data. Useful for a small "sandbox" chip in
  /// the UI — be honest on stage rather than getting caught.
  bool get isMock => provider == 'mock';

  factory ConnectionStatus.fromJson(Map<String, dynamic> j) => ConnectionStatus(
        provider: j['provider'] as String,
        connected: j['connected'] as bool,
        institution: j['institution'] as String?,
        persona: j['persona'] as String?,
        consentUrl: j['consent_url'] as String?,
        message: (j['message'] ?? '') as String,
      );
}

class BucketPlan {
  final String bucket;
  final double targetPct, targetAmount, actualAmount, variance;
  final bool onTrack;

  const BucketPlan({
    required this.bucket,
    required this.targetPct,
    required this.targetAmount,
    required this.actualAmount,
    required this.variance,
    required this.onTrack,
  });

  factory BucketPlan.fromJson(Map<String, dynamic> j) => BucketPlan(
        bucket: j['bucket'] as String,
        targetPct: (j['target_pct'] as num).toDouble(),
        targetAmount: (j['target_amount'] as num).toDouble(),
        actualAmount: (j['actual_amount'] as num).toDouble(),
        variance: (j['variance'] as num).toDouble(),
        onTrack: j['on_track'] as bool,
      );
}

class Plan {
  /// True = last known good data; the bank feed is down or consent ended.
  /// Show it, do not blank it out.
  final bool stale;
  final int periodDays;
  final double incomeObserved, adherence;
  final List<BucketPlan> buckets;
  final String headline;

  const Plan({
    this.stale = false,
    required this.periodDays,
    required this.incomeObserved,
    required this.buckets,
    required this.adherence,
    required this.headline,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        stale: j['stale'] as bool? ?? false,
        periodDays: j['period_days'] as int,
        incomeObserved: (j['income_observed'] as num).toDouble(),
        buckets: (j['buckets'] as List)
            .map((b) => BucketPlan.fromJson(b as Map<String, dynamic>))
            .toList(),
        adherence: (j['adherence'] as num).toDouble(),
        headline: j['headline'] as String,
      );
}

class Mission {
  final String id, title, detail, bucket, kind;
  final double target, progress;
  final bool complete, claimed;
  /// True = completion is derived from transaction data.
  /// False = the user asserts it; label it "self-reported" in the UI.
  final bool verified;
  final int xp, coins, expiresInDays;

  const Mission({
    required this.id,
    required this.title,
    required this.detail,
    required this.bucket,
    required this.kind,
    required this.target,
    required this.progress,
    required this.complete,
    required this.claimed,
    required this.verified,
    required this.xp,
    required this.coins,
    required this.expiresInDays,
  });

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        title: j['title'] as String,
        detail: j['detail'] as String,
        bucket: j['bucket'] as String,
        kind: j['kind'] as String,
        target: (j['target'] as num).toDouble(),
        progress: (j['progress'] as num).toDouble(),
        complete: j['complete'] as bool,
        claimed: j['claimed'] as bool,
        verified: j['verified'] as bool? ?? true,
        xp: j['xp'] as int,
        coins: j['coins'] as int,
        expiresInDays: j['expires_in_days'] as int,
      );
}

class Progression {
  final int xp, level, xpIntoLevel, xpForNextLevel, coins, streakDays;
  final List<String> unlockedSkins;
  final String activeSkin;

  const Progression({
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.coins,
    required this.streakDays,
    required this.unlockedSkins,
    required this.activeSkin,
  });

  double get levelProgress =>
      xpForNextLevel == 0 ? 1.0 : xpIntoLevel / xpForNextLevel;

  factory Progression.fromJson(Map<String, dynamic> j) => Progression(
        xp: j['xp'] as int,
        level: j['level'] as int,
        xpIntoLevel: j['xp_into_level'] as int,
        xpForNextLevel: j['xp_for_next_level'] as int,
        coins: j['coins'] as int,
        streakDays: j['streak_days'] as int,
        unlockedSkins: (j['unlocked_skins'] as List).cast<String>(),
        activeSkin: j['active_skin'] as String,
      );
}

class ClaimResult {
  final String missionId;
  final int xpAwarded, coinsAwarded;
  final bool levelledUp;
  final Progression progression;

  const ClaimResult({
    required this.missionId,
    required this.xpAwarded,
    required this.coinsAwarded,
    required this.levelledUp,
    required this.progression,
  });

  factory ClaimResult.fromJson(Map<String, dynamic> j) => ClaimResult(
        missionId: j['mission_id'] as String,
        xpAwarded: j['xp_awarded'] as int,
        coinsAwarded: j['coins_awarded'] as int,
        levelledUp: j['levelled_up'] as bool,
        progression:
            Progression.fromJson(j['progression'] as Map<String, dynamic>),
      );
}

class TowerFloor {
  final int index;
  final String bucket;
  final double height, health;
  const TowerFloor({
    required this.index,
    required this.bucket,
    required this.height,
    required this.health,
  });

  factory TowerFloor.fromJson(Map<String, dynamic> j) => TowerFloor(
        index: j['index'] as int,
        bucket: j['bucket'] as String,
        height: (j['height'] as num).toDouble(),
        health: (j['health'] as num).toDouble(),
      );
}

class TowerState {
  /// True = frozen at the last sync because bank access ended.
  /// The tower is never erased — show it with a "reconnect" prompt.
  final bool stale;
  final int stage;
  final List<TowerFloor> floors;
  final double health;
  final String weather; // clear | overcast | storm
  final String caption;

  const TowerState({
    this.stale = false,
    required this.stage,
    required this.floors,
    required this.health,
    required this.weather,
    required this.caption,
  });

  factory TowerState.fromJson(Map<String, dynamic> j) => TowerState(
        stale: j['stale'] as bool? ?? false,
        stage: j['stage'] as int,
        floors: (j['floors'] as List)
            .map((f) => TowerFloor.fromJson(f as Map<String, dynamic>))
            .toList(),
        health: (j['health'] as num).toDouble(),
        weather: j['weather'] as String,
        caption: j['caption'] as String,
      );
}

class ShopItem {
  final String id, name, kind, description;
  final int cost;
  final bool owned;

  const ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.kind,
    required this.owned,
    required this.description,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
        id: j['id'] as String,
        name: j['name'] as String,
        cost: j['cost'] as int,
        kind: j['kind'] as String,
        owned: j['owned'] as bool,
        description: j['description'] as String,
      );
}
