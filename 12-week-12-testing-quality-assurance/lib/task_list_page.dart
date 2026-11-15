import 'package:flutter/material.dart';
import 'is_valid_task_title.dart';
import 'task_service.dart';

/// Halaman manajemen tugas yang mengintegrasikan form input, validasi, dan daftar tugas.
class TaskListPage extends StatefulWidget {
  const TaskListPage({
    super.key,
    this.repository,
    this.initialTasks,
  });

  final TaskRepository? repository;
  final List<String>? initialTasks;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialTasks != null) {
      _tasks.addAll(widget.initialTasks!);
    }
    if (widget.repository != null) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await widget.repository!.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks.clear();
        _tasks.addAll(tasks);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat tugas: $e';
        _isLoading = false;
      });
    }
  }

  void _saveTask() {
    final text = _controller.text;
    if (!isValidTaskTitle(text)) {
      setState(() {
        _validationError = 'Judul tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _tasks.add(text.trim());
      _controller.clear();
      _validationError = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar tugas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('task-title-field'),
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Judul tugas baru',
                      errorText: _validationError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('save-task-button'),
                  onPressed: _saveTask,
                  child: const Text('Simpan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                key: Key('task-loading-indicator'),
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  key: const Key('task-error-message'),
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_tasks.isEmpty)
              const Expanded(
                child: Center(
                  key: Key('task-empty-state'),
                  child: Text('Belum ada tugas'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  key: const Key('task-list'),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final item = _tasks[index];
                    return ListTile(
                      title: Text(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

