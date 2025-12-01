import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentsSettingsScreen extends StatefulWidget {
  const DocumentsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsSettingsScreen> createState() =>
      _DocumentsSettingsScreenState();
}

class _DocumentsSettingsScreenState extends State<DocumentsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Storage'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentTab(),
          _buildStorageTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Recent Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildDocumentItem(
          title: 'Invoice #INV-2025-001.pdf',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: 'Invoice',
          size: '145 KB',
          onDownload: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _buildDocumentItem(
          title: 'Receipt - Payment Confirmation.pdf',
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: 'Receipt',
          size: '89 KB',
          onDownload: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _buildDocumentItem(
          title: 'Invoice #INV-2024-156.pdf',
          date: DateTime.now().subtract(const Duration(days: 15)),
          type: 'Invoice',
          size: '162 KB',
          onDownload: () {},
          onDelete: () {},
        ),
        const SizedBox(height: 12),
        _buildDocumentItem(
          title: 'Receipt - Payment Confirmation.pdf',
          date: DateTime.now().subtract(const Duration(days: 30)),
          type: 'Receipt',
          size: '76 KB',
          onDownload: () {},
          onDelete: () {},
        ),
      ],
    );
  }

  Widget _buildStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Storage chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud Storage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Used: 245 MB'),
                    Text('Limit: 5 GB'),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 245 / 5000,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${((245 / 5000) * 100).toStringAsFixed(1)}% used',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Breakdown
          const Text(
            'Breakdown by Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStorageItem(
            type: 'Invoices',
            size: '145 MB',
            percentage: 0.59,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStorageItem(
            type: 'Receipts',
            size: '76 MB',
            percentage: 0.31,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStorageItem(
            type: 'Other',
            size: '24 MB',
            percentage: 0.10,
            color: Colors.orange,
          ),
          const SizedBox(height: 32),

          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showClearanceDialog();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.red.shade50,
              ),
              child: Text(
                'Clear Old Documents',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Storage Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Documents older than 90 days can be safely deleted. Backups are retained for 30 days.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Auto-cleanup
          const Text(
            'Auto-Cleanup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Auto-delete old documents'),
            subtitle: const Text('Remove documents older than 90 days'),
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Keep backups'),
            subtitle: const Text('Retain backups for 30 days'),
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 32),

          // Default formats
          const Text(
            'Export Defaults',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('PDF'),
            subtitle: const Text('Include PDF in exports'),
            value: true,
            onChanged: (_) {},
          ),
          CheckboxListTile(
            title: const Text('CSV'),
            subtitle: const Text('Include CSV in exports'),
            value: true,
            onChanged: (_) {},
          ),
          CheckboxListTile(
            title: const Text('JSON'),
            subtitle: const Text('Include JSON in exports'),
            value: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 32),

          // Compression
          const Text(
            'File Compression',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Compress documents'),
            subtitle: const Text('Reduce file size (slower processing)'),
            value: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 32),

          // Download settings
          const Text(
            'Download Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Default naming'),
            subtitle: const Text('Pattern: INVOICE-{number}-{date}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document settings saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required DateTime date,
    required String type,
    required String size,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
  }) {
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type == 'Invoice'
                        ? Colors.blue.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: type == 'Invoice' ? Colors.blue : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormatter.format(date)} • $size',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItem({
    required String type,
    required String size,
    required double percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          size,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showClearanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Documents'),
        content: const Text(
          'This will delete all documents older than 90 days. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Old documents cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
