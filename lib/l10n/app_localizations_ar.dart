// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نظام المعلومات والترفيه';

  @override
  String get settings => 'الإعدادات';

  @override
  String get weather => 'الطقس';

  @override
  String get language => 'اللغة';

  @override
  String get about => 'حول النظام';

  @override
  String get home => 'الرئيسية';

  @override
  String get music => 'الموسيقى';

  @override
  String get phone => 'الهاتف';

  @override
  String get ok => 'موافق';

  @override
  String get noMusicFiles => 'لم يتم العثور على ملفات موسيقى على الجهاز.';

  @override
  String get troubleshootingTips => 'نصائح استكشاف الأخطاء:';

  @override
  String get grantPermissions => '- تأكد من منح أذونات التخزين/الوسائط.';

  @override
  String get placeMusicFiles => '- ضع ملفات الموسيقى في /Music أو /Download أو /Documents.';

  @override
  String get supportedFormats => '- فقط ملفات mp3, wav, aac, m4a, flac, ogg مدعومة.';

  @override
  String get refreshButton => '- استخدم زر التحديث بعد إضافة الملفات.';

  @override
  String get restartApp => '- جرب إعادة تشغيل التطبيق بعد إضافة الملفات.';

  @override
  String get avoidProtectedFolders => '- تجنب المجلدات المحمية مثل /Android/data.';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get humidity => 'الرطوبة';

  @override
  String get mobile => 'الجهاز';

  @override
  String get startJourney => 'بدء الرحلة';

  @override
  String get stopJourney => 'إيقاف الرحلة';

  @override
  String get eta => 'الوقت المتوقع';

  @override
  String get searchPlace => 'ابحث عن مكان';

  @override
  String get searchMusic => 'ابحث عن موسيقى...';

  @override
  String get playlist => 'قائمة التشغيل';

  @override
  String get close => 'إغلاق';

  @override
  String get permissionRequired => 'مطلوب إذن';

  @override
  String get storagePermissionMessage => 'يحتاج هذا التطبيق إلى إذن للوصول إلى تخزين الجهاز للعثور على ملفات الموسيقى. يرجى منح الإذن في إعدادات التطبيق.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get mediaEntertainment => 'الوسائط والترفيه';

  @override
  String get deviceTemperature => 'درجة حرارة الجهاز';

  @override
  String get driveConnected => 'قيادة متصلة. قيادة ملهمة.';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get german => 'الألمانية';

  @override
  String get getWeatherApi => 'الحصول على الطقس من API';

  @override
  String get getWeatherExternal => 'الحصول على الطقس من نظام خارجي';

  @override
  String get sunrise => 'شروق الشمس';

  @override
  String get sunset => 'غروب الشمس';

  @override
  String get precipitation => 'هطول الأمطار';

  @override
  String get wind => 'الرياح';

  @override
  String get pressure => 'الضغط';

  @override
  String lastUpdate(Object time) {
    return 'آخر تحديث: $time';
  }

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get recenter => 'إعادة تمركز';

  @override
  String get toggleTraffic => 'تبديل المرور';

  @override
  String get toggleMapMode => 'تبديل وضع الخريطة';

  @override
  String get refreshLocationWeather => 'تحديث الموقع والطقس';

  @override
  String get weatherSource => 'مصدر الطقس';

  @override
  String get getWeatherFromAPI => 'الحصول على الطقس من API';

  @override
  String get useOnlineWeatherAPI => 'استخدم واجهة برمجة تطبيقات الطقس عبر الإنترنت';

  @override
  String get getWeatherFromExternalSystem => 'الحصول على الطقس من نظام خارجي';

  @override
  String get useDataProvidedByExternalSystem => 'استخدم البيانات المقدمة من النظام الخارجي';

  @override
  String get infotainmentSystem => 'نظام المعلومات والترفيه';

  @override
  String get experienceFutureOfDriving => 'اختبر مستقبل القيادة.';

  @override
  String get driveConnectedDriveInspired => 'قيادة متصلة. قيادة ملهمة.';

  @override
  String get developerInfo => 'معلومات المطور';

  @override
  String get developedByAhmedHassan => 'تم التطوير بواسطة أحمد حسن';

  @override
  String contentForTitleWillAppearHere(Object title) {
    return 'سيظهر المحتوى الخاص بـ $title هنا.';
  }

  @override
  String get deutsch => 'الألمانية';

  @override
  String get apiKeyNotSet => 'API Key Not Set';

  @override
  String get apiKeyNotSetDescription => 'To use weather and map features, you must set your Google Cloud API key.';

  @override
  String get apiKeyNotSetSteps => '1. Go to lib/config/api_config.dart\n2. Replace YOUR_API_KEY_HERE with your Google Cloud API key\n3. See API_SETUP.md for detailed instructions';

  @override
  String get viewApiSetupGuide => 'View API Setup Guide';
}
