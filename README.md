# rkflashtool_ui

# Feature
* 支持瑞芯微系列 3326，3566等
* 支持全志R818
* 支持 M系列 Mac

# Use
前置条件：确保 mac 只连接一个要烧录的设备
```
$ adb devices
List of devices attached
4ae29ab43ad0e7eb	device
```
1. 打开软件 rkflashtool.app
第一次打开软件，需要右键打开, 允许不信任的开发者。
2. 上传固件
    * 点击固件，选择要烧录固件，显示以下信息
     <img src="https://github.com/suyulin/rkflashtool_ui/blob/main/assets/1.png" />

3. 切换设备
   * 点击切换，设备切换到 Loader 模式，切换成功，显示一下信息
   <img width="851" alt="image" src="https://github.com/suyulin/rkflashtool_ui/blob/main/assets/2.png">
4. 升级固件
   * 点击升级按钮开始升级。升级成功，设备会自动重启。
   * **R818设备必须带底壳供电,点击升级按钮,重新插拔设备的USB，设备更新成功后会自动重启 , 如长时间没有升级成功，设备完全断电后重试,**
        

