import 'package:capitals/domain/assemble.dart';
import 'package:capitals/domain/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'components.dart';
import 'home_page.dart';

const _appName = '${GameLogic.countryLimit} Capitals';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  var _dark = false;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          BlocProvider.value(value: assemble.game),
          Provider.value(value: assemble.assets),
          StreamProvider.value(
            value: assemble.itemsLogic.stream,
            initialData: assemble.itemsLogic.state,
          ),
          StreamProvider.value(
            value:
                assemble.palette.stream.map((event) => event.colors).distinct(),
            initialData: assemble.palette.colors,
          ),
          StreamProvider.value(
            value: assemble.game.stream,
            initialData: assemble.game.state,
          )
        ],
        child: MaterialApp(
          title: _appName,
          builder: (context, child) => ThemeSwitch(
            isDark: _dark,
            child: child,
            onToggle: () => setState(() => _dark = !_dark),
          ),
          theme:
              ThemeData(brightness: _dark ? Brightness.dark : Brightness.light),
          home: const HomePage(),
        ),
      );
}
