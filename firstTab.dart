
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
  CountdownService countdownService;

  @override
  void initState() {
    countdownService = getIt<CountdownService>();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => countdownService.loadMoreCountdowns());
    super.initState();
  }

  @override
  void dispose() {
    print("DISPOSING");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              : LiquidPullToRefresh( //external library
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


  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
