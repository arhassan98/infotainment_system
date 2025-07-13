/// Model representing a song for the music player feature.
/// Contains metadata such as title, artist, URL, album art, lyrics, and favorite status.
class Song {
  /// The song title.
  final String title;

  /// The song artist.
  final String artist;

  /// The song file URL or path.
  final String url;

  /// The album art image URL or path.
  final String albumArtUrl;

  /// The song lyrics, if available.
  final String? lyrics;

  /// Whether the song is marked as favorite.
  bool isFavorite;

  /// Creates a new [Song] instance.
  Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.albumArtUrl,
    this.lyrics,
    this.isFavorite = false,
  });

  /// Converts the [Song] instance to a JSON map.
  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'url': url,
    'albumArtUrl': albumArtUrl,
    'lyrics': lyrics,
    'isFavorite': isFavorite,
  };

  /// Creates a [Song] instance from a JSON map.
  factory Song.fromJson(Map<String, dynamic> json) => Song(
    title: json['title'],
    artist: json['artist'],
    url: json['url'],
    albumArtUrl: json['albumArtUrl'],
    lyrics: json['lyrics'],
    isFavorite: json['isFavorite'] ?? false,
  );
}
