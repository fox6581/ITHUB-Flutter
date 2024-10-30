import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'task.dart';
import 'task_provider.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final DateTime? selectedDate;

  TaskForm({this.task, this.selectedDate});

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  DateTime? _startTime;
  DateTime? _endTime;
  late List<Map<String, DateTime>> _timeSlots;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _title = widget.task!.title;
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
    } else {
      if (widget.selectedDate != null) {
        _startTime = widget.selectedDate!;
        _endTime = _startTime!.add(Duration(hours: 1));
      }
    }
    _timeSlots = generateTimeSlots();
  }

  List<Map<String, DateTime>> generateTimeSlots() {
    List<Map<String, DateTime>> timeSlots = [];
    if (_startTime != null) {
      DateTime start = DateTime(
        _startTime!.year,
        _startTime!.month,
        _startTime!.day,
        9,
        0,
      ); // Начало рабочего времени на выбранной дате
      DateTime end = DateTime(
        _startTime!.year,
        _startTime!.month,
        _startTime!.day,
        19,
        0,
      ); // Конец рабочего времени на выбранной дате
      Duration interval = Duration(minutes: 30); // Интервал времени

      while (start.isBefore(end)) {
        DateTime slotEnd = start.add(interval);
        timeSlots.add({
          'start': start,
          'end': slotEnd,
        });
        start = slotEnd;
      }
    }
    return timeSlots;
  }

  Future<void> _showTaskDialog(DateTime start, DateTime end) async {
    final TextEditingController _taskController = TextEditingController();
    String taskTitle = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Введите имя задачи'),
          content: TextField(
            controller: _taskController,
            decoration: InputDecoration(hintText: 'Имя'),
            onChanged: (value) {
              taskTitle = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Добавить'),
              onPressed: () {
                if (taskTitle.isNotEmpty) {
                  setState(() {
                    _title = taskTitle;
                    _startTime = start;
                    _endTime = end;
                  });

                  final task = Task(
                    id: widget.task?.id ?? 0, // Используйте существующий ID или новый
                    title: _title,
                    startTime: _startTime!,
                    endTime: _endTime!,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    isCompleted: false,
                  );

                  Provider.of<TaskProvider>(context, listen: false).addTask(task);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Добавить задачу' : 'Редактировать задачу'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 1, 1),
                focusedDay: _startTime ?? DateTime.now(),
                selectedDayPredicate: (day) {
                  return isSameDay(_startTime ?? DateTime.now(), day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _startTime = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                      _startTime?.hour ?? 9,
                      _startTime?.minute ?? 0,
                    );
                    _endTime = _startTime?.add(Duration(hours: 1));
                    _timeSlots = generateTimeSlots();
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final tasks = Provider.of<TaskProvider>(context).getTasksForDay(date);
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
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    // Обновляем список временных слотов с учетом текущих задач
                    _timeSlots = generateTimeSlots();
                    return ListView.builder(
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final isAvailable = !taskProvider.tasks.any(
                              (task) => task.startTime.isBefore(slot['end']!) && task.endTime.isAfter(slot['start']!),
                        );

                        bool isSelected = _startTime != null &&
                            _endTime != null &&
                            _startTime!.isAtSameMomentAs(slot['start']!) &&
                            _endTime!.isAtSameMomentAs(slot['end']!);

                        return GestureDetector(
                          onTap: () {
                            if (isAvailable) {
                              _showTaskDialog(slot['start']!, slot['end']!);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4.0),
                            padding: EdgeInsets.all(8.0),
                            color: isAvailable ? Colors.green : Colors.red,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${DateFormat('HH:mm').format(slot['start']!)} - ${DateFormat('HH:mm').format(slot['end']!)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                if (isSelected) // Показываем галочку только если слот выбран
                                  Icon(Icons.check, color: Colors.white),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final task = Task(
                      id: widget.task?.id, // id сохраняется для обновления существующей задачи
                      title: _title,
                      startTime: _startTime ?? widget.task?.startTime ?? DateTime.now(),
                      endTime: _endTime ?? widget.task?.endTime ?? DateTime.now().add(Duration(hours: 1)),
                      createdAt: widget.task?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      isCompleted: widget.task?.isCompleted ?? false,
                    );

                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

                    if (widget.task == null) {
                      // Добавляем новую задачу
                      taskProvider.addTask(task);
                    } else {
                      // Обновляем существующую задачу
                      taskProvider.updateTask(task);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.task == null ? 'Добавить задачу' : 'Обновить задачу'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
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
}
