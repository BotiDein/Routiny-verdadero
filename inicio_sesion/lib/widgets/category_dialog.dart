import 'package:flutter/material.dart';

class CategoryDialog extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryDialog({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late String _currentSelectedCategory;

  @override
  void initState() {
    super.initState();
    _currentSelectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona una categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = category == _currentSelectedCategory;
                
                return ListTile(
                  title: Text(
                    category,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Radio<String>(
                    value: category,
                    groupValue: _currentSelectedCategory,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _currentSelectedCategory = value;
                        });
                      }
                    },
                    activeColor: Colors.blue,
                  ),
                  onTap: () {
                    setState(() {
                      _currentSelectedCategory = category;
                    });
                  },
                  tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  _showAddCategoryDialog(context);
                },
                child: const Text('Crear o Editar'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onCategorySelected(_currentSelectedCategory);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Seleccionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    String selectedEmoji = '😊';
    
    final List<String> emojis = [
      '😊', '🏃', '🧠', '📚', '💼', '🍎', '💪', '🧘', '🎯', '⚽',
      '🎮', '🎨', '🎵', '🍳', '🌱', '💻', '🏠', '🚗', '✈️', '🛒',
      '💰', '🎓', '🔬', '🧪', '🧬', '🔭', '📱', '📷', '🎬', '📺',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear o Editar Categorías',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nueva categoría',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        hintText: 'Nombre',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Emoji para la categoría',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: emojis.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEmoji = emojis[index];
                              });
                            },
                            child: Container(
                              width: 50,
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: selectedEmoji == emojis[index]
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  emojis[index],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categorías existentes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: widget.categories.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(widget.categories[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                List<String> updatedCategories = List.from(widget.categories);
                                updatedCategories.removeAt(index);
                                
                                // Actualizar la categoría seleccionada si es necesario
                                if (_currentSelectedCategory == widget.categories[index]) {
                                  if (updatedCategories.isNotEmpty) {
                                    _currentSelectedCategory = updatedCategories[0];
                                  }
                                }
                                
                                setState(() {
                                  widget.categories.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (categoryController.text.isNotEmpty) {
                              setState(() {
                                widget.categories.add('$selectedEmoji ${categoryController.text}');
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Añadir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}