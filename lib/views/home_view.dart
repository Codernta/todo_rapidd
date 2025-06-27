import 'package:flutter/material.dart';
import 'package:mt_rapidd_todo/services/socket_services.dart';
import 'package:mt_rapidd_todo/viewModels/todo_view_model.dart';
import 'package:mt_rapidd_todo/views/todo_detail_view.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../widgets/custom_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/custom_text_field.dart';
import '../models/todo_model.dart';
import 'add_todo_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todoViewModel = Provider.of<TodoViewModel>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);

      todoViewModel.initialize().then((_) {
        if (todoViewModel.currentUser != null) {
          socketService.initSocket(todoViewModel.currentUser!.id);
          todoViewModel.setupSocketListeners(socketService);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        title: const Text('RAPIDD TODO'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'Shared'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodoList(isMyTasks: true),
                _buildTodoList(isMyTasks: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTodo(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborative TODO'),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTodoList(isMyTasks: true),
                      _buildTodoList(isMyTasks: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text('Select a task to view details'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTodo(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return _buildTabletLayout();
  }

  Widget _buildSearchAndFilters() {
    return Consumer<TodoViewModel>(
      builder: (context, todoViewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomTextField(
                controller: _searchController,
                labelText: 'Search tasks',
                hintText: 'Enter title or description...',
                suffixIcon: const Icon(Icons.search),
                onChanged: todoViewModel.setSearchQuery,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('High Priority'),
                      selected: todoViewModel.todos.any((t) => t.priority == Priority.high),
                      onSelected: (selected) {
                        todoViewModel.setFilterPriority(selected ? Priority.high : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Medium Priority'),
                      selected: todoViewModel.todos.any((t) => t.priority == Priority.medium),
                      onSelected: (selected) {
                        todoViewModel.setFilterPriority(selected ? Priority.medium : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: todoViewModel.todos.any((t) => t.isCompleted),
                      onSelected: (selected) {
                        todoViewModel.setFilterCompleted(selected ? true : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    if (todoViewModel.searchQuery.isNotEmpty ||
                        todoViewModel.todos.length != todoViewModel.todos.length)
                      TextButton(
                        onPressed: todoViewModel.clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodoList({required bool isMyTasks}) {
    return Consumer<TodoViewModel>(
      builder: (context, todoViewModel, child) {
        if (todoViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = isMyTasks ? todoViewModel.myTodos : todoViewModel.sharedTodos;

        if (todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMyTasks ? Icons.task_alt : Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  isMyTasks ? 'No tasks yet' : 'No shared tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMyTasks
                      ? 'Create your first task using the + button'
                      : 'Tasks shared with you will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: TodoCard(
                      todo: todo,
                      isOwner: todo.ownerId == todoViewModel.currentUser?.id,
                      onTap: () => _navigateToTodoDetail(todo),
                      onToggle: () => todoViewModel.toggleTodoCompletion(
                        todo.id,
                        Provider.of<SocketService>(context, listen: false),
                      ),
                      onShare: () => _showShareDialog(todo),
                      onDelete: todo.ownerId == todoViewModel.currentUser?.id
                          ? () => _showDeleteDialog(todo)
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToAddTodo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTodoView(),
      ),
    );
  }

  void _navigateToTodoDetail(TodoModel todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TodoDetailView(todo: todo),
      ),
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
            CustomTextField(
              controller: emailController,
              labelText: 'Email Address',
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

  void _showDeleteDialog(TodoModel todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TodoViewModel>(context, listen: false)
                  .deleteTodo(todo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}