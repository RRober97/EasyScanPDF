import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionState {
  const SubscriptionState({required this.isPro, this.lastPurchase});

  final bool isPro;
  final DateTime? lastPurchase;

  SubscriptionState copyWith({bool? isPro, DateTime? lastPurchase}) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      lastPurchase: lastPurchase ?? this.lastPurchase,
    );
  }
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController()
      : super(const SubscriptionState(isPro: false, lastPurchase: null));

  Future<void> purchaseProMonthly() async {
    state = state.copyWith(isPro: true, lastPurchase: DateTime.now());
  }

  Future<void> restorePurchases() async {
    if (state.lastPurchase != null) {
      state = state.copyWith(isPro: true);
    }
  }

  Future<void> downgradeToNormal() async {
    state = state.copyWith(isPro: false);
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
  return SubscriptionController();
});
