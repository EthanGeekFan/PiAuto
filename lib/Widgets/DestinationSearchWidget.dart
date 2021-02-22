import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DestinationSearchWidget extends StatefulWidget {
  @override
  _DestinationSearchWidgetState createState() =>
      _DestinationSearchWidgetState();
}

class _DestinationSearchWidgetState extends State<DestinationSearchWidget> {
  final SearchBarController<AMapPOI> _searchBarController =
      SearchBarController();
  final platform = MethodChannel("com.ethan.PiAuto");
  List<AMapPOI> resultCache;
  List<SearchItem> searchCache;
  int selectedPOI = 0;

  @override
  Widget build(BuildContext context) {
    final String viewType = 'com.ethan.PiAuto/views/mapview';
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return Center(
      child: Stack(
        children: [
          Center(
            child: UiKitView(
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
          Container(
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.1,
              maxChildSize: 1.0,
              builder: (BuildContext context, scrollController) {
                if (resultCache == null || resultCache.length == 0) {
                  return Container();
                }
                return Container(
                  // padding: EdgeInsets.only(top: 5),
                  margin: EdgeInsets.only(top: 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 20,
                            spreadRadius: 5,
                            color: Colors.grey.withOpacity(0.4),
                            offset: Offset(0, 0))
                      ]),
                  child: ListView.builder(
                    itemCount: resultCache.length,
                    controller: scrollController,
                    itemBuilder: (context, index) {
                      AMapPOI poi = resultCache[index];
                      return GestureDetector(
                        onTap: () async {
                          await selectPOI(index);
                        },
                        child: ListTile(
                          title: Text(poi.name),
                          subtitle: Text(poi.address),
                          trailing: IconButton(
                            icon: Icon(Icons.directions),
                            onPressed: () async {
                              Navigator.of(context).pushNamed("/navigation");
                              getDirections(poi, context);
                            },
                          ),
                          selected: index == selectedPOI,
                          selectedTileColor: Colors.grey.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                // color: Colors.white,
                // height: MediaQuery.of(context).size.height -
                //     (MediaQuery.of(context).viewInsets.top +
                //         MediaQuery.of(context).viewInsets.bottom) -
                //     40,
                height: 80,
                child: SearchBar<AMapPOI>(
                  shrinkWrap: true,
                  debounceDuration: Duration(seconds: 1),
                  searchBarPadding: EdgeInsets.symmetric(horizontal: 10),
                  headerPadding: EdgeInsets.symmetric(horizontal: 10),
                  listPadding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: MediaQuery.of(context).size.height,
                  ),
                  emptyWidget: Center(
                    child: Text(
                      "No Result Found",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  searchBarController: _searchBarController,
                  searchBarStyle: SearchBarStyle(
                    borderRadius: BorderRadius.circular(40.0),
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                  ),
                  minimumChars: 1,
                  hintText: 'Where to?',
                  onError: (error) => Center(
                    child: Text(
                      "Something Wrong",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onCancelled: cancelSearch,
                  onSearch: _searchDestination,
                  // onSearch: _inputTips,
                  onItemFound: (AMapPOI item, int index) {
                    // Icon typeIcon;
                    // switch (item.type) {
                    //   case 0:
                    //     typeIcon = Icon(Icons.search);
                    //     break;
                    //   case 1:
                    //     typeIcon = Icon(Icons.bus_alert);
                    //     break;
                    //   case 1:
                    //     typeIcon = Icon(Icons.pin_drop_rounded);
                    //     break;
                    //   default:
                    //     typeIcon = Icon(Icons.search);
                    // }
                    // return Container(
                    //   clipBehavior: Clip.antiAlias,
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.only(
                    //       topLeft:
                    //           index == 0 ? Radius.circular(10.0) : Radius.zero,
                    //       topRight:
                    //           index == 0 ? Radius.circular(10.0) : Radius.zero,
                    //       bottomLeft: index == resultCache.length
                    //           ? Radius.circular(10.0)
                    //           : Radius.zero,
                    //       bottomRight: index == resultCache.length
                    //           ? Radius.circular(10.0)
                    //           : Radius.zero,
                    //     ),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       GestureDetector(
                    //         onTap: () {
                    //           _searchDestination(item.name);
                    //         },
                    //         child: ListTile(
                    //           leading: typeIcon,
                    //           title: Text(item.name),
                    //           subtitle: Text(item.address),
                    //           tileColor: Colors.white,
                    //         ),
                    //       ),
                    //       Padding(
                    //         padding:
                    //             const EdgeInsets.symmetric(horizontal: 5.0),
                    //         child: Divider(),
                    //       )
                    //     ],
                    //   ),
                    // );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> cancelSearch() async {
    setState(() {
      resultCache = [];
    });
    try {
      final res = await platform.invokeMethod("clearAnnos");
    } catch (e) {
      print("failed to select");
    }
  }

  Future<void> selectPOI(int index) async {
    setState(() {
      selectedPOI = index;
    });
    try {
      final res = await platform.invokeMethod("selectPOI", index);
    } catch (e) {
      print("failed to select");
    }
  }

  Future<List<AMapPOI>> _searchDestination(String searchStr) async {
    try {
      final List rawRes =
          await platform.invokeListMethod("searchPOI", searchStr);
      if (rawRes == null) {
        return resultCache;
      }
      List<AMapPOI> result = List<AMapPOI>();
      for (var item in rawRes) {
        AMapPOI poi = AMapPOI(
          item['name'] as String,
          item['address'] as String,
          item['latitude'] as double,
          item['longitude'] as double,
        );
        result.add(poi);
      }
      setState(() {
        resultCache = result;
        selectedPOI = 0;
      });
      return result;
    } on PlatformException catch (e) {
      print("PLatform Exception: $e");
    }
    return resultCache;
  }

  Future<List<SearchItem>> _inputTips(String keywords) async {
    print("start");
    try {
      print("start");
      final List rawRes =
          await platform.invokeListMethod("inputTips", keywords);
      if (rawRes == null) {
        return searchCache;
      }
      List<SearchItem> result = List<SearchItem>();
      for (var item in rawRes) {
        SearchItem poi = SearchItem(
          item['name'] as String,
          item['address'] as String,
          item['type'] as int,
        );
        result.add(poi);
      }
      setState(() {
        searchCache = result;
      });
      print("hello");
      return result;
    } catch (e) {
      print("Platform Exception: $e");
    }

    return searchCache;
  }

  Future<void> getDirections(AMapPOI poi, BuildContext context) async {
    print("GO TO POI: ${poi.name} at ${poi.latitude}, ${poi.longitude}");
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case "stopNavigation":
          Navigator.of(context).pop();
          break;
        default:
          return null;
      }
    });
    await platform.invokeMethod('gotoPOI', [poi.latitude, poi.longitude]);
  }
}

class AMapPOI {
  String name;
  String address;
  double latitude;
  double longitude;

  AMapPOI(this.name, this.address, this.latitude, this.longitude);
}

class SearchItem {
  String name;
  String address;
  int type;

  SearchItem(this.name, this.address, this.type);
}
