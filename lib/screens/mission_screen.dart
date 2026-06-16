import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bouncing_wrapper.dart';
import '../pixel_emoji.dart';

class MissionScreen extends StatefulWidget {
  final bool isActive;
  final void Function(int amount) onAddCoin;

  const MissionScreen({
    super.key,
    required this.isActive,
    required this.onAddCoin,
  });

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 탭을 넘나들어도 스크롤/상태 유지

  Map<String, dynamic> _missionData = {};
  int _todayTodoTotal = 0;
  int _todayTodoDone = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _evaluateMissions();
  }

  @override
  void didUpdateWidget(MissionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 사용자가 미션 탭을 눌러서 화면이 활성화될 때마다 최신 할 일 정보로 미션 달성 여부를 갱신합니다.
    if (widget.isActive && !oldWidget.isActive) {
      _evaluateMissions();
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _evaluateMissions() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 오늘 할 일 달성률 계산
    final String? todosStr = prefs.getString('todos');
    int total = 0;
    int done = 0;
    final now = DateTime.now();
    final nowDateStr = _formatDate(now);

    if (todosStr != null) {
      final List<dynamic> decoded = jsonDecode(todosStr);
      for (var item in decoded) {
        if (item['date'] == nowDateStr) {
          total++;
          if (item['isDone'] == true) done++;
        }
      }
    }

    // 2. 미션 데이터 불러오기 및 갱신
    final String? missionStr = prefs.getString('mission_data');
    Map<String, dynamic> data = {
      "last_update_date": "",
      "week_start_date": "",
      "daily_attendance_claimed": false,
      "daily_all_clear_claimed": false,
      "weekly_attendance_progress": 0,
      "weekly_all_clear_progress": 0,
      "weekly_attendance_claimed": false,
      "weekly_all_clear_claimed": false,
      "last_daily_all_clear_counted_date": "",
    };

    if (missionStr != null) {
      // 💡 기존 저장 데이터와 새로운 기본값 병합 (Null 에러 방지)
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        jsonDecode(missionStr),
      );
      decoded.forEach((key, value) {
        data[key] = value;
      });
    }

    final weekStartStr = _formatDate(
      now.subtract(Duration(days: now.weekday - 1)),
    ); // 이번 주 월요일
    bool needsSave = false;

    // 💡 주간 초기화 (월요일 기준)
    if (data['week_start_date'] != weekStartStr) {
      data['week_start_date'] = weekStartStr;
      data['weekly_attendance_progress'] = 0;
      data['weekly_all_clear_progress'] = 0;
      data['weekly_attendance_claimed'] = false;
      data['weekly_all_clear_claimed'] = false;
      needsSave = true;
    }

    // 💡 일일 초기화 및 출석 카운트
    if (data['last_update_date'] != nowDateStr) {
      data['last_update_date'] = nowDateStr;
      data['daily_attendance_claimed'] = false;
      data['daily_all_clear_claimed'] = false;
      data['weekly_attendance_progress'] =
          ((data['weekly_attendance_progress'] ?? 0) as int) + 1;
      if (data['weekly_attendance_progress'] > 7) {
        data['weekly_attendance_progress'] = 7;
      }
      needsSave = true;
    }

    // 💡 할 일 올클리어 체크 (오늘 할 일이 1개 이상이고 모두 완료되었을 때)
    if (total > 0 && done == total) {
      if (data['last_daily_all_clear_counted_date'] != nowDateStr) {
        data['last_daily_all_clear_counted_date'] = nowDateStr;
        data['weekly_all_clear_progress'] =
            ((data['weekly_all_clear_progress'] ?? 0) as int) + 1;
        if (data['weekly_all_clear_progress'] > 7) {
          data['weekly_all_clear_progress'] = 7;
        }
        needsSave = true;
      }
    }

    if (needsSave) {
      await prefs.setString('mission_data', jsonEncode(data));
    }

    if (mounted) {
      setState(() {
        _missionData = data;
        _todayTodoTotal = total;
        _todayTodoDone = done;
        _isLoading = false;
      });
    }
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
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '알림',
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '닫기',
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

  Future<void> _claimReward(String key, int reward) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _missionData[key] = true);
    await prefs.setString('mission_data', jsonEncode(_missionData));
    widget.onAddCoin(reward);

    if (!mounted) return;
    _showNoticeDialog('보상 $reward코인을 획득했습니다! 🪙');
  }

  Widget _buildMissionCard({
    required String title,
    required String desc,
    required int reward,
    required bool isCompleted,
    required bool isClaimed,
    required String progressText,
    required VoidCallback onClaim,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClaimed ? Colors.grey[200] : Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: isClaimed
            ? null
            : const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          const PixelEmoji('coin', size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isClaimed ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$desc ($progressText)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isClaimed ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IgnorePointer(
            ignoring:
                !(isCompleted && !isClaimed), // 💡 보상을 받을 상태가 아니면 터치 완전 무시
            child: BouncingWrapper(
              showShadow: isCompleted && !isClaimed,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed
                      ? Colors.grey
                      : (isCompleted ? Colors.yellowAccent : Colors.grey[300]),
                  disabledBackgroundColor: isClaimed
                      ? Colors.grey
                      : Colors.grey[300], // 비활성 배경색 지정
                  foregroundColor: Colors.black,
                  disabledForegroundColor: Colors.black54, // 비활성 상태일 때 글씨 색상
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                onPressed: (isCompleted && !isClaimed) ? onClaim : null,
                child: Text(
                  isClaimed
                      ? '완료됨'
                      : (isCompleted ? '보상 받기\n($reward)' : '진행 중'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final bool dailyClearCompleted =
        _todayTodoTotal > 0 && _todayTodoDone == _todayTodoTotal;
    final int weeklyAttProgress =
        _missionData['weekly_attendance_progress'] ?? 0;
    final int weeklyClearProgress =
        _missionData['weekly_all_clear_progress'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '🔥 일일 미션',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _buildMissionCard(
            title: '오늘도 출석체크!',
            desc: '앱에 접속하기',
            reward: 1,
            isCompleted: true,
            isClaimed: _missionData['daily_attendance_claimed'] == true,
            progressText: '1/1',
            onClaim: () => _claimReward('daily_attendance_claimed', 1),
          ),
          _buildMissionCard(
            title: '오늘의 할 일 끝!',
            desc: '오늘의 모든 할 일 완료',
            reward: 2,
            isCompleted: dailyClearCompleted,
            isClaimed: _missionData['daily_all_clear_claimed'] == true,
            progressText: _todayTodoTotal > 0
                ? '$_todayTodoDone/$_todayTodoTotal'
                : '할 일 없음',
            onClaim: () => _claimReward('daily_all_clear_claimed', 2),
          ),

          const SizedBox(height: 24),
          const Text(
            '🏅 주간 미션',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _buildMissionCard(
            title: '성실한 개근상',
            desc: '일주일 내내 출석',
            reward: 10,
            isCompleted: weeklyAttProgress >= 7,
            isClaimed: _missionData['weekly_attendance_claimed'] == true,
            progressText: '$weeklyAttProgress/7',
            onClaim: () => _claimReward('weekly_attendance_claimed', 10),
          ),
          _buildMissionCard(
            title: '완벽한 일주일',
            desc: '일주일 내내 할 일 모두 완료',
            reward: 20,
            isCompleted: weeklyClearProgress >= 7,
            isClaimed: _missionData['weekly_all_clear_claimed'] == true,
            progressText: '$weeklyClearProgress/7',
            onClaim: () => _claimReward('weekly_all_clear_claimed', 20),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
