import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'todo.dart'; // todo.dart 파일 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All Care',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스를 저장
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 각 탭에 표시될 위젯 목록
  List<Widget> _widgetOptions(DateTime? selectedDay) {
    return <Widget>[
      TodoPage(selectedDate: selectedDay ?? DateTime.now()), // todo 페이지의 추가 콘텐츠
      const Text('Nutrition Page'),
      const Text('My Page'),
    ];
  }

  // 탭이 선택되었을 때 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 캘린더 위젯을 빌드하는 함수
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day); // 현재 선택된 날짜인지 확인
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay; // 선택된 날짜 업데이트
            _focusedDay = focusedDay; // 캘린더에 표시되는 달(몇월인지) 업데이트
          });
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format; // 캘린더 형식 업데이트
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay; // 페이지가 변경될 때 캘린더에 표시된 달 업데이트
      },
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.black),
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
        ),
        defaultDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey.withOpacity(0.1),
        ),
        weekendDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey.withOpacity(0.1),
        ),
        outsideDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10.0),
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekendStyle: TextStyle(color: Colors.red),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Care'),
      ),
      body: Column(
        children: <Widget>[
          if (_selectedIndex != 2) // My 페이지가 선택되지 않은 경우에만 캘린더 표시
            _buildCalendar(),
          Expanded(
            child: Center(
              child: _widgetOptions(_selectedDay).elementAt(_selectedIndex), // 현재 선택된 탭의 추가 콘텐츠 표시
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Todo',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.pills),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'My',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped, // 탭이 선택되었을 때 호출되는 콜백 함수
      ),
    );
  }
}


bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
