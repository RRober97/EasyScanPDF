import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants/limits.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
              selected: !ref.watch(subscriptionProvider).isPro,
            ),
            const SizedBox(height: 16),
            _PlanTile(
              title: 'Plan Pro',
              description:
                  'Páginas ilimitadas por PDF y hasta ${Limits.proMaxSavedPdfs} documentos recientes.',
              price: PricingText.pro,
              selected: ref.watch(subscriptionProvider).isPro,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(subscriptionProvider.notifier)
                    .purchaseProMonthly();
                Fluttertoast.showToast(msg: '¡Bienvenido a Pro!');
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Probar Pro'),
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
  });

  final String title;
  final String description;
  final String price;
  final bool selected;

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
          Text(price, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
