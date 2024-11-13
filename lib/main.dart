import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'todo.dart';
import 'nut.dart';
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
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  int _selectedIndex = 0;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _widgetOptions = [
      TodoPage(selectedDate: _selectedDay!),
      NutPage(selectedDate: _selectedDay!), // Nut 페이지 추가
      const Text('My Page'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          // Todo 페이지의 선택된 날짜 업데이트
          _widgetOptions[0] = TodoPage(selectedDate: selectedDay);
          // Nut 페이지의 선택된 날짜 업데이트
          _widgetOptions[1] = NutPage(selectedDate: selectedDay);
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.black),
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.Rectangle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.Rectangle,
        ),
        defaultDecoration: BoxDecoration(
          shape: BoxShape.Rectangle,
          color: Colors.grey.withOpacity(0.1),
        ),
        weekendDecoration: BoxDecoration(
          shape: BoxShape.Rectangle,
          color: Colors.grey.withOpacity(0.1),
        ),
        outsideDecoration: const BoxDecoration(shape: Retangle.circle),
        markerDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.Rectangle,
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
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          if (_selectedIndex != 2) _buildCalendar(),
          Expanded(
            child: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
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
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
