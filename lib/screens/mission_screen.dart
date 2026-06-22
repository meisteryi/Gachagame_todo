import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bouncing_wrapper.dart';
import '../pixel_emoji.dart';
import '../translations.dart';
import '../theme_manager.dart';

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
  int _weeklyCompletedCount = 0; // 💡 이번 주 완료한 총 할 일 개수
  bool _isLoading = true;
  bool _hasTomorrowTodo = false; // 내일 할 일 추가 여부

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
      "daily_tomorrow_prep_claimed": false, // 내일을 위한 준비 미션
      "weekly_attendance_progress": 0,
      "weekly_all_clear_progress": 0,
      "weekly_milestone_claimed": false,
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

    // 내일 할 일 유무 확인 (tomorrow의 date를 가진 todo가 1개 이상 있으면 달성)
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDateStr = _formatDate(tomorrow);
    bool hasTomorrowTodo = false;
    if (todosStr != null) {
      final List<dynamic> allTodos = jsonDecode(todosStr);
      hasTomorrowTodo = allTodos.any((item) => item['date'] == tomorrowDateStr);
    }

    final weekStartStr = _formatDate(
      now.subtract(Duration(days: now.weekday - 1)),
    ); // 이번 주 월요일
    bool needsSave = false;

    // 💡 이번 주 완료한 총 할 일 개수 계산
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    int weeklyCompletedCount = 0;
    if (todosStr != null) {
      final List<dynamic> decoded = jsonDecode(todosStr);
      for (var item in decoded) {
        if (item['date'] != null) {
          final parts = item['date'].toString().split('-');
          if (parts.length == 3) {
            final tDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            if (tDate.compareTo(weekStartDate) >= 0 &&
                tDate.compareTo(now) <= 0) {
              if (item['isDone'] == true) {
                weeklyCompletedCount++;
              }
            }
          }
        }
      }
    }

    // 💡 주간 초기화 (월요일 기준)
    if (data['week_start_date'] != weekStartStr) {
      data['week_start_date'] = weekStartStr;
      data['weekly_attendance_progress'] = 0;
      data['weekly_all_clear_progress'] = 0;
      data['weekly_attendance_claimed'] = false;
      data['weekly_all_clear_claimed'] = false;
      data['weekly_milestone_claimed'] = false;
      needsSave = true;
    }

    // 💡 일일 초기화 및 출석 카운트
    if (data['last_update_date'] != nowDateStr) {
      data['last_update_date'] = nowDateStr;
      data['daily_attendance_claimed'] = false;
      data['daily_all_clear_claimed'] = false;
      data['daily_tomorrow_prep_claimed'] = false; // 한 날이 지나면 리셋
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
        _weeklyCompletedCount = weeklyCompletedCount;
        _hasTomorrowTodo = hasTomorrowTodo;
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
              color: const Color(0xFFF2F0E5),
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

  Future<void> _claimReward(String key, int reward) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _missionData[key] = true);
    await prefs.setString('mission_data', jsonEncode(_missionData));
    widget.onAddCoin(reward);

    if (!mounted) {
      return;
    }
    _showNoticeDialog('보상 %s코인을 획득했습니다! 🪙'.trArgs([reward.toString()]));
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
        color: isClaimed ? const Color(0xFFB8B5B9) : AppTheme.panelBg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isClaimed
            ? null
            : [
                BoxShadow(
                  color: AppTheme.borderColor,
                  offset: const Offset(3, 3),
                ),
              ],
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
                    color: isClaimed
                        ? const Color(0xFF868188)
                        : AppTheme.borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$desc ($progressText)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isClaimed
                        ? const Color(0xFF868188)
                        : const Color(0xFF45444F),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '보상: 코인 %s개'.trArgs([reward.toString()]),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isClaimed
                            ? const Color(0xFF868188)
                            : AppTheme.themeSeed,
                      ),
                    ),
                  ],
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
              child: RetroGradientButton(
                color: isCompleted
                    ? AppTheme.weeklyMilestoneClaimButtonBg
                    : const Color(0xFFBCB2A1),
                disabledColor: isClaimed
                    ? const Color(0xFF868188)
                    : const Color(0xFFBCB2A1),
                foregroundColor: AppTheme.borderColor,
                disabledForegroundColor: Colors.black54,
                onPressed: (isCompleted && !isClaimed) ? onClaim : null,
                child: Text(
                  isClaimed
                      ? '완료됨'.tr
                      : (isCompleted
                            ? '보상 받기\n(%s)'.trArgs([reward.toString()])
                            : '진행 중'.tr),
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.panelBg,
              AppTheme.unselectedTabBg,
            ], // 💡 아주 옅은 그라데이션 배경
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '일일 미션'.tr,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _buildMissionCard(
              title: '오늘도 출석체크!'.tr,
              desc: '앱에 접속하기'.tr,
              reward: 1,
              isCompleted: true,
              isClaimed: _missionData['daily_attendance_claimed'] == true,
              progressText: '1/1',
              onClaim: () => _claimReward('daily_attendance_claimed', 1),
            ),
            _buildMissionCard(
              title: '오늘의 할 일 끝!'.tr,
              desc: '오늘의 모든 할 일 완료'.tr,
              reward: 3,
              isCompleted: dailyClearCompleted,
              isClaimed: _missionData['daily_all_clear_claimed'] == true,
              progressText: _todayTodoTotal > 0
                  ? '$_todayTodoDone/$_todayTodoTotal'
                  : '할 일 없음'.tr,
              onClaim: () => _claimReward('daily_all_clear_claimed', 3),
            ),
            _buildMissionCard(
              title: '내일을 위한 준비',
              desc: '밤 12시 전에 내일 할 일 추가하기',
              reward: 1,
              isCompleted: _hasTomorrowTodo,
              isClaimed: _missionData['daily_tomorrow_prep_claimed'] == true,
              progressText: _hasTomorrowTodo ? '1/1' : '0/1',
              onClaim: () => _claimReward('daily_tomorrow_prep_claimed', 1),
            ),

            const SizedBox(height: 24),
            Text(
              '주간 미션'.tr,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _buildMissionCard(
              title: '성실한 개근상'.tr,
              desc: '일주일 내내 출석'.tr,
              reward: 5,
              isCompleted: weeklyAttProgress >= 7,
              isClaimed: _missionData['weekly_attendance_claimed'] == true,
              progressText: '$weeklyAttProgress/7',
              onClaim: () => _claimReward('weekly_attendance_claimed', 5),
            ),
            _buildMissionCard(
              title: '완벽한 일주일'.tr,
              desc: '일주일 내내 할 일 모두 완료'.tr,
              reward: 10,
              isCompleted: weeklyClearProgress >= 7,
              isClaimed: _missionData['weekly_all_clear_claimed'] == true,
              progressText: '$weeklyClearProgress/7',
              onClaim: () => _claimReward('weekly_all_clear_claimed', 10),
            ),
            _buildMissionCard(
              title: '주간 마일스톤'.tr,
              desc: '이번 주에 30개의 할 일 완료하기'.tr,
              reward: 7,
              isCompleted: _weeklyCompletedCount >= 30,
              isClaimed: _missionData['weekly_milestone_claimed'] == true,
              progressText: '$_weeklyCompletedCount/30',
              onClaim: () => _claimReward('weekly_milestone_claimed', 7),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
