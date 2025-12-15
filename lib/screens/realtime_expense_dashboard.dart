import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expenses_provider.dart';
import '../widgets/realtime_expense_listener.dart';

/// Example dashboard showing real-time expense monitoring
class RealtimeExpenseDashboard extends StatefulWidget {
  const RealtimeExpenseDashboard({Key? key}) : super(key: key);

  @override
  State<RealtimeExpenseDashboard> createState() =>
      _RealtimeExpenseDashboardState();
}

class _RealtimeExpenseDashboardState extends State<RealtimeExpenseDashboard> {
  bool _isListening = true;
  int _newExpensesCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize real-time listeners on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.initializeRealtimeListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Dashboard'),
        subtitle: _isListening
            ? const Text('Listening for updates...')
            : const Text('Listening paused'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleListening,
            tooltip: _isListening ? 'Pause listening' : 'Resume listening',
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time listener (invisible, handles events)
          RealtimeExpenseListener(
            autoRefresh: _isListening,
            showNotifications: true,
            onExpenseAdded: (expense) {
              setState(() => _newExpensesCount++);
              // Could navigate to expense details here
            },
            onExpenseUpdated: (expense) {
              // Handle expense update
              debugPrint('Expense updated: ${expense.vendor}');
            },
            onExpenseRemoved: (expense) {
              // Handle expense removal
              debugPrint('Expense removed: ${expense.vendor}');
            },
          ),

          // Real-time statistics
          Padding(
            padding: const EdgeInsets.all(16),
            child: RealtimeExpenseStats(
              titleStyle: Theme.of(context).textTheme.labelMedium,
              valueStyle: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          // New expenses indicator
          if (_newExpensesCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'New expenses received: $_newExpensesCount',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _newExpensesCount = 0),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),

          // Real-time expense stream
          Expanded(
            child: RealtimeExpenseStream(
              showOnlyNew: false,
              onLoadingStart: () {
                debugPrint('Loading expenses...');
              },
              onLoadingComplete: () {
                debugPrint('Expenses loaded');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Toggle real-time listening
  void _toggleListening() {
    setState(() => _isListening = !_isListening);
  }

  /// Show add expense dialog
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: const Text('Navigate to add expense screen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add expense screen
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Real-time expense feed widget
/// Shows expenses as they're added with live updates
class RealtimeExpenseFeed extends StatefulWidget {
  final bool showHeader;
  final bool showFooter;
  final bool enableActions;

  const RealtimeExpenseFeed({
    Key? key,
    this.showHeader = true,
    this.showFooter = true,
    this.enableActions = true,
  }) : super(key: key);

  @override
  State<RealtimeExpenseFeed> createState() => _RealtimeExpenseFeedState();
}

class _RealtimeExpenseFeedState extends State<RealtimeExpenseFeed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.initializeRealtimeListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHeader)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.live_tv, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Live Expense Feed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RealtimeExpenseStream(
            builder: (context, expenses, changedIds) {
              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('Waiting for expenses...'),
                      const SizedBox(height: 8),
                      Text(
                        'New expenses will appear here in real-time',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final isNew = changedIds.contains(expense.id);

                  return Stack(
                    children: [
                      ExpenseChangeCard(expense: expense),
                      if (isNew)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (widget.showFooter)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_sync, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Syncing in real-time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Minimal real-time listener - just the notifications
class MinimalRealtimeListener extends StatefulWidget {
  final Function(String message)? onMessage;

  const MinimalRealtimeListener({
    Key? key,
    this.onMessage,
  }) : super(key: key);

  @override
  State<MinimalRealtimeListener> createState() =>
      _MinimalRealtimeListenerState();
}

class _MinimalRealtimeListenerState extends State<MinimalRealtimeListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.initializeRealtimeListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeExpenseListener(
      onExpenseAdded: (expense) {
        final message =
            '💰 New: \$${expense.amount} from ${expense.vendor}';
        widget.onMessage?.call(message);
      },
      onExpenseUpdated: (expense) {
        final message = '✏️ Updated: ${expense.vendor}';
        widget.onMessage?.call(message);
      },
      onExpenseRemoved: (expense) {
        final message = '🗑️ Removed: ${expense.vendor}';
        widget.onMessage?.call(message);
      },
    );
  }
}
