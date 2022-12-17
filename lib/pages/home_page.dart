import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List toDoList = [];
  final toDoController = TextEditingController();
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedIdx;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = toDoController.text;
      toDoController.text = "";
      newToDo["ok"] = false;
      toDoList.add(newToDo);

      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    final data = json.encode(toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return "Erro!";
    }
  }

  Widget _buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
            alignment: Alignment(-0.9, 0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            )),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(toDoList[index]);
          _lastRemovedIdx = index;
          toDoList.removeAt(index);

          _saveData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
              action: SnackBarAction(
                label: 'Desfazer',
                textColor: Colors.blueAccent,
                onPressed: () {
                  setState(
                    () {
                      toDoList.insert(_lastRemovedIdx, _lastRemoved);
                      _saveData();
                    },
                  );
                },
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        });
      },
      child: CheckboxListTile(
        value: toDoList[index]["ok"],
        onChanged: (value) {
          setState(() {
            toDoList[index]["ok"] = value;

            _saveData();
          });
        },
        title: Text(toDoList[index]["title"]),
        secondary: CircleAvatar(
            child: toDoList[index]["ok"]
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                  )),
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      toDoList.sort(
        (a, b) {
          if(a["ok"] && !b["ok"]){
            return 1;
          } else if(!a["ok"] && b["ok"]){
            return -1;
          }else {
            return 0;
          }
        },
      );
      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To do list"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 17),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: toDoController,
                    decoration: const InputDecoration(
                      label: Text('Nova tarefa'),
                      labelStyle: TextStyle(
                        color: Colors.deepPurple,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                ElevatedButton(
                  onPressed: _addToDo,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: toDoList.length,
                itemBuilder: _buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
