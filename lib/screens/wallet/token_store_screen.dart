import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../../services/wallet_service.dart';
import '../../components/animated_number.dart';

class TokenStoreScreen extends StatelessWidget {
  final PaymentService _paymentService = PaymentService();
  final WalletService _walletService = WalletService();

  static const List<Map<String, dynamic>> _packs = [
    {'id': 'pack_small', 'title': 'Starter Pack', 'tokens': 200, 'price': '\$5'},
    {'id': 'pack_medium', 'title': 'Growth Pack', 'tokens': 600, 'price': '\$12'},
    {'id': 'pack_large', 'title': 'Pro Pack', 'tokens': 1600, 'price': '\$25'},
  ];

  const TokenStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy AuraTokens')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            StreamBuilder<int>(
              stream: _walletService.streamBalance(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AuraTokens Balance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedNumber(
                              value: balance,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _walletService.refresh,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _packs.length,
                itemBuilder: (context, index) {
                  final pack = _packs[index];
                  return Card(
                    child: ListTile(
                      title: Text(pack['title'] as String),
                      subtitle: Text('${pack['tokens']} tokens • ${pack['price']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _buyPack(context, pack['id'] as String),
                        child: const Text('Buy'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyPack(BuildContext context, String packId) async {
    const successUrl = 'https://aurasphere-pro.web.app/billing/success';
    const cancelUrl = 'https://aurasphere-pro.web.app/billing/cancel';

    final session = await _paymentService.createTokenCheckoutSession(
      packId: packId,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
    );

    if (session?['url'] == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start payment')),
        );
      }
      return;
    }

    final uri = Uri.parse(session!['url'] as String);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page')),
        );
      }
    }
  }
}
