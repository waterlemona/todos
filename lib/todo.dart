  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

  // Todo 모델 클래스
  class Todo {
    String id;
    String title;
    final DateTime date;
    String? memo;
    TimeOfDay? alarmTime;
    String? repeat;
    bool isDone;

    Todo({
      this.id = '',
      required this.title,
      required this.date,
      this.memo,
      this.alarmTime,
      this.repeat,
      this.isDone = false,
    });

    // Firestore에서 가져온 데이터를 Map으로 변환
    Map<String, dynamic> toMap() {
      return {
        'title': title,
        'date': Timestamp.fromDate(date),  // DateTime을 Timestamp로 변환
        'memo': memo,
        'alarmTime': alarmTime != null
            ? {'hour': alarmTime!.hour, 'minute': alarmTime!.minute}
            : null,
        'repeat': repeat,
        'isDone': isDone,
      };
    }


    // Firestore의 데이터를 Todo 객체로 변환
    static Todo fromFirestore(DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Todo(
        id: doc.id,
        title: data['title'],
        date: (data['date'] as Timestamp).toDate(),
        memo: data['memo'],
        alarmTime: data['alarmTime'] != null
            ? TimeOfDay(
          hour: data['alarmTime']['hour'],
          minute: data['alarmTime']['minute'],
        )
            : null,
        repeat: data['repeat'],
        isDone: data['isDone'],
      );
    }
  }

  // TodoPage 수정: 콜백 함수 추가
  class TodoPage extends StatefulWidget {
    final DateTime selectedDate;
    final Function(Todo) onTodoAdded;
    final Function(Todo) onTodoRemoved;
    final Function(List<Todo>) onTodoListChanged; // 할 일 목록 변경 콜백

    TodoPage({
      required this.selectedDate,
      required this.onTodoAdded,
      required this.onTodoRemoved,
      required this.onTodoListChanged,
    });

    @override
    _TodoPageState createState() => _TodoPageState();
  }

  class _TodoPageState extends State<TodoPage> {
    // 할 일 목록 (Firestore에서 가져온 데이터 저장)
    List<Todo> _todoList = [];

    @override
    void initState() {
      super.initState();
      _loadTodos(); // 앱 시작 시 Firestore에서 데이터 불러오기
    }

    void _updateTodoList() {
      widget.onTodoListChanged(_todoList); // 콜백 함수 호출
    }
    Future<void> _updateTodoInFirestore(Todo todo) async {
      final todoCollection = FirebaseFirestore.instance.collection('todos');
      try {
        await todoCollection.doc(todo.id).update(todo.toMap());
      } catch (e) {
        print("Error updating todo: $e");
      }
    }
    // Firestore에서 할 일 목록 읽기
    Future<void> _loadTodos() async {
      final todoCollection = FirebaseFirestore.instance.collection('todos');
      QuerySnapshot snapshot = await todoCollection.get();

      setState(() {
        _todoList = snapshot.docs
            .map((doc) => Todo.fromFirestore(doc))  // Firestore에서 Todo 객체로 변환
            .toList();
        _updateTodoList();
      });
      widget.onTodoListChanged(_todoList); // 상위 위젯에 변경 알림
    }

    // Firestore에 할 일 추가
    Future<void> _addTodoToFirestore(Todo todo) async {
      final todoCollection = FirebaseFirestore.instance.collection('todos');
      try {
        DocumentReference docRef = await todoCollection.add(todo.toMap());
        setState(() {
          todo.id = docRef.id;  // Firestore에서 생성된 ID를 Todo에 저장
        });
      } catch (e) {
        print("Error adding todo: $e");
      }
    }

    // Firestore에서 할 일 삭제
    Future<void> _deleteTodoFromFirestore(String todoId) async {
      final todoCollection = FirebaseFirestore.instance.collection('todos');
      try {
        await todoCollection.doc(todoId).delete();
      } catch (e) {
        print("Error deleting todo: $e");
      }
    }

    @override
    Widget build(BuildContext context) {
      final filteredTodoList = _todoList.where((todo) => isSameDay(todo.date, widget.selectedDate)).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text('Todo'),
        ),
        body: ListView.builder(
          itemCount: filteredTodoList.length,
          itemBuilder: (context, index) {
            final todo = filteredTodoList[index];
            return Dismissible(
              key: Key(todo.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                setState(() {
                  _todoList.remove(todo);
                });
                widget.onTodoRemoved(todo); // 할 일 삭제 콜백 호출
                _deleteTodoFromFirestore(todo.id); // Firestore에서 할 일 삭제
                _updateTodoList();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${todo.title} 삭제됨')),
                );
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                trailing: _buildTrailingButtons(todo),
                onTap: () => _showTodoDetails(context, todo),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addNewTodoDialog(),
          child: Icon(Icons.add),
        ),
      );
    }

    // 할 일 항목의 우측 버튼 구성
    Widget _buildTrailingButtons(Todo todo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditTitleDialog(context, todo),
          ),
          Checkbox(
            value: todo.isDone,
            onChanged: (bool? value) async {
              setState(() {
                todo.isDone = value ?? false;
              });
              await _updateTodoInFirestore(todo);
              _updateTodoList();
            },
          ),
        ],
      );
    }

  // 제목 수정 다이얼로그
  void _showEditTitleDialog(BuildContext context, Todo todo) {
    TextEditingController _controller = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('타이틀 수정'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: '새로운 타이틀'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('수정'),
              onPressed: () {
                setState(() {
                  todo.title = _controller.text;
                });
                _updateTodoList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 할 일 상세 보기
  void _showTodoDetails(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(todo.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildMemoField(todo),
              SizedBox(height: 10),
              _buildAlarmAndRepeatRow(todo),
              SizedBox(height: 20),
              _buildCompletionButton(todo),
              Divider(),
              _buildDeleteButton(todo),
            ],
          ),
        ),
      ),
    );
  }

  // 메모 입력 필드
  Widget _buildMemoField(Todo todo) {
    return TextFormField(
      initialValue: todo.memo,
      onChanged: (value) => setState(() {
        todo.memo = value.trim().isEmpty ? null : value;
        _updateTodoList();
      }),
      decoration: InputDecoration(
        hintText: todo.memo?.isEmpty ?? true ? '메모' : '',
        hintStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      maxLines: 3,
    );
  }

  // 알림 및 반복 설정 버튼
  Widget _buildAlarmAndRepeatRow(Todo todo) {
    return Row(
      children: [
        _buildAlarmOption(todo),
        SizedBox(width: 10),
        _buildRepeatOption(todo),
      ],
    );
  }

  // 알림 옵션 생성 함수
  Widget _buildAlarmOption(Todo todo) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAlarmTime(context, todo),
        child: _buildOptionBox(
          icon: Icons.alarm,
          text: todo.alarmTime != null ? '${todo.alarmTime!.hour}:${todo.alarmTime!.minute}' : '알림 시간',
        ),
      ),
    );
  }

  // 반복 옵션 생성 함수
  Widget _buildRepeatOption(Todo todo) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectRepeatOption(context, todo),
        child: _buildOptionBox(
          icon: Icons.repeat,
          text: todo.repeat ?? '반복 설정',
        ),
      ),
    );
  }

  // 알림 시간 선택기
  Future<void> _selectAlarmTime(BuildContext context, Todo todo) async {
    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: todo.alarmTime ?? TimeOfDay.now(),
    );
    if (newTime != null) {
      setState(() {
        todo.alarmTime = newTime;
        _updateTodoList();
      });
    }
  }

  // 반복 옵션 선택기
  Future<void> _selectRepeatOption(BuildContext context, Todo todo) async {
    String? selectedRepeat = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('반복 설정'),
          children: [
            SimpleDialogOption(child: Text('매일'), onPressed: () => Navigator.pop(context, '매일')),
            SimpleDialogOption(child: Text('매주'), onPressed: () => Navigator.pop(context, '매주')),
            SimpleDialogOption(child: Text('매월'), onPressed: () => Navigator.pop(context, '매월')),
            SimpleDialogOption(child: Text('반복 안 함'), onPressed: () => Navigator.pop(context, null)),
          ],
        );
      },
    );
    if (selectedRepeat != null) {
      setState(() {
        todo.repeat = selectedRepeat;
        _updateTodoList();
      });
    }
  }

  // 옵션 박스 스타일링
  Widget _buildOptionBox({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  // 완료 버튼
  Widget _buildCompletionButton(Todo todo) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          todo.isDone = !todo.isDone;
        });
        await _updateTodoInFirestore(todo);
        _updateTodoList();
      },
      child: Text(todo.isDone ? '완료 취소' : '완료하기'),
    );
  }

  // 할 일 삭제 버튼
  Widget _buildDeleteButton(Todo todo) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _todoList.remove(todo);
        });
        widget.onTodoRemoved(todo);  // 삭제된 할 일 콜백 호출
        _deleteTodoFromFirestore(todo.id);
        _updateTodoList();
        Navigator.pop(context);
      },
      child: Text('삭제'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, ),

    );
  }

  // 새 할 일 추가 다이얼로그
  // 새 할 일 추가 다이얼로그
  void _addNewTodoDialog() {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 할 일 추가'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: '할 일 제목'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () async {
                String title = _controller.text.trim();

                if (title.isNotEmpty) {
                  // 새로운 할 일 생성
                  Todo newTodo = Todo(
                    title: title,
                    date: widget.selectedDate,
                  );

                  try {
                    // Firestore에 새로운 할 일 추가 후 setState 호출
                    await _addTodoToFirestore(newTodo);  // Firestore에 추가
                    setState(() {
                      _todoList.add(newTodo); // 할 일 목록에 추가
                    });
                    widget.onTodoAdded(newTodo); // 새 할 일 추가 콜백 호출
                    Navigator.of(context).pop();
                  } catch (e) {
                    // 오류 처리
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('오류가 발생했습니다: $e'))
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('할 일 제목을 입력해주세요!'))
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
