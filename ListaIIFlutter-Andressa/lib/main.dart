import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ActivityList()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: StartLiveApp(),
    ),
  );
}

class StartLiveApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: HomePage(),
          routes: {
            '/favorites': (context) => FavoritesPage(),
          },
        );
      },
    );
  }
}

final lightTheme = ThemeData(
  primaryColor: Colors.blue,
  fontFamily: 'candara',
);

final darkTheme = ThemeData(
  primaryColor: Colors.indigo,
  brightness: Brightness.dark,
  fontFamily: 'courier',
);

class ActivityList with ChangeNotifier {
  List<Activity> activities = [
    Activity(name: "Academia"),
    Activity(name: "Corrida"),
    Activity(name: "Ciclismo"),
    Activity(name: "Natação"),
    Activity(name: "Futebol"),
    Activity(name: "Yoga"),
  ];

  List<Activity> favoriteActivities = [];

  ActivityList() {
    loadFavoritesFromPrefs();
  }

  void addToFavorites(Activity activity) {
    favoriteActivities.add(activity);
    saveFavoritesToPrefs();
    notifyListeners();
  }

  void removeFromFavorites(Activity activity) {
    favoriteActivities.remove(activity);
    saveFavoritesToPrefs();
    notifyListeners();
  }

  void removeActivity(Activity activity) {
    activities.remove(activity);
    notifyListeners();
  }

  void saveFavoritesToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favList =
        favoriteActivities.map((activity) => activity.name).toList();
    await prefs.setStringList('favoriteActivities', favList);
  }

  void loadFavoritesFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favList = prefs.getStringList('favoriteActivities');

    if (favList != null) {
      favoriteActivities =
          favList.map((activityName) => Activity(name: activityName)).toList();
      notifyListeners();
    }
  }

  Future<List<Post>> fetchPosts() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Post> posts = data.map((json) => Post.fromJson(json)).toList();
      return posts;
    } else {
      throw Exception('Falha ao carregar os posts');
    }
  }
}

class Activity {
  final String name;
  bool isFavorite;

  Activity({required this.name, this.isFavorite = false});
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StartLive'),
      ),
      body: ActivityListWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/favorites');
        },
        child: Icon(Icons.favorite),
      ),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.toggleTheme();
          },
          child: Text(
            'Alterar Tema',
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final activityList =
                Provider.of<ActivityList>(context, listen: false);
            List<Post> posts = await activityList.fetchPosts();
            // Exibir os posts em um diálogo
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Posts da API'),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(posts[index].title),
                          subtitle: Text(posts[index].body),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Fechar'),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            'Obter Posts da API',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class ActivityListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityList = Provider.of<ActivityList>(context);

    return ListView.builder(
      itemCount: activityList.activities.length,
      itemBuilder: (context, index) {
        final activity = activityList.activities[index];
        return Dismissible(
          key: Key(activity.name),
          onDismissed: (direction) {
            activityList.removeActivity(activity);
          },
          child: ListTile(
            title: Text(activity.name),
            trailing: IconButton(
              icon: activity.isFavorite
                  ? Icon(Icons.favorite, color: Colors.red)
                  : Icon(Icons.favorite_border),
              onPressed: () async {
                if (activity.isFavorite) {
                  activityList.removeFromFavorites(activity);
                } else {
                  activityList.addToFavorites(activity);
                }
                activity.isFavorite = !activity.isFavorite;
              },
            ),
          ),
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityList = Provider.of<ActivityList>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // Remover todos os favoritos
              activityList.favoriteActivities.clear();
              activityList.saveFavoritesToPrefs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Todos os favoritos foram removidos.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: activityList.favoriteActivities.length,
        itemBuilder: (context, index) {
          final activity = activityList.favoriteActivities[index];
          return ListTile(
            title: Text(
              activity.name,
              style: TextStyle(color: Colors.red),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                activityList.removeFromFavorites(activity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Favorito removido: ${activity.name}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}
