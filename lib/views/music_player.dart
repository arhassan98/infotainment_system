import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:marquee/marquee.dart';
import 'dart:math';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:infotainment_system/l10n/app_localizations.dart';
import 'package:infotainment_system/controllers/music_player_controller.dart';
import 'package:infotainment_system/models/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:ionicons/ionicons.dart';
import 'package:infotainment_system/constants/app_colors.dart';

/// Music player screen for browsing, playing, and managing audio files.
/// Uses MusicPlayerController and Song model via Provider.
class MusicPlayerScreen extends StatefulWidget {
  /// Creates a new [MusicPlayerScreen].
  const MusicPlayerScreen({Key? key}) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

/// State for [MusicPlayerScreen]. Handles UI, file loading, and playback.
class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late StreamSubscription<Duration> _positionSubscription;
  List<PlatformFile> _pickedFiles = [];

  /// Returns the list of picked audio file paths.
  List<String> get _pickedAudioPaths =>
      _pickedFiles.map((f) => f.path ?? '').where((p) => p.isNotEmpty).toList();
  TabController? _tabController;
  List<String> _storageRoots = [];
  Map<String, List<FileSystemEntity>> _storageAudioFiles = {};
  String? _selectedStorage;

  List<FileSystemEntity> _allMusicFiles = [];
  bool _allMusicLoaded = false;

  // For folder navigation in Files tab
  String? _currentFilesRoot;
  String _currentFilesPath = '';
  List<FileSystemEntity> _currentFiles = [];
  List<String> _breadcrumb = [];
  String _filesSearchQuery = '';
  String _allMusicSearchQuery = '';

  // For favorites and playlists
  Set<String> _favorites = {};
  List<String> _playlistPaths = [];

  // Metadata cache: path -> metadata
  final Map<String, AudioMetadata?> _metadataCache = {};
  final Map<String, Uint8List?> _albumArtCache = {};

  late PlayerController _fullWaveformController;
  String? _lastFullSongUrl;
  double? _deviceVolume = null;

  /// Returns true if the given URL is a network URL.
  bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Downloads a file from a network URL to local storage and returns the local path.
  Future<String> downloadToLocal(String url) async {
    final dir = await getTemporaryDirectory();
    final fileName = url.split('/').last;
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath; // Already downloaded
    }
    final dio = Dio();
    await dio.download(url, filePath);
    return filePath;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 1.0,
      upperBound: 1.08,
    );
    _positionSubscription = StreamController<Duration>().stream.listen((_) {});
    _loadFavoritesAndPlaylists();
    _fullWaveformController = PlayerController();
    _setupFullWaveform();
    _initDeviceVolume();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStorageRoots();
    _loadAllMusicFiles();
  }

  @override
  void didUpdateWidget(covariant MusicPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupFullWaveform();
  }

  /// Loads the available storage roots for music files.
  Future<void> _loadStorageRoots() async {
    await Permission.audio.request();
    List<String> roots;
    try {
      roots =
          (await ExternalPath.getExternalStorageDirectories()) ?? <String>[];
    } catch (_) {
      roots = <String>[];
    }
    setState(() {
      _storageRoots = roots;
      if (_selectedStorage == null && roots.isNotEmpty) {
        _selectedStorage = roots.first;
        _loadFilesForStorage(_selectedStorage!);
      }
    });
  }

  /// Loads all files for the selected storage root.
  Future<void> _loadFilesForStorage(String root) async {
    final dir = Directory(root);
    if (await dir.exists()) {
      List<FileSystemEntity> files = [];
      try {
        files = dir.listSync(recursive: true, followLinks: false);
      } catch (e) {
        // Permission denied or other error, skip this directory
        if (kDebugMode) {
          print('Directory listing failed for $root: $e');
        }
        return;
      }
      final audioFiles = files.where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        // Skip protected folders
        if (f.path.contains('/Android/data') || f.path.contains('/Android/obb'))
          return false;
        return ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext);
      }).toList();
      setState(() {
        _storageAudioFiles[root] = audioFiles;
      });
    }
  }

  /// Loads all music files from device storage and updates [_allMusicFiles].
  Future<void> _loadAllMusicFiles() async {
    setState(() {
      _allMusicLoaded = false;
    });

    // Request multiple permissions that might be needed
    final audioStatus = await Permission.audio.request();
    final storageStatus = await Permission.storage.request();
    final manageStorageStatus = await Permission.manageExternalStorage
        .request();

    if (kDebugMode) {
      print(
        'Permission status - Audio: ${audioStatus.isGranted}, Storage: ${storageStatus.isGranted}, Manage: ${manageStorageStatus.isGranted}',
      );
    }

    if (!audioStatus.isGranted &&
        !storageStatus.isGranted &&
        !manageStorageStatus.isGranted) {
      setState(() {
        _allMusicFiles = [];
        _allMusicLoaded = true;
      });
      if (kDebugMode) {
        print('All permissions denied for music scanning.');
      }
      return;
    }

    final List<FileSystemEntity> found = [];

    // Expanded list of common music storage locations
    final userFolders = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/Videos',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/Telegram/Telegram Audio',
      '/storage/emulated/0/Android/media',
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0',
    ];

    if (kDebugMode) {
      print('Scanning user folders: $userFolders');
    }

    for (final folder in userFolders) {
      final dir = Directory(folder);
      if (await dir.exists()) {
        if (kDebugMode) {
          print('Scanning directory: $folder');
        }
        try {
          final files = dir.listSync(recursive: true, followLinks: false).where(
            (f) {
              // Skip protected folders but be less restrictive
              final path = f.path;
              if (path.contains('/Android/data/') &&
                  !path.contains('/Music/') &&
                  !path.contains('/Audio/') &&
                  !path.contains('/Downloads/')) {
                return false;
              }
              return true;
            },
          ).toList();

          final musicFiles = files.where((f) {
            final ext = f.path.split('.').last.toLowerCase();
            return [
              'mp3',
              'wav',
              'aac',
              'm4a',
              'flac',
              'ogg',
              'opus',
              'amr',
            ].contains(ext);
          }).toList();

          if (kDebugMode) {
            print('Found ${musicFiles.length} music files in $folder');
            if (musicFiles.isNotEmpty) {
              print(
                'Sample files: ${musicFiles.take(3).map((f) => f.path.split('/').last).join(', ')}',
              );
            }
          }
          found.addAll(musicFiles);
        } catch (e) {
          if (kDebugMode) {
            print('Error scanning $folder: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('Directory does not exist: $folder');
        }
      }
    }

    // Remove duplicates based on file path
    final uniqueFiles = found.toSet().toList();

    setState(() {
      _allMusicFiles = uniqueFiles;
      _allMusicLoaded = true;
    });

    if (kDebugMode) {
      print('Total unique music files found: ${uniqueFiles.length}');
      if (uniqueFiles.isNotEmpty) {
        print(
          'Sample unique files: ${uniqueFiles.take(5).map((f) => f.path.split('/').last).join(', ')}',
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_positionSubscription != null) {
      _positionSubscription.cancel();
    }
    _tabController?.dispose();
    _fullWaveformController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'],
    );
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
      });
    }
  }

  Future<void> _loadFavoritesAndPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = (prefs.getStringList('favorites') ?? []).toSet();
      _playlistPaths = prefs.getStringList('playlist') ?? [];
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist', _playlistPaths);
  }

  void _addToPlaylist(String path) {
    setState(() {
      if (!_playlistPaths.contains(path)) {
        _playlistPaths.add(path);
      }
    });
    _savePlaylist();
  }

  void _removeFromPlaylist(String path) {
    setState(() {
      _playlistPaths.remove(path);
    });
    _savePlaylist();
  }

  // Folder navigation for Files tab
  Future<void> _openFilesRoot(String root) async {
    setState(() {
      _currentFilesRoot = root;
      _currentFilesPath = root;
      _breadcrumb = [root];
    });
    await _openFilesPath(root);
  }

  Future<void> _openFilesPath(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      final files = dir.listSync(followLinks: false);
      setState(() {
        _currentFiles = files;
        _currentFilesPath = path;
        if (_breadcrumb.isEmpty || _breadcrumb.last != path) {
          _breadcrumb = _breadcrumb
              .takeWhile((p) => path.startsWith(p))
              .toList();
          _breadcrumb.add(path);
        }
      });
    }
  }

  void _breadcrumbTap(int idx) {
    final path = _breadcrumb[idx];
    _breadcrumb = _breadcrumb.sublist(0, idx + 1);
    _openFilesPath(path);
  }

  Future<AudioMetadata?> _getMetadata(String path) async {
    if (_metadataCache.containsKey(path)) return _metadataCache[path];
    try {
      final file = File(path);
      final meta = readMetadata(file, getImage: true);
      _metadataCache[path] = meta;
      if (meta?.pictures != null && meta!.pictures.isNotEmpty) {
        _albumArtCache[path] = meta.pictures.first.bytes;
      }
      return meta;
    } catch (_) {
      _metadataCache[path] = null;
      return null;
    }
  }

  void _showPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.playlist,
            style: TextStyle(color: Colors.white),
          ),
        ),
        content: SizedBox(
          width: 350,
          child: _playlistPaths.isEmpty
              ? const Text(
                  'No songs in playlist.',
                  style: TextStyle(color: Colors.white54),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlistPaths.length,
                  itemBuilder: (context, idx) {
                    final path = _playlistPaths[idx];
                    final fileName = path.split('/').last;
                    return ListTile(
                      leading: const Icon(
                        Icons.audiotrack,
                        color: Colors.white,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          _removeFromPlaylist(path);
                          Navigator.of(context).pop();
                          if (mounted) {
                            _showPlaylistDialog();
                          }
                        },
                      ),
                      onTap: () async {
                        final _controller = Provider.of<MusicPlayerController>(
                          context,
                        );
                        await _controller.player.setUrl(path);
                        _controller.player.play();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionAndScan() async {
    final status = await Permission.audio.request();
    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Builder(
            builder: (context) =>
                Text(AppLocalizations.of(context)!.permissionRequired),
          ),
          content: const Text(
            'This app needs access to your device storage to find music files. Please grant permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Builder(
                builder: (context) =>
                    Text(AppLocalizations.of(context)!.openSettings),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Builder(
                builder: (context) =>
                    Text(AppLocalizations.of(context)!.cancel),
              ),
            ),
          ],
        ),
      );
      return;
    }
    await _loadAllMusicFiles();
    if (_selectedStorage != null) {
      await _loadFilesForStorage(_selectedStorage!);
    }
  }

  void _setupFullWaveform() async {
    final url = Provider.of<MusicPlayerController>(
      context,
      listen: false,
    ).currentSong?.url;
    if (_lastFullSongUrl == url) return;
    _lastFullSongUrl = url;
    String path = url ?? '';
    if (isNetworkUrl(path)) {
      path = await downloadToLocal(path);
    }
    await _fullWaveformController.preparePlayer(
      path: path,
      shouldExtractWaveform: true,
    );
    setState(() {});
  }

  Future<void> _initDeviceVolume() async {
    double vol = await FlutterVolumeController.getVolume() ?? 0.5;
    setState(() {
      _deviceVolume = vol;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _controller = Provider.of<MusicPlayerController>(
      context,
      listen: false,
    );
    final screenSize = MediaQuery.of(context).size;
    // Debug: print the screen size
    if (kDebugMode) {
      print('Screen size: \\${screenSize.width} x \\${screenSize.height}');
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        title: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.mediaEntertainment,
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Left column: Info + mini player in a card
              Card(
                color: Colors.white.withOpacity(0.10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Consumer<MusicPlayerController>(
                        builder: (context, _controller, child) {
                          final song = _controller.currentSong;
                          if (song == null) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Hero(
                                  tag: song.url + '-mini',
                                  flightShuttleBuilder:
                                      (
                                        flightContext,
                                        animation,
                                        flightDirection,
                                        fromHeroContext,
                                        toHeroContext,
                                      ) {
                                        return AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, child) {
                                            final scale =
                                                0.9 + 0.1 * animation.value;
                                            final opacity =
                                                0.7 + 0.3 * animation.value;
                                            return Transform.scale(
                                              scale: scale,
                                              child: Opacity(
                                                opacity: opacity,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: toHeroContext.widget,
                                        );
                                      },
                                  child: (song.albumArtUrl.isEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          child: Image.asset(
                                            'assets/album_placeholder.jpg',
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.network(
                                          song.albumArtUrl,
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 180,
                                                    height: 180,
                                                    color: Colors.grey[900],
                                                    child: const Icon(
                                                      Icons.music_note,
                                                      color: Colors.white54,
                                                      size: 60,
                                                    ),
                                                  ),
                                        ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _favorites.contains(song.url)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                    onPressed: () =>
                                        _controller.player.setUrl(song.url),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Hero(
                                      tag: 'title-' + song.url + '-mini',
                                      flightShuttleBuilder:
                                          (
                                            flightContext,
                                            animation,
                                            flightDirection,
                                            fromHeroContext,
                                            toHeroContext,
                                          ) {
                                            return AnimatedBuilder(
                                              animation: animation,
                                              builder: (context, child) {
                                                final scale =
                                                    0.95 +
                                                    0.05 * animation.value;
                                                final opacity =
                                                    0.7 + 0.3 * animation.value;
                                                return Transform.scale(
                                                  scale: scale,
                                                  child: Opacity(
                                                    opacity: opacity,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: toHeroContext.widget,
                                            );
                                          },
                                      child: Material(
                                        color: Colors.transparent,
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final title = song.title;
                                            final isLong = title.length > 18;
                                            final isArabic = RegExp(
                                              r'[\u0600-\u06FF]',
                                            ).hasMatch(title);
                                            return isLong
                                                ? SizedBox(
                                                    height:
                                                        Localizations.localeOf(
                                                              context,
                                                            ).languageCode ==
                                                            'ar'
                                                        ? 30
                                                        : 22,
                                                    width: constraints.maxWidth,
                                                    child: Marquee(
                                                      text: title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 17,
                                                      ),
                                                      scrollAxis:
                                                          Axis.horizontal,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      blankSpace: 40.0,
                                                      velocity: 30.0,
                                                      startPadding: 0.0,
                                                      accelerationDuration:
                                                          const Duration(
                                                            seconds: 1,
                                                          ),
                                                      accelerationCurve:
                                                          Curves.linear,
                                                      decelerationDuration:
                                                          const Duration(
                                                            milliseconds: 500,
                                                          ),
                                                      decelerationCurve:
                                                          Curves.easeOut,
                                                      textDirection: isArabic
                                                          ? TextDirection.rtl
                                                          : TextDirection.ltr,
                                                    ),
                                                  )
                                                : SizedBox(
                                                    height:
                                                        Localizations.localeOf(
                                                              context,
                                                            ).languageCode ==
                                                            'ar'
                                                        ? 30
                                                        : 22,
                                                    width: double.infinity,
                                                    child: Center(
                                                      child: Text(
                                                        title,
                                                        key: ValueKey(song.url),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 17,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _controller.isShuffle
                                          ? Icons.shuffle_on
                                          : Icons.shuffle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: _controller.toggleShuffle,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: _controller.previousSong,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: _controller.playPause,
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                        child: Icon(
                                          _controller.isPlaying
                                              ? Ionicons.pause
                                              : Ionicons.play,
                                          key: ValueKey<bool>(
                                            _controller.isPlaying,
                                          ),
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: _controller.nextSong,
                                  ),
                                  IconButton(
                                    icon:
                                        _controller.repeatMode == RepeatMode.one
                                        ? Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                Icons.repeat,
                                                color: Colors.tealAccent,
                                                size: 24,
                                              ),
                                              Positioned(
                                                right: 6,
                                                top: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.tealAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Text(
                                                    '1',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Icon(
                                            _controller.repeatMode ==
                                                    RepeatMode.all
                                                ? Icons.repeat_on
                                                : Icons.repeat,
                                            color:
                                                _controller.repeatMode ==
                                                    RepeatMode.off
                                                ? Colors.white
                                                : Colors.tealAccent,
                                            size: 24,
                                          ),
                                    onPressed: _controller.toggleRepeat,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.position),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _controller.position.inSeconds
                                          .toDouble()
                                          .clamp(
                                            0,
                                            _controller.duration.inSeconds
                                                .toDouble(),
                                          ),
                                      min: 0,
                                      max: _controller.duration.inSeconds
                                          .toDouble(),
                                      onChanged: (value) async {
                                        await _controller.player.seek(
                                          Duration(seconds: value.toInt()),
                                        );
                                      },
                                      activeColor: Colors.tealAccent,
                                      inactiveColor: Colors.white24,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_controller.duration),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: _deviceVolume == null
                                        ? Center(
                                            child: SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : Slider(
                                            value: _deviceVolume!,
                                            min: 0,
                                            max: 1,
                                            onChanged: (value) async {
                                              setState(
                                                () => _deviceVolume = value,
                                              );
                                              await FlutterVolumeController.setVolume(
                                                value,
                                              );
                                            },
                                            activeColor: Colors.tealAccent,
                                            inactiveColor: Colors.white24,
                                          ),
                                  ),
                                ],
                              ),
                              if (song.lyrics != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    song.lyrics!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right column: Main content in a card
              Expanded(
                child: Card(
                  color: Colors.white.withOpacity(0.10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'All Music'),
                                Tab(text: 'Files'),
                              ],
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              indicatorColor: Colors.tealAccent,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        Column(
                                          children: [
                                            // Search bar and refresh button for All Music
                                            Expanded(
                                              child: AllMusicTab(
                                                allMusicFiles: _allMusicFiles,
                                                allMusicLoaded: _allMusicLoaded,
                                                allMusicSearchQuery:
                                                    _allMusicSearchQuery,
                                                favorites: _favorites,
                                                getMetadata: _getMetadata,
                                                addToPlaylist: _addToPlaylist,
                                                playSong: (path) async {
                                                  final controller =
                                                      Provider.of<
                                                        MusicPlayerController
                                                      >(context, listen: false);
                                                  if (kDebugMode) {
                                                    print(
                                                      'All Music: Playing song: $path',
                                                    );
                                                  }
                                                  final List<Song>
                                                  allSongs = await Future.wait(
                                                    _allMusicFiles.map((
                                                      file,
                                                    ) async {
                                                      final meta =
                                                          await _getMetadata(
                                                            file.path,
                                                          );
                                                      final fileName = file.path
                                                          .split('/')
                                                          .last;
                                                      return Song(
                                                        title:
                                                            meta?.title ??
                                                            fileName,
                                                        artist:
                                                            meta?.artist ??
                                                            'Unknown Artist',
                                                        url: file.path,
                                                        albumArtUrl: '',
                                                        lyrics: null,
                                                      );
                                                    }),
                                                  );
                                                  final index = allSongs
                                                      .indexWhere(
                                                        (song) =>
                                                            song.url == path,
                                                      );
                                                  if (index != -1) {
                                                    if (kDebugMode) {
                                                      print(
                                                        'All Music: Setting playlist with \\${allSongs.length} songs, playing index \\${index}',
                                                      );
                                                    }
                                                    controller.playlist =
                                                        allSongs;
                                                    controller.currentIndex =
                                                        index;
                                                    await controller.player
                                                        .setUrl(path);
                                                    controller.player.play();
                                                    controller
                                                        .notifyListeners();
                                                    if (kDebugMode) {
                                                      print(
                                                        'All Music: Successfully started playing: \\${allSongs[index].title}',
                                                      );
                                                    }
                                                  } else {
                                                    if (kDebugMode) {
                                                      print(
                                                        'All Music: Song not found in playlist: $path',
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Files Tab
                                        Column(
                                          children: [
                                            Expanded(
                                              child: FilesTab(
                                                storageRoots: _storageRoots,
                                                storageAudioFiles:
                                                    _storageAudioFiles,
                                                selectedStorage:
                                                    _selectedStorage,
                                                onSelectStorage: (root) async {
                                                  setState(() {
                                                    _selectedStorage = root;
                                                  });
                                                  await _loadFilesForStorage(
                                                    root,
                                                  );
                                                },
                                                getMetadata: _getMetadata,
                                                playSong: (path) async {
                                                  final controller =
                                                      Provider.of<
                                                        MusicPlayerController
                                                      >(context, listen: false);
                                                  final meta =
                                                      await _getMetadata(path);
                                                  final fileName = path
                                                      .split('/')
                                                      .last;
                                                  final tempSong = Song(
                                                    title:
                                                        meta?.title ?? fileName,
                                                    artist:
                                                        meta?.artist ??
                                                        'Unknown Artist',
                                                    url: path,
                                                    albumArtUrl: '',
                                                    lyrics: null,
                                                  );
                                                  final allSongs = [tempSong];
                                                  controller.playlist =
                                                      allSongs;
                                                  controller.currentIndex = 0;
                                                  await controller.player
                                                      .setUrl(path);
                                                  controller.player.play();
                                                  controller.notifyListeners();
                                                },
                                                favorites: _favorites,
                                                addToPlaylist: _addToPlaylist,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Playlist and Refresh buttons (vertical)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.queue_music,
                                          color: Colors.tealAccent,
                                          size: 32,
                                        ),
                                        tooltip: 'Show Playlist',
                                        onPressed: _showPlaylistDialog,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.tealAccent,
                                        ),
                                        tooltip: 'Refresh All Music',
                                        onPressed: () {
                                          _loadAllMusicFiles();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class MiniMusicPlayer extends StatefulWidget {
  final AudioPlayer? player;
  final Song? song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onOpenFullPlayer;

  const MiniMusicPlayer({
    Key? key,
    this.player,
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    this.onOpenFullPlayer,
  }) : super(key: key);

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  late PlayerController _waveformController;
  String? _lastSongUrl;

  /// Returns true if the given URL is a network URL.
  bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Downloads a file from a network URL to local storage and returns the local path.
  Future<String> downloadToLocal(String url) async {
    final dir = await getTemporaryDirectory();
    final fileName = url.split('/').last;
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath; // Already downloaded
    }
    final dio = Dio();
    await dio.download(url, filePath);
    return filePath;
  }

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();
    _setupWaveform();
  }

  @override
  void didUpdateWidget(covariant MiniMusicPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    if (widget.song?.url != _lastSongUrl) {
      _setupWaveform();
    }
  }

  void _setupWaveform() async {
    if (!mounted) return;
    _lastSongUrl = widget.song?.url;
    String path = widget.song?.url ?? '';
    if (isNetworkUrl(path)) {
      path = await downloadToLocal(path);
    }
    await _waveformController.preparePlayer(
      path: path,
      shouldExtractWaveform: true,
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  bool _isArabic(String text) {
    final arabic = RegExp(r'[\u0600-\u06FF]');
    int arabicCount = text.runes
        .where((r) => arabic.hasMatch(String.fromCharCode(r)))
        .length;
    int totalLetters = text.runes
        .where(
          (r) =>
              RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(String.fromCharCode(r)),
        )
        .length;
    if (totalLetters == 0) return false;
    return arabicCount > totalLetters / 2;
  }

  bool _isLong(String text) => text.length > 18;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final song =
        widget.song ??
        Song(title: 'No Song', artist: '', url: '', albumArtUrl: '');
    final isPlaying = widget.song != null && widget.isPlaying;
    final position = widget.song != null ? widget.position : Duration.zero;
    final duration = widget.song != null
        ? widget.duration
        : Duration(seconds: 1);
    final player = widget.player;
    final onPlayPause = widget.song != null ? widget.onPlayPause : null;
    final onNext = widget.song != null ? widget.onNext : null;
    final onPrevious = widget.song != null ? widget.onPrevious : null;
    final onOpenFullPlayer = widget.onOpenFullPlayer;

    return GestureDetector(
      onTap: onOpenFullPlayer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 210,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ListTile for image, title, subtitle (top)
                  ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 16,
                      top: 8,
                      bottom: 0,
                    ),
                    leading: Hero(
                      tag: song.url + '-mini',
                      flightShuttleBuilder:
                          (
                            flightContext,
                            animation,
                            flightDirection,
                            fromHeroContext,
                            toHeroContext,
                          ) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final scale = 0.9 + 0.1 * animation.value;
                                final opacity = 0.7 + 0.3 * animation.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: child,
                                  ),
                                );
                              },
                              child: toHeroContext.widget,
                            );
                          },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (song.albumArtUrl.isEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/album_placeholder.jpg',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (song.albumArtUrl.startsWith('http')
                                  ? Image.network(
                                      song.albumArtUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.asset(
                                        song.albumArtUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    )),
                      ),
                    ),
                    title: Hero(
                      tag: 'title-' + song.url + '-mini',
                      flightShuttleBuilder:
                          (
                            flightContext,
                            animation,
                            flightDirection,
                            fromHeroContext,
                            toHeroContext,
                          ) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final scale = 0.95 + 0.05 * animation.value;
                                final opacity = 0.7 + 0.3 * animation.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: child,
                                  ),
                                );
                              },
                              child: toHeroContext.widget,
                            );
                          },
                      child: Material(
                        color: Colors.transparent,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final title = song.title;
                            final isLong = title.length > 18;
                            final isArabic = RegExp(
                              r'[\u0600-\u06FF]',
                            ).hasMatch(title);
                            return isLong
                                ? SizedBox(
                                    height:
                                        Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 30
                                        : 22,
                                    width: constraints.maxWidth,
                                    child: Marquee(
                                      text: title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                      scrollAxis: Axis.horizontal,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      blankSpace: 40.0,
                                      velocity: 30.0,
                                      startPadding: 0.0,
                                      accelerationDuration: const Duration(
                                        seconds: 1,
                                      ),
                                      accelerationCurve: Curves.linear,
                                      decelerationDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      decelerationCurve: Curves.easeOut,
                                      textDirection: isArabic
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                    ),
                                  )
                                : SizedBox(
                                    height:
                                        Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 30
                                        : 22,
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        title,
                                        key: ValueKey(song.url),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ),
                  ),
                  // No SizedBox or extra space here
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AbsorbPointer(
                            absorbing: widget.song == null,
                            child: Slider(
                              value: position.inSeconds.toDouble().clamp(
                                0,
                                duration.inSeconds.toDouble(),
                              ),
                              min: 0,
                              max: duration.inSeconds.toDouble() > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1,
                              onChanged: (value) {
                                if (player != null) {
                                  player!.seek(
                                    Duration(seconds: value.toInt()),
                                  );
                                }
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-${_formatDuration(duration - position)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Control center (row, bottom)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4.0,
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AbsorbPointer(
                          absorbing: widget.song == null,
                          child: IconButton(
                            icon: Icon(
                              song.isFavorite
                                  ? Ionicons.star
                                  : Icons.star_border,
                              color: song.isFavorite
                                  ? Colors.amber
                                  : Colors.white54,
                              size: 24,
                            ),
                            onPressed: () {}, // TODO: Add favorite toggle
                            tooltip: 'Favorite',
                          ),
                        ),
                        const SizedBox(width: 4),
                        AbsorbPointer(
                          absorbing: widget.song == null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: IconButton(
                              key: ValueKey(song.url),
                              icon: const Icon(
                                Ionicons.play_skip_back,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: onPrevious,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AbsorbPointer(
                          absorbing: widget.song == null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: onPlayPause,
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  isPlaying ? Ionicons.pause : Ionicons.play,
                                  key: ValueKey<bool>(isPlaying),
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AbsorbPointer(
                          absorbing: widget.song == null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: IconButton(
                              key: ValueKey(song.url),
                              icon: const Icon(
                                Ionicons.play_skip_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: onNext,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AbsorbPointer(
                          absorbing: widget.song == null,
                          child: IconButton(
                            icon: Icon(
                              Ionicons.wifi,
                              color: Colors.white54,
                              size: 24,
                            ),
                            onPressed: () {}, // TODO: Add AirPlay action
                            tooltip: 'AirPlay',
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
      ),
    );
  }
}

class AnimatedEqualizerIcon extends StatefulWidget {
  final bool isPlaying;
  const AnimatedEqualizerIcon({Key? key, required this.isPlaying})
    : super(key: key);

  @override
  State<AnimatedEqualizerIcon> createState() => _AnimatedEqualizerIconState();
}

class _AnimatedEqualizerIconState extends State<AnimatedEqualizerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedEqualizerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barCount = 15;
    final barWidth = 1.2;
    final spacing = (32 - barCount * barWidth) / (barCount - 1);
    return SizedBox(
      width: 32,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final List<double> phases = List.generate(barCount, (i) => i * 0.35);
          final List<double> base = List.generate(
            barCount,
            (i) =>
                8 + 8 * (0.5 - (i - (barCount - 1) / 2).abs() / (barCount / 2)),
          );
          final List<double> amp = List.generate(
            barCount,
            (i) =>
                6 + 8 * (0.5 - (i - (barCount - 1) / 2).abs() / (barCount / 2)),
          );
          final heights = widget.isPlaying
              ? List.generate(barCount, (i) {
                  final t = _controller.value * 2 * 3.14159;
                  return base[i] +
                      amp[i] * (0.5 + 0.5 * (1 + sin(t + phases[i]))).abs();
                })
              : List.filled(barCount, base.reduce((a, b) => a < b ? a : b));
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              barCount,
              (i) => Container(
                width: barWidth,
                height: heights[i],
                margin: EdgeInsets.symmetric(
                  horizontal: i == 0 || i == barCount - 1 ? 0 : spacing / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.tealAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AllMusicTab extends StatefulWidget {
  final List<FileSystemEntity> allMusicFiles;
  final bool allMusicLoaded;
  final String allMusicSearchQuery;
  final Set<String> favorites;
  final Future<AudioMetadata?> Function(String) getMetadata;
  final void Function(String) addToPlaylist;
  final void Function(String) playSong;

  const AllMusicTab({
    Key? key,
    required this.allMusicFiles,
    required this.allMusicLoaded,
    required this.allMusicSearchQuery,
    required this.favorites,
    required this.getMetadata,
    required this.addToPlaylist,
    required this.playSong,
  }) : super(key: key);

  @override
  State<AllMusicTab> createState() => _AllMusicTabState();
}

class _AllMusicTabState extends State<AllMusicTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _lastScrolledSongPath;
  late MusicPlayerController _controller;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<MusicPlayerController>(context, listen: false);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final currentPath = Provider.of<MusicPlayerController>(
      context,
      listen: false,
    ).currentSong?.url;
    if (_lastScrolledSongPath != currentPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentSong(currentPath);
      });
      _lastScrolledSongPath = currentPath;
    }
  }

  void _scrollToCurrentSong(String? path) {
    if (path == null) return;
    final filtered = widget.allMusicFiles.where((f) {
      final query = _searchQuery.isNotEmpty
          ? _searchQuery
          : widget.allMusicSearchQuery;
      if (query.isEmpty) return true;
      return f.path.toLowerCase().contains(query.toLowerCase());
    }).toList();
    final currentIndex = filtered.indexWhere((f) => f.path == path);
    if (currentIndex != -1 && _itemKeys.containsKey(path)) {
      final context = _itemKeys[path]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          alignment: 0.1, // Not at the very top
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.allMusicLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.allMusicFiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No music files found on device.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Troubleshooting tips:',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '- Make sure you have granted storage/media permissions.\n'
                '- Place music files in /Music, /Download, or /Documents.\n'
                '- Only mp3, wav, aac, m4a, flac, ogg files are supported.\n'
                '- Use the refresh button after adding files.\n'
                '- Try restarting the app after adding files.\n'
                '- Avoid protected folders like /Android/data.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    final filtered = widget.allMusicFiles.where((f) {
      final query = _searchQuery.isNotEmpty
          ? _searchQuery
          : widget.allMusicSearchQuery;
      if (query.isEmpty) return true;
      return f.path.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search music...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
            ),
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final file = filtered[index];
              final fileName = file.path.split('/').last;
              return FutureBuilder<AudioMetadata?>(
                future: widget.getMetadata(file.path),
                builder: (context, snapshot) {
                  final meta = snapshot.data;
                  final albumArt =
                      (meta?.pictures != null && meta!.pictures!.isNotEmpty)
                      ? meta.pictures!.first.bytes
                      : null;
                  final controller = Provider.of<MusicPlayerController>(
                    context,
                  );
                  final isCurrent = controller.currentSong?.url == file.path;
                  _itemKeys[file.path] ??= GlobalKey();
                  return Container(
                    key: _itemKeys[file.path],
                    margin: isCurrent
                        ? const EdgeInsets.symmetric(vertical: 8)
                        : null,
                    decoration: isCurrent
                        ? BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: ListTile(
                      leading: Hero(
                        tag: file.path,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (albumArt != null)
                              ? Image.memory(
                                  albumArt,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/album_placeholder.jpg',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      title: Hero(
                        tag: 'title-' + file.path,
                        child: Material(
                          color: Colors.transparent,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: SizedBox(
                              height:
                                  Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'ar'
                                  ? 30
                                  : 22,
                              width: double.infinity,
                              child: Text(
                                meta?.title ?? fileName,
                                key: ValueKey(file.path),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          widget.favorites.contains(file.path)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => widget.addToPlaylist(file.path),
                      ),
                      onTap: () {
                        widget.playSong(file.path);
                        _scrollToCurrentSong(file.path);
                      },
                      onLongPress: () => widget.addToPlaylist(file.path),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FilesTab extends StatefulWidget {
  final List<String> storageRoots;
  final Map<String, List<FileSystemEntity>> storageAudioFiles;
  final String? selectedStorage;
  final void Function(String) onSelectStorage;
  final Future<AudioMetadata?> Function(String) getMetadata;
  final void Function(String) playSong;
  final Set<String> favorites;
  final void Function(String) addToPlaylist;

  const FilesTab({
    Key? key,
    required this.storageRoots,
    required this.storageAudioFiles,
    required this.selectedStorage,
    required this.onSelectStorage,
    required this.getMetadata,
    required this.playSong,
    required this.favorites,
    required this.addToPlaylist,
  }) : super(key: key);

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  bool get wantKeepAlive => true;

  String? _currentFilesRoot;
  String _currentFilesPath = '';
  List<FileSystemEntity> _currentFiles = [];
  List<String> _breadcrumb = [];
  String _filesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentFilesRoot = widget.selectedStorage;
    _currentFilesPath = widget.selectedStorage ?? '';
    _breadcrumb = [_currentFilesPath];
    _loadCurrentFiles();
  }

  @override
  void didUpdateWidget(covariant FilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStorage != _currentFilesRoot) {
      _currentFilesRoot = widget.selectedStorage;
      _currentFilesPath = widget.selectedStorage ?? '';
      _breadcrumb = [_currentFilesPath];
      _loadCurrentFiles();
    }
  }

  void _loadCurrentFiles() async {
    if (_currentFilesPath.isEmpty) {
      setState(() => _currentFiles = []);
      return;
    }
    final dir = Directory(_currentFilesPath);
    if (await dir.exists()) {
      try {
        final entities = await dir.list().toList();
        setState(() {
          _currentFiles = entities.where((f) {
            final name = f.path.split('/').last;
            // Exclude 'Android' folder
            if (FileSystemEntity.isDirectorySync(f.path) && name == 'Android')
              return false;
            return true;
          }).toList();
        });
      } catch (e) {
        setState(() => _currentFiles = []);
      }
    } else {
      setState(() => _currentFiles = []);
    }
  }

  void _navigateToFolder(String path) {
    setState(() {
      _currentFilesPath = path;
      _breadcrumb.add(path);
    });
    _loadCurrentFiles();
  }

  void _breadcrumbTap(int idx) {
    final path = _breadcrumb[idx];
    setState(() {
      _breadcrumb = _breadcrumb.sublist(0, idx + 1);
      _currentFilesPath = path;
    });
    _loadCurrentFiles();
  }

  void _scrollToCurrentSong(String path) {
    final filtered = _currentFiles.where((f) {
      if (_filesSearchQuery.isEmpty) return true;
      return f.path.toLowerCase().contains(_filesSearchQuery.toLowerCase());
    }).toList();
    final currentIndex = filtered.indexWhere((f) => f.path == path);
    if (currentIndex != -1 && _itemKeys.containsKey(path)) {
      final context = _itemKeys[path]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          alignment: 0.1,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.storageRoots.length,
            itemBuilder: (context, idx) {
              final root = widget.storageRoots[idx];
              final lastSegment = root.split('/').last;
              String label;
              final nonZeroRoots = widget.storageRoots
                  .where((r) => r.split('/').last != '0')
                  .toList();
              if (lastSegment == '0') {
                label = 'Internal';
              } else if (nonZeroRoots.length > 1) {
                final extIdx = nonZeroRoots.indexOf(root) + 1;
                label = 'External $extIdx';
              } else {
                label = 'External';
              }
              final isSelected = root == _currentFilesRoot;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.teal,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onSelectStorage(root);
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Breadcrumbs
        if (_breadcrumb.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_breadcrumb.length, (idx) {
                final isLast = idx == _breadcrumb.length - 1;
                final path = _breadcrumb[idx];
                String label;
                if (idx == 0) {
                  final lastSegment = path.split('/').last;
                  final nonZeroRoots = widget.storageRoots
                      .where((r) => r.split('/').last != '0')
                      .toList();
                  if (lastSegment == '0') {
                    label = 'Internal';
                  } else if (nonZeroRoots.length > 1) {
                    final extIdx = nonZeroRoots.indexOf(path) + 1;
                    label = 'External $extIdx';
                  } else {
                    label = 'External';
                  }
                } else {
                  label = path.split('/').last.isEmpty
                      ? 'Root'
                      : path.split('/').last;
                }
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isLast
                              ? AppColors.mainBlue.withOpacity(0.15)
                              : Colors.white10,
                          foregroundColor: isLast
                              ? Colors.tealAccent
                              : Colors.white70,
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _breadcrumbTap(idx),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isLast
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                        size: 18,
                      ),
                  ],
                );
              }),
            ),
          ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search files...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
            ),
            onChanged: (q) => setState(() => _filesSearchQuery = q),
          ),
        ),
        Expanded(
          child: _currentFilesRoot == null || _currentFiles.isEmpty
              ? const Center(
                  child: Text(
                    'No files found.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _currentFiles.where((f) {
                    if (_filesSearchQuery.isEmpty) return true;
                    return f.path.toLowerCase().contains(
                      _filesSearchQuery.toLowerCase(),
                    );
                  }).length,
                  itemBuilder: (context, index) {
                    final filtered = _currentFiles.where((f) {
                      if (_filesSearchQuery.isEmpty) return true;
                      return f.path.toLowerCase().contains(
                        _filesSearchQuery.toLowerCase(),
                      );
                    }).toList();
                    final file = filtered[index];
                    final fileName = file.path.split('/').last;
                    if (FileSystemEntity.isDirectorySync(file.path)) {
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(
                          fileName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => _navigateToFolder(file.path),
                      );
                    } else {
                      final ext = file.path.split('.').last.toLowerCase();
                      if (![
                        'mp3',
                        'wav',
                        'aac',
                        'm4a',
                        'flac',
                        'ogg',
                      ].contains(ext))
                        return const SizedBox.shrink();
                      return FutureBuilder<AudioMetadata?>(
                        future: widget.getMetadata(file.path),
                        builder: (context, snapshot) {
                          final meta = snapshot.data;
                          final albumArt =
                              (meta?.pictures != null &&
                                  meta!.pictures!.isNotEmpty)
                              ? meta.pictures!.first.bytes
                              : null;
                          final isCurrent =
                              Provider.of<MusicPlayerController>(
                                context,
                              ).currentSong?.url ==
                              file.path;
                          _itemKeys[file.path] ??= GlobalKey();
                          return ListTile(
                            key: _itemKeys[file.path],
                            contentPadding: isCurrent
                                ? const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  )
                                : null,
                            tileColor: isCurrent
                                ? Colors.teal.withOpacity(0.2)
                                : null,
                            leading: Hero(
                              tag: file.path,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (albumArt != null)
                                    ? Image.memory(
                                        albumArt,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/album_placeholder.jpg',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ),
                            title: Hero(
                              tag: 'title-' + file.path,
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                  child: SizedBox(
                                    height:
                                        Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 30
                                        : 22,
                                    width: double.infinity,
                                    child: Text(
                                      meta?.title ?? fileName,
                                      key: ValueKey(file.path),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                widget.favorites.contains(file.path)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => widget.addToPlaylist(file.path),
                            ),
                            onTap: () {
                              widget.playSong(file.path);
                              _scrollToCurrentSong(file.path);
                            },
                            onLongPress: () => widget.addToPlaylist(file.path),
                          );
                        },
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
