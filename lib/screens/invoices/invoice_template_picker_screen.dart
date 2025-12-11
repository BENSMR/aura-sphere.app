import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/invoice_templates.dart';
import '../../data/models/invoice_template_model.dart';
import '../../providers/user_provider.dart';

class InvoiceTemplatePickerScreen extends StatefulWidget {
  const InvoiceTemplatePickerScreen({super.key});

  @override
  State<InvoiceTemplatePickerScreen> createState() => _InvoiceTemplatePickerScreenState();
}

class _InvoiceTemplatePickerScreenState extends State<InvoiceTemplatePickerScreen> {
  late List<InvoiceTemplateModel> filteredTemplates;
  late List<InvoiceTemplateModel> allTemplates;
  String searchQuery = '';
  String? selectedFilter;
  bool showPremiumOnly = false;

  @override
  void initState() {
    super.initState();
    allTemplates = InvoiceTemplates.available;
    filteredTemplates = List.from(allTemplates);
  }

  void _filterTemplates() {
    filteredTemplates = allTemplates.where((template) {
      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          template.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          template.description.toLowerCase().contains(searchQuery.toLowerCase());

      // Type filter
      final matchesType =
          selectedFilter == null || template.templateType == selectedFilter;

      // Premium filter
      final matchesPremium =
          !showPremiumOnly || template.isPremium;

      return matchesSearch && matchesType && matchesPremium;
    }).toList();

    setState(() {});
  }

  void _selectTemplate(InvoiceTemplateModel template) async {
    try {
      // Track usage
      InvoiceTemplates.incrementUsage(template.id);

      // Update user provider
      await Provider.of<UserProvider>(context, listen: false)
          .setInvoiceTemplate(template.templateType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} selected'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, template);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Invoice Template'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${filteredTemplates.length} templates',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search templates...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                searchQuery = value;
                _filterTemplates();
              },
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchQuery = '';
                          _filterTemplates();
                        },
                      ),
                    ]
                  : [],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type filter dropdown
                  DropdownButton<String?>(
                    value: selectedFilter,
                    hint: const Text('All Types'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...InvoiceTemplates.getAllTypes().map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type[0].toUpperCase() + type.substring(1)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      selectedFilter = value;
                      _filterTemplates();
                    },
                  ),
                  const SizedBox(width: 16),

                  // Premium filter toggle
                  FilterChip(
                    label: const Text('Premium Only'),
                    selected: showPremiumOnly,
                    onSelected: (selected) {
                      showPremiumOnly = selected;
                      _filterTemplates();
                    },
                  ),
                  const SizedBox(width: 8),

                  // Stats
                  Chip(
                    label: Text(
                      'Free: ${InvoiceTemplates.getFree().length} | Premium: ${InvoiceTemplates.getPremium().length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Templates grid
          if (filteredTemplates.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No templates found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        searchQuery = '';
                        selectedFilter = null;
                        showPremiumOnly = false;
                        _filterTemplates();
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTemplates.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final template = filteredTemplates[index];
                  return _buildTemplateCard(context, template);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    InvoiceTemplateModel template,
  ) {
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[100],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Image.asset(
                      template.previewImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),

                    // Premium badge
                    if (template.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Usage count badge
                    if ((template.usageCount ?? 0) > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${template.usageCount} uses',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Template info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Type and tags row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Type chip
                        Chip(
                          label: Text(
                            template.templateType[0].toUpperCase() +
                                template.templateType.substring(1),
                          ),
                          labelStyle: const TextStyle(fontSize: 10),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),

                        // Tag chips
                        ...(template.tags ?? []).take(1).map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.blue[100],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
