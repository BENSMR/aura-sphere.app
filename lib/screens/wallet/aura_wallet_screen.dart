import 'package:flutter/material.dart';
import '../../services/tokens/aura_token_service.dart';
import '../../components/animated_number.dart';
import '../../components/token_floating_text.dart';

class AuraWalletScreen extends StatefulWidget {
  const AuraWalletScreen({super.key});
  
  @override
  State<AuraWalletScreen> createState() => _AuraWalletScreenState();
}

class _AuraWalletScreenState extends State<AuraWalletScreen> {
  int _tokenBalance = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  
  int _floatingAddAmount = 0;
  bool _showFloatingText = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    
    try {
      // Replace with actual user ID from auth
      const userId = 'TARGET_USER_UID';
      
      final balance = await AuraTokenService.getTokenBalance(userId);
      final history = await AuraTokenService.getTokenHistory(userId);
      
      setState(() {
        _tokenBalance = balance;
        _transactions = history;
      });
    } catch (e) {
      print('Error loading wallet data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _awardWelcomeBonus() async {
    setState(() => _isLoading = true);
    
    try {
      const userId = 'TARGET_USER_UID';
      
      // Award welcome bonus and verify
      await AuraTokenService.rewardWelcomeBonus(userId);
      await AuraTokenService.printTokenVerification(userId);
      
      // Reload wallet data
      await _loadWalletData();
      
      // Show floating text animation
      final newBalance = await AuraTokenService.getTokenBalance(userId);
      _onTokensAdded(newBalance - _tokenBalance);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome bonus awarded!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  void _onTokensAdded(int amount) {
    setState(() {
      _floatingAddAmount = amount;
      _showFloatingText = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFloatingText = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aura Wallet')),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'AuraToken Balance',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AnimatedNumber(
                            value: _tokenBalance,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Test Button
                  ElevatedButton(
                    onPressed: _awardWelcomeBonus,
                    child: const Text('Award Welcome Bonus (Test)'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Transaction History
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: _transactions.isEmpty
                        ? const Center(child: Text('No transactions yet'))
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return ListTile(
                                title: Text(transaction['action'] ?? 'Unknown'),
                                subtitle: Text(transaction['createdAt']?.toString() ?? ''),
                                trailing: Text(
                                  '+${transaction['amount']}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          // Floating text overlay
          if (_showFloatingText)
            Center(
              child: TokenFloatingText(
                amount: _floatingAddAmount,
                onFinish: () {
                  setState(() => _showFloatingText = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}