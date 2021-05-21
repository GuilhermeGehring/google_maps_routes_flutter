import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trabalho_e2/map_screen.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore _db = Firestore.instance;

  FirebaseUser _currentUser;

  Future<FirebaseUser> _getUser() async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );
      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final FirebaseUser user = authResult.user;
      print("User: " + user.displayName);
      return user;
    } catch (erro) {
      return null;
    }
  }

  _abrirMapa(String idRota) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapScreen(idRota: idRota)),
    );
  }

  _excluir(String idRota) {
    _db.collection("rotas").document(idRota).delete();
  }

  _adicionar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapScreen()),
    );
  }

  _adicionarListenerRotas() async {
    final stream = _db.collection("rotas").snapshots();
    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  handleLogin() async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Não foi possível fazer login!'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
        _adicionarListenerRotas();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (_currentUser != null)
        ? Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text('Trabalho E2 - Rotas, ${_currentUser.displayName}'),
              actions: [
                _currentUser != null
                    ? IconButton(
                        icon: Icon(Icons.exit_to_app),
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          googleSignIn.signOut();
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text("Logout"),
                          ));
                        },
                      )
                    : Container()
              ],
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                _adicionar();
              },
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: _controller.stream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(child: CircularProgressIndicator());
                  case ConnectionState.active:
                  case ConnectionState.done:
                    QuerySnapshot querySnapshot = snapshot.data;
                    List<DocumentSnapshot> rotas =
                        querySnapshot.documents.toList();
                    return Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.builder(
                            itemCount: rotas.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot item = rotas[index];
                              String titulo = item.documentID;
                              String idRota = item.documentID;
                              return GestureDetector(
                                onTap: () {
                                  _abrirMapa(idRota);
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(titulo),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            _excluir(idRota);
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                    break;
                } //switch
                return Text('erro desconhecido.');
              }, //builder
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text("Trabalho E2 - Rotas"),
            ),
            body: Center(
              child: OutlineButton(
                onPressed: () async {
                  await handleLogin();
                },
                child: Text(
                  "Login with google",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
  }
}
