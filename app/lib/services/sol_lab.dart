class SolLab {
  int credits = 12580;
  int gold = 0;
  int diamonds = 0;
  final List<String> ledger = [];

  bool spend(int amount, String reason) {
    if (amount <= 0 || credits < amount) return false;
    final before = credits;
    credits -= amount;
    ledger.insert(0, '$reason | -$amount | $before -> $credits');
    return true;
  }

  void reward(int amount, String reason) {
    if (amount <= 0) return;
    final before = credits;
    credits += amount;
    ledger.insert(0, '$reason | +$amount | $before -> $credits');
  }
}

final solLab = SolLab();

