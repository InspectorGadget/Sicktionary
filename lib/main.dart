import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sicktionary',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _url = "https://owlbot.info/api/v4/dictionary/";
  String _token = "4af505c0a522d9ba7f4983b81554e7a45e5d96eb";

  TextEditingController _searchBar = TextEditingController();
  StreamController _streamController;
  Stream _stream;
  Timer _debounce;

  _search() async {
    if (_searchBar.text == null || _searchBar.text.length < 1) {
      return _streamController.add(null);
    }

    _streamController.add(
        "waiting"); // Emit a new Event, just to tell the Code that we're waiting for the response
    Response response = await get(_url + _searchBar.text.trim(),
        headers: {"Authorization": "Token " + _token});

    _streamController.add(json.decode(
        response.body)); // Add the Response to the Stream as a final product
  }

  @override
  void initState() {
    super.initState();

    _streamController =
        StreamController(); // Start a new instance of the SteamController just to keep stuffs ready to be appended (Events)
    _stream = _streamController
        .stream; // Assign the stream variable with the "stream" from the Controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sicktionary"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 12.0, bottom: 12.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0)),
                  child: TextFormField(
                    onChanged: (String text) {
                      if (_debounce?.isActive ?? false) _debounce.cancel();
                      _debounce = Timer(Duration(milliseconds: 1000), () {
                        _search();
                      });
                    },
                    controller: _searchBar,
                    decoration: InputDecoration(
                        hintText: 'Type something... :)',
                        contentPadding: EdgeInsets.only(left: 24.0),
                        border: InputBorder.none),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  _search();
                },
              )
            ],
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Center(
                child: Text('Something maybe? :/'),
              );
            }

            if (snapshot.data == "waiting") {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data["definitions"].length ?? 0,
              itemBuilder: (BuildContext context, int i) {
                return ListBody(
                  children: <Widget>[
                    Container(
                      color: Colors.grey[300],
                      child: ListTile(
                        leading: snapshot.data["definitions"][i]["image_url"] ==
                                null
                            ? null
                            : CircleAvatar(
                                backgroundImage: snapshot.data["definitions"][i]
                                    ["image_url"],
                              ),
                        title: Text(_searchBar.text.trim() +
                            "(" +
                            snapshot.data["definitions"][i]["type"] +
                            ")"),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child:
                          Text(snapshot.data["definitions"][i]["definition"]),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
