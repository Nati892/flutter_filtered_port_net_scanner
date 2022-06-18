import 'dart:io';
import 'package:port_scanner/ip_data.dart';

class NetworkCcanner {
  //returns a list of all device network addresses
  Future<List<String>> getNetworkInterfaces() async {
    List<String> lst = [];
    for (var interface in await NetworkInterface.list()) {
      for (var add in interface.addresses) {
        lst.add(add.address.toString());
      }
    }
    return lst;
  }

//gets an address and returns a list of all possible addresses in network
//assumes only for subnet of : 255.255.255.0
  Future<List<String>> getAllNetworkAddresses(List<String> list) async {
    List<String> lst = [];
    for (var add in list) {
      String host = "${add.substring(0, add.lastIndexOf("."))}.";
      for (int i = 0; i < 256; i++) {
        lst.add("$host$i");
      }
    }
    return lst;
  }

//trys to connect to a socket and returns a Future<bool> with true if succesed and false for not
//closes connection immediatly
  Future<bool> tryConnectToSocketAsync(String ip, int port) async {
    bool res = true;
    try {
      Socket socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.close();
      print("success ${ip}:${port}");
    } catch (e) {
      res = false;
      return res;
    }
    //print("$res + $ip");
    return res;
  }

  //gets socket details and a List<String>, if connected successfuly then adds the ip to the list
  Future<void> addStringConnectedAsync(
      String ip, int port, List<String> lst) async {
    var res = await tryConnectToSocketAsync(ip, port);
    if (res) {
      lst.add(ip);
    }
    return;
  }

//scans the network for all ip addresses that have a specific port open, returns a list<String> of them
  Future<List<String>> scanNetworkForPort(int port) async {
    List<String> addresses =
        await getAllNetworkAddresses(await getNetworkInterfaces());
    List<Future<void>> futures = [];
    List<String> resAddresses = [];
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
        .then((value) async => {if (value) data.openPorts.add(port)});
  }

//scanning network with port filter
  Future<List<String>> ScanNetworkWithPortFilterAsync(List<int> ports) async {
    if (ports.isEmpty) return ["empty filter!"];
    List<String> result = [];
    List<Future<void>> futures = [];
    List<String> addresses =
        await getAllNetworkAddresses(await getNetworkInterfaces());
    for (var address in addresses) {
      futures.add(ScanPortsForIpAsync(address, ports, result));
    }
    await Future.wait(futures);
    return result;
  }

  Future<void> ScanPortsForIpAsync(
      String ip, List<int> portsFilter, List<String> IpCollection) async {
    List<Future<bool>> futures = [];
    List<bool> results = [];
    for (var element in portsFilter) {
      futures.add(tryConnectToSocketAsync(ip, element));
    }
    for (var e in futures) {
      e.then((value) => results.add(value));
    }
    await Future.wait(futures);
    if (!results.contains(false)) IpCollection.add(ip);
  }

  Future<void> addPortConnectedAsync(String ip, int port, List<int> lst) async {
    if (await tryConnectToSocketAsync(ip, port)) lst.add(port);
  }
}
