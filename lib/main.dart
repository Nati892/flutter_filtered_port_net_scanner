import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:port_scanner/network_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final myController = TextEditingController();

  int portToScan = 80;
  List<String> leftListView = [];
  List<String> rightListView = [];
  List<String> portFilter = [];
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    myController.text = portToScan.toString();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 50, 5, 5),
        child: Center(
          child: Column(
            children: <Widget>[
              const Text("Port scanner"),
              Row(
                children: [
                  ConstrainedBox(
                    //specific port
                    constraints:
                        const BoxConstraints(maxWidth: 100, maxHeight: 100),
                    child: TextField(
                      controller: myController,
                      onChanged: (val) {
                        int intVal;
                        try {
                          intVal = int.parse(val);
                        } catch (e) {
                          intVal = 0;
                          myController.text = intVal.toString();
                        }
                        if (intVal > 65536) {
                          myController.text = 65536.toString();
                        }
                        if (intVal < 0) {
                          myController.text = 0.toString();
                        }
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        portFilter.add(myController.text);
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blueGrey[100])),
                    child: const Text("add port"),
                  ),
                  DropdownButton(
                      hint: const Text("ports"),
                      items: portFilter.map((e) {
                        return DropdownMenuItem(
                            value: e,
                            child: TextButton(
                                child: Text(e),
                                onPressed: () {
                                  setState(() {
                                    portFilter.remove(e);
                                  });
                                }));
                      }).toList(),
                      onChanged: (v) {})
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 40, 0, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.blueGrey[100])),
                        onPressed: () async {
                          setState(() {
                            leftListView = ['scanning'];
                          });
                          portToScan = int.parse(myController.text);
                          var scanner = NetworkCcanner();
                          var x = await scanner
                              .scanNetworkForPort(int.parse(myController.text));

                          setState(() {
                            leftListView = x;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.search),
                            Text("Scan by single")
                          ],
                        )),
                    TextButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.blueGrey[100])),
                        onPressed: () async {
                          print("pressed");
                          setState(() {
                            rightListView = ["scanning"];
                            portFilter = portFilter.toSet().toList();
                          });
                          List<int> portFilterInt =
                              portFilter.map((e) => int.parse(e)).toList();
                          print("bbbb:$portFilterInt");
                          var scanner = NetworkCcanner();
                          var x = await scanner.ScanNetworkWithPortFilterAsync(
                              portFilterInt);
                          setState(() {
                            rightListView = x;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.search),
                            Text("Scan by filter")
                          ],
                        )),
                  ],
                ),
              ),
              Expanded(
                  child: Row(
                children: [
                  SizedBox(
                    width: screenWidth / 2,
                    height: 600,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.blueGrey[100],
                          shape: BoxShape.rectangle),
                      child: ListView.builder(
                          itemCount: leftListView.length,
                          itemBuilder: (context, index) {
                            return SelectableText(
                              leftListView[index],
                              style: const TextStyle(color: Colors.black87),
                              //TextStyle(backgroundColor: Colors.grey[200]),
                              showCursor: true,
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: leftListView[index]));
                              },
                            );
                          }),
                    ),
                  ), //********first list here **********/
                  const SizedBox(
                    //******middle*******
                    width: 10,
                  ), //******middle*******
                  Expanded(
                    //********second list here **********/
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.blueGrey[100],
                          shape: BoxShape.rectangle),
                      child: ListView.builder(
                          itemCount: rightListView.length,
                          itemBuilder: (context, index) {
                            return SelectableText(
                              rightListView[index],
                              style: const TextStyle(color: Colors.black87),
                              //TextStyle(backgroundColor: Colors.grey[200]),
                              showCursor: true,
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: rightListView[index]));
                              },
                            );
                          }),
                    ),
                  ),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }
}



//add combobox
//give func to add,scan all buttons
//connect listViews with the right data