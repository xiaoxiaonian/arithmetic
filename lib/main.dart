import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(size: Size(1650, 850), center: true, title: "应该给年宏博出多少道题呢");
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(MyApp());
  /*  doWhenWindowReady(() {
    final window = appWindow;
    const initialSize = ui.Size(1650, 680);
    window.minSize = initialSize;
    window.size = initialSize;
    window.alignment = Alignment.center;
    window.title = "";
    window.show();
  });*/
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: <LocalizationsDelegate<Object>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: [const Locale('zh', 'CH'), const Locale('en', 'US')],
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white), useMaterial3: true),
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
  List<Bean> arr = [];

  bool debugNeedsPaint = true;

  // region  ---- 输入题目数量 ----
  late TextEditingController editingController;

  // endregion
  // region  ---- 默认显示今天的日期，点击日期可以选择日期 ----
  late DateTime selectedTime;

  // endregion
  // region  ---- 主页是否显示，答案是否显示 ----
  late bool dashboardVisibility, answerVisibility = false;

  // endregion
  // region  ---- 题目数量，图层索引 ----
  late int quantity, index = 0;

  // endregion

  String content = "";

  @override
  void initState() {
    super.initState();
    dashboardVisibility = true;
    selectedTime = DateTime.now();
    editingController = TextEditingController(text: "10");
    // createBean();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("两位数乘法"),),
      body: Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(10),
        child: IndexedStack(
          index: index,
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              alignment: AlignmentDirectional.center,
              color: Colors.transparent,
              width: 180,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onEditingComplete: () => inputDone(),
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter(RegExp(r"\d"), allow: true)],
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      controller: editingController,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.blueGrey, width: 2)), hintText: "请输入数字"),
                    ),
                  ),
                  IconButton(onPressed: () => inputDone(), icon: Icon(Icons.double_arrow_sharp)),
                ],
              ),
            ),
            RepaintBoundary(
              key: repaint,
              child: Column(
                // mainAxisSize: ,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Platform.isAndroid)
                    ...arr.asMap().keys.map((index)=>Text("${arr[index].label}", style: TextStyle(fontSize: 32)))
                  else if (Platform.isWindows) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            openDialog();
                          },
                          child: Text("${selectedTime.year}年${selectedTime.month}月${selectedTime.day}日", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Spacer(),
                        Visibility(
                          visible: dashboardVisibility,
                          child: commonButton(
                            title: "返回主页",
                            fun: () {
                              setState(() {
                                index = 0;
                                dashboardVisibility = true;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Visibility(
                          visible: dashboardVisibility,
                          child: commonButton(
                            title: answerVisibility == false ? "显示答案" : "隐藏答案",
                            fun: () {
                              setState(() {
                                answerVisibility = !answerVisibility;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Visibility(visible: dashboardVisibility, child: commonButton(title: "截屏并保存", fun: () => onButtonClicked())),
                      ],
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        // color: Colors.green,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runAlignment: WrapAlignment.start,
                          runSpacing: 500,
                          children:
                              arr
                                  .asMap()
                                  .keys
                                  .map(
                                    (index) => FractionallySizedBox(
                                      widthFactor: 0.18,
                                      child: Container(
                                        color: index % 2 == 0 ? Colors.black12.withAlpha(20) : Colors.white,
                                        child: Text("${arr[index].label}${answerVisibility == true ? arr[index].answer : ""}${answerVisibility == true ? "..." : ""}   ${answerVisibility == true ? arr[index].additional : ""}", style: TextStyle(fontSize: 32)),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // region  ---- 创造一个个题目和答案 ----
  void createBean() {
    arr = List.generate(quantity, (index) {
      int num = Random().nextInt(OperatorType.values.length);
      Bean bean = Bean.fromParams(type: OperatorType.values[num]);
      bean = Bean.fromParams(type: OperatorType.values[2]);
      return bean;
    });
    int left, right, count = 1;
    for (var bean in arr) {
      left = Random().nextInt(84) + 15;
      right = Random().nextInt(84) + 15;
      while (!diagnose(operator: bean.type!, left: left, right: right)) {
        left = Random().nextInt(84) + 15;
        // right = Random().nextInt(999);
        right = Random().nextInt(84) + 15;
      }
      bean.label = "($count)  $left${bean.type?.label}$right=";
      bean.answer = getAnswer(operator: bean.type!, left: left, right: right);
      if (bean.type!.isDivision) {
        bean.additional = getAdditional(operator: bean.type!, left: left, right: right);
      }
      count++;
    }
  }

  // endregion

  // region  ---- 按键盘回车键或者点击了向右箭头显示题目 ----
  void inputDone() {
    if (editingController.value.text.isNotEmpty) {
      setState(() {
        String result = editingController.value.text;
        quantity = int.parse(result);
        createBean();
        index = 1;
      });
    }
  }

  // endregion

  // region  ---- 出题合法性诊断 ----
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
      case OperatorType.multiplication:
        if (left % 10 == 0 || right % 10 == 0) {
          result = false;
        } else if ( /*!((left < 100 && right < 10) || (left < 10 && right < 100))*/ false) {
          result = false;
        } else {}
        break;
      case OperatorType.division:
        if (left < 100) {
          result = false;
        }
        break;
    }
    return result;
  }

  // endregion

  // region  ---- 返回答案 ----
  int getAnswer({required OperatorType operator, required int left, required int right}) {
    late int answer;
    switch (operator) {
      case OperatorType.plus:
        answer = left + right;
        break;
      case OperatorType.minus:
        answer = left - right;
        break;
      case OperatorType.multiplication:
        answer = left * right;
        break;
      case OperatorType.division:
        answer = left ~/ right;
        break;
    }
    return answer;
  }

  // endregion

  //region  ---- 返回余数 ----
  ///            返回余数
  int getAdditional({required OperatorType operator, required int left, required int right}) {
    late int additional;
    switch (operator) {
      case OperatorType.plus:
        break;
      case OperatorType.minus:
        break;
      case OperatorType.multiplication:
        break;
      case OperatorType.division:
        additional = left % right;
        break;
    }
    return additional;
  }

  //endregion

  // region  ---- 截屏并且在指定路径输出图片 ----
  void onButtonClicked() {
    setState(() {
      dashboardVisibility = answerVisibility;
    });
    Future.delayed(Duration(milliseconds: 200), () {
      getImageData().then((value) {
        uint8list = value;
        downloadPicture();
      });
    });
  }

  // endregion

  Uint8List? uint8list;
  GlobalKey repaint = GlobalKey();

  // region  ---- 获取截取图片的数据 ----
  Future<Uint8List> getImageData() async {
    BuildContext buildContext = repaint.currentContext!;
    RenderObject? boundary = buildContext.findRenderObject();
    // 第一次执行时，boundary.debugNeedsPaint 为 true，此时无法截图（如果为true时直接截图会报错）
    if (debugNeedsPaint) {
      // 延时一定时间后，boundary.debugNeedsPaint 会变为 false，然后可以正常执行截图的功能
      await Future.delayed(Duration(milliseconds: 20));
      debugNeedsPaint = false;
      // 重新调用方法
      return getImageData();
    }
    // 获取当前设备的像素比
    double dpr = View.of(context).devicePixelRatio;
    // double dpr = ui.window.devicePixelRatio;
    // pixelRatio 代表截屏之后的模糊程度，因为不同设备的像素比不同
    // 定义一个固定数值显然不是最佳方案，所以以当前设备的像素为目标值
    ui.Image image = await (boundary as RenderRepaintBoundary).toImage(pixelRatio: dpr);

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? imageBytes = byteData?.buffer.asUint8List();
    // 返回图片的数据
    return imageBytes!;
  }

  // endregion

  downloadPicture() async {
    // final directory = await getApplicationDocumentsDirectory();
    // final filePath = path.join(directory.path, 'image.png');
    // String path = "D:/code/salary_sheet/assets/capture/";
    String path = "C:/Users/年锐/Desktop/";
    final file = File("$path${answerVisibility ? "数学题答案.png" : "年宏博的数学题.png"}");
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

  void openDialog() {
    DateTime today = DateTime.now();
    showDatePicker(context: context, initialDate: today, firstDate: DateTime(1950), lastDate: today.add(Duration(days: 365)), locale: Locale("zh")).then(
      (value) => {
        // debugPrint("showDatePicker")
        setState(() {
          selectedTime = value ?? DateTime.now();
        }),
      },
    );
  }
}

MaterialButton commonButton({required String title, required Function fun}) {
  return MaterialButton(
    onPressed: () {
      fun.call();
    },
    color: Colors.blue,
    textColor: Colors.white,
    child: Text(title),
  );
}

// region  ---- 数据结构 ----
class Bean {
  int? answer;
  int? additional;
  String? label;
  OperatorType? type;

  Bean.fromParams({this.answer, this.additional, this.label, this.type});

  factory Bean(Object jsonStr) => jsonStr is String ? Bean.fromJson(json.decode(jsonStr)) : Bean.fromJson(jsonStr);

  static Bean? parse(jsonStr) => ['null', '', null].contains(jsonStr) ? null : Bean(jsonStr);

  Bean.fromJson(jsonRes) {
    answer = jsonRes['answer'];
    additional = jsonRes['additional'];
    label = jsonRes['label'];
    type = jsonRes['type'];
  }

  @override
  String toString() {
    return '{"answer": $answer, "label": ${label != null ? json.encode(label) : 'null'}, "type": ${type != null ? json.encode(type) : 'null'}}';
  }

  String toJson() => toString();
}
// endregion

// region  ---- 枚举:加减乘除 ----
enum OperatorType {
  plus(label: "+"),
  minus(label: "-"),
  multiplication(label: "×"),
  division(label: "÷");

  bool get isDivision => this == division;
  final String label;

  const OperatorType({required this.label});
}

// endregion
