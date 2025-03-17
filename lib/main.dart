import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeNotifications();
  await initializeDateFormatting('es', null);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale('es', 'ES'),
    supportedLocales: [
      Locale('es', 'ES'),
      Locale('es', 'MX'),
    ],
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: TaskCalendarApp(),
  ));
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> scheduleNotification(DateTime taskDate, TimeOfDay taskTime, String taskTitle) async {
  final DateTime fullDateTime = DateTime(
    taskDate.year,
    taskDate.month,
    taskDate.day,
    taskTime.hour,
    taskTime.minute,
  );
  final scheduledDate = tz.TZDateTime.from(fullDateTime, tz.local);
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'task_channel', 'Task Notifications',
    importance: Importance.max, priority: Priority.high);
  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Recordatorio de Tarea',
    'Tienes una tarea: $taskTitle',
    scheduledDate,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

class Task {
  String title;
  String category;
  TimeOfDay time;

  Task(this.title, this.category, this.time);
}

class TaskCalendarApp extends StatefulWidget {
  const TaskCalendarApp({super.key});

  @override
  _TaskCalendarAppState createState() => _TaskCalendarAppState();
}

class _TaskCalendarAppState extends State<TaskCalendarApp> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _taskController = TextEditingController();
  String _selectedCategory = 'Estudio';
  Map<DateTime, List<Task>> _tasks = {};

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Tareas')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            locale: 'es_ES',
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Ingrese una tarea',
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: ['Estudio', 'Trabajo', 'Pago'].map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks[_selectedDate]?.length ?? 0,
              itemBuilder: (context, index) {
                Task task = _tasks[_selectedDate]![index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text('Categoría: ${task.category}, Hora: ${task.time.format(context)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTask(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks[_selectedDate] = (_tasks[_selectedDate] ?? [])..add(Task(_taskController.text, _selectedCategory, _selectedTime));
        scheduleNotification(_selectedDate, _selectedTime, _taskController.text);
        _taskController.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks[_selectedDate]?.removeAt(index);
      if (_tasks[_selectedDate]?.isEmpty == true) {
        _tasks.remove(_selectedDate);
      }
    });
  }
}