import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget{
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>{
  final TextEditingController _controller = TextEditingController();
  List<String> tasks = [];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Tareas')),
      body: Column(
        children: [
          Padding(
            padding:const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ingrese una tarea',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                  )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index){
                return ListTile(
                  title: Text(tasks[index]),
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

  void _addTask(){
    if(_controller.text.isNotEmpty){
      setState(() {
        tasks.add(_controller.text);
        _controller.clear();
      });
    }
  }

  void _removeTask(int index){
    setState(() {
      tasks.removeAt(index);
    });
  }
}
