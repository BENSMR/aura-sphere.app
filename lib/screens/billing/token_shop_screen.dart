import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Token pack model (mirrors server TOKEN_PACKS)
class TokenPack {
  final String id;
  final String title;
  final int tokens;
  final int priceCents;
  final String currency;
  final String description;

  TokenPack({
    required this.id,
    required this.title,
    required this.tokens,
    required this.priceCents,
    required this.currency,
    required this.description,
  });
}

class TokenShopScreen extends StatefulWidget {
  const TokenShopScreen({Key? key}) : super(key: key);

  @override
  State<TokenShopScreen> createState() => _TokenShopScreenState();
}

class _TokenShopScreenState extends State<TokenShopScreen> {
  final _paymentSvc = PaymentService();
  bool _loading = false;

  final List<TokenPack> packs = [
    TokenPack(
      id: 'pack_small',
      title: 'Starter Pack',
      tokens: 200,
      priceCents: 500,
      currency: 'usd',
      description: '200 AuraTokens — great to try AI features',
    ),
    TokenPack(
      id: 'pack_medium',
      title: 'Growth Pack',
      tokens: 600,
      priceCents: 1200,
      currency: 'usd',
      description: '600 AuraTokens — best value',
    ),
    TokenPack(
      id: 'pack_large',
      title: 'Pro Pack',
      tokens: 1600,
      priceCents: 2500,
      currency: 'usd',
      description: '1600 AuraTokens — heavy user pack',
    ),
  ];

  Future<void> _purchasePack(TokenPack pack) async {
    setState(() => _loading = true);

    final baseUrl = 'https://aurasphere-pro.web.app';
    final successUrl = '$baseUrl/billing/success';
    final cancelUrl = '$baseUrl/billing/cancel';

    final session = await _paymentSvc.createTokenCheckoutSession(
      packId: pack.id,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (session?['url'] != null) {
      final checkoutUrl = session!['url'] as String;
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open checkout: ${checkoutUrl.substring(0, 50)}...')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create checkout session')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AuraToken Shop'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Unlock AI Features',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use AuraTokens to access premium AI coaching and analysis',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...packs.map((pack) => _buildPackCard(pack)).toList(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 How AuraTokens work',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Free users spend 5 tokens per AI coaching session\n'
                          '• Pro+ subscribers get unlimited AI access (no tokens needed)\n'
                          '• Tokens never expire\n'
                          '• Unused tokens roll over each month',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackCard(TokenPack pack) {
    final priceUsd = pack.priceCents / 100;
    final costPerToken = priceUsd / pack.tokens;
    final isBestValue = pack.id == 'pack_medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pack.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Best Value',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pack.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${priceUsd.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${costPerToken.toStringAsFixed(3)}/token',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _purchasePack(pack),
                  child: Text('Buy ${pack.tokens} Tokens'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
