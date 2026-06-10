// 할 일 화면 분리 완료
import 'package:flutter/material.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // 할 일 데이터 상태 관리 (임시 데이터)
  final List<Map<String, dynamic>> _todoList = [
    {'task': '대충 세운 계획 1', 'isDone': false},
    {'task': '대충 세운 계획 2', 'isDone': false},
    {'task': '대충 세운 계획 3', 'isDone': false},
  ];

  // 체크박스 클릭 시 상태 업데이트
  void _toggleTodo(int index, bool? value) {
    setState(() {
      _todoList[index]['isDone'] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity, // 가로 너비를 화면에 꽉 채우도록 보장
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '오늘의 할 일',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: _todoList[index]['isDone'],
                    onChanged: (bool? value) => _toggleTodo(index, value),
                  ),
                  title: Text(
                    _todoList[index]['task'],
                    style: TextStyle(
                      // 체크되면 회색 및 취소선 처리
                      decoration: _todoList[index]['isDone']
                          ? TextDecoration.lineThrough
                          : null,
                      color: _todoList[index]['isDone']
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
