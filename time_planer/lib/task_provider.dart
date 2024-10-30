import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _tasks = await DatabaseHelper().getTasks();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final existingTasks = await DatabaseHelper().getTasks();
    final isDuplicate = existingTasks.any(
            (t) => t.startTime == task.startTime && t.endTime == task.endTime
    );

    if (isDuplicate) {
      print('Task with the same time already exists');
    } else {
      await DatabaseHelper().insertTask(task);
      await _loadTasks();
    }
  }


  Future<void> updateTask(Task updatedTask) async {
    final db = DatabaseHelper();
    final result = await db.updateTask(updatedTask);

    if (result > 0) { // Проверка успешного обновления
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } else {
      print('Error updating task with ID: ${updatedTask.id}');
    }
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper().deleteTask(id);
    await _loadTasks();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      startTime: task.startTime,
      endTime: task.endTime,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(), // Используем DateTime, а не строку
      isCompleted: !task.isCompleted,
    );
    await updateTask(updatedTask);
  }

  List<Task> getTasksForToday() {
    DateTime now = DateTime.now();
    return _tasks.where((task) => isSameDay(task.startTime, now)).toList();
  }

  List<Task> getTasksForTomorrow() {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    return _tasks.where((task) => isSameDay(task.startTime, tomorrow)).toList();
  }

  // Метод для получения задач на определенный день
  List<Task> getTasksForDay(DateTime date) {
    return _tasks.where((task) => isSameDay(task.startTime, date)).toList();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
