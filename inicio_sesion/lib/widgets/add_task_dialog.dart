import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(Task) addTask;

  const AddTaskDialog({super.key, required this.addTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    setState(() {
      _dueDate = pickedDate;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              children: [
                Text(
                  _dueDate == null
                      ? 'No Date Chosen!'
                      : 'Due Date: ${DateFormat('MM/dd/yyyy').format(_dueDate!)}',
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text(
                    'Choose Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty ||
                _descriptionController.text.isEmpty ||
                _dueDate == null) {
              return;
            }

            final newTask = Task(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text,
              description: _descriptionController.text,
              date: _dueDate!,
              createdAt: DateTime.now(),
            );

            widget.addTask(newTask);
            Navigator.of(context).pop();
          },
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}