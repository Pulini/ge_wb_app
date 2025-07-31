# ge_wb_app

金帝WebBuilderApp

# 权限与硬件设备集成 API 使用说明（Flutter）

> 适用于 **Flutter** 项目，通过 `permission_handler` 和 **MethodChannel** 与原生（Android/iOS）交互，实现权限申请、蓝牙、扫码、人脸活体检测、地磅秤、USB 监听等功能。

---

## 📁 文件结构

| 文件 | 说明 |
|------|------|
| `permissions.dart` | 权限申请（相机、蓝牙等） |
| `face_verify.dart` | 活体人脸检测 |
| `pda_scan.dart` | PDA 扫码 |
| `bluetooth.dart` | 蓝牙扫描、连接、数据发送 |
| `weighbridge.dart` | 地磅秤监听与读取 |
| `usb.dart` | USB 插拔监听与文件打开 |

---

## 🎯 权限申请

### 1. 相机权限

```dart
bool granted = await requestCameraPermission();
```

- **返回**
    - `true`：已授权
    - `false`：未授权

---

### 2. 蓝牙相关权限（位置 + 蓝牙 5 项）

```dart
requestBluetoothPermission(
  allGranted: () {
    // 所有权限已授予
  },
  hasDenied: (permission) {
    // permission 为失败项：location / bluetoothConnect / bluetoothScan / bluetooth / bluetoothAdvertise
  },
);
```

---

## 🧑‍🦰 活体人脸检测

```dart
livenFaceVerify(
  faceFilePath: '/storage/emulated/0/face.jpg',
  verifySuccess: (base64) {
    // base64：检测成功后的照片
  },
  verifyFail: (err) {
    // err：错误信息
  },
);
```

---

## 📷 PDA 扫码（连续监听）

```dart
addPDAScanListener(
  scan: (code) {
    // code：扫码结果字符串
  },
);
```

---

## 📡 蓝牙

### 1. 扫描 & 设备监听

```dart
addBluetoothListener(
  startScan: () => print('开始扫描'),
  endScan: () => print('结束扫描'),
  connected: (mac) => print('已连接 $mac'),
  disconnected: (mac) => print('已断开 $mac'),
  stateOff: () => print('蓝牙关闭'),
  stateOn: () => print('蓝牙开启'),
  actionStateOff: () => print('切换为关闭'),
  actionStateOn: () => print('切换为开启'),
  deviceFind: (device) {
    // device 字段：
    // DeviceName, DeviceMAC, DeviceBondState(bool), DeviceIsConnected(bool)
  },
);
```

---

### 2. 扫描控制

```dart
bool ok = await scanBluetooth();   // 开始扫描
bool ok = await endScanBluetooth(); // 结束扫描
```

---

### 3. 连接 & 关闭

```dart
int result = await connectBluetooth(
  deviceMac: 'AA:BB:CC:DD:EE:FF',
  connectCallback: (type) {
    // type: 0 成功 / 1 失败 / 2 未找到 / 3 蓝牙关闭
  },
);

bool ok = await closeBluetooth('AA:BB:CC:DD:EE:FF');
```

---

### 4. 获取已扫描设备列表

```dart
List<Map> list = await getScannedDevices();
// 每个元素包含：DeviceName, DeviceMAC, DeviceBondState, DeviceIsConnected
```

---

### 5. 状态检查

```dart
bool enable = await bluetoothIsEnable();       // 蓝牙是否打开
bool location = await bluetoothIsLocationOn(); // 蓝牙定位是否打开
```

---

### 6. 发送标签数据

```dart
int code = await sendLabel([Uint8List.fromList([0x1B, 0x40])]);
// 1000 成功 / 1003 失败 / 1007 通道断开
```

---

## ⚖️ 地磅秤

### 1. 监听

```dart
weighbridgeListener(
  weighbridgeState: (state) {
    // state：设备状态字符串
  },
  weight: (value) {
    // value：称重结果（double）
  },
);
```

### 2. 打开地磅秤

```dart
await weighbridgeOpen();
```

---

## 🔌 USB 插拔 & 文件

### 1. 监听插拔

```dart
usbListener(
  usbAttached: () => print('USB 插入'),
  usbDetached: () => print('USB 拔出'),
);
```

### 2. 打开文件

```dart
openFile('/storage/emulated/0/Documents/demo.txt');
```


## 📌 使用示例（完整流程）

```dart
// 1. 申请权限
await requestBluetoothPermission(
  allGranted: () async {
    // 2. 开始扫描
    await scanBluetooth();
    // 3. 监听结果
    addBluetoothListener(
      deviceFind: (d) => print('发现 ${d['DeviceName']}'),
      connected: (mac) => print('已连接 $mac'),
    );
  },
  hasDenied: (p) => print('$p 权限被拒绝'),
);

// 4. 扫码监听
addPDAScanListener(scan: (code) => print('扫码结果 $code'));

// 5. 人脸检测
livenFaceVerify(
  faceFilePath: '/sdcard/face.jpg',
  verifySuccess: (b64) => print('人脸 base64：${b64.substring(0, 30)}...'),
  verifyFail: (err) => print('人脸检测失败 $err'),
);
```

