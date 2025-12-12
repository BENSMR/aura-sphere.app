# Loyalty System - Quick Integration Guide

## 🚀 5-Minute Setup

### 1. Add Provider to app.dart
```dart
// In lib/app/app.dart MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => WalletProvider()),
    ChangeNotifierProvider(create: (_) => LoyaltyProvider()),  // ← Add this
    // ... other providers
  ],
  // ...
)
```

### 2. Initialize Loyalty on Signup
```dart
// In auth/signup flow
final auth = FirebaseAuth.instance;
final user = await auth.createUserWithEmailAndPassword(...);

// Initialize loyalty profile
final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
await loyaltyProvider.initializeUserLoyalty(user.uid);
```

### 3. Process Daily Login on App Start
```dart
// In app.dart bootstrap or splash screen
void _initializeApp() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
    final reward = await loyaltyProvider.processDailyLogin(uid);
    if (reward > 0) {
      // Show notification: "Earned $reward tokens!"
    }
  }
}
```

### 4. Record Payments
```dart
// In payment webhook or success handler
final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
await loyaltyProvider.recordPayment(
  sessionId: paymentSession.id,
  uid: currentUser.uid,
  packId: selectedPack.id,
  tokens: selectedPack.tokens,
);
```

### 5. Initialize Global Config (Admin Only)
```dart
// Run once in Firebase Console or admin dashboard
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeGlobalConfig() async {
  const config = {
    'daily': {'baseReward': 50, 'streakBonus': 10, 'maxStreakBonus': 500},
    'weekly': {'thresholdDays': 7, 'bonus': 500},
    'milestones': [
      {'id': 'bronze', 'name': 'Bronze', 'tokensThreshold': 1000, 'reward': 100},
      {'id': 'silver', 'name': 'Silver', 'tokensThreshold': 5000, 'reward': 500},
      {'id': 'gold', 'name': 'Gold', 'tokensThreshold': 10000, 'reward': 1000},
      {'id': 'platinum', 'name': 'Platinum', 'tokensThreshold': 25000, 'reward': 2500},
      {'id': 'diamond', 'name': 'Diamond', 'tokensThreshold': 50000, 'reward': 5000},
    ],
    'specialDays': [
      {'dateISO': '12-25', 'bonusMultiplier': 2.0, 'name': 'Christmas'},
      {'dateISO': '01-01', 'bonusMultiplier': 1.5, 'name': 'New Year'},
      {'dateISO': '07-04', 'bonusMultiplier': 1.5, 'name': 'Independence Day'},
    ],
  };
  
  await FirebaseFirestore.instance
      .collection('loyalty_config')
      .doc('global')
      .set(config);
}
```

---

## 📺 UI Components (Examples)

### Loyalty Dashboard Widget
```dart
Widget buildLoyaltyDashboard(BuildContext context) {
  return Consumer<LoyaltyProvider>(
    builder: (context, provider, _) {
      final loyalty = provider.userLoyalty;
      if (loyalty == null) return const SizedBox();
      
      return Column(
        children: [
          // Streak display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('${loyalty.streak.current} day streak'),
                ],
              ),
            ),
          ),
          
          // Daily bonus eligible?
          if (provider.isLoading)
            const CircularProgressIndicator()
          else if (loyalty.lastBonus == null || 
                   DateTime.now().difference(loyalty.lastBonus!).inHours > 24)
            ElevatedButton(
              onPressed: () async {
                final reward = await provider.processDailyLogin(loyalty.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎉 Earned $reward tokens!')),
                );
              },
              child: const Text('Claim Daily Bonus'),
            ),
          
          // Lifetime totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Earned: ${loyalty.totals.lifetimeEarned}'),
              Text('Spent: ${loyalty.totals.lifetimeSpent}'),
              Text('Badges: ${loyalty.badges.length}'),
            ],
          ),
        ],
      );
    },
  );
}
```

### Milestone Progress Widget
```dart
Widget buildMilestoneProgress(BuildContext context) {
  return Consumer<LoyaltyProvider>(
    builder: (context, provider, _) {
      final nextMilestone = provider.getNextMilestone();
      final progress = provider.getProgressToNextMilestone();
      
      if (nextMilestone == null) {
        return const Text('🏆 You are Diamond member!');
      }
      
      return Column(
        children: [
          Text('${nextMilestone.name} - $${nextMilestone.tokensThreshold}'),
          LinearProgressIndicator(value: progress / 100),
          Text('$progress% complete'),
        ],
      );
    },
  );
}
```

### Badge Showcase
```dart
Widget buildBadges(BuildContext context) {
  return Consumer<LoyaltyProvider>(
    builder: (context, provider, _) {
      final badges = provider.userLoyalty?.badges ?? [];
      
      return Wrap(
        children: badges.map((badge) {
          return Chip(
            label: Text(badge.name),
            avatar: CircleAvatar(child: Text('${badge.level}')),
          );
        }).toList(),
      );
    },
  );
}
```

### Audit History
```dart
Widget buildAuditHistory(BuildContext context) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  return Consumer<LoyaltyProvider>(
    builder: (context, provider, _) {
      return FutureBuilder(
        future: Future.value(provider.auditLogs.isEmpty
            ? provider.fetchTokenAuditLogs(uid)
            : null),
        builder: (context, snapshot) {
          final logs = provider.auditLogs;
          
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.action),
                subtitle: Text(log.createdAt.toString()),
                trailing: Text('${log.amount > 0 ? '+' : ''}${log.amount}'),
              );
            },
          );
        },
      );
    },
  );
}
```

---

## 🔗 Database Structure

### Firestore Collections
```
firestore/
├── users/
│   └── {uid}/
│       ├── loyalty/
│       │   └── profile  ← UserLoyalty document
│       └── token_audit/
│           ├── txId1    ← TokenAuditEntry
│           ├── txId2
│           └── ...
├── payments_processed/
│   ├── sessionId1  ← PaymentProcessed
│   ├── sessionId2
│   └── ...
└── loyalty_config/
    └── global  ← LoyaltyConfig singleton
```

---

## 🔑 Key Methods Reference

### LoyaltyProvider Methods
```dart
// Initialization
await initializeUserLoyalty(uid)  // Setup on signup

// Operations
final reward = await processDailyLogin(uid)      // Daily bonus
await recordPayment(sessionId, uid, packId, tokens)
await awardBadge(uid, badge)
await checkAndUpdateMilestone(uid, 'gold')
await freezeStreak(uid)

// Queries
await fetchUserLoyalty(uid)
await fetchLoyaltyConfig()
await fetchTokenAuditLogs(uid, limit: 50)

// Streams (real-time)
streamUserLoyalty(uid)
streamLoyaltyConfig()
streamTokenAuditLogs(uid)

// Computed
getNextMilestone()
getProgressToNextMilestone()  // Returns 0-100
```

---

## 🧪 Testing Scenarios

### Test Daily Bonus Calculation
```dart
test('Daily bonus calculation', () async {
  final service = LoyaltyService();
  
  // Setup: Fresh user
  await service.initializeLoyaltyProfile('test-uid');
  
  // Day 1: 50 + 10 = 60 tokens
  int reward = await service.processDailyLogin('test-uid');
  expect(reward, 60);
  
  // Day 7: 50 + (7*10) = 120 tokens
  // (requires mocking time advance)
});
```

### Test Milestone Unlocking
```dart
test('Milestone unlocking', () async {
  final service = LoyaltyService();
  
  // Spend to bronze threshold (1000 tokens)
  await service.recordPaymentProcessed(
    'session1', 'test-uid', 'pack1', 1000
  );
  
  bool success = await service.checkAndUpdateMilestone('test-uid', 'bronze');
  expect(success, true);
  
  // Verify badge
  final loyalty = await service.getUserLoyalty('test-uid');
  expect(loyalty?.milestones.bronze, true);
});
```

---

## 📋 Deployment Checklist

- [ ] Add LoyaltyProvider to MultiProvider
- [ ] Update Firestore rules with loyalty-loyalty.rules content
- [ ] Create Firestore index: `/users/{uid}/token_audit` by `createdAt`
- [ ] Initialize global loyalty config (via admin dashboard or Cloud Function)
- [ ] Add daily login logic to app startup
- [ ] Hook payment recording to Stripe webhook
- [ ] Create loyalty dashboard UI screen
- [ ] Create milestone progress UI
- [ ] Add badge showcase to profile
- [ ] Test daily login on emulator
- [ ] Test payment processing
- [ ] Test audit log recording
- [ ] Deploy to Firestore
- [ ] Monitor audit logs in Firestore Console

---

## 🐛 Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Audit logs not appearing | Missing Firestore index | Create index in Console |
| Streak not incrementing | lastLogin check failing | Verify timestamp format |
| Milestone not unlocking | lifetimeSpent not updated | Call recordPayment() first |
| Config changes not showing | Config not subscribed to stream | Use streamLoyaltyConfig() |
| Daily bonus claimed twice | Time validation too lenient | Check 24-hour diff properly |

---

## 📞 Support

For issues or questions:
1. Check LOYALTY_SYSTEM_SCHEMA.md for detailed docs
2. Review LoyaltyService for implementation details
3. Check Firestore rules for permissions issues
4. Monitor audit logs for transaction history

