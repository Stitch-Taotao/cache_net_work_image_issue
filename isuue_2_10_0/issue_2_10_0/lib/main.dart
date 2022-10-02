import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'avata_image.dart';
import 'ids.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Material App',
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material App Bar'),
      ),
      body: Center(
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return const SecondePage();
              },
            ));
          },
          child: Container(
            child: const Text('Hello World'),
          ),
        ),
      ),
    );
  }
}

class SecondePage extends StatefulWidget {
  const SecondePage({Key? key}) : super(key: key);

  @override
  State<SecondePage> createState() => _SecondePageState();
}

class _SecondePageState extends State<SecondePage> {
  List<String> ids = [];
  @override
  void initState() {
    super.initState();
    parse();
  }

  parse() {
    ids = List<String>.generate(120, (index) {
      return initSourceFile2();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        key: UniqueKey(),
        itemBuilder: (context, index) {
          final id = ids[index];
          return LYAvatarWidget(src: id);
        },
        itemCount: ids.length,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Icon(Icons.refresh),
          ),
          OutlinedButton(
            onPressed: () {
              CacheUtil.cacheClean();
            },
            child: const Icon(Icons.delete),
          )
        ],
      ),
    );
  }
}

class CacheUtil {
  // 清楚缓存
  static Future cacheClean() async {
    try {
      var tempDir = await getTemporaryDirectory();
      await delDir(tempDir);
    } catch (e) {
      print(e);
    }
  }

  static Future delDir(FileSystemEntity file) async {
    try {
      if (file is Directory) {
        List<FileSystemEntity> children = file.listSync();
        for (FileSystemEntity child in children) {
          await delDir(child);
        }
      }
      await file.delete();
    } catch (e) {
      print(e);
    }
  }
}
