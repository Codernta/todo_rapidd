import 'package:flutter/material.dart';
import 'package:mt_rapidd_todo/services/socket_services.dart';
import 'package:mt_rapidd_todo/viewModels/todo_view_model.dart';
import 'package:provider/provider.dart';
import 'views/home_view.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
        Provider(create: (_) => SocketService()),
      ],
      child: MaterialApp(
        title: 'TODO',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        ),
        home: const HomeView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}