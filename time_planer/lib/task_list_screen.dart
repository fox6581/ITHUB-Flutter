import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task_provider.dart'; // Импортируйте TaskProvider
import 'task_form.dart'; // Импортируйте TaskForm
import 'task.dart'; // Импортируйте Task

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Запись клиентов'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Получаем задачи для выбранного дня и сортируем их по времени
          final tasksForDay = taskProvider.getTasksForDay(_selectedDay)
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 1, 1),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final tasks = taskProvider.getTasksForDay(date);
                    if (tasks.isNotEmpty) {
                      return Positioned(
                        top: 5,
                        right: 5,
                        child: _buildEventsMarker(date, tasks.length),
                      );
                    }
                    return SizedBox();
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tasksForDay.length,
                  itemBuilder: (context, index) {
                    final task = tasksForDay[index];
                    return ListTile(
                      title: Text(
                        '${task.title}, ${DateFormat('HH:mm').format(task.startTime)} - ${DateFormat('HH:mm').format(task.endTime)}',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _confirmDeleteTask(context, taskProvider, task);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskForm(task: task),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskForm(selectedDate: _selectedDay),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      width: 16,
      height: 16,
      child: Center(
        child: Text(
          '$count',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _confirmDeleteTask(BuildContext context, TaskProvider taskProvider, Task task) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Вы хотите удалить "${task.title}"?'),

          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () {
                if (task.id != null) {
                  taskProvider.deleteTask(task.id!);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
