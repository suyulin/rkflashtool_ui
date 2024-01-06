import 'dart:async';
import 'dart:convert';
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
  adb,
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
final upgradeTool = path.joinAll([_assetsDir.path, "upgrade_tool"]);
final adb = path.joinAll([_assetsDir.path, "adb"]);
final xfel = path.joinAll([_assetsDir.path, "xfel"]);
final phoenixsuit =
    path.joinAll([_assetsDir.path, "phoenixsuit", "phoenixsuit"]);
final phoenixsuitWorkDir = path.joinAll([_assetsDir.path, "phoenixsuit"]);

class _ButtonsPageState extends State<ButtonsPage> {
  String firmwarePath = "";
  DeviceStatus deviceStatus = DeviceStatus.unknown;
  String chipInfo = "";
  bool isR818 = false;
  bool isLoading = false;
  Timer? _timer;
  late double _progress;

  @override
  void initState() {
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
    Timer.periodic(const Duration(seconds: 2), (Timer timer) async {
      // 在定时器触发时执行的操作
      var adbResult = await Process.run(adb, ["devices"]);
      if (adbResult.stdout.toString().split("\n").length == 4) {
        setState(() {
          deviceStatus = DeviceStatus.adb;
        });
      } else {
        var result = await Process.run(upgradeTool, ["ld"]);
        if (result.stdout.toString().contains("Loader")) {
          setState(() {
            deviceStatus = DeviceStatus.ready;
          });
        } else {
          setState(() {
            deviceStatus = DeviceStatus.notReady;
          });
          var result = await Process.run(xfel, ["version"]);
          if (result.stdout.toString().contains("WARNING")) {
            setState(() {
              deviceStatus = DeviceStatus.ready;
              isR818 = true;
            });
          } else {
            setState(() {
              deviceStatus = DeviceStatus.notReady;
            });
          }
        }
      }
    });
    super.initState();
  }

  unPackFirmwareHandle() async {
    clearData();
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
      setState(() {
        chipInfo ="";
      });
      await unPackFWFirmware(filePath);
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

  if (deviceStatus == DeviceStatus.notReady) {
      EasyLoading.showError("设备未连接");
      return;
    }
    if (deviceStatus == DeviceStatus.adb) {
      EasyLoading.showError("设备未处于升级状态，请先切换");
      return;
    }

    if (!isR818) {
      if (queryChipInfo() != chipInfo) {
        EasyLoading.showError("芯片不匹配");
        return;
      }
    }
    if (isR818) {
      await updateR818Firmware();
    } else {
      await updateFirmware();
    }
  }

  isR818Handle() {
    var out = Process.runSync(adb, ["shell", "hostname"]);
    if (out.stdout.toString().contains("TinaLinux")) {
      return true;
    }
    return false;
  }

  changeDeviceStatusHandle() async {
    if (deviceStatus == DeviceStatus.ready) {
      EasyLoading.showInfo("设备已连接");
      return;
    }
    isR818 = await isR818Handle();
    var cmd = isR818 ? "efex" : "bootloader";
    var out = await Process.run(adb, ["reboot", cmd]);
    if (out.exitCode != 0) {
      EasyLoading.showError("设备切换失败");
      logger.e("adb reboot bootloader failed");
    } else {
      EasyLoading.showSuccess("设备切换成功");
      logger.i("adb reboot bootloader success");
    }
  }

  updateR818Firmware() async {
    setState(() {
      isLoading = true;
    });
    EasyLoading.show(
      status: '请拔插设备',
    );
    _progress = 0;
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(milliseconds: 100), (Timer timer) {});
    String pattern = r'\d+%';
    RegExp regExp = RegExp(pattern);
    var result = await Process.start(phoenixsuit, [firmwarePath],
        workingDirectory: phoenixsuitWorkDir);
    result.stdout.listen((event) {
      var text = utf8.decode(event);
      Match? match = regExp.firstMatch(text);
      if (match != null) {
        String number = match.group(0)!.replaceAll("%", "");
        logger.i(number);
        _progress = double.parse(number) / 100;
        EasyLoading.showProgress(_progress,
            status: '${(_progress * 100).toStringAsFixed(0)}%');
      }
      logger.i(text);
    }, onDone: () {
      setState(() {
        isLoading = false;
        _progress = 0.0;
      });
      EasyLoading.showSuccess("固件更新成功");
      EasyLoading.dismiss();
    }, onError: (e) {
      setState(() {
        isLoading = false;
        _progress = 0.0;
      });
      EasyLoading.showError("固件更新失败");
      EasyLoading.dismiss();
      logger.e(e);
    });
  }

  Future<void> updateFirmware() async {
    setState(() {
      isLoading = true;
    });
    _progress = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      EasyLoading.showProgress(_progress,
          status: '${(_progress * 100).toStringAsFixed(0)}%');
      _progress += 0.02;

      if (_progress >= 1) {
        _timer?.cancel();
      }
    });
    var result = await Process.run(upgradeTool, ["uf", firmwarePath]);
    if (result.exitCode != 0) {
      EasyLoading.showError("固件更新失败");
      logger.e(result.stderr);
    } else {
      EasyLoading.showSuccess("固件更新成功");
      logger.i(result.stdout);
    }
    _timer?.cancel();
    setState(() {
      isLoading = false;
      _progress = 0.0;
    });
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
    });
    logger.i("unPackFWFirmware:\n ${out.stdout}");
  }

  String queryChipInfo() {
    var out = Process.runSync(upgradeTool, ["rci"]);
    RegExp regex = RegExp(r'(\d+)');
    Match? match = regex.firstMatch(out.stdout);
    if (match != null) {
      String number = match.group(1)!;
      var chip = int.parse("0x$number");
      logger.i('Extracted Number: 0x$number');
      return chipInfoMap[chip];
    }
    return "未知芯片";
  }

  deviceStatusDesc() {
    switch (deviceStatus) {
      case DeviceStatus.adb:
        return "✅ 发现一个ADB设备";
      case DeviceStatus.notReady:
        return "❌ 设备未连接";
      case DeviceStatus.ready:
        return "✅ 设备已连接,可更新固件";
      default:
        return "❌ 设备未连接";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
          backgroundColor: const Color.fromARGB(1, 255, 255, 255),

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
                                onPressed:
                                    isLoading ? null : unPackFirmwareHandle,
                                controlSize: ControlSize.large,
                                child: const Text('固件'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PushButton(
                                controlSize: ControlSize.large,
                                onPressed:
                                    isLoading ? null : updateFirmwareHandle,
                                child: const Text('升级'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PushButton(
                                controlSize: ControlSize.large,
                                onPressed:
                                    isLoading ? null : changeDeviceStatusHandle,
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
                      child: Text(deviceStatusDesc()),
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

rebootDevice() {
  var out = Process.runSync(upgradeTool, ["rd"]);
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

clearData() {
  Process.runSync("rm", ["-rf", "/tmp/Image"]);
}
