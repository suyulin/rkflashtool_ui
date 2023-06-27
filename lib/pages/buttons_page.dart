import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';

Map chipInfoMap = {0x30: "PX30", 0x38: "RK3566", 0x36: "RK3326"};

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
  String chipInfo = "";

  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      // 在定时器触发时执行的操作
      var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
      var result = await Process.run(pypth, ["ld"]);
      if (result.stdout.toString().contains("Loader")) {
        setState(() {
          deviceStatus = DeviceStatus.ready;
        });
      } else {
        setState(() {
          deviceStatus = DeviceStatus.notReady;
        });
      }
    });
    super.initState();
  }

  unPackFirmwareHandle() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['img']);
    if (result != null) {
      logger.i(result.files.single.path);
      setState(() {
        firmwarePath = "";
      });
      EasyLoading.show(
          status: '解压中',
          indicator: LoadingAnimationWidget.waveDots(
            color: Colors.white,
            size: 100,
          ));
      String filePath = result.files.single.path as String;
      await unPackFWFirmware(filePath);
      await unPackAFFirmware();
      EasyLoading.dismiss();
      setState(() {
        firmwarePath = filePath;
      });
    }
  }

  updateFirmwareHandle() async {
    if (firmwarePath == "") {
      EasyLoading.showError("请先选择固件");
      return;
    }
    if (deviceStatus != DeviceStatus.ready) {
      EasyLoading.showError("设备未连接");
      return;
    }
    if (queryChipInfo() != chipInfo) {
      EasyLoading.showError("芯片不匹配");
      return;
    }
    EasyLoading.showProgress(0, status: '升级中 0%');
    await updateOemFirmware();
    await updateData();
    rebootDevice();
    EasyLoading.showSuccess("固件更新成功");
    EasyLoading.dismiss();
  }

  changeDeviceStatusHandle() async {
    if (deviceStatus == DeviceStatus.ready) {
      EasyLoading.showInfo("设备已连接");
      return;
    }
    var out = await Process.run("adb", ["reboot", "bootloader"]);
    if (out.exitCode != 0) {
      EasyLoading.showError("设备切换失败");
      logger.e("adb reboot bootloader failed");
    } else {
      EasyLoading.showSuccess("设备切换成功");
      logger.i("adb reboot bootloader success");
    }
  }

  Future<void> updateOemFirmware() async {
    Completer<void> completer = Completer<void>();
    Future<void> future = completer.future;
    logger.i("updateFirmware oem");
    var appDataDir = await getAppDataDirectory();
    var oemPath = path.joinAll([appDataDir.path, "Image", "oem.img"]);
    var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
    var result = await Process.start(pypth, ["wlx", "oem", oemPath]);
    var s = result.stdout.transform(utf8.decoder);
    s.listen((event) {
      RegExp regex = RegExp(r'\b(\d+)%');
      Match? match = regex.firstMatch(event);
      if (match != null) {
        String percentage = match.group(1)!;
        EasyLoading.showProgress(
          double.parse(percentage) / 100,
          status: '升级中 $percentage%',
        );
      }
    }, onDone: () {
      completer.complete();
      logger.i("oem updateFirmware done");
    }, onError: (e) {
      logger.e("oem updateFirmware error");
      completer.completeError(e);
      logger.e(e);
    });
    return future;
  }

  updateData() async {
    logger.i("updateFirmware");
    var appDataDir = await getAppDataDirectory();
    var oemPath = path.joinAll([appDataDir.path, "Image", "userdata.img"]);
    var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
    var result = await Process.run(pypth, ["wlx", "userdata", oemPath]);
    logger.i(result.stdout);
    logger.i(result.stderr);
    logger.w("updateFirmware data done");
  }

  unPackFWFirmware(filePath) async {
    var pypth = path.joinAll([_assetsDir.path, "afptool-rs"]);
    var appDataDir = await getAppDataDirectory();
    logger.i(appDataDir.path);
    var out = await Process.run(pypth, [filePath, appDataDir.path]);
    out.stdout.toString().split("\n").forEach((element) {
      if (element.contains("family")) {
        chipInfo = element.split(":")[1].trim();
      }
      logger.i(element);
    });
    logger.i("unPackFWFirmware:\n ${out.stdout}");
  }

  String queryChipInfo() {
    var pypth = path.joinAll([_assetsDir.path, "rkdeveloptool"]);
    var out = Process.runSync(pypth, ["rci"]);
    RegExp regex = RegExp(r'(\d+)');
    Match? match = regex.firstMatch(out.stdout);
    logger.i(out.stdout);
    if (match != null) {
      String number = match.group(1)!;
      var chip = int.parse("0x$number");
      logger.i('Extracted Number: 0x$number');
      return chipInfoMap[chip];
    }
    return "未知芯片";
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PushButton(
                                buttonSize: ButtonSize.large,
                                onPressed: unPackFirmwareHandle,
                                child: const Text('固件'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PushButton(
                                buttonSize: ButtonSize.large,
                                onPressed: updateFirmwareHandle,
                                child: const Text('升级'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PushButton(
                                buttonSize: ButtonSize.large,
                                onPressed: changeDeviceStatusHandle,
                                child: const Text('切换'),
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: SelectableText(
                                "固件路径 : $firmwarePath",
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: SelectableText(
                                  "固件版本：${getVersion(firmwarePath)}"),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: SelectableText("芯片信息：$chipInfo"),
                            ),
                          ],
                        ),
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

String getVersion(path) {
  RegExp regex = RegExp(r'(\d+\.\d+\.\d+\.\d+)');
  Match? match = regex.firstMatch(path);
  if (match != null) {
    String version = match.group(1)!;
    return version;
  }
  return "";
}
