import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';
import 'package:pi_auto/main.dart';

class MusicPlayerTask extends BackgroundAudioTask {
  AudioPlayer player = new AudioPlayer();
  AudioProcessingState _skipState;
  StreamSubscription<PlaybackEvent> _eventSubscription;
  NeteaseCloudMusicModel api = neteaseCloudMusicModel;
  MyPlaylist _myPlaylist = MyPlaylist();

  int get index => _myPlaylist.currentIndex;
  MediaItem get mediaItem => index == null ? null : _myPlaylist.current();

  Future<void> loadLibrary() async {
    // Default Daily recommended Songs:
    _myPlaylist.setPlaylist(
        (await neteaseCloudMusicModel.fetchDailyRecommendedSongs())
            .map((e) => e.toMediaItem())
            .toList());

    onUpdateQueue(_myPlaylist.playlist);
  }

  Future<void> usePlaylist(String playlistId) async {
    _myPlaylist.setPlaylist(
        (await neteaseCloudMusicModel.fetchPlaylistDetail(playlistId))
            .tracks
            .map((e) => e.toMediaItem())
            .toList());
    _myPlaylist.playlist.removeWhere((element) => element == null);
    // Load and broadcast the queue
    await AudioServiceBackground.setQueue(_myPlaylist.playlist);
    onPlay();
  }

  // Future updateUrlList() async {
  //   print(playlist.length);
  //   var rawUrls = await api.parseSongsUrl(playlist.map((e) => e.id).toList());
  //   urlList = [];
  //   var corruptedIds = [];
  //   for (var i = 0; i < playlist.length; i++) {
  //     var newUrl = rawUrls[playlist[i].id];
  //     if (newUrl == null) {
  //       print("something wrong");
  //       corruptedIds.add(playlist[i].id);
  //     } else {
  //       urlList.add(newUrl);
  //     }
  //   }
  //   playlist.removeWhere((element) => corruptedIds.contains(element.id));
  //   print(urlList.length);
  // }

  // Future<void> setAudioSource(int index) async {
  //   await onPause();
  //   try {
  //     print("1: " + DateTime.now().toString());
  //     var sources = urlList.map((e) => AudioSource.uri(Uri.parse(e))).toList();
  //     print("2: " + DateTime.now().toString());
  //     await player.setAudioSource(
  //       ConcatenatingAudioSource(
  //         children: sources,
  //       ),
  //       initialIndex: index ?? 0,
  //       preload: false,
  //     );
  //     print("3: " + DateTime.now().toString());
  //     onPlay();
  //   } catch (e) {
  //     print("Error: $e");
  //     // onStop();
  //   }
  // }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    // Propagate all events from the audio player to AudioService clients.
    _eventSubscription = player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    player.positionStream.listen((position) async {
      if (position == null) {
        return;
      }
      // var duration = _myPlaylist.current()?.duration;
      var duration = player.duration;
      if (position >= duration) {
        await onSkipToNext();
      }
    });

    // player.playerStateStream.listen((event) async {
    //   print()
    // });

    // Special processing for state transitions.
    player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          // In this example, the service stops when reaching the end.
          // onStop();
          break;
        case ProcessingState.ready:
          // If we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          onPlay();
          break;
        default:
          break;
      }
    });
    await loadLibrary();
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) async {
    this._myPlaylist.setPlaylist(queue);
    // Load and broadcast the queue
    await AudioServiceBackground.setQueue(_myPlaylist.playlist);
    await AudioServiceBackground.setMediaItem(mediaItem);
    onPlay();
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex =
        _myPlaylist.playlist.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).
    _skipState = newIndex > index
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    // This jumps to the beginning of the queue item at newIndex.
    var success = _myPlaylist.skipToItem(newIndex);
    if (!success) {
      return;
    }
    AudioServiceBackground.setMediaItem(mediaItem);
    onPlay();
  }

  @override
  Future<void> onPlay() async {
    try {
      if (mediaItem == null) {
        return;
      }
      var currentPosition = player.position;
      var url = _myPlaylist.currentUrl;
      if (url != null) {
        // already played
        RegExp regExp = RegExp(r"\/(\d{14})\/");
        var timeStr = regExp.firstMatch(url).group(0);
        if (timeStr != null) {
          var rawDateTime = timeStr.replaceAll("\/", "");
          var date = [
            rawDateTime.substring(0, 4),
            rawDateTime.substring(4, 6),
            rawDateTime.substring(6, 8)
          ].join('-');
          var time = [
            rawDateTime.substring(8, 10),
            rawDateTime.substring(10, 12),
            rawDateTime.substring(12, 14)
          ].join(':');
          DateTime expire = DateTime.tryParse([date, time].join('T'));
          if (expire.isBefore(DateTime.now())) {
            // paused for too long that url expired
            // replace the url of this song
            var newUrl = await api.parseSongUrl(mediaItem.id);
            await player.setAudioSource(
              AudioSource.uri(Uri.parse(newUrl)),
              initialPosition: currentPosition,
            );
          }
        } else {
          print("no match");
        }
      } else {
        // init source:
        var newUrl = await api.parseSongUrl(mediaItem.id);
        _myPlaylist.currentUrl = newUrl;
        if (newUrl == null) {
          onSkipToNext();
          print(mediaItem.toString());
        }
        await player.setAudioSource(
          AudioSource.uri(Uri.parse(newUrl)),
        );
      }
      player.play();
    } catch (e) {
      print("Catch " + e.toString());
    }
  }

  @override
  Future<void> onPause() => player.pause();

  @override
  Future<void> onSeekTo(Duration position) => player.seek(position);

  @override
  Future<void> onSkipToNext() async {
    var next = _myPlaylist.next();
    if (next == null) {
      return;
    }
    await AudioServiceBackground.setMediaItem(mediaItem);
    onPlay();
  }

  @override
  Future<void> onSkipToPrevious() async {
    var next = _myPlaylist.previous();
    if (next == null) {
      return;
    }
    await AudioServiceBackground.setMediaItem(mediaItem);
    onPlay();
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      _myPlaylist.mode = MyPlayMode.loopAll;
    } else {
      _myPlaylist.mode = MyPlayMode.shuffle;
    }
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (repeatMode == AudioServiceRepeatMode.none) {
      _myPlaylist.mode = MyPlayMode.loopAll;
    } else if (repeatMode == AudioServiceRepeatMode.one) {
      _myPlaylist.mode = MyPlayMode.loopOne;
    } else {
      _myPlaylist.mode = MyPlayMode.loopAll;
    }
  }

  @override
  Future<void> onStop() async {
    await player.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: player.playing,
      position: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    );
  }

  AudioProcessingState _getProcessingState() {
    if (_skipState != null) return _skipState;
    switch (player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${player.processingState}");
    }
  }
}

enum MyPlayMode {
  loopOne,
  loopAll,
  shuffle,
}

class MyPlaylist {
  List<MediaItem> playlist = [];
  int _currentIndex = 0;
  String currentUrl;
  MyPlayMode mode = MyPlayMode.loopAll;
  List<int> history = [];
  int _historyIndex = 0;

  // List<MediaItem> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  void setPlaylist(List<MediaItem> p) {
    // history = [];
    // _historyIndex = 0;
    playlist = p;
    _currentIndex = 0;
    currentUrl = null;
  }

  void addAll(List<MediaItem> mediaItems) {
    playlist.addAll(mediaItems);
  }

  void add(MediaItem mediaItem) {
    playlist.add(mediaItem);
  }

  void addNext(MediaItem mediaItem) {
    playlist.insert(_currentIndex + 1, mediaItem);
  }

  void clearList() {
    playlist.clear();
    _currentIndex = 0;
  }

  MediaItem removeAt(int rmIndex) {
    if (rmIndex >= 0) {
      // Found object
      if (rmIndex < _currentIndex) {
        _currentIndex -= 1;
      } else if (rmIndex == _currentIndex) {
        return null;
      }
      return playlist.removeAt(rmIndex);
    } else {
      return null;
    }
  }

  bool remove(MediaItem mediaItem) {
    int rmIndex = playlist.indexOf(mediaItem);
    if (rmIndex >= 0) {
      // Found object
      if (rmIndex < _currentIndex) {
        _currentIndex -= 1;
      } else if (rmIndex == _currentIndex) {
        return false;
      }
      return playlist.remove(mediaItem);
    } else {
      return false;
    }
  }

  // Called by MusicPlayer
  MediaItem next() {
    currentUrl = null;
    switch (mode) {
      case MyPlayMode.loopAll:
        // history.insert(0, _currentIndex);
        // _historyIndex = 0;
        if (this.hasNext()) {
          _currentIndex += 1;
          return playlist[_currentIndex];
        } else if (this.hasFirst()) {
          _currentIndex = 0;
          return playlist[_currentIndex];
        }
        return null;
      case MyPlayMode.loopOne:
        return playlist[_currentIndex];
      case MyPlayMode.shuffle:
        if (playlist.length <= 0) {
          return null;
        }
        if (history.length > 0 && _historyIndex != 0) {
          return playlist[history[_historyIndex]];
        }
        // history.insert(0, _currentIndex);
        // _historyIndex = 0;
        _currentIndex = Random().nextInt(playlist.length);
        return playlist[_currentIndex];
      default:
        return null;
    }
  }

  // Called by MusicPlayer
  MediaItem previous() {
    currentUrl = null;
    switch (mode) {
      case MyPlayMode.loopAll:
        // history.insert(0, _currentIndex);
        // _historyIndex = 0;
        if (this.hasPrevious()) {
          _currentIndex -= 1;
          return playlist[_currentIndex];
        } else if (this.hasLast()) {
          _currentIndex = playlist.length - 1;
          return playlist[_currentIndex];
        }
        return null;
      case MyPlayMode.loopOne:
        return playlist[_currentIndex];
      case MyPlayMode.shuffle:
        if (playlist.length <= 0) {
          return null;
        }
        if (history.length > 0) {
          return playlist[history[_historyIndex++]];
        }
        // history.insert(0, _currentIndex);
        // _historyIndex = 0;
        _currentIndex = Random().nextInt(playlist.length);
        return playlist[_currentIndex];
      default:
        return null;
    }
  }

  bool skipToItem(int index) {
    if (index < 0 || index >= playlist.length) {
      return false;
    } else {
      currentUrl = null;
      // history.insert(0, _currentIndex);
      // _historyIndex = 0;
      _currentIndex = index;
      return true;
    }
  }

  MediaItem current() {
    if (_currentIndex >= 0 && _currentIndex < playlist.length) {
      return playlist[_currentIndex];
    } else {
      return null;
    }
  }

  bool hasPrevious() {
    return _currentIndex > 0 && _currentIndex < playlist.length;
  }

  bool hasNext() {
    return _currentIndex < playlist.length - 1 && _currentIndex >= 0;
  }

  bool hasFirst() {
    return playlist.length > 0;
  }

  bool hasLast() {
    return playlist.length > 0;
  }
}
