import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:detector_de_madera/src/model/styles.dart';
import 'package:detector_de_madera/src/views/home.dart';

class MagicWeatherFlutter extends StatelessWidget {
  const MagicWeatherFlutter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        barBackgroundColor: kColorBar,
        primaryColor: kColorText,
        textTheme: CupertinoTextThemeData(
          primaryColor: kColorText,
        ),
      ),
      home: AppContainer(),
    );
  }
}
