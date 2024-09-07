
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "fetchApiTask",
    "fetchApiTask",
    frequency: Duration(minutes: 10),
  );
  runApp(MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await fetchAllData();
    return Future.value(true);
  });
}

Future fetchAllData() async {
  try {
    final matchesResponse = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/matches?populate=*'));
    if (matchesResponse.statusCode == 200) {
      final matchesData = json.decode(matchesResponse.body)['data'];
      for (var match in matchesData) {
        // تحقق من وقت المباراة وأرسل إشعارًا إذا كانت المباراة ستبدأ قريبًا
        await scheduleMatchNotification(match);
      }
    }
  } catch (e) {
    print("Error fetching data: $e");
  }
}

Future<void> scheduleMatchNotification(dynamic match) async {
  final matchTime = match['attributes']['matchTime'] ?? '00:00';
  final now = DateTime.now();
  final matchDateTime = DateFormat('HH:mm').parse(matchTime);
  final matchDateTimeWithToday = DateTime(now.year, now.month, now.day, matchDateTime.hour, matchDateTime.minute);

  // تحقق إذا كانت المباراة ستبدأ خلال 5 دقائق
  if (matchDateTimeWithToday.isAfter(now) && matchDateTimeWithToday.isBefore(now.add(Duration(minutes: 5)))) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description', // استخدم channelDescription بدلاً من الوصف
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'تذكير',
      'ستبدأ مباراة ${match['attributes']['teamA']} ضد ${match['attributes']['teamB']} قريبًا',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}

void openVideo(BuildContext context, String? url) {
  if (url != null && url.isNotEmpty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(url: url),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('لا يوجد رابط للبث المباشر')),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hussein TV',
      theme: ThemeData(
        primaryColor: Color(0xFF512da8),
        scaffoldBackgroundColor: Color(0xFF673ab7),
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF512da8),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF512da8),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<List> channelCategories;
  late Future<List> newsArticles;
  late Future<List> matches;

  @override
  void initState() {
    super.initState();
    channelCategories = fetchChannelCategories();
    newsArticles = fetchNews();
    matches = fetchMatches();
  }

  Future<List> fetchChannelCategories() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/channel-categories?populate=channels'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching channel categories: $e");
      return [];
    }
  }

  Future<List> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/news?populate=*'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching news: $e");
      return [];
    }
  }

  Future<List> fetchMatches() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/matches?populate=*'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching matches: $e");
      return [];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hussein TV'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ChannelsSection(channelCategories: channelCategories),
          NewsSection(newsArticles: newsArticles),
          MatchesSection(matches: matches),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.tv),
            label: 'القنوات',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.newspaper),
            label: 'الأخبار',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.futbol),
            label: 'المباريات',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ChannelsSection extends StatelessWidget {
  final Future<List> channelCategories;

  ChannelsSection({required this.channelCategories});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: channelCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ في استرجاع القنوات'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد قنوات لعرضها'));
        } else {
          final categories = snapshot.data!;
          return ListView.separated(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ChannelBox(category: categories[index]);
            },
            separatorBuilder: (context, index) => SizedBox(height: 16),
          );
        }
      },
    );
  }
}

class ChannelBox extends StatelessWidget {
  final dynamic category;

  ChannelBox({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Center(
          child: Text(
            category['attributes']['name'] ?? 'Unknown Category',
            style: TextStyle(
              color: Color(0xFF673ab7),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CategoryChannelsScreen(channels: category['attributes']['channels']['data'] ?? []),
            ),
          );
        },
      ),
    );
  }
}

class CategoryChannelsScreen extends StatelessWidget {
  final List channels;

  CategoryChannelsScreen({required this.channels});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('القنوات'),
      ),
      body: ListView.separated(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return ChannelTile(channel: channels[index]);
        },
        separatorBuilder: (context, index) => SizedBox(height: 16),
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  final dynamic channel;

  ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Center(
          child: Text(
            channel['attributes']['name'] ?? 'Unknown Channel',
            style: TextStyle(
              color: Color(0xFF673ab7),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          openVideo(context, channel['attributes']['streamLink']);
        },
      ),
    );
  }
}

class MatchesSection extends StatelessWidget {
  final Future<List> matches;

  MatchesSection({required this.matches});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: matches,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ في استرجاع المباريات'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد مباريات لعرضها'));
        } else {
          final matches = snapshot.data!;
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return MatchBox(match: matches[index]);
            },
          );
        }
      },
    );
  }
}

class MatchBox extends StatelessWidget {
  final dynamic match;

  MatchBox({required this.match});

  @override
  Widget build(BuildContext context) {
    final teamA = match['attributes']['teamA'] ?? 'Team A';
    final teamB = match['attributes']['teamB'] ?? 'Team B';
    final logoA = match['attributes']['logoA']['data']['attributes']['url'] ?? '';
    final logoB = match['attributes']['logoB']['data']['attributes']['url'] ?? '';
    final matchTime = match['attributes']['matchTime'] ?? '00:00';
    final streamLink = match['attributes']['streamLink'] ?? '';
    final commentator = match['attributes']['commentator'] ?? '';
    final channel = match['attributes']['channel'] ?? '';

    final now = DateTime.now();
    final matchDateTime = DateFormat('HH:mm').parse(matchTime);
    final matchTime12Hour = DateFormat('hh:mm a').format(matchDateTime);
    final matchDateTimeWithToday = DateTime(now.year, now.month, now.day, matchDateTime.hour, matchDateTime.minute);

    final timeDifference = matchDateTimeWithToday.difference(now).inMinutes;
    String timeStatus;
    Color borderColor;

    if (timeDifference < 0) {
      if (now.isAfter(matchDateTimeWithToday.add(Duration(minutes: 110)))) {
        timeStatus = 'انتهت المباراة';
        borderColor = Colors.black;
      } else {
        timeStatus = 'مباشر';
        borderColor = Colors.red;
      }
    } else {
      timeStatus = matchTime12Hour;
      borderColor = Colors.blueAccent;
    }

    return GestureDetector(
      onTap: () {
        openVideo(context, streamLink);
      },
      child: Card(
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Image.network(logoA, width: 60, height: 60),
                        SizedBox(height: 5),
                        Text(teamA, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      timeStatus,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Image.network(logoB, width: 60, height: 60),
                        SizedBox(height: 5),
                        Text(teamB, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 20),
                  SizedBox(width: 5),
                  Text(commentator),
                  SizedBox(width: 50),
                  Icon(Icons.tv, size: 20),
                  SizedBox(width: 5),
                  Text(channel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsSection extends StatelessWidget {
  final Future<List> newsArticles;

  NewsSection({required this.newsArticles});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: newsArticles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ في استرجاع الأخبار'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد أخبار لعرضها'));
        } else {
          final articles = snapshot.data!;
          return ListView.separated(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index]['attributes'];
              return NewsBox(article: article);
            },
            separatorBuilder: (context, index) => SizedBox(height: 8),
          );
        }
      },
    );
  }
}

class NewsBox extends StatelessWidget {
  final dynamic article;

  NewsBox({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        title: Text(
          article['title'] ?? 'Unknown Title',
          style: TextStyle(
            color: Color(0xFF673ab7),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Image.network(article['image']['data']['attributes']['url']),
            SizedBox(height: 10),
            Text(article['content'] ?? 'No content available'),
            SizedBox(height: 10),
            Text(article['date'] ?? 'No date available'),
          ],
        ),
        onTap: () {
          if (article['link'] != null && article['link'].isNotEmpty) {
            _launchURL(article['link']);
          }
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final bool isLive;

  VideoPlayerScreen({required this.url, this.isLive = false});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  bool _isControlsVisible = true;
  bool _isFullScreen = false;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  Duration _videoBuffered = Duration.zero;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _videoDuration = _videoPlayerController.value.duration;
          _videoBuffered = Duration.zero;
          _videoPosition = _videoPlayerController.value.position;
        });
        _videoPlayerController.play();
        _videoPlayerController.addListener(() {
          if (mounted) {
            setState(() {
              _videoPosition = _videoPlayerController.value.position;
              _videoBuffered = _videoPlayerController.value.buffered.isNotEmpty
                  ? _videoPlayerController.value.buffered.last.end
                  : Duration.zero;
            });
          }
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
      } else {
        _videoPlayerController.play();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Stack(
          children: [
            Center(
              child: _videoPlayerController.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              )
                  : Container(color: Colors.black),
            ),
            if (_isControlsVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: Colors.transparent,
                              overlayColor: Colors.transparent,
                            ),
                            child: Slider(
                              value: widget.isLive ? 0.0 : _videoPosition.inSeconds.toDouble(),
                              max: widget.isLive ? 1.0 : _videoDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                if (!widget.isLive) {
                                  _videoPlayerController.seekTo(Duration(seconds: value.toInt()));
                                }
                              },
                              min: 0,
                            ),
                          ),
                          if (!widget.isLive) ...[
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 4,
                                  width: (_videoBuffered.inSeconds.toDouble() / (_videoDuration.inSeconds.toDouble() == 0 ? 1 : _videoDuration.inSeconds.toDouble())) * MediaQuery.of(context).size.width,
                                  color: Colors.blue.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 4,
                                  width: (_videoPosition.inSeconds.toDouble() / (_videoDuration.inSeconds.toDouble() == 0 ? 1 : _videoDuration.inSeconds.toDouble())) * MediaQuery.of(context).size.width,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              left: (_videoPosition.inSeconds.toDouble() / (_videoDuration.inSeconds.toDouble() == 0 ? 1 : _videoDuration.inSeconds.toDouble())) * MediaQuery.of(context).size.width - 8,
                              bottom: 15,
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              _videoPlayerController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          IconButton(
                            icon: Icon(
                              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFullScreen,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _isFullScreen
          ? FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Icon(Icons.arrow_back),
        backgroundColor: Colors.black,
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}