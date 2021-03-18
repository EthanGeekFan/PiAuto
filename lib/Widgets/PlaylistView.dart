import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';
import 'package:pi_auto/Widgets/AppleMusicPlayerCard.dart';
import 'package:pi_auto/Widgets/MediaCenterWidget.dart';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';

class PlaylistView extends StatefulWidget {
  @override
  _PlaylistViewState createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.back),
                  onPressed: () {
                    cardKey.currentState.toggleCard();
                  },
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Playing Next",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "From Current Playlist",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          StreamBuilder<QueueState>(
            stream: _queueStateStream,
            builder: (context, queueSnapshot) {
              final queueState = queueSnapshot.data;
              final queue = queueState?.queue ?? [];
              final mediaItem = queueState?.mediaItem;
              return Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    var item = queue[index];
                    return ListTile(
                      onTap: () {
                        print("tapped index $index");
                        AudioService.skipToQueueItem(item.id).then(
                          (value) => context
                              .read<NeteaseCloudMusicClient>()
                              .causeRebuild(),
                        );
                      },
                      contentPadding: EdgeInsets.zero,
                      title: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 5.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Colors.grey,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(
                                      item.artUri,
                                      errorBuilder: (context, _, __) =>
                                          Container(),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20.0,
                                  ),
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 21.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            item.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // IconButton(
                            //   icon: Icon(CupertinoIcons.multiply_circle_fill),
                            //   onPressed: () {
                            //     print("remove index $index");
                            //     AudioService.removeQueueItem(item).then(
                            //       (value) => context
                            //           .read<NeteaseCloudMusicClient>()
                            //           .causeRebuild(),
                            //     );
                            //   },
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A stream reporting the combined state of the current queue and the current
/// media item within that queue.
Stream<QueueState> get _queueStateStream =>
    Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
        AudioService.queueStream,
        AudioService.currentMediaItemStream,
        (queue, mediaItem) => QueueState(queue, mediaItem));
