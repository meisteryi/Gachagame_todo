import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_manager.dart';
import '../translations.dart';
import '../bouncing_wrapper.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaveToCloud;
  final VoidCallback onLoadFromCloud;
  final VoidCallback onClearTodos;

  const SettingsScreen({
    super.key,
    required this.onSaveToCloud,
    required this.onLoadFromCloud,
    required this.onClearTodos,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyUncompleted = true;
  bool _notifyDayStart = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyUncompleted = prefs.getBool('notify_uncompleted') ?? true;
      _notifyDayStart = prefs.getBool('notify_day_start') ?? true;
    });
  }

  Future<void> _toggleUncompleted(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_uncompleted', val);
    setState(() {
      _notifyUncompleted = val;
    });
    await NotificationService().updateDailyReminders();
  }

  Future<void> _toggleDayStart(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_day_start', val);
    setState(() {
      _notifyDayStart = val;
    });
    await NotificationService().updateDailyReminders();
  }



  Widget _buildSettingsGroup({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.borderColor, offset: const Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.borderColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.panelBg, AppTheme.unselectedTabBg],
          ),
        ),
        child: ValueListenableBuilder<ThemeType>(
          valueListenable: AppTheme.themeNotifier,
          builder: (context, theme, _) {
            return ValueListenableBuilder<AppLang>(
              valueListenable: Tr.langNotifier,
              builder: (context, lang, _) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Language Section
                    _buildSettingsGroup(
                      title: '언어 / Language'.tr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: AppLang.values.map((l) {
                          final isSelected = l == Tr.lang;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => Tr.changeLang(l),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.yellowAccent
                                      : AppTheme.unselectedTabBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  l.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.black
                                        : AppTheme.unselectedTabText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 2. Theme Section
                    _buildSettingsGroup(
                      title: '테마 변경'.tr,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => AppTheme.setTheme(ThemeType.current),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme == ThemeType.current
                                    ? Colors.yellowAccent
                                    : AppTheme.unselectedTabBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                '지금 색감'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme == ThemeType.current
                                      ? Colors.black
                                      : AppTheme.unselectedTabText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => AppTheme.setTheme(ThemeType.classic),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme == ThemeType.classic
                                    ? Colors.yellowAccent
                                    : AppTheme.unselectedTabBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                '쨍한 색감'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme == ThemeType.classic
                                      ? Colors.black
                                      : AppTheme.unselectedTabText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Cloud Sync Section
                    _buildSettingsGroup(
                      title: '데이터 동기화'.tr,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: BouncingWrapper(
                              child: RetroGradientButton(
                                color: AppTheme.selectedTabBg,
                                foregroundColor: AppTheme.selectedTabText,
                                onPressed: widget.onSaveToCloud,
                                child: Text(
                                  '클라우드에 저장 ☁️'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: BouncingWrapper(
                              child: RetroGradientButton(
                                color: AppTheme.milestoneCompletedBg,
                                foregroundColor: AppTheme.borderColor,
                                onPressed: widget.onLoadFromCloud,
                                child: Text(
                                  '클라우드에서 불러오기 ☁️'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: BouncingWrapper(
                              child: RetroGradientButton(
                                color: const Color(0xFFEDC8C4),
                                foregroundColor: AppTheme.borderColor,
                                onPressed: widget.onClearTodos,
                                child: Text(
                                  '할 일 초기화'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Notification Section
                    _buildSettingsGroup(
                      title: '푸시 알림 설정'.tr,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '미완료 할 일 알림'.tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '매일 밤 11시, 완료하지 않은 할 일이 있으면 알림을 보냅니다.'.tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.unselectedTabText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PixelSwitch(
                                value: _notifyUncompleted,
                                onChanged: _toggleUncompleted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '하루 시작 알림'.tr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '매일 아침 8시, 하루의 시작을 알리는 알림을 보냅니다.'.tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.unselectedTabText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PixelSwitch(
                                value: _notifyDayStart,
                                onChanged: _toggleDayStart,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// 💡 픽셀 감성 토글 스위치 위젯
class PixelSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingWrapper(
      showShadow: false,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          width: 70,
          height: 34,
          decoration: BoxDecoration(
            color: value ? const Color(0xFF68C2D3) : const Color(0xFFE5CEB4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF212123), width: 3),
          ),
          child: Stack(
            children: [
              // Text indicator
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: value ? 0 : 20,
                    right: value ? 20 : 0,
                  ),
                  child: Text(
                    value ? 'ON' : 'OFF',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Color(0xFF212123),
                    ),
                  ),
                ),
              ),
              // Slider knob
              AnimatedAlign(
                duration: const Duration(milliseconds: 100),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: const Color(0xFF212123), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
