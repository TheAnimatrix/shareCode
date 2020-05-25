class TabPage extends StatefulWidget {
  @override
  _TabPageState createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey;

  TabController _tabController;
  double _scaleFab = 1;
  AnimationController _controller;
  bool isLoading = false;
  List<Tab> myTabs;

  final countingService = getIt<CountingService>();
  @override
  void initState() {
    super.initState();
    myTabs = [
                          Tab(
                            text: "Private",
                          ),
                          Tab(text: "Public")
                        ];
    _tabController = TabController(vsync: this, length: 2);

    _tabController.animation.addListener(() {
      // print("changing? ${_tabController.animation.value}");
    });
    _scaffoldKey = new GlobalKey<ScaffoldState>();
    countingService.start();
  }

  @override
  void dispose() {
    _tabController.dispose();
    countingService.close();
    super.dispose();
  }
  //
  final ColorTween fabColorChanger = ColorTween(begin: Colors.black,end: Colors.orangeAccent);
  @override
  Widget build(BuildContext context) {
    return (isLoading)
        ? LogOutLoading()
        : Scaffold(
            extendBody: true,
            bottomNavigationBar: ClipRect(
              //I'm using BackdropFilter for the blurring effect
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5.0,
                  sigmaY: 5.0,
                ),
                child: Opacity(
                  //you can change the opacity to whatever suits you best
                  opacity: 0.8,
                  child: BottomAppBar(
                  notchMargin: 5,
                  shape: CircularNotchedRectangle(),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 28.0,
                        padding: EdgeInsets.only(top:12,bottom:12),
                        icon: Icon(Icons.home,color: Colors.white,),
                        onPressed: () {
                        },
                      ),
                                   IconButton(
                    iconSize: 28.0,
                    padding: EdgeInsets.only(top:12,bottom:12),
                    icon: Icon(Icons.search,color: Colors.white),
                    onPressed: () {
                    },
                  ),
                                                 IconButton(
                    iconSize: 28.0,
                    padding: EdgeInsets.only(top:12,bottom:12),
                    icon: Icon(Icons.filter_list,color: Colors.white),
                    onPressed: () {
                    },
                  ),
                    ],
                  ),
                  color: Colors.black
                ),
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endDocked,
            // bottomNavigationBar: BottomNavigationBar(backgroundColor: Colors.black38,items: [BottomNavigationBarItem(icon: Icon(Icons.refresh),title: Text("one")),BottomNavigationBarItem(icon: Icon(Icons.refresh),title:Text("two"))]),
            floatingActionButton: AnimatedBuilder(
              animation: _tabController.animation,
              builder: (_, child) {
                Color color = fabColorChanger.lerp(_tabController.animation.value);
                return NewCountdownFab(scaffoldKey: _scaffoldKey,bgColor: color,);
              },
            ),
            key: _scaffoldKey,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                      pinned: true,
                      floating: true,
                      forceElevated: innerBoxIsScrolled,
                      backgroundColor: Colors.black,
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                              });
                              await Future.delayed(Duration(seconds: 2));
                              await AuthService().logoutCurrentUser();
                            },
                            child: Text(
                              "Sign Out",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                      title: Text("The Countdown App",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white)),
                      centerTitle: true,
                      bottom: TabBar(
                        controller: _tabController,
                        tabs: myTabs,
                      ))
                ];
              },
              body: TabBarView(
                children: [UserCountdownPage(key:PageStorageKey<String>(myTabs[0].text)), PublicCountdownPage(key:PageStorageKey<String>(myTabs[1].text))],
                controller: _tabController,
              ),
            ),
          );
  }
}
