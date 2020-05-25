import 'package:countdown_app/helpers/countdownStringHelper.dart';
import 'package:countdown_app/helpers/loaderDialog.dart';
import 'package:countdown_app/helpers/loading.dart';
import 'package:countdown_app/models/countdown.dart';
import 'package:countdown_app/models/response.dart';
import 'package:countdown_app/services/CountdownCrudService.dart';
import 'package:countdown_app/services/CountingService.dart';
import 'package:countdown_app/widgets/countdownCards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';

import '../getit.dart';

//TODO:setup page with LastEvaluatedKey (refer) and per_page and load more with scroll tomorrow..
//TODO:setup editing
//TODO:add image to countdown
//TODO:publc/private toggle and work on public listings.
//TODO:setup a huge list of fake countdowns for public.. load by file and make use of filters etc.
//DEADLINE 3 days.

class UserCountdownPage extends StatefulWidget {
  @override
  _UserCountdownPageState createState() => _UserCountdownPageState();

  UserCountdownPage({key}):super(key:key);
}

class _UserCountdownPageState extends State<UserCountdownPage>
    with AutomaticKeepAliveClientMixin<UserCountdownPage> {
  bool isError = true;

  final countingService = getIt<CountingService>();
  GlobalKey<AnimatedListState> _listKey;
  //change notifier provider
  CountdownService countdownService;

  @override
  void initState() {
    countdownService = getIt<CountdownService>();
    _listKey = countdownService.countdownChangeNotifier.listKey;
    SchedulerBinding.instance
        .addPostFrameCallback((_) => countdownService.loadMoreCountdowns());
    super.initState();
  }

  @override
  void dispose() {
    print("DISPOSING");
    super.dispose();
  }

  //make an onchange stream within the app and use the stream onchange event to rebuild the listview. (on new insert and so forth)

  @override
  Widget build(BuildContext context) {
    //find a way to do it without the builder? idk.
    return ChangeNotifierProvider(
      create: (ctx) => countdownService.countdownChangeNotifier,
      child: Consumer<CountdownChangeNotifier>(
        builder: (BuildContext context, CountdownChangeNotifier value,
            Widget child) {
          return (value.countdownList.length <= 0)
              ? Center(
                  child: Loading(
                  color: Colors.white24,
                ))
              : LiquidPullToRefresh(
                key: widget.key,
                  child: AnimatedList(
                    key: _listKey,
                    itemBuilder: (context, i, anim) {
                      print("BUILDING ITEMS $i");
                      return _buildItem(value, context, i, null);
                    },
                    initialItemCount: value.countdownList.length,
                    shrinkWrap: true,
                  ),
                  color: Colors.black,
                  showChildOpacityTransition: false,
                  onRefresh: () async {
                    countdownService.reload();
                    return;
                  },
                );
        },
      ),
    );
  }

  _showErrorDialog(title, errorMessage) {
    showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(20),
            children: <Widget>[Text(errorMessage)],
            title: Text(title),
          );
        });
  }

  _buildItem(value, context, i, anim) {
    bool isLast = false;
    if (i == value.countdownList.length - 1) isLast = true;
    return (!value.countdownList[i].isCompleted)
        ? StreamBuilder<Object>(
            stream: countingService.streamController.stream,
            builder: (context, tick) {
              String text = "Countdown over";

              //on stream tick parse CountdownData.expired and check if it has Expired already and set the text
              if (int.parse(value.countdownList[i].expired) >
                  DateTime.now().millisecondsSinceEpoch) {
                String data = DateTime.fromMillisecondsSinceEpoch(
                        int.parse(value.countdownList[i].expired))
                    .difference(new DateTime.now())
                    .abs()
                    .toString(); //random fixed future date
                text = parseCountdownToText(data);
              } else {
                value.countdownList[i].setIsCompleted();
              }

              //return a card that displays the countdown data.

              return CountdownNoImage(
                countdownData: value.countdownList[i],
                textAnimate: text,
                isLast: isLast,
                onDeleteTap: () {
                  print(
                      "Deleting ${value.countdownList[i].title} ${value.countdownList[i].id}");
                  _showDeleteDialog(value, i);
                },
                onEditTap: () {
                  print(
                      "Editing ${value.countdownList[i].title} ${value.countdownList[i].id}");
                },
              );
            })
        : CountdownNoImage(
            countdownData: value.countdownList[i],
            textAnimate: "Completed",
            complete: true,
            gradientOption: GradientOption.RED,
            isLast: isLast,
            onDeleteTap: () {
              print(
                  "Deleting ${value.countdownList[i].title} ${value.countdownList[i].id}");
              _showDeleteDialog(value, i);
            },
            onEditTap: () {
              print(
                  "Editing ${value.countdownList[i].title} ${value.countdownList[i].id}");
            },
          );
  }

  _buildRemovedItem(removedIsLast, removedItem) {
    return (!removedItem.isCompleted)
        ? CountdownNoImage(
            countdownData: removedItem,
            textAnimate: "Deleted",
            isLast: removedIsLast,
            onDeleteTap: () {},
            onEditTap: () {},
          )
        : CountdownNoImage(
            countdownData: removedItem,
            textAnimate: "Deleted",
            complete: true,
            gradientOption: GradientOption.RED,
            isLast: removedIsLast,
            onDeleteTap: () {},
            onEditTap: () {},
          );
  }

  _showDeleteDialog(service,i) {
    CountdownData countdown = service.countdownList[i];
    int countdownsLength = service.countdownList.length;
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
              title: Text("Confirm Deletion"),
              contentPadding: EdgeInsets.all(20),
              actions: <Widget>[
                FlatButton(
                  child: Text("DELETE"),
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                ),
                FlatButton(
                  child: Text("CANCEL"),
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                )
              ],
              content: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Are you sure you want to ',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(
                        text: 'delete (${countdown.title}) ',
                        style: TextStyle(color: Colors.redAccent)),
                    TextSpan(
                        text:
                            'countdown scheduled to ${getDateStringFromExpired2(countdown.expired)}',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ));
        }).then((onValue) {
      print("Deleting for good $onValue");
      if (onValue == null || !onValue) {
        return;
      }
      //delete code here
      //TODO:show loader.
      
      showLoadingDialog(context);
      countdownService.deleteCountdown(countdown.id).then((onValue) {
        Navigator.pop(context);
        if (onValue is CountdownSuccessResponse) {
          print("deleted");
          bool removedIsLast = false;
          if (i == countdownsLength - 1) removedIsLast = true;
          CountdownData removedItem = service.removeAt(i);
          _listKey.currentState.removeItem(i, (ctx, anim) {
            return _buildRemovedItem(removedIsLast, removedItem);
          }); //why reload entire list?
        } else if (onValue is CountdownErrorResponse) {
          print("not deleted");
          _showErrorDialog("Delete failed.", onValue.errorMessage);
        } else {
          print("not deleted");
          //do better handling
          _showErrorDialog("Delete failed..", onValue.toString());
        }
      }).catchError((onError) {
        print(onError);
        _showErrorDialog("Delete failed...", onError.toString());
      });
    });
  }

  showLoadingDialog(context)
  {
    showDialog(context: context,barrierDismissible: false,builder: (_)
    {
      return LoaderDialog();
    });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
