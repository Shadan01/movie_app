// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:movie_app/sqlite_db_helper.dart';
import 'movie_details.dart';
import 'movies.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';


void main() {
  runApp(const MyApp());
}

const String API_KEY = "77964820";
const String BASE_URL = "https://omdbapi.com/?";

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = false;
  bool _isButtonEnabled = true;
  List<Movie> _movies = [];
  bool hasInternet = false;
  late StreamSubscription sub;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    sub = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isConnected = (result != ConnectivityResult.none);
      });
    });
  }
  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }


  Future<void> _fetchMovies(String search) async {
    if (search.isEmpty || search.length < 3) {
      setState(() {
        _movies = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    final res =
        await http.get(Uri.parse('${BASE_URL}s=$search&apikey=$API_KEY'));
    final jsonObject = jsonDecode(res.body);
    Iterable jsonArray = jsonObject["Search"];

    setState(() => _isLoading = false);

    _movies = jsonArray.map((movies) => Movie.fromJson(movies)).toList();
  }

  _addWatchLater(String imdb) async {
    if (imdb.isEmpty) {
      return;
    }

    setState(() => {_isButtonEnabled = false, _isLoading = true});

    final response =
        await http.get(Uri.parse('${BASE_URL}i=$imdb&apikey=$API_KEY'));
    final jsonObject = jsonDecode(response.body);
    setState(() => _isLoading = false);

    MovieImdb movieImdb = MovieImdb.fromJson(jsonObject);
    bool isSuccess = await DbHelper.init().insertMovie(movieImdb.toMap(imdb));
    Fluttertoast.showToast(
        msg: isSuccess
            ? "Added successfully"
            : "Movie not added or already added",
        toastLength: Toast.LENGTH_LONG);
    setState(() => _isButtonEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/film.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Movie'),
            backgroundColor: Colors.purple[600],
          ),
          body: !isConnected ? Column(
            children: [
              Padding(
                padding: EdgeInsets.all(7.0),
                child: TextField(
                  keyboardType: TextInputType.text,
                  onChanged: (text) => _fetchMovies(text),
                  decoration: InputDecoration(
                      labelText: 'Enter at least 3 letters to search movie',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500],)
                  ),
                ),
              ),
              Center(
                child: FutureBuilder(
                  builder: (context, snapshot) {
                    return _isLoading ? CircularProgressIndicator() : Text('');
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _movies.length,
                  itemBuilder: (context, index) => ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MovieDetails(
                                title: _movies[index].title,
                                imdb: _movies[index].imdb)),
                      );
                    },
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey[500], // background
                      ),
                      onPressed: _isButtonEnabled
                          ? () {
                        _addWatchLater(_movies[index].imdb);
                      }
                          : null,
                      child: Text("Watch Later"),
                    ),
                    title: Row(
                      children: [
                        SizedBox(
                          width: 100.0,
                          child: ClipRRect(
                            child: CachedNetworkImage(
                              imageUrl: _movies[index].poster,
                              placeholder: (context, url) => Image.asset('assets/not-available.png'),
                              errorWidget: (context, url, error) => Icon(Icons.error,size: 30.0),
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text("Title: " + _movies[index].title),
                              Text("Year: " + _movies[index].year),
                              Text("Type: ${_movies[index].type}")
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ) : Padding(
            padding: EdgeInsets.only(left: 300.0, top: 260.0),
            child: Row(
              children: [
                Text('You are not connected to network ', style: TextStyle(fontSize: 25.0, color: Colors.grey[600]),),
                Padding(padding: EdgeInsets.only(left: 7.0), child: Icon(Icons.wifi_off, size: 25.0, color: Colors.grey[700],),)
              ],
            ),
          ),
          drawer: Drawer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[500],
                    width: double.infinity,
                    height: 150.0,
                    padding: EdgeInsets.only(top: 20.0),
                  ),
                  Builder(
                    builder: (context) {
                      return Container(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: (){
                                Navigator.of(context).pop();
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>WatchList()));
                              },
                              icon: Icon(Icons.access_time, size: 30.0,),
                            ),
                            Padding(padding: EdgeInsets.only(top: 6.0, left: 8.0), child: Text('Watch later', style: TextStyle(fontSize: 15.0),),)
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MovieDetails extends StatefulWidget {
  const MovieDetails({Key? key, required this.title, required this.imdb})
      : super(key: key);

  final String title;
  final String imdb;

  @override
  _MovieDetailsState createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  bool _isLoading = false;
  MovieImdb? imdb;

  Future<void> _fetchImdbDetails() async {
    if (widget.imdb.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    final res = await http
        .get(Uri.parse('${BASE_URL}i=${widget.imdb}&apikey=$API_KEY'));
    final jsonObject = jsonDecode(res.body);
    setState(() => _isLoading = false);

    imdb = MovieImdb.fromJson(jsonObject);
  }

  @override
  void initState() {
    super.initState();
    _fetchImdbDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.purple[600],
      ),
      body: Column(
        children: [
          Center(
            child: FutureBuilder(
              builder: (context, snapshot) {
                return _isLoading
                    ? CircularProgressIndicator()
                    : Padding(
                        padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 60.0),
                              child: SizedBox(
                                width: 300.0,
                                child: ClipRRect(
                                  child: Image.network(imdb!.poster),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 15.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Title: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.title, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Year: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.year, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'IMDB rating: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.rating, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Genre: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.genre, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Writer: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.writer, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Director: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.director, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Actors: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.0),
                                        ),
                                        Text(imdb!.actors, style: TextStyle(fontSize: 17.0)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WatchList extends StatefulWidget {
  const WatchList({Key? key}) : super(key: key);

  @override
  _WatchListState createState() => _WatchListState();
}

class _WatchListState extends State<WatchList> {
  DbHelper? helper;
  @override
  void initState() {
    super.initState();
    helper = DbHelper();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies to watch later'),
        backgroundColor: Colors.purple[600],
      ),
      body: FutureBuilder(
          future: helper!.allIMDB(),
        builder: (context, AsyncSnapshot snapshot) {
            if(!snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.only(top: 7.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(
                      children: [
                        SizedBox(
                          width: 100.0,
                          child: ClipRRect(
                            child: CachedNetworkImage(
                                imageUrl: snapshot.data[index]['Poster'],
                                placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(Icons.error,size: 30.0)
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Title: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Title"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Year: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Year"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'IMDB rating: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Rated"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Genre: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Genre"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Writer: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Writer"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Director: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Director"]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text(
                                'Actors: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.0),
                              ),
                              Text(snapshot.data[index]["Actors"]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  },
              );
            }
        },
      ),
    );
  }
}
