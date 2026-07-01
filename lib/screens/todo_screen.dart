import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bouncing_wrapper.dart';
import '../pixel_emoji.dart';
import '../translations.dart';
import '../theme_manager.dart';
import '../services/notification_service.dart';

class TodoScreen extends StatefulWidget {
  final VoidCallback? onSecretCommand;
  final VoidCallback? onUnlockAllCommand;

  const TodoScreen({super.key, this.onSecretCommand, this.onUnlockAllCommand});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 💡 탭을 전환해도 화면(데이터)을 파괴하지 않고 유지

  DateTime _selectedDate = DateTime.now();

  // 💡 무한 스크롤(PageView)을 위해 특정 기준일부터의 차이(일수)를 인덱스로 변환합니다.
  final DateTime _baseDate = DateTime.utc(2020, 1, 1);
  late final PageController _datePageController = PageController(
    initialPage: _dateToIndex(_selectedDate),
  );

  // 💡 카테고리별 색상 정의 (도트 감성에 어울리는 쨍한 색상)
  late final Map<String, Color> _categoryColors = Map.from(AppTheme.defaultCategoryColors);

  // 전체 할 일 목록 (날짜 및 카테고리 포함)
  final List<Map<String, dynamic>> _todoList = [];

  // 💡 반복되는 할 일 루틴 목록
  final List<Map<String, dynamic>> _routines = [];

  int _dateToIndex(DateTime date) {
    // 일광절약시간(DST) 문제를 방지하기 위해 강제로 UTC로 계산
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return utcDate.difference(_baseDate).inDays;
  }

  DateTime _indexToDate(int index) {
    final utcDate = _baseDate.add(Duration(days: index));
    return DateTime(utcDate.year, utcDate.month, utcDate.day);
  }

  @override
  void initState() {
    super.initState();
    _loadData(); // 앱 실행 시 저장된 데이터 불러오기
  }

  @override
  void dispose() {
    _datePageController.dispose();
    super.dispose();
  }

  // --- 💡 기기 저장소(SharedPreferences) 연동 로직 ---
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 커스텀 카테고리 불러오기
      final String? categoriesStr = prefs.getString('categories');
      if (categoriesStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(categoriesStr);
        setState(() {
          _categoryColors.clear();
          decoded.forEach((key, value) {
            _categoryColors[key] = Color(
              (value as num).toInt(),
            ); // 💡 안전한 숫자 변환
          });
        });
      }

      // 2. 할 일 목록 불러오기
      final String? todosStr = prefs.getString('todos');
      if (todosStr != null) {
        final List<dynamic> decoded = jsonDecode(todosStr);
        bool needsSave = false;
        setState(() {
          _todoList.clear();
          for (var item in decoded) {
            final map = Map<String, dynamic>.from(item);
            if (map['id'] == null) {
              map['id'] = ((DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF) - _todoList.length - (item.hashCode & 0xFFFFF)).abs();
              needsSave = true;
            }
            // JSON에 저장할 수 없는 TimeOfDay 객체를 문자열에서 다시 복구
            if (map['time'] != null && map['time'].toString().contains(':')) {
              final parts = map['time'].toString().split(':');
              map['time'] = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            if (map['alarmTime'] != null &&
                map['alarmTime'].toString().contains(':')) {
              final parts = map['alarmTime'].toString().split(':');
              map['alarmTime'] = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            _todoList.add(map);
          }
        });
        if (needsSave) {
          _saveData();
        }
      } else {
        _setInitialData();
      }

      // 3. 루틴 목록 불러오기
      final String? routinesStr = prefs.getString('routines');
      if (routinesStr != null) {
        final List<dynamic> decoded = jsonDecode(routinesStr);
        setState(() {
          _routines.clear();
          for (var item in decoded) {
            final map = Map<String, dynamic>.from(item);
            if (map['alarmTime'] != null && map['alarmTime'].toString().contains(':')) {
              final parts = map['alarmTime'].toString().split(':');
              map['alarmTime'] = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            if (map['repeatDays'] != null) {
              map['repeatDays'] = List<int>.from(map['repeatDays']);
            } else {
              map['repeatDays'] = <int>[];
            }
            _routines.add(map);
          }
        });
      }

      // 데이터 로드 완료 후 현재 선택된 날짜에 루틴 동기화 실행
      _syncRoutinesForDate(_selectedDate);

    } catch (e) {
      debugPrint('투두 데이터 로드 에러: $e');
      _setInitialData(); // 에러 발생 시 임시 데이터로 안전하게 덮어쓰기
    }
  }

  void _setInitialData() {
    setState(() {
      _todoList.clear();
      _routines.clear();
    });
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 카테고리 저장
    final encodedCategories = _categoryColors.map(
      (key, value) => MapEntry(key, value.toARGB32()), // 💡 최신 SDK 권장 방식 적용
    );
    await prefs.setString('categories', jsonEncode(encodedCategories));

    // 2. 할 일 목록 저장
    final encodedTodos = _todoList.map((todo) {
      final copy = Map<String, dynamic>.from(todo);
      // JSON에 저장할 수 없는 TimeOfDay 객체를 문자열("HH:mm")로 변환
      if (copy['time'] != null) {
        final t = copy['time'] as TimeOfDay;
        copy['time'] = '${t.hour}:${t.minute}';
      }
      if (copy['alarmTime'] != null) {
        final t = copy['alarmTime'] as TimeOfDay;
        copy['alarmTime'] = '${t.hour}:${t.minute}';
      }
      return copy;
    }).toList();
    await prefs.setString('todos', jsonEncode(encodedTodos));

    // 3. 루틴 목록 저장
    final encodedRoutines = _routines.map((routine) {
      final copy = Map<String, dynamic>.from(routine);
      if (copy['alarmTime'] != null) {
        final t = copy['alarmTime'] as TimeOfDay;
        copy['alarmTime'] = '${t.hour}:${t.minute}';
      }
      return copy;
    }).toList();
    await prefs.setString('routines', jsonEncode(encodedRoutines));
  }

  // 💡 선택된 날짜의 루틴 동기화 로직
  void _syncRoutinesForDate(DateTime date) {
    final dateStr = _formatDate(date);
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday

    // 이미 해당 날짜에 등록된 루틴 ID 목록
    final existingRoutineIds = _todoList
        .where((todo) => todo['date'] == dateStr && todo['routineId'] != null)
        .map((todo) => todo['routineId'] as int)
        .toSet();

    bool updated = false;
    for (var routine in _routines) {
      // 💡 시작일/종료일 기간 확인
      final String? startDateStr = routine['startDate'];
      final String? endDateStr = routine['endDate'];
      final checkDate = DateTime(date.year, date.month, date.day);

      if (startDateStr != null) {
        final startParts = startDateStr.split('-');
        if (startParts.length == 3) {
          final start = DateTime(
            int.parse(startParts[0]),
            int.parse(startParts[1]),
            int.parse(startParts[2]),
          );
          if (checkDate.isBefore(start)) {
            continue; // 시작일 이전이면 추가하지 않음
          }
        }
      }

      if (endDateStr != null) {
        final endParts = endDateStr.split('-');
        if (endParts.length == 3) {
          final end = DateTime(
            int.parse(endParts[0]),
            int.parse(endParts[1]),
            int.parse(endParts[2]),
          );
          if (checkDate.isAfter(end)) {
            continue; // 종료일 이후면 추가하지 않음
          }
        }
      }

      final List<int> repeatDays = List<int>.from(routine['repeatDays'] ?? []);
      // repeatDays가 비어있으면 매일 반복, 또는 해당 요일이 포함되어 있으면
      if (repeatDays.isEmpty || repeatDays.contains(weekday)) {
        final int routineId = routine['id'] as int;
        if (!existingRoutineIds.contains(routineId)) {
          // 새로 추가
          final newTodo = {
            'id': ((DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF) - _todoList.length - (routine.hashCode & 0xFFFFF)).abs(),
            'task': routine['task'],
            'category': routine['category'] ?? '기본'.tr,
            'isDone': false,
            'date': dateStr,
            'isAlarmOn': routine['isAlarmOn'] ?? false,
            'alarmTime': routine['alarmTime'],
            'routineId': routineId,
          };
          setState(() {
            _todoList.add(newTodo);
          });
          _scheduleTodoNotification(newTodo);
          updated = true;
        }
      }
    }

    if (updated) {
      _saveData();
    }
  }

  void _scheduleTodoNotification(Map<String, dynamic> todo) async {
    if (todo['isAlarmOn'] != true || todo['alarmTime'] == null || todo['isDone'] == true) {
      return;
    }
    try {
      final dateParts = todo['date'].toString().split('-');
      if (dateParts.length != 3) return;
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final TimeOfDay alarmTime = todo['alarmTime'] as TimeOfDay;
      final scheduledDateTime = DateTime(year, month, day, alarmTime.hour, alarmTime.minute);

      if (scheduledDateTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: todo['id'] as int,
          title: '할 일 알림'.tr,
          body: todo['task']?.toString() ?? '',
          scheduledDate: scheduledDateTime,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  void _cancelTodoNotification(int id) async {
    try {
      await NotificationService().cancelNotification(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // 날짜 포맷팅 함수 (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatLocalizedDate(DateTime date) {
    return '%s년 %s월 %s일'.trArgs([
      date.year.toString(),
      date.month.toString(),
      date.day.toString(),
    ]);
  }

  // 현재 선택된 날짜의 할 일 (위쪽 프로그레스 바 통계 용도)
  List<Map<String, dynamic>> get _currentTodos =>
      _getTodosForDate(_selectedDate);

  // 💡 특정 날짜의 할 일을 필터링하고 정렬하는 메서드
  List<Map<String, dynamic>> _getTodosForDate(DateTime date) {
    final dateStr = _formatDate(date);
    final filteredList = _todoList
        .where((todo) => todo['date'] == dateStr)
        .toList();

    // 카테고리 이름(가나다순)을 기준으로 정렬
    filteredList.sort((a, b) {
      final catA = a['category']?.toString() ?? '';
      final catB = b['category']?.toString() ?? '';
      final catCompare = catA.compareTo(catB);

      if (catCompare != 0) return catCompare; // 1. 카테고리 가나다순 우선 정렬

      // 2. 같은 카테고리 내에서는 완료(체크)된 항목을 맨 아래로
      final bool isDoneA = a['isDone'] == true;
      final bool isDoneB = b['isDone'] == true;
      if (isDoneA && !isDoneB) return 1;
      if (!isDoneA && isDoneB) return -1;
      return 0;
    });
    return filteredList;
  }

  // 공통 안내 팝업창
  void _showNoticeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '알림'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RetroGradientButton(
                    color: Colors.grey[300]!,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '닫기'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. 체크박스 상태 토글
  void _toggleTodo(int originalIndex, bool value) {
    setState(() {
      _todoList[originalIndex]['isDone'] = value;
    });
    _saveData(); // 상태 변경 시 저장

    final todo = _todoList[originalIndex];
    if (value) {
      if (todo['id'] != null) {
        _cancelTodoNotification(todo['id'] as int);
      }
    } else {
      _scheduleTodoNotification(todo);
    }
  }

  // 2. 할 일 추가/수정 바텀 시트
  void _showTodoEditorBottomSheet({int? editIndex}) {
    final bool isEdit = editIndex != null;
    final int safeIndex = editIndex ?? 0; // 컴파일러가 헷갈리지 않게 확실한 int 타입으로 캐스팅
    final Map<String, dynamic>? existingTodo = isEdit
        ? _todoList[safeIndex]
        : null;

    String newTask = existingTodo?['task']?.toString() ?? '';
    String selectedCategory =
        existingTodo?['category']?.toString() ??
        (_categoryColors.keys.isNotEmpty
            ? _categoryColors.keys.first
            : '없음'.tr);
    TimeOfDay? selectedTime = existingTodo?['time'] as TimeOfDay?;
    TimeOfDay? selectedAlarmTime = existingTodo?['alarmTime'] as TimeOfDay?;
    bool isAlarmOn = existingTodo?['isAlarmOn'] == true;
    String newLocation = existingTodo?['location']?.toString() ?? '';
    String newMemo = existingTodo?['memo']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom, // 키보드 올라올 때 가리지 않게
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEdit ? '할 일 수정 '.tr : '새로운 할 일 '.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const PixelEmoji('memo', size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: newTask,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        labelText: '할 일을 입력하세요'.tr,
                      ),
                      onChanged: (val) => newTask = val,
                    ),
                    const SizedBox(height: 16),
                    // --- ⏰ 시간 설정 ---
                    BouncingWrapper(
                      showShadow: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: RetroGradientButton(
                          color: Colors.white,
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setSheetState(() {
                                selectedTime = time;
                                selectedAlarmTime ??= time;
                              });
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime?.format(context) ?? '시간 설정'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- 🔔 알림 켜기/끄기 스위치 ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '알림 켜기'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAlarmOn ? Colors.black : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: isAlarmOn,
                          onChanged: (val) async {
                            if (val) {
                              await NotificationService().requestPermission();
                            }
                            setSheetState(() {
                              isAlarmOn = val;
                              if (val && selectedAlarmTime == null) {
                                selectedAlarmTime =
                                    selectedTime ?? TimeOfDay.now();
                              }
                            });
                          },
                          activeThumbColor: Colors.yellowAccent,
                          activeTrackColor: Colors.black,
                          inactiveTrackColor: Colors.grey[300],
                        ),
                      ],
                    ),
                    if (isAlarmOn) ...[
                      const SizedBox(height: 8),
                      BouncingWrapper(
                        showShadow: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: RetroGradientButton(
                            color: Colors.white,
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    selectedAlarmTime ??
                                    selectedTime ??
                                    TimeOfDay.now(),
                              );
                              if (time != null) {
                                setSheetState(() {
                                  selectedAlarmTime = time;
                                });
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_active,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedAlarmTime?.format(context) ??
                                      '알림 설정'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // --- 📍 장소 및 📝 메모 ---
                    TextFormField(
                      initialValue: newLocation,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        labelText: '장소 (선택)'.tr,
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: (val) => newLocation = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: newMemo,
                      maxLines: 2,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        labelText: '메모 (선택)'.tr,
                        prefixIcon: Icon(Icons.notes, color: Colors.black),
                      ),
                      onChanged: (val) => newMemo = val,
                    ),
                    const SizedBox(height: 20),
                    // --- 🏷️ 카테고리 ---
                    Text(
                      '카테고리'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categoryColors.keys.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.tr, // 💡 카테고리 이름 번역 (기본 카테고리인 경우)
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedCategory = cat);
                            }
                          },
                          selectedColor: Colors.black, // 선택 시 검은색 배경
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: BouncingWrapper(
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: RetroGradientButton(
                                color: Colors.grey[300]!,
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  '취소하기'.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BouncingWrapper(
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: RetroGradientButton(
                                color: Colors.black,
                                foregroundColor: Colors.white,
                                onPressed: () {
                                  // 💡 개발자 치트키 로직
                                  final trimmedTask = newTask
                                      .trim()
                                      .toLowerCase();
                                  if (trimmedTask == 'showmethemoney') {
                                    widget.onSecretCommand?.call();
                                    _showNoticeDialog(
                                      '쇼미더머니! 코인 1,000개가 지급되었습니다. 🪙'.tr,
                                    );
                                    Navigator.pop(context);
                                    return; // 일정으로 추가하지 않고 종료
                                  }

                                  // 💡 개발자 치트키 2: 모든 물고기/수초 해금
                                  if (trimmedTask == 'unlockall') {
                                    widget.onUnlockAllCommand?.call();
                                    _showNoticeDialog(
                                      '도감 100% 달성! 모든 물고기와 수초가 보관함에 추가되었습니다. 🐟🌿'
                                          .tr,
                                    );
                                    Navigator.pop(context);
                                    return; // 일정으로 추가하지 않고 종료
                                  }

                                  if (newTask.trim().isNotEmpty) {
                                    final int todoId = isEdit
                                        ? (_todoList[safeIndex]['id'] as int)
                                        : (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);

                                    // Cancel any existing scheduled notification for this ID
                                    _cancelTodoNotification(todoId);

                                    setState(() {
                                      if (isEdit) {
                                        _todoList[safeIndex]['task'] = newTask
                                            .trim();
                                        _todoList[safeIndex]['category'] =
                                            selectedCategory;
                                        _todoList[safeIndex]['time'] =
                                            selectedTime;
                                        _todoList[safeIndex]['alarmTime'] =
                                            selectedAlarmTime;
                                        _todoList[safeIndex]['isAlarmOn'] =
                                            isAlarmOn;
                                        _todoList[safeIndex]['location'] =
                                            newLocation.trim();
                                        _todoList[safeIndex]['memo'] = newMemo
                                            .trim();
                                      } else {
                                        _todoList.add({
                                          'id': todoId,
                                          'task': newTask.trim(),
                                          'isDone': false,
                                          'category': selectedCategory,
                                          'date': _formatDate(_selectedDate),
                                          'time': selectedTime,
                                          'alarmTime': selectedAlarmTime,
                                          'isAlarmOn': isAlarmOn,
                                          'location': newLocation.trim(),
                                          'memo': newMemo.trim(),
                                        });
                                      }
                                    });
                                    _saveData(); // 추가/수정 완료 시 저장

                                    // Schedule the new notification if needed
                                    if (isEdit) {
                                      _scheduleTodoNotification(_todoList[safeIndex]);
                                    } else {
                                      _scheduleTodoNotification(_todoList.last);
                                    }

                                    Navigator.pop(context); // 💡 바텀 시트를 먼저 닫음
                                    if (isAlarmOn &&
                                        selectedAlarmTime != null) {
                                      _showNoticeDialog(
                                        '%s에 알림이 %s되었습니다! 🔔'.trArgs([
                                          selectedAlarmTime!.format(context),
                                          isEdit ? '수정'.tr : '설정'.tr,
                                        ]),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  isEdit ? '수정하기'.tr : '추가하기'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 할 일 상세 보기 바텀 시트 (수정 가능)
  void _showTodoDetailBottomSheet(int originalIndex) {
    final todo = _todoList[originalIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _categoryColors[todo['category']?.toString()] ??
                          Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (todo['category']?.toString() ?? '').tr, // 💡 카테고리명 번역
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                todo['task']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (todo['time'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '시간: %s'.trArgs([
                        (todo['time'] as TimeOfDay).format(context),
                      ]), // 💡 시간 표시 번역
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (todo['isAlarmOn'] == true && todo['alarmTime'] != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      size: 20,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '알림 설정됨 (%s)'.trArgs([
                        (todo['alarmTime'] as TimeOfDay).format(context),
                      ]),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (todo['location'] != null &&
                  todo['location'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '장소: %s'.trArgs([todo['location']]),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (todo['memo'] != null &&
                  todo['memo'].toString().isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '메모:\n%s'.trArgs([todo['memo']]),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BouncingWrapper(
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: RetroGradientButton(
                          color: Colors.redAccent,
                          foregroundColor: Colors.white,
                          onPressed: () {
                            final todo = _todoList[originalIndex];
                            final todoId = todo['id'] as int?;
                            Navigator.pop(context); // 상세 뷰를 닫고
                            setState(() {
                              _todoList.removeAt(originalIndex);
                            });
                            _saveData(); // 삭제 후 저장
                            if (todoId != null) {
                              _cancelTodoNotification(todoId);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '삭제하기'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BouncingWrapper(
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: RetroGradientButton(
                          color: Colors.black,
                          foregroundColor: Colors.white,
                          onPressed: () {
                            Navigator.pop(context); // 상세 뷰를 닫고
                            _showTodoEditorBottomSheet(
                              editIndex: originalIndex,
                            ); // 에디터 열기
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '수정하기'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 3. 카테고리 관리 바텀 시트
  void _showCategoryManagerBottomSheet() {
    String newCategoryName = '';
    Color selectedColor = const Color(0xFFCF8ACB);

    // 선택 가능한 레트로 쨍한 색상 목록
    final List<Color> availableColors = [
      const Color(0xFF8AB060),
      const Color(0xFFC2D368),
      const Color(0xFF68C2D3),
      const Color(0xFFCF8ACB),
      const Color(0xFFCF8ACB),
      const Color(0xFFD3A068),
      const Color(0xFFE5CEB4),
      const Color(0xFF4B80CA),
      const Color(0xFFEDE19E),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '카테고리 관리 '.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PixelEmoji('tag', size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 기존 카테고리 목록
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryColors.entries.map((entry) {
                      return Chip(
                        label: Text(
                          entry.key.tr, // 💡 카테고리명 번역
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: entry.value,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          if (_categoryColors.length > 1) {
                            setSheetState(() {
                              _categoryColors.remove(entry.key);
                            });
                            setState(() {}); // 메인 화면도 갱신
                            _saveData(); // 카테고리 삭제 시 저장
                          } else {
                            _showNoticeDialog('최소 1개의 카테고리는 남겨둬야 합니다!'.tr);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.black, thickness: 2),
                  const SizedBox(height: 10),
                  Text(
                    '새 카테고리 추가'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      labelText: '새 카테고리 이름'.tr,
                    ),
                    onChanged: (val) => newCategoryName = val,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableColors.map((color) {
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: selectedColor == color
                                ? const [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(2, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  BouncingWrapper(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: RetroGradientButton(
                        color: Colors.black,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          if (newCategoryName.trim().isNotEmpty &&
                              !_categoryColors.containsKey(
                                newCategoryName.trim(),
                              )) {
                            setSheetState(() {
                              _categoryColors[newCategoryName.trim()] =
                                  selectedColor;
                            });
                            setState(() {}); // 메인 화면 갱신
                            _saveData(); // 카테고리 추가 시 저장
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          '카테고리 추가하기'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 💡 루틴 관리 바텀시트
  void _showRoutineManagerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final weekdaysMap = {
              1: '월'.tr,
              2: '화'.tr,
              3: '수'.tr,
              4: '목'.tr,
              5: '금'.tr,
              6: '토'.tr,
              7: '일'.tr,
            };

            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '루틴 관리'.tr,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.repeat, size: 22),
                          ],
                        ),
                        BouncingWrapper(
                          child: RetroGradientButton(
                            color: const Color(0xFF68C2D3),
                            foregroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            onPressed: () {
                              _showRoutineEditorBottomSheet();
                              Future.delayed(const Duration(milliseconds: 300), () {
                                setSheetState(() {});
                              });
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 16),
                                const SizedBox(width: 4),
                                Text('루틴 추가'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1.5, color: Colors.black),
                    Expanded(
                      child: _routines.isEmpty
                          ? Center(
                              child: Text(
                                '등록된 루틴이 없습니다.\n상단의 버튼을 눌러 추가해보세요!'.tr,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _routines.length,
                              itemBuilder: (context, index) {
                                final routine = _routines[index];
                                final List<int> repeatDays = List<int>.from(routine['repeatDays'] ?? []);
                                
                                String daysText = '';
                                if (repeatDays.isEmpty) {
                                  daysText = '매일'.tr;
                                } else {
                                  daysText = repeatDays.map((d) => weekdaysMap[d]).join(', ');
                                }

                                final category = routine['category']?.toString() ?? '기본'.tr;
                                final catColor = _categoryColors[category] ?? Colors.grey;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFF212123), offset: Offset(2, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: catColor,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: Text(
                                                    category,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  routine['task']?.toString() ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.repeat, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  daysText,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                                ),
                                                if (routine['isAlarmOn'] == true && routine['alarmTime'] != null) ...[
                                                  const SizedBox(width: 12),
                                                  const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(routine['alarmTime'] as TimeOfDay).hour.toString().padLeft(2, '0')}:${(routine['alarmTime'] as TimeOfDay).minute.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showRoutineEditorBottomSheet(editRoutine: routine);
                                          Future.delayed(const Duration(milliseconds: 300), () {
                                            setSheetState(() {});
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _routines.removeAt(index);
                                          });
                                          _saveData();
                                          setSheetState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: RetroGradientButton(
                        color: Colors.grey[300]!,
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '닫기'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 💡 루틴 등록/수정 에디터 바텀시트
  void _showRoutineEditorBottomSheet({Map<String, dynamic>? editRoutine}) {
    final bool isEdit = editRoutine != null;
    String task = editRoutine?['task']?.toString() ?? '';
    String selectedCategory = editRoutine?['category']?.toString() ??
        (_categoryColors.keys.isNotEmpty ? _categoryColors.keys.first : '없음'.tr);
    TimeOfDay? selectedAlarmTime = editRoutine?['alarmTime'] as TimeOfDay?;
    bool isAlarmOn = editRoutine?['isAlarmOn'] == true;
    List<int> repeatDays = editRoutine != null
        ? List<int>.from(editRoutine['repeatDays'])
        : [];
    String? startDate = editRoutine?['startDate']?.toString();
    if (startDate == null && !isEdit) {
      startDate = _formatDate(DateTime.now());
    }
    String? endDate = editRoutine?['endDate']?.toString();
 
    final weekdaysMap = {
      1: '월'.tr,
      2: '화'.tr,
      3: '수'.tr,
      4: '목'.tr,
      5: '금'.tr,
      6: '토'.tr,
      7: '일'.tr,
    };
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEdit ? '루틴 수정'.tr : '루틴 추가'.tr,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.repeat, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: task,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        labelText: '루틴으로 반복할 일 입력'.tr,
                      ),
                      onChanged: (val) => task = val,
                    ),
                    const SizedBox(height: 16),
                    // 카테고리 선택 Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('카테고리'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedCategory,
                          items: _categoryColors.keys.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: _categoryColors[cat],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 요일 반복 설정
                    Text('반복 요일'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // 💡 가운데 정렬로 모으기
                      children: weekdaysMap.entries.map((entry) {
                        final isSelected = repeatDays.contains(entry.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0), // 💡 좁은 간격 적용
                          child: BouncingWrapper(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    repeatDays.remove(entry.key);
                                  } else {
                                    repeatDays.add(entry.key);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF68C2D3) : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4), // 💡 외곽선 제거
                                ),
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repeatDays.isEmpty ? '매일 반복됩니다.'.tr : '선택한 요일에만 반복됩니다.'.tr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // 알림 설정
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined),
                            const SizedBox(width: 8),
                            Text('알림 설정'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: isAlarmOn,
                          onChanged: (val) {
                            setSheetState(() {
                              isAlarmOn = val;
                              if (isAlarmOn && selectedAlarmTime == null) {
                                selectedAlarmTime = const TimeOfDay(hour: 9, minute: 0);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (isAlarmOn) ...[
                      const SizedBox(height: 8),
                      BouncingWrapper(
                        showShadow: false,
                        child: RetroGradientButton(
                          color: Colors.white,
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedAlarmTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setSheetState(() => selectedAlarmTime = time);
                            }
                          },
                          child: Text(
                            selectedAlarmTime != null
                                ? '알림 시간: %s시 %s분'.trArgs([
                                    selectedAlarmTime!.hour.toString(),
                                    selectedAlarmTime!.minute.toString(),
                                  ])
                                : '알림 시간 선택'.tr,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // 💡 기간 설정
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('기간 설정'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('시작일'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              BouncingWrapper(
                                showShadow: false,
                                child: RetroGradientButton(
                                  color: Colors.white,
                                  onPressed: () async {
                                    final initialDate = startDate != null ? DateTime.parse(startDate!) : DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        startDate = _formatDate(picked);
                                      });
                                    }
                                  },
                                  child: Text(
                                    startDate != null ? startDate! : '설정 안 함'.tr,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('종료일'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  if (endDate != null)
                                    GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          endDate = null;
                                        });
                                      },
                                      child: const Icon(Icons.clear, size: 16, color: Colors.red),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              BouncingWrapper(
                                showShadow: false,
                                child: RetroGradientButton(
                                  color: Colors.white,
                                  onPressed: () async {
                                    final initialDate = endDate != null ? DateTime.parse(endDate!) : DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initialDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        endDate = _formatDate(picked);
                                      });
                                    }
                                  },
                                  child: Text(
                                    endDate != null ? endDate! : '설정 안 함'.tr,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: RetroGradientButton(
                        color: const Color(0xFF68C2D3),
                        foregroundColor: Colors.white,
                        onPressed: () {
                          if (task.trim().isEmpty) return;
                          final routineData = {
                            'id': editRoutine?['id'] ?? DateTime.now().millisecondsSinceEpoch,
                            'task': task.trim(),
                            'category': selectedCategory,
                            'isAlarmOn': isAlarmOn,
                            'alarmTime': selectedAlarmTime,
                            'repeatDays': repeatDays,
                            'startDate': startDate,
                            'endDate': endDate,
                          };

                          setState(() {
                            if (isEdit) {
                              final idx = _routines.indexWhere((r) => r['id'] == editRoutine['id']);
                              if (idx != -1) {
                                _routines[idx] = routineData;
                              }
                            } else {
                              _routines.add(routineData);
                            }
                          });
                          _saveData();
                          _syncRoutinesForDate(_selectedDate);
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEdit ? '수정 완료'.tr : '추가 완료'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. 커스텀 도트 달력 팝업 띄우기
  void _showPixelCalendar() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) =>
          _PixelCalendarDialog(initialDate: _selectedDate, todoList: _todoList),
    );

    if (picked != null && mounted) {
      _datePageController.animateToPage(
        _dateToIndex(picked),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필수 호출
    final currentTodos = _currentTodos;
    final total = currentTodos.length;
    final done = currentTodos.where((t) => t['isDone'] == true).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFE8E8E8)], // 💡 아주 옅은 그라데이션 배경
          ),
        ),
        child: Column(
          children: [
            // --- 1. 날짜 선택기 (Date Navigator) ---
            Container(
              color: Colors.transparent, // 💡 단색 흰색을 투명하게 변경하여 배경이 비치게 함
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  // 💡 오늘 날짜로 즉시 이동 버튼 (너비 고정하여 좌우 대칭 유지)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: BouncingWrapper(
                        showShadow: false,
                        child: GestureDetector(
                          onTap: () {
                            _datePageController.animateToPage(
                              _dateToIndex(DateTime.now()),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const PixelEmoji('calendar', size: 20),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 💡 왼쪽 화살표 (SizedBox 고정폭 + Center 정렬로 비대칭 해결)
                        BouncingWrapper(
                          showShadow: false,
                          child: GestureDetector(
                            onTap: () {
                              final newDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                              _datePageController.animateToPage(
                                _dateToIndex(newDate),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(Icons.arrow_back_ios_new, size: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        BouncingWrapper(
                          child: GestureDetector(
                            onTap: _showPixelCalendar,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: getRetroGradient(Colors.white),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PixelEmoji('calendar', size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatLocalizedDate(
                                      _selectedDate,
                                    ), // 💡 현지화된 날짜 형식
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 💡 오른쪽 화살표 (SizedBox 고정폭 + Center 정렬로 비대칭 해결)
                        BouncingWrapper(
                          showShadow: false,
                          child: GestureDetector(
                            onTap: () {
                              final newDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
                              _datePageController.animateToPage(
                                _dateToIndex(newDate),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(Icons.arrow_forward_ios, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 💡 루틴 관리 바텀시트 열기 버튼 (너비 고정하여 좌우 대칭 유지)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: BouncingWrapper(
                        showShadow: false,
                        child: GestureDetector(
                          onTap: _showRoutineManagerBottomSheet,
                          child: const PixelEmoji('routine', size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. 하루 계획 통계 및 픽셀 달성률 (Progress Bar) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '오늘의 달성률 '.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PixelEmoji('trophy', size: 16),
                        ],
                      ),
                      Text(
                        '%s / %s 완료'.trArgs([
                          done.toString(),
                          total.toString(),
                        ]), // 💡 달성률 텍스트 번역
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PixelProgressBar(progress: progress),
                ],
              ),
            ),

            // --- 3. 카테고리별 할 일 리스트 ---
            Expanded(
              child: PageView.builder(
                controller: _datePageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedDate = _indexToDate(index);
                  });
                  _syncRoutinesForDate(_selectedDate);
                },
                itemBuilder: (context, index) {
                  final pageDate = _indexToDate(index);
                  final pageTodos = _getTodosForDate(pageDate);

                  final Map<String, List<Map<String, dynamic>>>
                  pageGroupedTodos = {};
                  for (var todo in pageTodos) {
                    final cat = todo['category']?.toString() ?? '미지정';
                    pageGroupedTodos.putIfAbsent(cat, () => []).add(todo);
                  }
                  final pageSortedCategories = pageGroupedTodos.keys.toList()
                    ..sort();

                  if (pageTodos.isEmpty) {
                    return Center(
                      child: Text(
                        '예정된 계획이 없습니다!\n우측 하단 버튼을 눌러 추가해보세요.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // 💡 플로팅 버튼에 가리지 않게 하단 여백 추가
                    itemCount: pageSortedCategories.length,
                    itemBuilder: (context, catIndex) {
                      final category = pageSortedCategories[catIndex];
                      final catTodos = pageGroupedTodos[category]!;

                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent, // 💡 확장 타일 위아래 선 제거
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          // 💡 날짜별, 카테고리별로 접힘 상태를 기기가 기억하게 함
                          key: PageStorageKey(
                            'cat_${_formatDate(pageDate)}_$category',
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _categoryColors[category] ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category.tr, // 💡 카테고리 번역
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '%s / %s 완료'.trArgs([
                                  catTodos
                                      .where((t) => t['isDone'] == true)
                                      .length
                                      .toString(),
                                  catTodos.length.toString(),
                                ]), // 💡 달성률 번역
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          children: catTodos.map((todo) {
                            final originalIndex = _todoList.indexOf(todo);

                            // 💡 에러 방지: 분석기가 헷갈리지 않도록 모든 데이터를 미리 변수로 안전하게 추출합니다.
                            final bool isDone = todo['isDone'] == true;
                            final String task = todo['task']?.toString() ?? '';
                            final TimeOfDay? timeObj =
                                todo['time'] as TimeOfDay?;
                            final TimeOfDay? alarmObj =
                                todo['alarmTime'] as TimeOfDay?;
                            final bool isAlarmOn = todo['isAlarmOn'] == true;
                            final String location =
                                todo['location']?.toString() ?? '';
                            final String memo = todo['memo']?.toString() ?? '';

                            final bool hasTime = timeObj != null;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4, // 💡 간격을 살짝 좁힘
                              ),
                              child: BouncingWrapper(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      _showTodoDetailBottomSheet(originalIndex),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? Colors.grey[200]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        // --- 🌟 도트 그래픽 픽셀 체크박스 ---
                                        PixelCheckbox(
                                          isDone: isDone,
                                          onChanged: (val) =>
                                              _toggleTodo(originalIndex, val),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // 할 일 텍스트
                                              Text(
                                                task,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: isDone
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  color: isDone
                                                      ? Colors.grey[600]
                                                      : Colors.black,
                                                ),
                                              ),
                                              // --- 상세 정보(시간, 알림, 장소, 메모) 표시 ---
                                              if (hasTime ||
                                                  location.isNotEmpty ||
                                                  memo.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (hasTime)
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color: isDone
                                                                  ? Colors
                                                                        .grey[500]
                                                                  : Colors
                                                                        .grey[700],
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text.rich(
                                                              TextSpan(
                                                                children: [
                                                                  TextSpan(
                                                                    text: timeObj
                                                                        .format(
                                                                          context,
                                                                        ),
                                                                  ),
                                                                  if (isAlarmOn &&
                                                                      alarmObj !=
                                                                          null) ...[
                                                                    TextSpan(
                                                                      text: ' (알림 '
                                                                          .tr,
                                                                    ),
                                                                    const WidgetSpan(
                                                                      alignment:
                                                                          PlaceholderAlignment
                                                                              .middle,
                                                                      child: Padding(
                                                                        padding: EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              2,
                                                                        ),
                                                                        child: PixelEmoji(
                                                                          'bell',
                                                                          size:
                                                                              10,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text:
                                                                          ' ${alarmObj.format(context)})',
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: isDone
                                                                    ? Colors
                                                                          .grey[500]
                                                                    : Colors
                                                                          .grey[800],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      if (location.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 4.0,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .location_on,
                                                                size: 14,
                                                                color: isDone
                                                                    ? Colors
                                                                          .grey[500]
                                                                    : Colors
                                                                          .grey[700],
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                location,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: isDone
                                                                      ? Colors
                                                                            .grey[500]
                                                                      : Colors
                                                                            .grey[800],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (memo.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 4.0,
                                                              ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Icon(
                                                                Icons.notes,
                                                                size: 14,
                                                                color: isDone
                                                                    ? Colors
                                                                          .grey[500]
                                                                    : Colors
                                                                          .grey[700],
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  memo,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        isDone
                                                                        ? Colors
                                                                              .grey[500]
                                                                        : Colors
                                                                              .grey[800],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 카테고리 관리 & 할 일 추가 플로팅 버튼 (도트 스타일 적용)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 카테고리 관리 버튼 (좌측 하단)
            BouncingWrapper(
              child: SizedBox(
                width: 56,
                height: 56,
                child: RetroGradientButton(
                  color: AppTheme.categoryEditButtonColor,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(4), // 💡 네모 반듯한 도트 모서리 적용
                  onPressed: _showCategoryManagerBottomSheet,
                  child: const PixelEmoji('shapes', size: 24),
                ),
              ),
            ),
            // 할 일 추가 버튼 (우측 하단)
            BouncingWrapper(
              child: SizedBox(
                width: 56,
                height: 56,
                child: RetroGradientButton(
                  color: AppTheme.addTodoButtonColor,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(4), // 💡 네모 반듯한 도트 모서리 적용
                  onPressed: () => _showTodoEditorBottomSheet(),
                  child: const PixelEmoji('plus', size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 🎮 커스텀 도트/레트로 위젯들 ---

// 1. 도트 감성을 살린 픽셀 프로그레스 바
class PixelProgressBar extends StatelessWidget {
  final double progress;

  const PixelProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  color: Colors.greenAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 2. 네모 반듯한 도트 체크박스 위젯
class PixelCheckbox extends StatelessWidget {
  final bool isDone;
  final ValueChanged<bool> onChanged;

  const PixelCheckbox({
    super.key,
    required this.isDone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDone),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDone ? Colors.yellowAccent : Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isDone
              ? null // 체크되면 눌린 것처럼 그림자 제거
              : const [
                  BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
                ],
        ),
        child: isDone ? CustomPaint(painter: PixelCheckPainter()) : null,
      ),
    );
  }
}

// 3. 2D 픽셀 배열로 그리는 수제 도트 체크마크
class PixelCheckPainter extends CustomPainter {
  final Color color;

  PixelCheckPainter({this.color = const Color(0xFF212123)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // 8x6 해상도의 V자 체크마크 매트릭스 패턴
    final List<List<int>> pixels = [
      [0, 0, 0, 0, 0, 0, 1, 1],
      [0, 0, 0, 0, 0, 1, 1, 0],
      [1, 0, 0, 0, 1, 1, 0, 0],
      [1, 1, 0, 1, 1, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0, 0],
      [0, 0, 1, 0, 0, 0, 0, 0],
    ];

    // 32x32 컨테이너 안에 약간의 여백을 주기 위해 10칸 기준 크기로 분할
    final double cellW = size.width / 10;
    final double cellH = size.height / 10;

    // 여백 오프셋 지정 (가운데 정렬)
    final double offsetX = cellW * 1;
    final double offsetY = cellH * 2;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              offsetX + x * cellW,
              offsetY + y * cellH,
              cellW,
              cellH,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. 커스텀 도트 스타일 달력 다이얼로그 위젯
class _PixelCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final List<Map<String, dynamic>> todoList;
  const _PixelCalendarDialog({
    required this.initialDate,
    required this.todoList,
  });

  @override
  State<_PixelCalendarDialog> createState() => _PixelCalendarDialogState();
}

class _PixelCalendarDialogState extends State<_PixelCalendarDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final int firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;
    final int emptyPrefixCount = firstWeekday % 7; // 일요일(7)을 0으로 맞춤
    final List<String> weekDays = [
      '일'.tr,
      '월'.tr,
      '화'.tr,
      '수'.tr,
      '목'.tr,
      '금'.tr,
      '토'.tr,
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 달력 상단 (월 이동)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '%s년 %s월'.trArgs([
                    _currentMonth.year.toString(),
                    _currentMonth.month.toString(),
                  ]), // 💡 연월 포맷 번역
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 요일 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: day == '일'.tr
                            ? Colors.redAccent
                            : (day == '토'.tr
                                  ? Colors.blueAccent
                                  : Colors.black),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // 날짜 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: emptyPrefixCount + daysInMonth,
              itemBuilder: (context, index) {
                if (index < emptyPrefixCount) return const SizedBox.shrink();
                final day = index - emptyPrefixCount + 1;
                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  day,
                );
                final isSelected =
                    widget.initialDate.year == date.year &&
                    widget.initialDate.month == date.month &&
                    widget.initialDate.day == date.day;
                final isToday =
                    DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                // --- 💡 해당 날짜의 100% 달성 여부 확인 ---
                final dateStr =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                final dayTodos = widget.todoList
                    .where((t) => t['date'] == dateStr)
                    .toList();
                final bool hasTodos = dayTodos.isNotEmpty;
                final bool isAllDone =
                    hasTodos && dayTodos.every((t) => t['isDone'] == true);

                Color? bgColor = Colors.transparent;
                if (isSelected) {
                  bgColor = Colors.yellowAccent;
                } else if (isToday) {
                  bgColor = Colors.grey[200];
                }

                return GestureDetector(
                  onTap: () => Navigator.pop(context, date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black
                                  : (index % 7 == 0
                                        ? Colors.redAccent
                                        : (index % 7 == 6
                                              ? Colors.blueAccent
                                              : Colors.black)),
                            ),
                          ),
                        ),
                        if (isAllDone)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CustomPaint(painter: PixelTrophyPainter()),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 5. 달력용 도트 트로피 픽셀 페인터
class PixelTrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGold = Paint()..color = Colors.yellowAccent;
    final paintBlack = Paint()..color = const Color(0xFF212123);

    // 7x7 해상도 미니 픽셀 트로피
    final List<List<int>> pixels = [
      [0, 0, 2, 2, 2, 0, 0],
      [0, 2, 1, 1, 1, 2, 0],
      [2, 1, 1, 1, 1, 1, 2],
      [0, 2, 1, 1, 1, 2, 0],
      [0, 0, 2, 1, 2, 0, 0],
      [0, 2, 1, 1, 1, 2, 0],
      [2, 2, 2, 2, 2, 2, 2],
    ];

    final double cellW = size.width / 7;
    final double cellH = size.height / 7;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
            paintGold,
          );
        } else if (pixels[y][x] == 2) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
            paintBlack,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
