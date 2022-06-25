import 'dart:io';
import 'package:port_scanner/ip_data.dart';

class NetworkCcanner {
  //returns a list of all device network addresses
  Future<List<String>> getNetworkInterfaces() async {
    List<String> lst = [];
    for (var interface in await NetworkInterface.list()) {
      for (var add in interface.addresses) {
        bool isGood = true;
        int dot_times = 0;
        String parsed = add.address;
        for (int i = 0; i < 4; i++) {
          if (dot_times < 3) {
            //if dot supposed to exist
            if (parsed.contains(".")) {
              dot_times++;
              String supposeToBeInt = parsed.substring(0, parsed.indexOf("."));
              if (int.tryParse(supposeToBeInt) != null) {
                parsed =
                    parsed.substring(parsed.indexOf(".") + 1, parsed.length);
              } else {
                isGood = false;
              }
            } else {
              isGood = false;
            }
          } else {
            if (int.tryParse(parsed) != null) {
              parsed = parsed.substring(parsed.indexOf(".") + 1, parsed.length);
            } else {
              isGood = false;
            }
          }
        }
        if (isGood) lst.add(add.address.toString());
      }
    }
    print("lst:");
    lst.map((e) => print(e));
    return lst;
  }

//gets an address and returns a list of all possible addresses in network
//assumes only for subnet of : 255.255.255.0
  Future<List<String>> getAllNetworkAddresses(List<String> list) async {
    List<String> lst = [];
    for (var add in list) {
      print("object");
      print(add);
      String host = "${add.substring(0, add.lastIndexOf("."))}.";
      for (int i = 0; i < 256; i++) {
        lst.add("$host$i");
      }
    }
    return lst;
  }

//trys to connect to a socket and returns a Future<bool> with true if succesed and false for not
//closes connection immediatly
  Future<IpData?> tryConnectToSocketAsync(String ip, int port) async {
    IpData? res;
    Socket? socket;
    try {
      socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      res = IpData();
      res.ip = ip;

      print("success ${ip}:${port}");
    } on Exception catch (e) {
      if (socket != null) {
        socket.close();
        socket.destroy();
      }
    }
    //print("$res + $ip");
    return res;
  }

  //gets socket details and a List<String>, if connected successfuly then adds the ip to the list
  Future<void> addStringConnectedAsync(
      String ip, int port, List<IpData> lst) async {
    var res = await tryConnectToSocketAsync(ip, port);
    if (res != null) {
      lst.add(res);
    }
    return;
  }

//scans the network for all ip addresses that have a specific port open, returns a list<String> of them
  Future<List<IpData>> scanNetworkForPort(int port) async {
    List<String> addresses =
        await getAllNetworkAddresses(await getNetworkInterfaces());
    List<Future<void>> futures = [];
    List<IpData> resAddresses = [];
    for (var element in addresses) {
      futures.add(addStringConnectedAsync(element, port, resAddresses));
    }
    await Future.wait(futures);
    print("************this is end********");

    print(":::::::::: $resAddresses");
    return resAddresses;
  }

  Future<void> portScanIpAddressRangeAsync(
      IpData data, int rStart, int rEnd) async {
    List<Future<void>> futures = [];
    if (rEnd < rStart || rStart < 0 || rEnd > 65536) {
      for (var i = rStart; i <= rEnd; i++) {
        futures.add(addSocketToListOnConnected(data, i));
      }
    }
    await Future.wait(futures);
  }

  Future<void> addSocketToListOnConnected(IpData data, int port) async {
    await tryConnectToSocketAsync(data.ip, port)
        .then((value) async => {if (value != null) data.openPorts.add(port)});
  }

//scanning network with port filter
  Future<List<String>> ScanNetworkWithPortFilterAsync(List<int> ports) async {
    if (ports.isEmpty) return ["empty filter!"];
    List<String> results = [];
    List<Future<void>> futures = [];
    List<String> addresses =
        await getAllNetworkAddresses(await getNetworkInterfaces());
    for (var address in addresses) {
      //run a port scan for each address
      futures.add(ScanPortsForIpAsync(address, ports, results));
    }
    await Future.wait(futures);
    return results;
  }

  Future<void> ScanPortsForIpAsync(
      String ip, List<int> portsFilter, List<String> IpCollection) async {
    List<Future<IpData?>> futures = [];
    List<bool> results = [];
    for (var element in portsFilter) {
      //try all ports
      futures.add(tryConnectToSocketAsync(ip, element));
    }
    for (var e in futures) {
      //wait for results
      e.then((value) {
        results
            .add((e != null)); //add true if recieved object and false for none
      });
    }
    await Future.wait(futures);
    if (!results.contains(false)) IpCollection.add(ip);
  }

  Future<void> addPortConnectedAsync(String ip, int port, List<int> lst) async {
    await tryConnectToSocketAsync(ip, port).then((value) {
      if (value != null) lst.add(port);
    });
  }
}
