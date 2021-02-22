import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Models/MediaCenterModel.dart';
import 'package:pi_auto/Widgets/AppleMusicPlayerCard.dart';
import 'package:pi_auto/Widgets/BrowserView.dart';
import 'package:pi_auto/Widgets/PlaylistView.dart';
import 'package:provider/provider.dart';

class MediaCenterWidget extends StatefulWidget {
  @override
  _MediaCenterWidgetState createState() => _MediaCenterWidgetState();
}

GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

class _MediaCenterWidgetState extends State<MediaCenterWidget> {
  Widget playlistView = PlaylistView();
  Widget browserView = BrowserView();

  @override
  Widget build(BuildContext context) {
    print(playlistView.hashCode);
    print(browserView.hashCode);
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: FlipCard(
        direction: FlipDirection.HORIZONTAL,
        flipOnTouch: false,
        key: cardKey,
        front: AppleMusicPlayerCard(),
        back: context.watch<MediaCenterCardControllerModel>().showPlaylist
            ? playlistView
            : browserView,
      ),
    );
  }
}

class MediaCenterCardControllerModel with ChangeNotifier {
  bool _showPlaylist = true;
  bool get showPlaylist => _showPlaylist;
  set showPlaylist(bool value) {
    _showPlaylist = value;
    notifyListeners();
  }

  void togglePlaylist() {
    showPlaylist = true;
    cardKey.currentState.toggleCard();
  }

  void toggleBrowser() {
    showPlaylist = false;
    cardKey.currentState.toggleCard();
  }
}
