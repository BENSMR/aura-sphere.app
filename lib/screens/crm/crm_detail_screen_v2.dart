import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// CRM Detail Screen V2
///
/// Enhanced client detail view with invoice integration,
/// timeline events, AI metrics, and action buttons
class CRMDetailScreenV2 extends StatelessWidget {
  final String clientId;

  const CRMDetailScreenV2({super.key, required this.clientId});

  /// Get current user ID from Firebase Auth
  String getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'CURRENT_USER_ID';
  }

  /// Load client data and related information
  Future<void> _loadClientData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load client
      final client = await _clientService.getClientById(widget.clientId);