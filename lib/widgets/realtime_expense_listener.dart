import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import '../services/expense_realtime_listener.dart';
import '../services/expense_status_monitor.dart';
import '../utils/toast_service.dart';

/// Real-time expense display widget
/// Listens to user's expenses collection and displays changes as they occur
class RealtimeExpenseListener extends StatefulWidget {
  final Function(Expense)? onExpenseAdded;
  final Function(Expense)? onExpenseUpdated;
  final Function(Expense)? onExpenseRemoved;
  final bool showNotifications;
  final bool autoRefresh;

  const RealtimeExpenseListener({
    Key? key,
    this.onExpenseAdded,
    this.onExpenseUpdated,
    this.onExpenseRemoved,
    this.showNotifications = true,
    this.autoRefresh = true,
  }) : super(key: key);

  @override
  State<RealtimeExpenseListener> createState() =>
      _RealtimeExpenseListenerState();
}

class _RealtimeExpenseListenerState extends State<RealtimeExpenseListener> {
  final _realtimeListener = ExpenseRealtimeListener();
  final _statusMonitor = ExpenseStatusMonitor();
  late Function() unsubscribe;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoRefresh) {
      _startListening();
    }
  }

  /// Start listening to expenses
  void _startListening() {
    if (_isListening) return;

    unsubscribe = _realtimeListener.onExpenseChange(
      onAdded: (expense) {
        if (mounted) {
          widget.onExpenseAdded?.call(expense);
          if (widget.showNotifications) {
            _showExpenseNotification(expense, 'added');
          }
        }
      },
      onModified: (expense) {
        if (mounted) {
          widget.onExpenseUpdated?.call(expense);
          if (widget.showNotifications) {
            _showExpenseNotification(expense, 'updated');
          }
        }
      },
      onRemoved: (expense) {
        if (mounted) {
          widget.onExpenseRemoved?.call(expense);
          if (widget.showNotifications) {
            _showExpenseNotification(expense, 'removed');
          }
        }
      },
    );

    setState(() => _isListening = true);
  }

  /// Stop listening to expenses
  void _stopListening() {
    if (_isListening) {
      unsubscribe();
      setState(() => _isListening = false);
    }
  }

  /// Show notification for expense change
  void _showExpenseNotification(Expense expense, String action) {
    String message;
    switch (action) {
      case 'added':
        message = '💰 New expense: \$${expense.amount} from ${expense.vendor}';
        break;
      case 'updated':
        message = '✏️ Expense updated: ${expense.vendor}';
        break;
      case 'removed':
        message = '🗑️ Expense removed: ${expense.vendor}';
        break;
      default:
        message = 'Expense changed: ${expense.vendor}';
    }

    if (mounted) {
      ToastService.showInfo(context, message);
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(); // This is a listener, not a visual widget
  }
}

/// Real-time expense stream builder widget
/// Displays expenses in real-time with change animations
class RealtimeExpenseStream extends StatelessWidget {
  final Widget Function(BuildContext, List<Expense>, List<String>)? builder;
  final bool showOnlyNew;
  final Duration animationDuration;
  final VoidCallback? onLoadingStart;
  final VoidCallback? onLoadingComplete;

  const RealtimeExpenseStream({
    Key? key,
    this.builder,
    this.showOnlyNew = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onLoadingStart,
    this.onLoadingComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return StreamBuilder<List<Expense>>(
      stream: expenseProvider.getExpenseStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          onLoadingStart?.call();
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        onLoadingComplete?.call();
        final expenses = snapshot.data ?? [];
        final changedIds = <String>[];

        if (builder != null) {
          return builder!(context, expenses, changedIds);
        }

        return _defaultBuilder(context, expenses);
      },
    );
  }

  /// Default builder - displays expenses as list
  Widget _defaultBuilder(BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No expenses yet'),
            const SizedBox(height: 8),
            Text(
              'Create your first expense to get started',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.animated(
      children: expenses
          .map((expense) => ExpenseChangeCard(expense: expense))
          .toList(),
    );
  }
}

/// Card displaying individual expense with change animation
class ExpenseChangeCard extends StatefulWidget {
  final Expense expense;
  final Duration animationDuration;

  const ExpenseChangeCard({
    Key? key,
    required this.expense,
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<ExpenseChangeCard> createState() => _ExpenseChangeCardState();
}

class _ExpenseChangeCardState extends State<ExpenseChangeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Vendor & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.expense.vendor,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.expense.category != null)
                            Text(
                              widget.expense.category!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${widget.expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFffd700),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Items
                if (widget.expense.items.isNotEmpty) ...[
                  Text(
                    'Items (${widget.expense.items.length})',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.expense.items
                        .map(
                          (item) => Chip(
                            label: Text(item, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.expense.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.expense.status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Metadata
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.expense.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'inventory_added':
        return Colors.blue;
      case 'paid':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Real-time statistics widget
class RealtimeExpenseStats extends StatelessWidget {
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const RealtimeExpenseStats({
    Key? key,
    this.titleStyle,
    this.valueStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return StreamBuilder<List<Expense>>(
      stream: expenseProvider.getExpenseStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final expenses = snapshot.data ?? [];
        final totalAmount = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );
        final approved = expenses
            .where((e) => e.status == 'approved')
            .fold<double>(0, (sum, e) => sum + e.amount);
        final pending = expenses
            .where((e) => e.status == 'pending_review')
            .fold<double>(0, (sum, e) => sum + e.amount);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _StatRow(
                title: 'Total Expenses',
                value: '\$${totalAmount.toStringAsFixed(2)}',
                titleStyle: titleStyle,
                valueStyle: valueStyle,
              ),
              const Divider(height: 16),
              _StatRow(
                title: 'Approved',
                value: '\$${approved.toStringAsFixed(2)}',
                color: Colors.green,
                titleStyle: titleStyle,
                valueStyle: valueStyle,
              ),
              const SizedBox(height: 12),
              _StatRow(
                title: 'Pending Review',
                value: '\$${pending.toStringAsFixed(2)}',
                color: Colors.orange,
                titleStyle: titleStyle,
                valueStyle: valueStyle,
              ),
              const SizedBox(height: 12),
              _StatRow(
                title: 'Count',
                value: '${expenses.length} expenses',
                color: Colors.blue,
                titleStyle: titleStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Statistics row
class _StatRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const _StatRow({
    required this.title,
    required this.value,
    this.color,
    this.titleStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ??
              Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey),
        ),
        Text(
          value,
          style: (valueStyle ??
                  Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)) ?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Extension for animated list
extension ListViewAnimatedExtension on ListView {
  static Widget animated({required List<Widget> children}) {
    return ListView(
      children: List.generate(
        children.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: children[index],
        ),
      ),
    );
  }
}
