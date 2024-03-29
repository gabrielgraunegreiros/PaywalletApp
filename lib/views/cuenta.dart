import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paywallet_app/models/users.dart';
import 'package:paywallet_app/services/storage_service.dart';

final usersRef = FirebaseFirestore.instance.collection('usuarios/');

class Cuenta extends StatefulWidget {
  const Cuenta({Key? key}) : super(key: key);

  @override
  State<Cuenta> createState() => _Cuenta();
}

class _Cuenta extends State<Cuenta> {
  final user = FirebaseAuth.instance.currentUser!;
  final String uid = FirebaseAuth.instance.currentUser!.uid.toString();
  String imageUrl = '';
  final Storage storage = Storage();

  //Para leer solo mi usuario
  Future<Usuario?> leerUsuario() async {
    //Get document by ID
    final docUser = FirebaseFirestore.instance.collection('usuarios/').doc(uid);
    final snapshot = await docUser.get();
    if (snapshot.exists) {
      return Usuario.fromJson(snapshot.data()!);
    }
  }

  Future volverAutenticar() async {
    String pass = _contrasenacontroller.text.trim();
    await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: '${user.email}', password: pass));
    user.delete();
    final docUser = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    docUser.delete();
  }

  void actualizarImagen() async {
    final docUser = FirebaseFirestore.instance
        .collection('usuarios/')
        .doc(uid)
        .withConverter(
            fromFirestore: Usuario.fromFirestore,
            toFirestore: (Usuario user, _) => user.toFirestore());
    final snapshot = await docUser.get();
    Reference ref =
        FirebaseStorage.instance.ref(user.uid).child('fotoperfil.jpg');
    ref.getDownloadURL().then((value) {
      print(value);
      docUser.update({'imagen': value});
      setState(() {
        imageUrl = snapshot.data()!.imagen.toString();
      });
    });
  }

  void elegirImagen() async {
    final imagen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 75);

    final docUser = FirebaseFirestore.instance
        .collection('usuarios/')
        .doc(uid)
        .withConverter(
            fromFirestore: Usuario.fromFirestore,
            toFirestore: (Usuario user, _) => user.toFirestore());
    final snapshot = await docUser.get();
    Reference ref =
        FirebaseStorage.instance.ref(user.uid).child('fotoperfil.jpg');

    await ref.putFile(File(imagen!.path));
    ref.getDownloadURL().then((value) {
      print(value);
      docUser.update({'imagen': value});
      setState(() {
        imageUrl = snapshot.data()!.imagen.toString();
      });
    });
  }

  final _nombrecontroller = TextEditingController();
  final _apellidocontroller = TextEditingController();
  final _usuariocontroller = TextEditingController();
  final _contrasenacontroller = TextEditingController();

  void dispose() {
    _nombrecontroller.dispose();
    _apellidocontroller.dispose();
    _usuariocontroller.dispose();
    _contrasenacontroller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    actualizarImagen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _styleBotones = ElevatedButton.styleFrom(
        primary: Color(0xff202f36),
        onPrimary: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        shadowColor: Colors.black12);

    final _styleBotonEliminar = ElevatedButton.styleFrom(
        backgroundColor: Color(0xffff6767),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        shadowColor: Colors.black12);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Color(0xff3a4d54),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Color(0xff3a4d54),
                                title: Text(
                                  '¿Seguro que deseas cerrar sesión?',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18),
                                ),
                                actions: [
                                  //Salir
                                  TextButton(
                                      onPressed: () {
                                        FirebaseAuth.instance.signOut();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Salir")),
                                  //Cancelar
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Cancelar")),
                                ],
                              ));
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xff202f36),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 28,
                            ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      elegirImagen();
                    },
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      CircleAvatar(
                          backgroundColor: imageUrl == ''
                              ? Colors.white
                              : Colors.transparent,
                          radius: 80,
                          child: imageUrl == ''
                              ? Image(
                                  image:
                                      AssetImage('assets/images/usuario.png'),
                                  height: 100)
                              : Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover)),
                                )),
                      CircleAvatar(
                          backgroundColor: Colors.white60,
                          radius: 20,
                          child: Icon(
                            Icons.photo,
                            color: Colors.black,
                          )),
                    ]),
                  ),
                  Container(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    //Para leer solo mi usuario
                    child: FutureBuilder<Usuario?>(
                        future: leerUsuario(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Algo está mal...${snapshot.error}');
                          } else if (snapshot.hasData) {
                            final usuario = snapshot.data;
                            return usuario == null
                                ? Center(child: Text('No hay usuario'))
                                : buildUsuario(usuario);
                          } else {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        }),
                  )),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 45,
                          width: 140,
                          child: ElevatedButton(
                              style: _styleBotones,
                              onPressed: () {
                                if (_nombrecontroller.text != '') {
                                  final docUser = FirebaseFirestore.instance
                                      .collection('usuarios/')
                                      .doc(uid);
                                  //Actualizar campos específicos
                                  docUser.update({
                                    'nombre': _nombrecontroller.text.trim(),
                                  });
                                } else {}
                                if (_apellidocontroller.text != '') {
                                  final docUser = FirebaseFirestore.instance
                                      .collection('usuarios/')
                                      .doc(uid);
                                  //Actualizar campos específicos
                                  docUser.update({
                                    'apellido': _apellidocontroller.text.trim(),
                                  });
                                } else {}
                                if (_usuariocontroller.text != '') {
                                  final docUser = FirebaseFirestore.instance
                                      .collection('usuarios/')
                                      .doc(uid);
                                  //Actualizar campos específicos
                                  docUser.update({
                                    'usuario': _usuariocontroller.text.trim(),
                                  });
                                } else {}
                                ;
                              },
                              child: Text('Actualizar')),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 45,
                          width: 140,
                          child: ElevatedButton(
                              style: _styleBotonEliminar,
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          backgroundColor: Color(0xff3a4d54),
                                          title: Text(
                                            '¿Seguro que quieres eliminar tu cuenta?',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                          content: Text(
                                              'Se eliminarán todos tus datos',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18)),
                                          actions: [
                                            //Salir
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  showDialog(
                                                      context: context,
                                                      builder:
                                                          (context) =>
                                                              AlertDialog(
                                                                backgroundColor:
                                                                    Color(
                                                                        0xff3a4d54),
                                                                title: Text(
                                                                    'Por favor ingresa tu contraseña'),
                                                                content:
                                                                    TextField(
                                                                  controller:
                                                                      _contrasenacontroller,
                                                                  obscureText:
                                                                      true,
                                                                  enableSuggestions:
                                                                      false,
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        volverAutenticar();
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      child: Text(
                                                                          "Ok")),
                                                                  //Cancelar
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      child: Text(
                                                                          "Cancelar")),
                                                                ],
                                                              ));
                                                },
                                                child: Text("Eliminar")),
                                            //Cancelar
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("Cancelar")),
                                          ],
                                        ));
                              },
                              child: Text('Eliminar')),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 80,)
                ],
              ),
            ),
          ),
        ));
  }

  Widget buildUsuario(Usuario user) => Center(
        child: Column(
          children: [
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nombre:'),
                  Campo(user, 'nombre', _nombrecontroller),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Apellido:'),
                  Campo(user, 'apellido', _apellidocontroller),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Usuario:'),
                  Campo(user, 'usuario', _usuariocontroller),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Email:'),
                  Container(
                    width: 200,
                    child: TextFormField(
                      initialValue: user.email,
                      decoration: InputDecoration(
                          fillColor: Colors.grey,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          enabled: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget Campo(Usuario user, String tipo, campoController) {
    String nombre = user.nombre;
    String apellido = user.apellido;
    String usuario = user.usuario;
    switch (tipo) {
      case 'nombre':
        {
          tipo = nombre;
        }
        break;
      case 'apellido':
        {
          tipo = apellido;
        }
        break;
      case 'usuario':
        {
          tipo = usuario;
        }
        break;
      default:
        {
          print('Elección no valida');
        }
        break;
    }
    return Container(
      width: 200,
      child: TextFormField(
        controller: campoController,
        decoration: InputDecoration(
            fillColor: Colors.grey.shade300,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: tipo,
            hintStyle: TextStyle(color: Colors.black)),
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
