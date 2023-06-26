import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';

class ButtonsPage extends StatefulWidget {
  const ButtonsPage({super.key});

  @override
  State<ButtonsPage> createState() => _ButtonsPageState();
}

enum DeviceStatus {
  ready,
  notReady,
  notConnected,
  notFound,
  unknown,
}

final String _assetsPath = Platform.isWindows
    ? '../data/flutter_assets/bin'
    : '../../Frameworks/App.framework/Resources/flutter_assets/bin';
File mainFile = File(Platform.resolvedExecutable);
final Directory _assetsDir =
    Directory(path.normalize(path.join(mainFile.path, _assetsPath)));

class _ButtonsPageState extends State<ButtonsPage> {
  String firmwarePath = "";
  DeviceStatus deviceStatus = DeviceStatus.unknown;

  @override
  void initState() {
    // Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
    //   // 在定时器触发时执行的操作
    //   var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
    //   var result = await Process.run(pypth, ["ld"]);
    //   logger.i("result:\n ${result.stdout}");
    //   if (result.stdout.toString().contains("Loader")) {
    //     setState(() {
    //       deviceStatus = DeviceStatus.ready;
    //     });
    //   } else {
    //     setState(() {
    //       deviceStatus = DeviceStatus.notReady;
    //     });
    //   }
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Column(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PushButton(
                            buttonSize: ButtonSize.large,
                            child: const Text('固件'),
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['img']);
                              if (result != null) {
                                logger.i(result.files.single.path);
                                String filePath =
                                    result.files.single.path as String;
                                await unPackFWFirmware(filePath);
                                await unPackAFFirmware();
                                setState(() {
                                  firmwarePath = filePath;
                                });
                                // File file = File(result!.files.single.path);
                              }
                            },
                          ),
                          PushButton(
                            buttonSize: ButtonSize.large,
                            child: const Text('升级'),
                            onPressed: () async {
                              EasyLoading.show(
                                  maskType: EasyLoadingMaskType.clear,
                                  indicator:
                                      LoadingAnimationWidget.waveDots(
                                    color: Colors.white,
                                    size: 100,
                                  ));
                              await updateFirmware();
                              await updateData();
                              rebootDevice();
                              EasyLoading.dismiss();
                            },
                          ),
                          PushButton(
                            buttonSize: ButtonSize.large,
                            child: const Text('切换'),
                            onPressed: () async {
                              var out = await Process.run(
                                  "adb", ["reboot", "bootloader"]);
                              logger.i("result:\n ${out.stdout}");
                              logger.i("result:\n ${out.stderr}");
                              logger.i(out.stdout);
                            },
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "固件路径: $firmwarePath",
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                ResizablePane(
                  maxSize: 50,
                  minSize: 50,
                  startSize: 50,
                  //windowBreakpoint: 600,
                  builder: (_, __) {
                    return Center(
                      child: Text(deviceStatus == DeviceStatus.ready
                          ? "✅ 设备已连接"
                          : "❌ 设备未连接"),
                    );
                  },
                  resizableSide: ResizableSide.top,
                )
              ],
            );
          },
        ),
        ResizablePane(
          minSize: 200,
          startSize: 200,
          maxSize: 200,
          windowBreakpoint: 800,
          resizableSide: ResizableSide.left,
          builder: (_, __) {
            return const Center(
              child: Text('log'),
            );
          },
        ),
      ],
    );
  }
}

Future<Directory> getAppDataDirectory() async {
  Directory p = Directory("/tmp");
  return p;
}

updateFirmware() async {
  logger.i("updateFirmware");
  var appDataDir = await getAppDataDirectory();
  var oemPath = path.joinAll([appDataDir.path, "Image", "oem.img"]);
  var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
  var result = await Process.run(pypth, ["wlx", "oem", oemPath]);
  logger.i(result.stdout);
  logger.i(result.stderr);
  logger.w("updateFirmware done");
}

updateData() async {
  logger.i("updateFirmware");
  var appDataDir = await getAppDataDirectory();
  var oemPath = path.joinAll([appDataDir.path, "Image", "userdata.img"]);
  var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
  var result = await Process.run(pypth, ["wlx", "userdata", oemPath]);
  logger.i(result.stdout);
  logger.i(result.stderr);
  logger.w("updateFirmware done");
}

changeDeviceStatus() {
  var out = Process.runSync("adb", ["reboot", "bootloader"]);
  logger.i("result:\n ${out.stdout}");
  logger.i("result:\n ${out.stderr}");
  logger.i(out.stdout);
}

rebootDevice() {
  var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
  var out = Process.runSync(pypth, ["rd"]);
  logger.i("result:\n ${out.stdout}");
  logger.i("result:\n ${out.stderr}");
  logger.i(out.stdout);
}

unPackAFFirmware() async {
  var pypth = path.joinAll([_assetsDir.path, "afptool-rs"]);
  var appDataDir = await getAppDataDirectory();
  logger.i(appDataDir.path);
  var filePath = path.joinAll([appDataDir.path, "embedded-update.img"]);
  var out = await Process.run(pypth, [filePath, appDataDir.path]);
  logger.i("result:\n ${out.stdout}");
  logger.i("result:\n ${out.stderr}");
  logger.i(out.stdout);
}

unPackFWFirmware(filePath) async {
  var pypth = path.joinAll([_assetsDir.path, "afptool-rs"]);
  var appDataDir = await getAppDataDirectory();
  logger.i(appDataDir.path);
  var out = await Process.run(pypth, [filePath, appDataDir.path]);
  logger.i("result:\n ${out.stdout}");
  logger.i("result:\n ${out.stderr}");
  logger.i(out.stdout);
}
