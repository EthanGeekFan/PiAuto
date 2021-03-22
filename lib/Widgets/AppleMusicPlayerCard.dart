import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_auto/Models/MediaCenterModel.dart';
import 'package:pi_auto/Widgets/MediaCenterWidget.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volume_watcher/volume_watcher.dart';
import 'package:provider/provider.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';

void _musicPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => MusicPlayerTask());
}

class AppleMusicPlayerCard extends StatefulWidget {
  @override
  _AppleMusicPlayerCardState createState() => _AppleMusicPlayerCardState();
}

class _AppleMusicPlayerCardState extends State<AppleMusicPlayerCard> {
  Duration songDuration;
  double _volume = 0;
  double _maxVolume = 1;
  int playlistMode = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      VolumeWatcher.hideVolumeView = false;
    } on PlatformException {}

    double initVolume;
    double maxVolume;
    try {
      initVolume = await VolumeWatcher.getCurrentVolume;
      maxVolume = await VolumeWatcher.getMaxVolume;
    } on PlatformException {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      this._volume = initVolume;
      this._maxVolume = maxVolume;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.white,
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            // color: Colors.grey[300],
            color: Theme.of(context).shadowColor,
            blurRadius: 10.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: StreamBuilder<bool>(
                  stream: AudioService.runningStream,
                  builder: (context, runningSnapshot) {
                    if (runningSnapshot.connectionState !=
                        ConnectionState.active) {
                      // Don't show anything until we've ascertained whether or not the
                      // service is running, since we want to show a different UI in
                      // each case.
                      return Text("Service not available");
                    }
                    final running = runningSnapshot.data ?? false;
                    if (!running) {
                      AudioService.start(
                          backgroundTaskEntrypoint: _musicPlayerTaskEntrypoint);
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 0.0),
                      child: StreamBuilder<QueueState>(
                        stream: _queueStateStream,
                        builder: (context, queueSnapshot) {
                          context.watch<NeteaseCloudMusicClient>();
                          final queueState = queueSnapshot.data;
                          final queue = queueState?.queue ?? [];
                          final mediaItem = queueState?.mediaItem;
                          String title = "";
                          String artist = "";
                          String artUri;
                          String id = "";
                          if (mediaItem != null) {
                            title = mediaItem.title;
                            artist = mediaItem.artist;
                            artUri = mediaItem.artUri;
                            id = mediaItem.id;
                          }
                          return Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.0),
                                child: Center(
                                  child: Container(
                                    child: artUri != null
                                        ? Image.network(
                                            artUri,
                                            errorBuilder: (context, exception,
                                                stacktrace) {
                                              print(exception);
                                              return Container();
                                            },
                                            fit: BoxFit.cover,
                                          )
                                        : Container(),
                                    height: 200,
                                    width: 200,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.grey,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          offset: Offset(0, 10),
                                          color: Theme.of(context).shadowColor,
                                          spreadRadius: 10.0,
                                          blurRadius: 20.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          artist,
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.pink,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40.0,
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          child: IconButton(
                                            iconSize: 20,
                                            splashColor: Colors.pink[100],
                                            padding: EdgeInsets.zero,
                                            icon: Builder(builder: (context) {
                                              var icon;
                                              switch (context
                                                  .watch<
                                                      NeteaseCloudMusicClient>()
                                                  .playMode) {
                                                case NeteaseCloudMusicPlayMode
                                                    .list:
                                                  icon = CupertinoIcons
                                                      .list_bullet_indent;
                                                  break;
                                                case NeteaseCloudMusicPlayMode
                                                    .loopAll:
                                                  icon = CupertinoIcons.repeat;
                                                  break;
                                                case NeteaseCloudMusicPlayMode
                                                    .loopOne:
                                                  icon =
                                                      CupertinoIcons.repeat_1;
                                                  break;
                                                case NeteaseCloudMusicPlayMode
                                                    .shuffle:
                                                  icon = CupertinoIcons.shuffle;
                                                  break;
                                                default:
                                                  icon = CupertinoIcons
                                                      .list_bullet_indent;
                                              }
                                              return Center(
                                                child: Icon(
                                                  icon,
                                                  color: Colors.pinkAccent,
                                                  size: 20,
                                                ),
                                              );
                                            }),
                                            onPressed: () {
                                              context
                                                  .read<
                                                      NeteaseCloudMusicClient>()
                                                  .switchPlayMode();
                                            },
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: FutureBuilder<bool>(
                                            future: context
                                                .watch<
                                                    NeteaseCloudMusicClient>()
                                                .checkIfLiked(id),
                                            builder: (context, snapshot) {
                                              bool isLiked;
                                              if (!snapshot.hasData) {
                                                isLiked = false;
                                              } else if (snapshot.hasError) {
                                                isLiked = false;
                                              } else {
                                                isLiked = snapshot.data;
                                              }
                                              context.watch<
                                                  NeteaseCloudMusicClient>();
                                              return IconButton(
                                                splashColor: Colors.pink,
                                                padding: EdgeInsets.zero,
                                                icon: Icon(
                                                  isLiked
                                                      ? CupertinoIcons
                                                          .heart_fill
                                                      : CupertinoIcons.heart,
                                                  color: Colors.pinkAccent,
                                                ),
                                                onPressed: () async {
                                                  print(isLiked);
                                                  if (isLiked) {
                                                    await context
                                                        .read<
                                                            NeteaseCloudMusicClient>()
                                                        .dislike(id);
                                                  } else {
                                                    await context
                                                        .read<
                                                            NeteaseCloudMusicClient>()
                                                        .like(id);
                                                  }
                                                  setState(() {});
                                                },
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              StreamBuilder<Duration>(
                                stream: AudioService.positionStream,
                                builder: (context, positionSnapshot) {
                                  var position = Duration.zero;
                                  var duration = Duration.zero;
                                  if (positionSnapshot.hasData) {
                                    position = positionSnapshot.data;
                                  }
                                  if (mediaItem?.duration != null) {
                                    duration = mediaItem.duration;
                                  }
                                  if (position > duration) {
                                    position = duration;
                                  }
                                  context.watch<NeteaseCloudMusicClient>();
                                  return Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          inactiveTrackColor: Colors.grey[500],
                                          activeTrackColor: Colors.grey[600],
                                          trackHeight: 3.0,
                                          trackShape: CustomSliderTrackShape(),
                                          thumbColor: Colors.grey[600],
                                          thumbShape: RoundSliderThumbShape(
                                              enabledThumbRadius: 5.0),
                                        ),
                                        child: Slider(
                                          min: 0.0,
                                          max: duration.inMilliseconds
                                                  .toDouble() +
                                              500.0,
                                          value: position.inMilliseconds
                                              .toDouble(),
                                          onChanged: (position) {
                                            if (mediaItem?.duration == null) {
                                              return;
                                            }
                                            AudioService.seekTo(
                                              Duration(
                                                  milliseconds:
                                                      position.toInt()),
                                            );
                                          },
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            positionSnapshot?.data
                                                    ?.toString()
                                                    ?.split('.')
                                                    ?.first ??
                                                "0:00:00",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            mediaItem?.duration
                                                    ?.toString()
                                                    ?.split('.')
                                                    ?.first ??
                                                "-:--:--",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      iconSize: 50,
                                      icon: Icon(
                                        CupertinoIcons.backward_fill,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          AudioService.skipToPrevious();
                                        });
                                      },
                                    ),
                                    StreamBuilder<bool>(
                                        stream: AudioService.playbackStateStream
                                            .map((state) => state.playing)
                                            .distinct(),
                                        builder: (context, snapshot) {
                                          final playing =
                                              snapshot.data ?? false;
                                          // bool enabled = true;
                                          // if (!snapshot.hasData) {
                                          //   enabled = false;
                                          // }
                                          // if (snapshot.hasError) {
                                          //   enabled = false;
                                          // }
                                          return IconButton(
                                            iconSize: 50,
                                            icon: Icon(playing
                                                ? CupertinoIcons.pause_fill
                                                : CupertinoIcons.play_fill),
                                            onPressed: () {
                                              setState(() {
                                                if (playing) {
                                                  AudioService.pause();
                                                } else {
                                                  AudioService.play();
                                                }
                                              });
                                            },
                                          );
                                        }),
                                    IconButton(
                                      iconSize: 50,
                                      icon: Icon(
                                        CupertinoIcons.forward_fill,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          AudioService.skipToNext();
                                        });
                                      },
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  VolumeWatcher(
                                    onVolumeChangeListener: (double volume) {
                                      setState(() {
                                        _volume = volume;
                                      });
                                    },
                                  ),
                                  Icon(
                                    CupertinoIcons.speaker_fill,
                                    color: Colors.grey[600],
                                    size: 15,
                                  ),
                                  Flexible(
                                    child: Slider.adaptive(
                                      min: 0.0,
                                      max: 1.0,
                                      value: _volume / _maxVolume,
                                      onChanged: (volume) {
                                        setState(() {
                                          _volume = volume;
                                          VolumeWatcher.setVolume(
                                              _maxVolume * volume);
                                        });
                                      },
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.speaker_3_fill,
                                    color: Colors.grey[600],
                                    size: 15,
                                  ),
                                ],
                              )
                            ],
                          );
                        },
                      ),
                    );
                  }),
            ),
          ),
          Positioned(
            top: 5,
            left: 5,
            child: IconButton(
              icon: Icon(CupertinoIcons.list_bullet),
              onPressed: () {
                context.read<MediaCenterCardControllerModel>().togglePlaylist();
              },
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: Icon(CupertinoIcons.music_note_list),
              onPressed: () {
                context.read<MediaCenterCardControllerModel>().toggleBrowser();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem, Duration, MediaState>(
          AudioService.currentMediaItemStream,
          AudioService.positionStream,
          (mediaItem, position) => MediaState(mediaItem, position));

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));
}

class QueueState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
