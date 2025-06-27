import 'package:flutter/material.dart';
import 'package:mt_rapidd_todo/services/socket_services.dart';
import 'package:mt_rapidd_todo/viewModels/todo_view_model.dart';
import 'package:mt_rapidd_todo/views/widgets/custom_text_field.dart';
import 'package:mt_rapidd_todo/views/widgets/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/todo_model.dart';


class TodoDetailView extends StatefulWidget {
  final TodoModel todo;

  const TodoDetailView({super.key, required this.todo});

  @override
  State<TodoDetailView> createState() => _TodoDetailViewState();
}

class _TodoDetailViewState extends State<TodoDetailView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Priority _selectedPriority;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
    _selectedPriority = widget.todo.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (_canEdit())
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Center(
        child: SizedBox(
          width: 800,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: [
                          if (_canEdit())
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                });
                              },
                              icon: Icon(_isEditing ? Icons.close : Icons.edit),
                              label: Text(_isEditing ? 'Cancel' : 'Edit'),
                            ),
                          if (_isEditing) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveChanges,
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return _buildTabletLayout();
  }

  Widget _buildContent() {
    return Consumer<TodoViewModel>(
      builder: (context, todoViewModel, child) {
        final currentTodo = todoViewModel.todos.firstWhere(
              (t) => t.id == widget.todo.id,
          orElse: () => widget.todo,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(currentTodo),
              const SizedBox(height: 16),
              _buildDetailsCard(currentTodo),
              const SizedBox(height: 16),
              _buildSharingCard(currentTodo),
              const SizedBox(height: 16),
              _buildMetadataCard(currentTodo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(TodoModel todo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: todo.isCompleted,
              onChanged: _canEdit() ? (value) => _toggleCompletion(todo) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.isCompleted ? 'Completed' : 'In Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: todo.isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (todo.isCompleted && todo.updatedAt != null)
                    Text(
                      'Completed on ${DateFormat('MMM dd, yyyy').format(todo.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(TodoModel todo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Text('Priority'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Priority.values.map((priority) {
                  return ChoiceChip(
                    label: Text(_getPriorityLabel(priority)),
                    selected: _selectedPriority == priority,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                todo.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  todo.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Priority: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getPriorityColor(todo.priority).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getPriorityLabel(todo.priority),
                      style: TextStyle(
                        color: _getPriorityColor(todo.priority),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSharingCard(TodoModel todo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sharing',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_canShare(todo))
                  TextButton.icon(
                    onPressed: () => _showShareDialog(todo),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (todo.sharedWith.isEmpty)
              Text(
                'This task is not shared with anyone',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shared with:'),
                  const SizedBox(height: 8),
                  ...todo.sharedWith.map((email) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(email),
                      ],
                    ),
                  )),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _shareViaEmail(todo),
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _shareViaOther(todo),
                  icon: const Icon(Icons.share),
                  label: const Text('Other'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(TodoModel todo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Created', DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(todo.createdAt)),
            if (todo.updatedAt != null)
              _buildMetadataRow('Last Updated', DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(todo.updatedAt!)),
            _buildMetadataRow('Task ID', todo.id),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButtons() {
    if (!ResponsiveLayout.isMobile(context)) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () => _shareViaOther(widget.todo),
          child: const Icon(Icons.share),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'email',
          onPressed: () => _shareViaEmail(widget.todo),
          child: const Icon(Icons.email),
        ),
      ],
    );
  }

  bool _canEdit() {
    final todoViewModel = Provider.of<TodoViewModel>(context, listen: false);
    return widget.todo.ownerId == todoViewModel.currentUser?.id;
  }

  bool _canShare(TodoModel todo) {
    final todoViewModel = Provider.of<TodoViewModel>(context, listen: false);
    return todo.ownerId == todoViewModel.currentUser?.id;
  }

  void _toggleCompletion(TodoModel todo) {
    final todoViewModel = Provider.of<TodoViewModel>(context, listen: false);
    final socketService = Provider.of<SocketService>(context, listen: false);
    todoViewModel.toggleTodoCompletion(todo.id, socketService);
  }

  void _saveChanges() {
    final todoViewModel = Provider.of<TodoViewModel>(context, listen: false);
    final socketService = Provider.of<SocketService>(context, listen: false);

    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _selectedPriority,
    );

    todoViewModel.updateTodo(updatedTodo, socketService);
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated successfully')),
    );
  }

  void _showShareDialog(TodoModel todo) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share "${todo.title}" with:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Provider.of<TodoViewModel>(context, listen: false)
                    .shareTodo(todo.id, emailController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task shared successfully')),
                );
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _shareViaEmail(TodoModel todo) {
    final subject = Uri.encodeComponent('Task: ${todo.title}');
    final body = Uri.encodeComponent(
        'I\'m sharing a task with you:\n\n'
            'Title: ${todo.title}\n'
            'Description: ${todo.description}\n'
            'Priority: ${_getPriorityLabel(todo.priority)}\n'
            'Status: ${todo.isCompleted ? 'Completed' : 'In Progress'}\n\n'
            'Created on: ${DateFormat('MMM dd, yyyy').format(todo.createdAt)}'
    );

    final emailUrl = 'mailto:?subject=$subject&body=$body';
    launchUrl(Uri.parse(emailUrl));
  }

  void _shareViaOther(TodoModel todo) {
    final shareText = 'Task: ${todo.title}\n'
        'Description: ${todo.description}\n'
        'Priority: ${_getPriorityLabel(todo.priority)}\n'
        'Status: ${todo.isCompleted ? 'Completed' : 'In Progress'}';

    // In a real app, you would use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality: $shareText'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getPriorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}