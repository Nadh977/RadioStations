import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Application radio'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> stations = [];

  // Variables to track the selected and hovered index
  int _selectedIndex = -1;
  int _hoveredIndex = -1;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadStations();
  }

  void _loadStations() async {
    final dbRef = FirebaseDatabase.instance.ref().child('radio_stations');
    final dataSnapshot = await dbRef.once();
    final stationsData = dataSnapshot.snapshot.value;

    if (stationsData != null) {
      for (var stationData in (stationsData as Map<dynamic, dynamic>).values) {
        final station = <String, String>{
          'name': stationData['name'],
          'url': stationData['url'],
          'logo': stationData['logoUrl'],
        };
        stations.add(station);
      }
    }

    setState(() {});
  }





  void _playRadio(String url) async {
    int result = await _audioPlayer.play(url, isLocal: false);
    if (result == 1) {
      // success
      if (kDebugMode) {
        print('Radio playing');
      }
    } else {
      // error
      if (kDebugMode) {
        print('Error playing radio');
      }
    }
  }
  void _stopRadio() async {
    int result = await _audioPlayer.stop();
    if (result == 1) {
      // success
      if (kDebugMode) {
        print('Radio stopped');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: stations.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTapDown: (TapDownDetails details) {
                setState(() {
                  _hoveredIndex = index;
                  _animationController.forward();
                });
              },
              onTapUp: (TapUpDetails details) {
                if(_selectedIndex == index){
                  _stopRadio();
                  setState(() {
                    _selectedIndex = -1;
                    _hoveredIndex = -1;
                  });
                } else {
                  setState(() {
                    _hoveredIndex = -1;
                    _animationController.reverse();
                    _playRadio(stations[index]['url']!);
                    _selectedIndex = index;
                  });
                }},
              onTapCancel: () {
                setState(() {
                  _hoveredIndex = -1;
                  _animationController.reverse();
                });
              },
              child: ScaleTransition(
                scale: _hoveredIndex == index ? _scaleAnimation : Tween<double>(
                    begin: 1.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedIndex == index ? Colors.blue[900] : Colors
                        .blue[400],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        stations[index]['logo']!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stations[index]['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}