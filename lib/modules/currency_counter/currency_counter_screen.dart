import 'package:flutter/material.dart';
import 'package:object_detection/layouts/home_screen/home_screen.dart';
import 'package:object_detection/shared/constants.dart';
import 'package:object_detection/strings/strings.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/tflite/stats.dart';
import 'package:object_detection/ui/box_widget.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

import '../../ui/camera_view.dart';

/// [HomeView] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class CurrencyCounter extends StatefulWidget {
  static CameraView? cameraView;

  const CurrencyCounter({Key? key}) : super(key: key);

  @override
  _CurrencyCounterState createState() => _CurrencyCounterState();
}

class _CurrencyCounterState extends State<CurrencyCounter> with WidgetsBindingObserver {
  List<Recognition>? results;
  Stats? stats;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  int pauseModule = 0;

  @override
  void initState() {
    super.initState();
    initializeTTS();
    initializeCameraView();
  }

  void initializeTTS() {
    ENG_LANG
        ? ttsOffline(CURR_MOD_LABEL, EN)
        : ttsOffline(CURR_MOD_LABEL_AR, AR);
    HomeScreen.cubit.changeSelectedIndex(1);
  }

  void initializeCameraView() {
    CurrencyCounter.cameraView =
        CameraView(resultsCallback, statsCallback, CURR_MOD_LABEL, pauseModule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: handleDoubleTap,
        child: Stack(
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CurrencyCounter.cameraView),
            boundingBoxes(results),
          ],
        ),
      ),
    );
  }

  void handleDoubleTap() {
    Vibration.vibrate(duration: 200);
    stopTextToSpeech();
    setState(() {
      pauseModule = (pauseModule + 1) % 2;
      results = null;
    });
    if (pauseModule == 1) {
      ENG_LANG ? ttsOffline("Paused", EN) : ttsOffline("توقف", AR);
    } else {
      ENG_LANG ? ttsOffline("Start", EN) : ttsOffline("بدأ", AR);
    }
  }

  Widget boundingBoxes(List<Recognition>? results) {
    if (this.pauseModule == 1 || results == null) {
      setState(() {
        this.results = null;
      });
      return Container();
    }

    handleResults(results);
    return Stack(
      children: results
          .map((e) => BoxWidget(
        result: e,
      ))
          .toList(),
    );
  }

  // Create a Map to store the last time each label was spoken
Map<String, DateTime> lastSpokenTimes = {};

void handleResults(List<Recognition>? results) {
  results?.forEach((element) async {
    if (element.label == "0 Pounds") {
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        this.results = null;
      });
      if (shouldSpeakLabel("No Notes Found")) {
        ENG_LANG
            ? ttsOffline("No Notes Found", EN)
            : ttsOffline("لم يتم العثور على أوراق نقدية", AR);
      }
    }
  });

  int totalNotes = 0;
  results?.forEach((element) {
    totalNotes +=
        int.parse(element.label.substring(0, element.label.length - 3));
  });
  String totalNotesLabel = totalNotes.toString() + (ENG_LANG ? " Pounds" : " جنيه");
  if (shouldSpeakLabel(totalNotesLabel)) {
    ENG_LANG
        ? ttsOffline(totalNotesLabel, EN)
        : ttsOffline(totalNotesLabel, AR);
  }
}

bool shouldSpeakLabel(String label) {
  // If the label has not been spoken before, or if it was spoken more than a second ago, speak it
  if (!lastSpokenTimes.containsKey(label) || DateTime.now().difference(lastSpokenTimes[label]!).inSeconds > 1) {
    lastSpokenTimes[label] = DateTime.now();
    return true;
  }
  // Otherwise, don't speak it
  return false;
}

  void resultsCallback(List<Recognition>? results) {
    if (mounted) {
      setState(() {
        this.results = results;
      });
    }
  }

  void statsCallback(Stats stats) {
    if (mounted) {
      setState(() {
        this.stats = stats;
      });
    }
  }
}
