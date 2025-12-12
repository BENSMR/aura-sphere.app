import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

/// Premium glassmorphic confirmation dialog for AI actions.
/// Usage: await showDialog<bool>(
///   context: context,
///   builder: (_) => AICostConfirmationDialog(cost: 5, balance: 12, plan: 'free'),
/// );
class AICostConfirmationDialog extends StatelessWidget {
  final int cost;
  final int balance;
  final String plan;
  final String title;

  const AICostConfirmationDialog({
    super.key,
    required this.cost,
    required this.balance,
    required this.plan,
    this.title = 'Use AI Finance Coach?',
  });

  @override
  Widget build(BuildContext context) {
    final canProceed = plan != 'free' || balance >= cost;
    final isFreePlan = plan == 'free';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x0Fffffff), Color(0x05ffffff)],
            ),
            border: Border.all(color: const Color(0x14ffffff)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('AI Narrative cost:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _AuraTokenChip(cost.toString()),
                        const SizedBox(width: 12),
                        Text('(AuraTokens)', style: TextStyle(color: Colors.white60)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Your plan: $plan', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('Balance: $balance AuraTokens', style: const TextStyle(color: Colors.white)),
                    if (isFreePlan && !canProceed) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Insufficient tokens — upgrade to Pro or earn tokens to use AI.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: canProceed ? () => Navigator.of(context).pop(true) : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: canProceed ? Colors.blueAccent : Colors.grey,
                          ),
                          child: Text(
                            isFreePlan
                                ? 'Spend $cost tokens'
                                : 'Proceed (Free for ${plan.capitalize()})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _AuraTokenChip extends StatelessWidget {
  final String text;

  const _AuraTokenChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x0Fffffff),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x3Dffffff)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.whatshot, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
