import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class Session {
  String id;
  String title;
  DateTime date;
  String note;
  Session({required this.id, required this.title, required this.date, this.note = ''});
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'note': note,
      };
  factory Session.fromMap(Map<String, dynamic> m) => Session(
        id: m['id'],
        title: m['title'],
        date: DateTime.parse(m['date']),
        note: m['note'] ?? '',
      );
}

class TaskItem {
  String id;
  String text;
  bool done;
  TaskItem({required this.id, required this.text, this.done = false});
  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};
  factory TaskItem.fromMap(Map<String, dynamic> m) => TaskItem(id: m['id'], text: m['text'], done: m['done'] ?? false);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ana Bas',
      themeMode: ThemeMode.dark,
      theme: ThemeData.light(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFF0B0F14),
        cardColor: Color(0xFF111418),
        textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white70)),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0B0F14),
          elevation: 0,
        ),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Session> sessions = [];
  List<TaskItem> tasks = [];
  String quote = "Quote of the day - tap to edit";
  late SharedPreferences prefs;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('sessions') ?? '[]';
    final t = prefs.getString('tasks') ?? '[]';
    final q = prefs.getString('quote') ?? quote;
    final listS = jsonDecode(s) as List;
    final listT = jsonDecode(t) as List;
    setState(() {
      sessions = listS.map((e) => Session.fromMap(e)).toList();
      tasks = listT.map((e) => TaskItem.fromMap(e)).toList();
      quote = q;
    });
  }

  Future<void> _saveSessions() async {
    final encoded = jsonEncode(sessions.map((e) => e.toMap()).toList());
    await prefs.setString('sessions', encoded);
  }

  Future<void> _saveTasks() async {
    final encoded = jsonEncode(tasks.map((e) => e.toMap()).toList());
    await prefs.setString('tasks', encoded);
  }

  List<Session> get todaysSessions {
    final now = DateTime.now();
    return sessions.where((s) {
      return s.date.year == now.year && s.date.month == now.month && s.date.day == now.day;
    }).toList()..sort((a,b)=>a.date.compareTo(b.date));
  }

  Future<void> _addSession() async {
    final titleController = TextEditingController();
    DateTime selected = DateTime.now();
    String note = '';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Add session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              SizedBox(height: 8),
              Row(children: [
                Flexible(child: Text('Date: ${selected.toLocal().toString().split(' ')[0]} ${selected.hour.toString().padLeft(2,'0')}:${selected.minute.toString().padLeft(2,'0')}')),
                SizedBox(width: 8),
                TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: selected, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selected));
                        if (t != null) {
                          selected = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                          setSt(() {});
                        }
                      }
                    },
                    child: Text('Change'))
              ]),
              TextField(
                decoration: InputDecoration(labelText: 'Note (optional)'),
                onChanged: (v) => note = v,
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  final s = Session(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      date: selected,
                      note: note);
                  setState(() {
                    sessions.add(s);
                  });
                  _saveSessions();
                  Navigator.pop(ctx);
                },
                child: Text('Add'))
          ],
        );
      }),
    );
  }

  Future<void> _addTask() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Add Task'),
        content: TextField(controller: c, decoration: InputDecoration(labelText: 'Task')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (c.text.trim().isEmpty) return;
                final t = TaskItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: c.text.trim());
                setState(() => tasks.add(t));
                _saveTasks();
                Navigator.pop(ctx);
              },
              child: Text('Add'))
        ],
      ),
    );
  }

  Future<void> _editQuote() async {
    final c = TextEditingController(text: quote);
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text('Set quote of the day'),
              content: TextField(controller: c),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      setState(() => quote = c.text.trim());
                      prefs.setString('quote', quote);
                      Navigator.pop(context);
                    },
                    child: Text('Save'))
              ],
            ));
  }

  Future<void> _deleteSession(String id) async {
    setState(() => sessions.removeWhere((s) => s.id == id));
    await _saveSessions();
  }

  Future<void> _toggleTaskDone(String id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    setState(() => tasks[idx].done = !tasks[idx].done);
    await _saveTasks();
  }

  Future<void> _deleteTask(String id) async {
    setState(() => tasks.removeWhere((t) => t.id == id));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final today = todaysSessions;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Bas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Sessions'), Tab(text: 'Tasks')],
        ),
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _editQuote),
        ],
      ),
      body: Column(
        children: [
          // Banner quote
          GestureDetector(
            onTap: _editQuote,
            child: Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.format_quote),
                  SizedBox(width: 12),
                  Expanded(child: Text(quote, style: TextStyle(fontSize: 16))),
                  Icon(Icons.edit, size: 18)
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sessions Tab
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Expanded(
                        child: today.isEmpty
                            ? Center(child: Text('No sessions for today'))
                            : ListView.builder(
                                itemCount: today.length,
                                itemBuilder: (_, i) {
                                  final s = today[i];
                                  final time = "${s.date.hour.toString().padLeft(2,'0')}:${s.date.minute.toString().padLeft(2,'0')}";
                                  return Card(
                                    child: ListTile(
                                      title: Text(s.title),
                                      subtitle: Text("$time — ${s.note}"),
                                      trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteSession(s.id)),
                                    ),
                                  );
                                }),
                      ),
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          ElevatedButton.icon(onPressed: _addSession, icon: Icon(Icons.add), label: Text('Add Session'))
                        ],
                      )
                    ],
                  ),
                ),

                // Tasks Tab
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Expanded(
                        child: tasks.isEmpty
                            ? Center(child: Text('No tasks yet'))
                            : ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (_, i) {
                                  final t = tasks[i];
                                  return Card(
                                    child: ListTile(
                                      leading: Checkbox(value: t.done, onChanged: (_) => _toggleTaskDone(t.id)),
                                      title: Text(t.text, style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null)),
                                      trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteTask(t.id)),
                                    ),
                                  );
                                }),
                      ),
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          ElevatedButton.icon(onPressed: _addTask, icon: Icon(Icons.add), label: Text('Add Task'))
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}