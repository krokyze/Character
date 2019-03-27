import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(App());

const PANTS = 0, HAT = 1, BODY = 2, SHOES = 3;

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      color: Colors.black,
      home: Material(
        color: Colors.white,
        child: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  double width = 0, height = 0;
  double hOffset = 0, hOffsetEnd = 0, vOffset = 0, vOffsetEnd = 0;

  final clothes = List.filled(4, List<String>());
  final widgets = List<Widget>(4);

  final centerWidgets = List<Widget>.filled(4, Container());
  int swipeIndex;

  AnimationController controller;

  @override
  void initState() {
    super.initState();
    init();
    controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          hOffset = lerpDouble(hOffset, hOffsetEnd, controller.value);
          vOffset = lerpDouble(vOffset, vOffsetEnd, controller.value);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            hOffset = vOffset = 0;
            hOffsetEnd = vOffsetEnd = 0;
            if (swipeIndex != null) {
              onSwipe(swipeIndex);
            }
          });
        }
      });
  }

  void init() async {
    final assets = await DefaultAssetBundle.of(context)
        .loadString('assets/clothes.json')
        .then((string) => List.from(json.decode(string)));

    setState(() {
      for (int i = 0; i < clothes.length; i++) {
        clothes[i] = List.from(assets[i]);
        widgets[i] = buildWidget(clothes[i].first);
        _firstToLast(clothes[i]);
      }
    });
  }

  void _firstToLast(List<String> list) {
    final item = list[0];
    list.removeAt(0);
    list.add(item);
  }

  Widget buildWidget(String url) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: 32),
      child: Image.asset(url, fit: BoxFit.contain),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  onDragUpdate(DragUpdateDetails details) {
    setState(() {
      hOffset += details.delta.dx;
      vOffset += details.delta.dy;
    });
  }

  onDragEnd(_) {
    setState(() {
      if (hOffset < -(width / 4)) {
        swipeIndex = BODY;
        hOffsetEnd = -width;
      } else if (hOffset > (width / 4)) {
        swipeIndex = PANTS;
        hOffsetEnd = width;
      } else if (vOffset < -(height / 6)) {
        swipeIndex = SHOES;
        vOffsetEnd = -height;
      } else if (vOffset > (height / 6)) {
        swipeIndex = HAT;
        vOffsetEnd = height;
      } else {
        swipeIndex = null;
        hOffsetEnd = vOffsetEnd = 0;
      }
      if (swipeIndex != null) {
        centerWidgets[swipeIndex] = Container();
      }
    });
    controller.forward(from: 0);
  }

  onSwipe(int index) {
    centerWidgets[index] = widgets[index];
    widgets[index] = buildWidget(clothes[index].first);
    _firstToLast(clothes[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (width == 0 && height == 0) {
      Size size = MediaQuery.of(context).size;
      setState(() {
        width = size.width;
        height = size.height;
      });
    }

    if (clothes.any((it) => it.isEmpty)) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: onDragUpdate,
      onVerticalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      onVerticalDragEnd: onDragEnd,
      child: Stack(
        children: List<Widget>()
          ..add(SvgPicture.asset(
            'assets/background.svg',
            height: height,
            fit: BoxFit.cover,
          ))
          ..add(buildWidget('assets/character.png'))
          ..add(centerWidgets[SHOES])
          ..add(transform(Offset(0, height + vOffset), widgets[SHOES]))
          ..add(centerWidgets[PANTS])
          ..add(transform(Offset(-width + hOffset, 0), widgets[PANTS]))
          ..add(centerWidgets[BODY])
          ..add(transform(Offset(width + hOffset, 0), widgets[BODY]))
          ..add(centerWidgets[HAT])
          ..add(transform(Offset(0, -height + vOffset), widgets[HAT])),
      ),
    );
  }

  final transform = (o, c) => Transform.translate(offset: o, child: c);
}
