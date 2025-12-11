import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CRMAIInsights extends StatelessWidget {
  final String clientId;

  const CRMAIInsights({super.key, required this.clientId});

  String getCurrentUserId() => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final uid = getCurrentUserId();

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('clients')
          .doc(clientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingCard();
        }

        if (!snapshot.data!.exists) {
          return _errorCard();
        }

        final data = snapshot.data!.data()!;
        final ai = data['ai'] ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("AI Relationship Insights"),
            const SizedBox(height: 8),

            _insightCard(
              title: "Relationship Health",
              score: (ai['relationshipScore'] ?? 0).toDouble(),
              description: ai['relationshipLabel'] ?? "Calculating...",
              color: Colors.blue,
            ),

            _insightCard(
              title: "Client Value",
              score: (ai['valueScore'] ?? 0).toDouble(),
              description: ai['valueLabel'] ?? "Estimating importance...",
              color: Colors.green,
            ),

            _insightCard(
              title: "Risk Assessment",
              score: (ai['riskScore'] ?? 0).toDouble(),
              description: ai['riskLabel'] ?? "Monitoring activity...",
              color: Colors.red,
            ),

            _insightCard(
              title: "Opportunity Score",
              score: (ai['opportunityScore'] ?? 0).toDouble(),
              description: ai['opportunityLabel'] ?? "Forecasting...",
              color: Colors.orange,
            ),

            const SizedBox(height: 12),
            _sectionTitle("AI Suggested Actions"),

            _suggestions(ai['suggestions'] ?? []),

            const SizedBox(height: 12),

            if (ai['summary'] != null) _sectionTitle("AI Relationship Summary"),
            if (ai['summary'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Text(
                  ai['summary'],
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _insightCard({required String title, required double score, required String description, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 22,
            child: Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestions(List suggestions) {
    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text(
          "AI is still learning from your activity...",
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    return Column(
      children: suggestions.map<Widget>((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Text("Client not found"),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    );
  }
}
