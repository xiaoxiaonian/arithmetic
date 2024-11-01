import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late List<Bean> arr;
  late TextEditingController editingController;
  late DateTime selectedTime;
  late bool visible;

  //输入的值，接收键盘输入和擦除尾端
  String content = "";

  @override
  void initState() {
    super.initState();
    visible = true;
    selectedTime = DateTime.now();
    editingController = TextEditingController(text: "");
    createBean();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.all(20),
      child: RepaintBoundary(
          key: repaint,
          child: SingleChildScrollView(padding: EdgeInsets.only(left: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${selectedTime.year}年${selectedTime.month}月${selectedTime.day}日",
                      style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                    ),
                    Visibility(
                      child: TextButton(onPressed: () => onButtonClicked(), child: Text("截屏并保存")),
                      visible: visible,
                    )
                  ],
                ),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 1,
                  child: Wrap(
                    spacing: 45,
                    runSpacing: 25,
                    children: arr
                        .asMap()
                        .keys
                        .map((index) => Container(
                              width: 220,
                              color: index % 2 == 0 ? Colors.black12.withAlpha(20) : Colors.white,
                              child: Text(
                                arr[index].label ?? "",
                                style: TextStyle(fontSize: 22),
                              ),
                            ))
                        .toList(),
                  ),
                )
              ],
            ),
          )),
    ));
  }

  //随机生成0-9的数字按键，然后增加擦除和随机按键
  void createBean() {
    arr = List.generate(60, (index) {
      int num = Random().nextInt(OperatorType.values.length);
      Bean bean = Bean.fromParams(type: OperatorType.values[num]);
      return bean;
    });
    int left, right, count = 1;
    arr.forEach((bean) {
      left = Random().nextInt(999);
      right = Random().nextInt(999);
      while (!diagnose(operator: bean.type!, left: left, right: right)) {
        left = Random().nextInt(999);
        right = Random().nextInt(999);
      }
      bean.label = "($count)  $left${bean.type?.label}$right=";
      count++;
    });
    debugPrint("");
  }

  bool diagnose({required OperatorType operator, required int left, required int right}) {
    bool result = true;
    switch (operator) {
      case OperatorType.plus:
        if (left < 10) {
          left = left * 10 + Random().nextInt(10);
        }
        if (right < 10) {
          right = right * 10 + Random().nextInt(10);
        }
        if ((left % 10) + (right % 10) < 10) {
          result = false;
        } else if ((left % 100 ~/ 10) + (right % 100 ~/ 10) < 10) {
          result = false;
        } else {}
        break;
      case OperatorType.minus:
        if ((left - right) <= 0) {
          result = false;
        } else if ((left % 10) - (right % 10) > 0) {
          result = false;
        } else if ((left % 100 ~/ 10) - (right % 100 ~/ 10) > 0) {
          result = false;
        } else {}
        break;
    }
    return result;
  }

  //按钮被点击
  void onButtonClicked() {
    setState(() {
      visible = false;
    });
    Future.delayed(Duration(milliseconds: 200), () {
      getImageData().then((value) {
        uint8list = value;
        downloadPicture();
      });
    });
  }

  Uint8List? uint8list;
  GlobalKey repaint = GlobalKey();

  /// 获取截取图片的数据
  Future<Uint8List> getImageData() async {

    BuildContext buildContext = repaint.currentContext!;
    RenderObject? boundary = buildContext.findRenderObject();
    // 第一次执行时，boundary.debugNeedsPaint 为 true，此时无法截图（如果为true时直接截图会报错）
    if (boundary!.debugNeedsPaint) {
      // 延时一定时间后，boundary.debugNeedsPaint 会变为 false，然后可以正常执行截图的功能
      await Future.delayed(Duration(milliseconds: 20));
      // 重新调用方法
      return getImageData();
    }
    // 获取当前设备的像素比
    double dpr = ui.window.devicePixelRatio;
    // pixelRatio 代表截屏之后的模糊程度，因为不同设备的像素比不同
    // 定义一个固定数值显然不是最佳方案，所以以当前设备的像素为目标值
    ui.Image image = await (boundary as RenderRepaintBoundary).toImage(pixelRatio: dpr);

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? imageBytes = byteData?.buffer.asUint8List();
    // 返回图片的数据
    return imageBytes!;
  }

  downloadPicture() async {
    // final directory = await getApplicationDocumentsDirectory();
    // final filePath = path.join(directory.path, 'image.png');
    // String path = "D:/code/salary_sheet/assets/capture/";
    String path = "C:/Users/Administrator/Desktop/";
    final file = File("./年宏博的数学题.png");
    await file.writeAsBytes(uint8list!);
    /*for(int i=0 ; i<arrayListSigned.length-1;i++){
      int j = i+1;
      DateTime before = arrayListSigned[i][cc.time];
      DateTime after = arrayListSigned[j][cc.time];
      if(before.year==after.year&& before.month==after.month&& before.day==after.day){
        debugPrint("occur");
      }
    }*/
  }
}

class Bean {
  String? label;
  OperatorType? type;

  Bean.fromParams({this.label, this.type});

  factory Bean(Object jsonStr) => jsonStr is String ? Bean.fromJson(json.decode(jsonStr)) : Bean.fromJson(jsonStr);

  static Bean? parse(jsonStr) => ['null', '', null].contains(jsonStr) ? null : Bean(jsonStr);

  Bean.fromJson(jsonRes) {
    label = jsonRes['label'];
    type = jsonRes['type'];
  }

  @override
  String toString() {
    return '{"label": ${label != null ? '${json.encode(label)}' : 'null'}, "type": ${type != null ? '${json.encode(type)}' : 'null'}}';
  }

  String toJson() => this.toString();
}

//按钮类型：数字、擦除、随机
enum ButtonType { number, wipe, random }

enum OperatorType {
  plus(label: "+"),
  minus(label: "-");

  final String label;

  const OperatorType({required this.label});
}
