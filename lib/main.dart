import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trade_twice/pages/login_page.dart';
import 'package:trade_twice/pages/signup_page.dart';
import 'package:trade_twice/pages/home_page.dart';
import 'package:trade_twice/pages/add_products.dart';
import 'package:trade_twice/pages/home_details_page.dart';
import 'package:trade_twice/utils/routes.dart';
import 'package:trade_twice/models/product.dart';
import 'package:trade_twice/pages/profile_page.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trade Twice',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: MyRoutes.loginroute,
      routes: {
        MyRoutes.loginroute: (context) => LoginPage(),
        MyRoutes.signuproute: (context) => SignUpPage(),
        MyRoutes.homeroutes: (context) => HomePage(),
        MyRoutes.addproducts: (context) => AddProductsPage(),
        MyRoutes.profileroute: (context) =>  ProfilePage(),
        MyRoutes.loginroute: (context) => LoginPage(),


      },
      onGenerateRoute: (settings) {
        if (settings.name == MyRoutes.homedetails) {
          final item = settings.arguments as Items;
          return MaterialPageRoute(
            builder: (context) => HomeDetailsPage(item: item),
          );
        }
        return null;
      },
    );
  }
}
