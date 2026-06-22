import 'package:flutter/material.dart';
import '../theme_manager.dart';
import '../translations.dart';
import '../bouncing_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onSaveToCloud;
  final VoidCallback onLoadFromCloud;

  const SettingsScreen({
    super.key,
    required this.onSaveToCloud,
    required this.onLoadFromCloud,
  });

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
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                                onPressed: onSaveToCloud,
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
                                onPressed: onLoadFromCloud,
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
