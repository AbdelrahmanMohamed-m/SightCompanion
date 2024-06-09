import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:object_detection/layouts/home_screen/home_screen.dart';
import 'package:object_detection/shared/constants.dart';
import 'package:object_detection/strings/strings.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/tflite/stats.dart';
import 'package:object_detection/ui/box_widget.dart';
import 'package:object_detection/utils/stt_utils.dart';
import 'package:vibration/vibration.dart';

import '../../ui/camera_view.dart';

class ObjectDetection extends StatefulWidget {
  static CameraView? cameraView;

  const ObjectDetection({Key? key}) : super(key: key);

  @override
  _ObjectDetectionState createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection>
    with WidgetsBindingObserver {
  List<Recognition>? detectedObjects;
  Stats? detectionStats;
  int detectionPauseStatus = 0;
  String? detectedObjectName;
  String resultText = "";
  double confidenceLevel = 1.0;
  double detectedObjectArea = 0.0;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final FlutterTts textToSpeech = FlutterTts();

  @override
  void initState() {
    super.initState();
    initializeTextToSpeech();
    initializeCameraView();
  }

  void initializeTextToSpeech() {
    ENG_LANG ? ttsOffline(OBJ_MOD_LABEL, EN) : ttsOffline(OBJ_MOD_LABEL_AR, AR);
    HomeScreen.cubit.changeSelectedIndex(0);
  }

  void initializeCameraView() {
    ObjectDetection.cameraView = CameraView(detectionResultsCallback,
        statsCallback, OBJ_MOD_LABEL, detectionPauseStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPress: handleLongPressGesture,
        onDoubleTap: handleDoubleTapGesture,
        child: Stack(
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ObjectDetection.cameraView),
            drawBoundingBoxes(detectedObjects),
          ],
        ),
      ),
    );
  }

  void handleLongPressGesture() async {
    stopTextToSpeech();
    if (detectionPauseStatus == 0) {
      setState(() {
        detectionPauseStatus = 1;
      });
    }
    Vibration.vibrate(duration: 200);
    Event<DataTest> speechEvent =
        ENG_LANG ? await mySTT.listen(EN) : await mySTT.listen(AR);
    speechEvent.subscribe((args) => {
          if (args != null)
            {
              detectedObjectName = args.value,
              detectionPauseStatus = 0,
              ENG_LANG
                  ? ttsOffline("Searching for ${detectedObjectName}", EN)
                  : ttsOffline("تبحث عن " + detectedObjectName!, AR),
            }
        });

    // Stop the search and return to normal after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          detectionPauseStatus = 1;
          detectedObjectName = "";
          detectedObjects = null;
        });
        ENG_LANG ? ttsOffline("Paused", EN) : ttsOffline("توقف", AR);
      }
    });
  }

  void handleDoubleTapGesture() {
    Vibration.vibrate(duration: 200);
    stopTextToSpeech();
    setState(() {
      detectionPauseStatus = (detectionPauseStatus + 1) % 2;
      detectedObjects = null;
    });
    if (detectionPauseStatus == 1) {
      ENG_LANG ? ttsOffline("Paused", EN) : ttsOffline("توقف", AR);
      setState(() {
        detectedObjectName = "";
      });
    } else {
      ENG_LANG ? ttsOffline("Start", EN) : ttsOffline("بدأ", AR);
    }
  }

  Widget drawBoundingBoxes(List<Recognition>? detectedObjects) {
    if (detectionPauseStatus == 1 || detectedObjects == null) {
      setState(() {
        this.detectedObjects = null;
      });
      return Container();
    }

    handleDetectionResults(detectedObjects);
    return Stack(
      children: detectedObjects
          .map((e) => BoxWidget(
                result: e,
              ))
          .toList(),
    );
  }

 Map<String, DateTime> spokenLabels = {};

void handleDetectionResults(List<Recognition>? detectedObjects) {
  String resultText = "";
  DateTime now = DateTime.now();
  detectedObjects?.forEach((element) {
    if (!spokenLabels.containsKey(element.label) ||
        now.difference(spokenLabels[element.label]!).inSeconds >= 1) {
      spokenLabels[element.label] = now;
      resultText += (element.label + ", ");
    }
  });
  if (resultText.isNotEmpty) {
    ENG_LANG ? ttsOffline(resultText, EN) : ttsOffline(resultText, AR);
  }
}

  void detectionResultsCallback(List<Recognition>? detectedObjects) {
    if (mounted) {
      setState(() {
        this.detectedObjects = detectedObjects;
      });
    }

    double screenArea = 1280 * 720;
    if (detectedObjects != null &&
        detectedObjectName != null &&
        detectedObjectName!.isNotEmpty) {
      setState(() {
        detectedObjects.retainWhere(
            (element) => element.label == detectedObjectName!.toLowerCase());
      });
      detectedObjects.forEach((element) {
        detectedObjectArea = element.location!.width * element.location!.height;
        double ratio = detectedObjectArea / screenArea;
        Vibration.vibrate(amplitude: 255, duration: (ratio * 5000).toInt());
      });
    }
  }

  void statsCallback(Stats stats) {
    if (mounted) {
      setState(() {
        this.detectionStats = stats;
      });
    }
  }
}
