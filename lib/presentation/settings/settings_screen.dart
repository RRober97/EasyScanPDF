import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants/limits.dart';
import '../../routes/app_routes.dart';
import '../../services/subscription_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Plan actual', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subscription.isPro ? 'Pro' : 'Normal',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subscription.isPro
                ? 'Páginas ilimitadas y hasta ${Limits.proMaxSavedPdfs} documentos recientes.'
                : 'Hasta ${Limits.normalMaxPagesPerPdf} páginas por PDF y ${Limits.normalMaxSavedPdfs} documentos recientes.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              final upgraded = await Navigator.pushNamed<bool>(
                context,
                AppRoutes.paywall,
              );
              if (upgraded == true) {
                Fluttertoast.showToast(msg: 'Suscripción actualizada');
              }
            },
            child: const Text('Ir a Pro'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              try {
                await ref
                    .read(subscriptionProvider.notifier)
                    .restorePurchases();
                Fluttertoast.showToast(msg: 'Compras restauradas');
              } on SubscriptionPurchaseException catch (error) {
                Fluttertoast.showToast(msg: error.message);
              } catch (error) {
                Fluttertoast.showToast(
                  msg: 'No se pudieron restaurar las compras: $error',
                );
              }
            },
            child: const Text('Restaurar compras'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Política de privacidad'),
            subtitle: const Text('Consulta cómo tratamos tus datos.'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Política de privacidad'),
                  content: const Text(
                      'Este es un stub de política de privacidad para fines de demostración.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
