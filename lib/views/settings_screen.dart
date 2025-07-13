import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:infotainment_system/l10n/app_localizations.dart';
import 'package:infotainment_system/controllers/settings_controller.dart';
import 'package:infotainment_system/models/settings.dart';
import '../main.dart'; // for LocaleProvider
import 'package:infotainment_system/constants/app_colors.dart';

/// Settings screen for changing app preferences such as language and weather source.
/// Uses SettingsController and Settings model via Provider.
class SettingsScreen extends StatefulWidget {
  /// Callback when settings are changed.
  final VoidCallback? onSettingsChanged;

  /// Creates a new [SettingsScreen].
  const SettingsScreen({Key? key, this.onSettingsChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State for [SettingsScreen]. Handles UI and settings logic.
class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.cloud, 'label': 'weather'},
    {'icon': Icons.language, 'label': 'language'},
    {'icon': Icons.info_outline, 'label': 'about'},
  ];

  /// Returns the localized label for a category key.
  String _localizedCategoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'weather':
        return AppLocalizations.of(context)!.weather;
      case 'language':
        return AppLocalizations.of(context)!.language;
      case 'about':
        return AppLocalizations.of(context)!.about;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  /// Builds the main settings screen UI.
  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF101012),
      body: Row(
        children: [
          // Left pane: categories as a rounded card
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 16,
              bottom: 16,
              right: 16,
            ),
            child: Card(
              color: const Color(0xFF18181C),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        AppLocalizations.of(context)!.settings,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // No search bar for simplicity
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final selected = index == _selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Material(
                              color: selected
                                  ? AppColors.white.withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () =>
                                    setState(() => _selectedIndex = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        cat['icon'],
                                        color: selected
                                            ? AppColors.mainBlue
                                            : AppColors.white70,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _localizedCategoryLabel(
                                          context,
                                          cat['label'],
                                        ),
                                        style: TextStyle(
                                          color: selected
                                              ? AppColors.mainBlue
                                              : AppColors.white,
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Right pane: details as a rounded card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
              child: Card(
                color: Colors.transparent,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2B1B3A),
                        Color(0xFF1B223A),
                        Color(0xFF232B3A),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 32,
                    ),
                    child: SingleChildScrollView(
                      child: _buildRightPaneContent(settingsController),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the right pane content for the selected category.
  Widget _buildRightPaneContent(SettingsController settingsController) {
    if (_selectedIndex == 2) {
      // About tab: do not wrap in scroll view
      return _buildAboutSystem();
    }
    // Other tabs: allow scrolling
    return SingleChildScrollView(
      child: _buildTabContent(_selectedIndex, settingsController),
    );
  }

  /// Builds the content for the Weather settings tab.
  Widget _buildWeatherSettings(SettingsController settingsController) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: AppColors.mainBlue, size: 40),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context)!.weatherSource,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          RadioListTile<int>(
            value: 0,
            groupValue: settingsController.weatherSource,
            onChanged: (val) {
              settingsController.setWeatherSource(val!);
              if (widget.onSettingsChanged != null) widget.onSettingsChanged!();
            },
            activeColor: AppColors.mainBlue,
            title: Text(
              AppLocalizations.of(context)!.getWeatherFromAPI,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.useOnlineWeatherAPI,
              style: const TextStyle(color: AppColors.white70),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<int>(
            value: 1,
            groupValue: settingsController.weatherSource,
            onChanged: (val) {
              settingsController.setWeatherSource(val!);
              if (widget.onSettingsChanged != null) widget.onSettingsChanged!();
            },
            activeColor: AppColors.mainBlue,
            title: Text(
              AppLocalizations.of(context)!.getWeatherFromExternalSystem,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.useDataProvidedByExternalSystem,
              style: const TextStyle(color: AppColors.white70),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the content for the Language settings tab.
  Widget _buildLanguageSettings(SettingsController settingsController) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppColors.mainBlue, size: 40),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context)!.language,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          RadioListTile<int>(
            value: 0,
            groupValue: settingsController.languageIndex,
            onChanged: (val) {
              settingsController.setLanguageIndex(val!);
              localeProvider.setLocale(const Locale('ar'));
            },
            activeColor: AppColors.mainBlue,
            title: Text(
              AppLocalizations.of(context)!.arabic,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.arabic,
              style: const TextStyle(color: AppColors.white70),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<int>(
            value: 1,
            groupValue: settingsController.languageIndex,
            onChanged: (val) {
              settingsController.setLanguageIndex(val!);
              localeProvider.setLocale(const Locale('de'));
            },
            activeColor: AppColors.mainBlue,
            title: Text(
              AppLocalizations.of(context)!.deutsch,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.german,
              style: const TextStyle(color: AppColors.white70),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<int>(
            value: 2,
            groupValue: settingsController.languageIndex,
            onChanged: (val) {
              settingsController.setLanguageIndex(val!);
              localeProvider.setLocale(const Locale('en'));
            },
            activeColor: AppColors.mainBlue,
            title: Text(
              AppLocalizations.of(context)!.english,
              style: const TextStyle(color: AppColors.white, fontSize: 20),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.english,
              style: const TextStyle(color: AppColors.white70),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a placeholder widget for tabs that are not yet implemented.
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, color: AppColors.mainBlue, size: 64),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.appTitle,
            style: const TextStyle(color: AppColors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the content for the About tab.
  Widget _buildAboutSystem() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.mainBlue,
              size: 60,
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.infotainmentSystem,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.experienceFutureOfDriving,
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Divider(
              color: AppColors.mainBlue.withOpacity(0.2),
              thickness: 1,
              indent: 30,
              endIndent: 30,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.driveConnectedDriveInspired,
              style: TextStyle(
                color: AppColors.mainBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white10,
                foregroundColor: AppColors.mainBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.info_outline, size: 20),
              label: Text(
                AppLocalizations.of(context)!.developerInfo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF232B3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.person, color: AppColors.mainBlue),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.developerInfo,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.developedByAhmedHassan,
                          style: TextStyle(
                            color: AppColors.white70,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'arhassan97@gmail.com',
                            );
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            }
                          },
                          child: Text(
                            //AppLocalizations.of(context)!.email,
                            'arhassan97@gmail.com',
                            style: TextStyle(
                              color: AppColors.mainBlue,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          AppLocalizations.of(context)!.close,
                          style: TextStyle(color: AppColors.mainBlue),
                        ),
                      ),
                    ],
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
