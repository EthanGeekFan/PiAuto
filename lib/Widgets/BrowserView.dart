import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pi_auto/Configurations/NeteaseCloudMusicConfig.dart';
import 'package:pi_auto/Models/MediaCenterModel.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';
import 'package:pi_auto/Widgets/MediaCenterWidget.dart';
import 'AppleMusicPlayerCard.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

class BrowserView extends StatefulWidget {
  @override
  _BrowserViewState createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300],
            blurRadius: 10.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Stack(
        // mainAxisSize: MainAxisSize.max,
        children: [
          // content
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // 推荐歌单
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 70,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        "推荐歌单",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      // color: Colors.indigo,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: context
                            .watch<NeteaseCloudMusicClient>()
                            .recommendedPlaylists
                            .length,
                        itemBuilder: (context, index) {
                          var playlistPreview = context
                              .watch<NeteaseCloudMusicClient>()
                              .recommendedPlaylists[index];
                          return PlaylistPreviewWidget(
                              playlistPreview: playlistPreview);
                        },
                      ),
                    ),
                  ],
                ),
                // 每日推荐
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        "每日推荐",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: context
                            .watch<NeteaseCloudMusicClient>()
                            .dailyRecommendedPlaylists
                            .length,
                        itemBuilder: (context, index) {
                          var playlistPreview = context
                              .watch<NeteaseCloudMusicClient>()
                              .dailyRecommendedPlaylists[index];
                          return PlaylistPreviewWidget(
                              playlistPreview: playlistPreview);
                        },
                      ),
                    ),
                  ],
                ),
                // 我的收藏
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        "我的收藏",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: context
                            .watch<NeteaseCloudMusicClient>()
                            .userPlaylists
                            .length,
                        itemBuilder: (context, index) {
                          var playlistPreview = context
                              .watch<NeteaseCloudMusicClient>()
                              .userPlaylists[index];
                          return PlaylistPreviewWidget(
                              playlistPreview: playlistPreview);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // Header
          ClipRect(
            clipBehavior: Clip.antiAlias,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(CupertinoIcons.back),
                            onPressed: () {
                              cardKey.currentState.toggleCard();
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Explore Playlists",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    "Powered by Netease Cloud Music",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        context.watch<NeteaseCloudMusicModel>().loggedin
                            ? CupertinoIcons.person_circle_fill
                            : CupertinoIcons.person_circle,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistPreviewWidget extends StatelessWidget {
  const PlaylistPreviewWidget({
    Key key,
    @required this.playlistPreview,
  }) : super(key: key);

  final PlaylistPreview playlistPreview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          context
              .read<NeteaseCloudMusicClient>()
              .usePlaylist(playlistPreview.id);
        },
        child: Container(
          width: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                child: Image.network(
                  playlistPreview.coverImgUrl ?? "",
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    playlistPreview.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
