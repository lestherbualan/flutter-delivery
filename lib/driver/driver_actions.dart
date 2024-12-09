import 'package:delivery/driver/driver_map.dart';
import 'package:delivery/driver/driver_map_initializer.dart';
import 'package:delivery/model/order.dart';
import 'package:delivery/model/user.dart';
import 'package:flutter/material.dart';

class DriverActions extends StatefulWidget {
  final Order orderInformation;
  final dynamic driverInformation;
  const DriverActions({super.key, required this.orderInformation, required this.driverInformation});

  @override
  State<DriverActions> createState() => _DriverActionsState();
}

class _DriverActionsState extends State<DriverActions> {
  @override
  void initState() {
    super.initState();
    print(widget.orderInformation);
  }

  @override
  Widget build(BuildContext context) {
    dynamic orderInfo = widget.orderInformation;
    return Scaffold(
      body: SafeArea(
          child: Material(
        child: DriverMapInitializer(
          orderInformation: orderInfo,
          driverInformation: widget.driverInformation,
        ),
      )),
    );
  }
}
