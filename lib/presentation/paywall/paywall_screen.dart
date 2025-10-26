import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants/limits.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final isProcessing = subscription.purchasePending ||
        (subscription.isLoading && subscription.proPlanPrice == null);
    final theme = Theme.of(context);

    ref.listen<SubscriptionState>(subscriptionProvider,
        (previous, next) async {
      final wasPro = previous?.isPro ?? false;
      if (!wasPro && next.isPro) {
        Fluttertoast.showToast(msg: '¡Bienvenido a Pro!');
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }

      final previousError = previous?.errorMessage;
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty &&
          next.errorMessage != previousError) {
        Fluttertoast.showToast(msg: next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Desbloquea Pro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desbloquea páginas ilimitadas y 20 documentos recientes — 2,99 €/mes (IVA incl.).',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            _PlanTile(
              title: 'Plan Normal',
              description:
                  'Hasta ${Limits.normalMaxPagesPerPdf} páginas por PDF y ${Limits.normalMaxSavedPdfs} documentos recientes.',
              price: PricingText.normal,
              selected: !subscription.isPro,
            ),
            const SizedBox(height: 16),
            _PlanTile(
              title: 'Plan Pro',
              description:
                  'Páginas ilimitadas por PDF y hasta ${Limits.proMaxSavedPdfs} documentos recientes.',
              price: subscription.proPlanPrice ?? PricingText.pro,
              selected: subscription.isPro,
              isLoading: subscription.isLoading && subscription.proPlanPrice == null,
            ),
            if (!subscription.isStoreAvailable && !subscription.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No pudimos conectar con la tienda. Puedes volver a intentarlo más tarde o usar el pago con tarjeta.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(subscriptionProvider.notifier)
                            .purchaseProMonthly();
                      } on SubscriptionPurchaseException catch (error) {
                        Fluttertoast.showToast(msg: error.message);
                      } catch (error) {
                        Fluttertoast.showToast(
                          msg: 'No se pudo iniciar el pago: $error',
                        );
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Probar Pro'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Más tarde'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    this.isLoading = false,
  });

  final String title;
  final String description;
  final String? price;
  final bool selected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cargando precio...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          else
            Text(price ?? '—', style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
