import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionState {
  const SubscriptionState({
    required this.isPro,
    this.lastPurchase,
    required this.isStoreAvailable,
    required this.isLoading,
    required this.purchasePending,
    this.errorMessage,
    this.proPlanPrice,
  });

  static const Object _noValue = Object();

  final bool isPro;
  final DateTime? lastPurchase;
  final bool isStoreAvailable;
  final bool isLoading;
  final bool purchasePending;
  final String? errorMessage;
  final String? proPlanPrice;

  SubscriptionState copyWith({
    bool? isPro,
    DateTime? lastPurchase,
    bool? isStoreAvailable,
    bool? isLoading,
    bool? purchasePending,
    Object? errorMessage = _noValue,
    String? proPlanPrice,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      isLoading: isLoading ?? this.isLoading,
      purchasePending: purchasePending ?? this.purchasePending,
      errorMessage: identical(errorMessage, _noValue)
          ? this.errorMessage
          : errorMessage as String?,
      proPlanPrice: proPlanPrice ?? this.proPlanPrice,
    );
  }
}

class SubscriptionPurchaseException implements Exception {
  const SubscriptionPurchaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController({
    InAppPurchase? inAppPurchase,
    Stream<List<PurchaseDetails>>? purchaseStream,
  })  : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        _purchaseStream =
            purchaseStream ?? InAppPurchase.instance.purchaseStream,
        super(const SubscriptionState(
          isPro: false,
          lastPurchase: null,
          isStoreAvailable: false,
          isLoading: true,
          purchasePending: false,
          errorMessage: null,
          proPlanPrice: null,
        )) {
    _initialize();
  }

  static const String _androidProductId = 'pro_monthly_android';
  static const String _iosProductId = 'pro_monthly_ios';
  static const String _cardCheckoutUrl =
      'https://easyscanpdf.app/pago/pro'; // Placeholder checkout URL.

  final InAppPurchase _inAppPurchase;
  final Stream<List<PurchaseDetails>> _purchaseStream;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _activeProduct;
  bool _hasLoadedProducts = false;

  void _initialize() {
    _purchaseSubscription = _purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        state = state.copyWith(
          errorMessage: 'Error del servicio de pagos: $error',
          purchasePending: false,
        );
      },
    );
    Future.microtask(_loadProducts);
  }

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String _resolveProductId() {
    if (_isIOS) {
      return _iosProductId;
    }
    return _androidProductId;
  }

  Future<void> _loadProducts() async {
    if (_hasLoadedProducts) {
      return;
    }
    _hasLoadedProducts = true;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final available = await _inAppPurchase.isAvailable();
      state = state.copyWith(isStoreAvailable: available);
      if (!available) {
        _hasLoadedProducts = false;
        state = state.copyWith(isLoading: false);
        return;
      }
      final response = await _inAppPurchase
          .queryProductDetails({_resolveProductId()});
      if (response.error != null) {
        _hasLoadedProducts = false;
        state = state.copyWith(
          errorMessage: response.error!.message,
          isLoading: false,
        );
        return;
      }
      if (response.productDetails.isEmpty) {
        _hasLoadedProducts = false;
        state = state.copyWith(
          errorMessage:
              'El producto de suscripción no está disponible actualmente.',
          isLoading: false,
        );
        return;
      }
      _activeProduct = response.productDetails.first;
      state = state.copyWith(
        proPlanPrice: _activeProduct?.price,
        isLoading: false,
      );
    } catch (error) {
      _hasLoadedProducts = false;
      state = state.copyWith(
        errorMessage: 'No se pudo cargar la información de suscripción.',
        isLoading: false,
      );
    }
  }

  Future<void> purchaseProMonthly() async {
    state = state.copyWith(errorMessage: null);

    if (kIsWeb || (!_isAndroid && !_isIOS)) {
      await _launchCardCheckout();
      return;
    }

    await _ensureProductsLoaded();
    final product = _activeProduct;
    if (product == null) {
      throw const SubscriptionPurchaseException(
        'No se encontró el producto de suscripción Pro.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    state = state.copyWith(purchasePending: true);
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!started) {
      state = state.copyWith(purchasePending: false);
      throw const SubscriptionPurchaseException(
        'No se pudo iniciar el proceso de pago.',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(errorMessage: null);

    if (kIsWeb || (!_isAndroid && !_isIOS)) {
      throw const SubscriptionPurchaseException(
        'La restauración de compras solo está disponible en la App Store y Google Play.',
      );
    }

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw const SubscriptionPurchaseException(
        'No hay conexión con la tienda para restaurar compras.',
      );
    }

    await _inAppPurchase.restorePurchases();
  }

  Future<void> downgradeToNormal() async {
    state = state.copyWith(isPro: false);
  }

  Future<void> _ensureProductsLoaded() async {
    if (!_hasLoadedProducts || _activeProduct == null) {
      _hasLoadedProducts = false;
      await _loadProducts();
    }
  }

  Future<void> _launchCardCheckout() async {
    final uri = Uri.parse(_cardCheckoutUrl);
    if (!await canLaunchUrl(uri)) {
      throw const SubscriptionPurchaseException(
        'No se pudo abrir la página de pago con tarjeta.',
      );
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const SubscriptionPurchaseException(
        'No se pudo abrir la página de pago con tarjeta.',
      );
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          state = state.copyWith(
            isPro: true,
            lastPurchase: DateTime.now(),
            purchasePending: false,
            errorMessage: null,
          );
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
          state = state.copyWith(purchasePending: true);
          break;
        case PurchaseStatus.error:
          state = state.copyWith(
            purchasePending: false,
            errorMessage: purchase.error?.message ??
                'Ocurrió un error durante la compra.',
          );
          break;
        default:
          state = state.copyWith(purchasePending: false);
          break;
      }
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
  return SubscriptionController();
});
