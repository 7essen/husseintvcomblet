import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
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
  late Future<List<dynamic>> channelCategories;
  late Future<List<dynamic>> newsArticles;
  late Future<List<dynamic>> matches;

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    channelCategories = fetchChannelCategories();
    newsArticles = fetchNews();
    matches = fetchMatches();
    checkForUpdate(context); // Check for updates on app start
  }

  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<List<dynamic>> fetchMatches() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/matches?populate=*'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching matches: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchChannelCategories() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/channel-categories?populate=channels'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching channel categories: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('https://st2-5jox.onrender.com/api/news?populate=*'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching news: $e");
      return [];
    }
  }

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/7essen/forceupdate/main/latestversion.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'];
        final updateUrl = data['update_url'];
        const currentVersion = '1.0.0';
        if (currentVersion != latestVersion) {
          showUpdateDialog(context, updateUrl);
        }
      }
    } catch (e) {
      print("Error checking for update: $e");
    }
  }

  void showUpdateDialog(BuildContext context, String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from being dismissed
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevents back button from closing the dialog
          child: AlertDialog(
            title: Text('تحديث مطلوب'),
            content: Text('يرجى تحديث التطبيق إلى أحدث إصدار.'),
            actions: [
              TextButton(
                child: Text('تحديث الآن'),
                onPressed: () async {
                  try {
                    await launch(updateUrl);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في فتح الرابط، لكن يمكنك نسخه: $updateUrl')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
          ChannelsSection(channelCategories: channelCategories, openVideo: openVideo),
          NewsSection(newsArticles: newsArticles),
          MatchesSection(matches: matches, openVideo: openVideo),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  void openVideo(BuildContext context, String? url) {
    if (url != null && url.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(url: url),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يوجد رابط للبث المباشر')));
    }
  }
}

class ChannelsSection extends StatelessWidget {
  final Future<List<dynamic>> channelCategories;
  final Function openVideo;

  ChannelsSection({required this.channelCategories, required this.openVideo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
          categories.sort((a, b) => a['id'].compareTo(b['id']));
          return ListView.separated(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ChannelBox(category: categories[index], openVideo: openVideo);
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
  final Function openVideo;

  ChannelBox({required this.category, required this.openVideo});

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
              builder: (context) => CategoryChannelsScreen(channels: category['attributes']['channels']['data'] ?? [], openVideo: openVideo),
            ),
          );
        },
      ),
    );
  }
}

class CategoryChannelsScreen extends StatelessWidget {
  final List<dynamic> channels;
  final Function openVideo;

  CategoryChannelsScreen({required this.channels, required this.openVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('القنوات'),
      ),
      body: ListView.separated(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return ChannelTile(channel: channels[index], openVideo: openVideo);
        },
        separatorBuilder: (context, index) => SizedBox(height: 16),
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  final dynamic channel;
  final Function openVideo;

  ChannelTile({required this.channel, required this.openVideo});

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
  final Future<List<dynamic>> matches;
  final Function openVideo;

  MatchesSection({required this.matches, required this.openVideo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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

          // تقسيم المباريات إلى ثلاث مجموعات
          List<dynamic> liveMatches = [];
          List<dynamic> upcomingMatches = [];
          List<dynamic> finishedMatches = [];

          for (var match in matches) {
            final matchDateTime = DateFormat('HH:mm').parse(match['attributes']['matchTime']);
            if (matchDateTime.isBefore(DateTime.now()) && DateTime.now().isBefore(matchDateTime.add(Duration(minutes: 110)))) {
              liveMatches.add(match);
            } else if (matchDateTime.isAfter(DateTime.now())) {
              upcomingMatches.add(match);
            } else {
              finishedMatches.add(match);
            }
          }

          // ترتيب المباريات القادمة من الأقرب للأبعد
          upcomingMatches.sort((a, b) {
            final matchTimeA = DateFormat('HH:mm').parse(a['attributes']['matchTime']);
            final matchTimeB = DateFormat('HH:mm').parse(b['attributes']['matchTime']);
            return matchTimeA.compareTo(matchTimeB);
          });

          return ListView(
            children: [
              ...liveMatches.map((match) => MatchBox(match: match, openVideo: openVideo)).toList(),
              ...upcomingMatches.map((match) => MatchBox(match: match, openVideo: openVideo)).toList(),
              ...finishedMatches.map((match) => MatchBox(match: match, openVideo: openVideo)).toList(),
            ],
          );
        }
      },
    );
  }
}

class MatchBox extends StatelessWidget {
  final dynamic match;
  final Function openVideo;

  MatchBox({required this.match, required this.openVideo});

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
      timeStatus = 'انتهت المباراة';
      borderColor = Colors.black;
    } else if (timeDifference < 110) {
      timeStatus = 'مباشر';
      borderColor = Colors.red;
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
  final Future<List<dynamic>> newsArticles;

  NewsSection({required this.newsArticles});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
    return GestureDetector(
      onTap: () {
        if (article['link'] != null && article['link'].isNotEmpty) {
          _launchURL(article['link']);
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              article['image']['data']['attributes']['url'],
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'Unknown Title',
                    style: TextStyle(
                      color: Color(0xFF673ab7),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['content'] ?? 'No content available',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article['date'] != null
                            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(article['date']))
                            : 'No date available',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (article['link'] != null && article['link'].isNotEmpty) {
                            _launchURL(article['link']);
                          }
                        },
                        child: Text(
                          'المزيد',
                          style: TextStyle(
                            color: Color(0xFF673ab7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } catch (e) {
      print('Could not launch $url: $e');
      // يمكنك هنا إضافة كود لفتح المتصفح بشكل يدوي إذا لزم الأمر
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
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(8)),
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
                              value: widget.isLive
                                  ? 0.0
                                  : _videoPosition.inSeconds.toDouble(),
                              max: widget.isLive
                                  ? 1.0
                                  : _videoDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                if (!widget.isLive) {
                                  _videoPlayerController
                                      .seekTo(Duration(seconds: value.toInt()));
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
                                  width: (_videoBuffered.inSeconds.toDouble() /
                                      (_videoDuration.inSeconds
                                          .toDouble() ==
                                          0
                                          ? 1
                                          : _videoDuration.inSeconds
                                          .toDouble())) *
                                      MediaQuery.of(context).size.width,
                                  color: Colors.blue.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 4,
                                  width: (_videoPosition.inSeconds.toDouble() /
                                      (_videoDuration.inSeconds
                                          .toDouble() ==
                                          0
                                          ? 1
                                          : _videoDuration.inSeconds
                                          .toDouble())) *
                                      MediaQuery.of(context).size.width,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              left: (_videoPosition.inSeconds.toDouble() /
                                  (_videoDuration.inSeconds
                                      .toDouble() ==
                                      0
                                      ? 1
                                      : _videoDuration.inSeconds
                                      .toDouble())) *
                                  MediaQuery.of(context).size.width -
                                  8,
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
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
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
