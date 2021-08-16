import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_logger/easy_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:gitjournal/app.dart';
import 'package:gitjournal/error_reporting.dart';
import 'package:gitjournal/settings/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableLevels = [
    LevelMessages.error,
    LevelMessages.warning,
  ];

  // FIXME: Does this need to be done over here?
  await Supabase.initialize(
    url: 'https://tefpmcttotopcptdivsj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYyODA2NDAyNiwiZXhwIjoxOTQzNjQwMDI2fQ.xAN-giE3m1MPjoRkkdcg_0NJueLH0_L-Wu-V0TSnpwU',
    authCallbackUrlHostname: 'login-callback',
  );

  var pref = await SharedPreferences.getInstance();
  AppSettings.instance.load(pref);

  JournalApp.isInDebugMode = foundation.kDebugMode;
  FlutterError.onError = flutterOnErrorHandler;

  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) async {
    var isolateError = pair as List<dynamic>;
    assert(isolateError.length == 2);
    assert(isolateError.first.runtimeType == Error);
    assert(isolateError.last.runtimeType == StackTrace);

    await reportError(isolateError.first, isolateError.last);
  }).sendPort);

  runZonedGuarded(() async {
    await Chain.capture(() async {
      await JournalApp.main(pref);
    });
  }, reportError);
}
