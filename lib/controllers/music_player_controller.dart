/// Controller for managing music playback, playlist, and player state.
/// Handles play, pause, next/previous, shuffle, repeat, and state persistence.
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

// RepeatMode enum moved from music_player.dart
enum RepeatMode { off, all, one }

class MusicPlayerController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  List<Song> playlist = [];
  int currentIndex = 0;
  bool isPlaying = false;
  bool isShuffle = false;
  RepeatMode repeatMode = RepeatMode.off;
  double volume = 1.0;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  MusicPlayerController() {
    _init();
    restoreState();
  }

  Song? get currentSong =>
      playlist.isNotEmpty && currentIndex >= 0 && currentIndex < playlist.length
      ? playlist[currentIndex]
      : null;

  void _init() async {
    if (playlist.isNotEmpty) {
      await player.setUrl(playlist[currentIndex].url);
    }
    player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
    player.durationStream.listen((d) {
      duration = d ?? Duration.zero;
      notifyListeners();
    });
    player.positionStream.listen((p) {
      position = p;
      if (duration != Duration.zero && position >= duration) {
        _handleSongEnd();
      }
      notifyListeners();
    });
    player.setVolume(volume);
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'playlist',
      jsonEncode(playlist.map((s) => s.toJson()).toList()),
    );
    prefs.setInt('currentIndex', currentIndex);
    prefs.setDouble('position', position.inMilliseconds.toDouble());
    prefs.setBool('isShuffle', isShuffle);
    prefs.setBool('isRepeat', repeatMode != RepeatMode.off);
  }

  Future<void> restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistStr = prefs.getString('playlist');
    if (playlistStr != null) {
      final List<dynamic> decoded = jsonDecode(playlistStr);
      playlist = decoded.map((e) => Song.fromJson(e)).toList();
    }
    currentIndex = prefs.getInt('currentIndex') ?? 0;
    final posMs = prefs.getDouble('position');
    if (posMs != null) position = Duration(milliseconds: posMs.toInt());
    isShuffle = prefs.getBool('isShuffle') ?? false;
    repeatMode = prefs.getBool('isRepeat') == true
        ? RepeatMode.all
        : RepeatMode.off;
    if (playlist.isNotEmpty) {
      await player.setUrl(playlist[currentIndex].url);
      await player.seek(position);
    }
    notifyListeners();
  }

  void _handleSongEnd() {
    if (repeatMode == RepeatMode.one) {
      player.seek(Duration.zero);
      player.play();
    } else if (repeatMode == RepeatMode.all && playlist.isNotEmpty) {
      nextSong();
    } else if (currentIndex < playlist.length - 1) {
      nextSong();
    } else {
      player.seek(Duration.zero);
      player.pause();
    }
    saveState();
  }

  void nextSong() async {
    if (isShuffle) {
      final indices = List.generate(playlist.length, (i) => i)
        ..remove(currentIndex);
      indices.shuffle();
      currentIndex = indices.first;
    } else {
      currentIndex = (currentIndex + 1) % playlist.length;
    }
    await player.setUrl(playlist[currentIndex].url);
    player.play();
    notifyListeners();
    saveState();
  }

  void previousSong() async {
    if (isShuffle) {
      final indices = List.generate(playlist.length, (i) => i)
        ..remove(currentIndex);
      indices.shuffle();
      currentIndex = indices.first;
    } else {
      currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    }
    await player.setUrl(playlist[currentIndex].url);
    player.play();
    notifyListeners();
    saveState();
  }

  void playPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    notifyListeners();
    saveState();
  }

  void setVolume(double value) {
    volume = value;
    player.setVolume(volume);
    notifyListeners();
    saveState();
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
    saveState();
  }

  void toggleRepeat() {
    switch (repeatMode) {
      case RepeatMode.off:
        repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
    saveState();
  }

  Future<void> playSongWithMetadata(
    String filePath,
    Future<AudioMetadata?> Function(String) getMetadata,
  ) async {
    try {
      if (kDebugMode) {
        print('Playing song with metadata: $filePath');
      }
      final metadata = await getMetadata(filePath);
      final fileName = filePath.split('/').last;
      final tempSong = Song(
        title: metadata?.title ?? fileName,
        artist: metadata?.artist ?? 'Unknown Artist',
        url: filePath,
        albumArtUrl: '',
        lyrics: null,
      );
      if (kDebugMode) {
        print('Created song:  [1m${tempSong.title} [0m by ${tempSong.artist}');
      }
      final existingIndex = playlist.indexWhere((song) => song.url == filePath);
      if (existingIndex == -1) {
        playlist.add(tempSong);
        currentIndex = playlist.length - 1;
        if (kDebugMode) {
          print('Added new song to playlist at index $currentIndex');
        }
      } else {
        currentIndex = existingIndex;
        if (kDebugMode) {
          print('Found existing song at index $currentIndex');
        }
      }
      await player.setUrl(filePath);
      player.play();
      notifyListeners();
      if (kDebugMode) {
        print('Successfully started playing: ${tempSong.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing song with metadata: $e');
      }
      try {
        await player.setUrl(filePath);
        player.play();
        final fileName = filePath.split('/').last;
        final tempSong = Song(
          title: fileName,
          artist: 'Unknown Artist',
          url: filePath,
          albumArtUrl: '',
          lyrics: null,
        );
        final existingIndex = playlist.indexWhere(
          (song) => song.url == filePath,
        );
        if (existingIndex == -1) {
          playlist.add(tempSong);
          currentIndex = playlist.length - 1;
        } else {
          currentIndex = existingIndex;
        }
        notifyListeners();
        if (kDebugMode) {
          print('Fallback playback successful for: $fileName');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Fallback playback also failed: $fallbackError');
        }
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
 