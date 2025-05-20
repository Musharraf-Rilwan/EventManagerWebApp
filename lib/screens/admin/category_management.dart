import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => CategoryManagementPageState();
}

class CategoryManagementPageState extends State<CategoryManagementPage> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final categories = await _categoryService.getAllCategories(activeOnly: false);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddEditDialog([CategoryModel? category]) async {
    _nameController.text = category?.name ?? '';
    _descriptionController.text = category?.description ?? '';
    Color selectedColor = category?.color ?? Colors.blue;
    IconData selectedIcon = category?.icon ?? Icons.category;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(selectedIcon),
                      onPressed: () async {
                        // Show icon picker
                        final IconData? icon = await showDialog<IconData>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Icon'),
                            content: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Icons.category,
                                  Icons.event,
                                  Icons.sports,
                                  Icons.music_note,
                                  Icons.movie,
                                  Icons.book,
                                  Icons.business,
                                  Icons.school,
                                  Icons.restaurant,
                                  Icons.local_activity,
                                ].map((icon) => IconButton(
                                  icon: Icon(icon),
                                  onPressed: () => Navigator.of(context).pop(icon),
                                )).toList(),
                              ),
                            ),
                          ),
                        );
                        if (icon != null) {
                          setState(() {
                            selectedIcon = icon;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.color_lens, color: selectedColor),
                      onPressed: () async {
                        // Show color picker
                        final Color? color = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Color'),
                            content: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Colors.blue,
                                  Colors.red,
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.purple,
                                  Colors.orange,
                                  Colors.teal,
                                  Colors.pink,
                                  Colors.indigo,
                                  Colors.brown,
                                ].map((color) => InkWell(
                                  onTap: () => Navigator.of(context).pop(color),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: color,
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        );
                        if (color != null) {
                          setState(() {
                            selectedColor = color;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  if (category == null) {
                    final newCategory = CategoryModel(
                      id: '',
                      name: _nameController.text,
                      description: _descriptionController.text,
                      color: selectedColor,
                      icon: selectedIcon,
                      createdAt: DateTime.now(),
                    );
                    await _categoryService.createCategory(newCategory);
                  } else {
                    final updatedCategory = CategoryModel(
                      id: category.id,
                      name: _nameController.text,
                      description: _descriptionController.text,
                      color: selectedColor,
                      icon: selectedIcon,
                      createdAt: category.createdAt,
                      isActive: category.isActive,
                    );
                    await _categoryService.updateCategory(category.id, updatedCategory);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    refreshData();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving category: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      category.icon,
                      color: category.color,
                      size: 32,
                    ),
                    title: Text(category.name),
                    subtitle: Text(category.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddEditDialog(category),
                        ),
                        IconButton(
                          icon: Icon(
                            category.isActive ? Icons.visibility : Icons.visibility_off,
                            color: category.isActive ? Colors.green : Colors.grey,
                          ),
                          onPressed: () async {
                            try {
                              final updatedCategory = CategoryModel(
                                id: category.id,
                                name: category.name,
                                description: category.description,
                                color: category.color,
                                icon: category.icon,
                                createdAt: category.createdAt,
                                isActive: !category.isActive,
                              );
                              await _categoryService.updateCategory(
                                category.id,
                                updatedCategory,
                              );
                              refreshData();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating category: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
