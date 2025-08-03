import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:herhaven_admin/sidebar/sidebar_controller.dart';
import 'package:sidebarx/sidebarx.dart';

import '../../colors.dart';
import '../Login.dart'; // Make sure this file contains the original colors

class ExampleSidebarX extends StatefulWidget {
  @override
  State<ExampleSidebarX> createState() => _ExampleSidebarXState();
}

class _ExampleSidebarXState extends State<ExampleSidebarX> {

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: pink,
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.red,
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                sidebarController.selectedindex.value = 0;
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
              ),
              onPressed: () async {
                Get.offAll(Login());
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  final SidebarController sidebarController = Get.put(SidebarController());

  // final navHoverGradient = const LinearGradient(
  //   colors: [
  //    orange,
  //     Colors.white,
  //   ],
  //   begin: Alignment.topLeft,
  //   end: Alignment.bottomRight,
  // );

  @override
  void initState() {
    super.initState();
    Get.put(SidebarController());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SidebarController>(
      builder: (sidebarController) {
        return ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbVisibility: MaterialStatePropertyAll(true),
            thumbColor: MaterialStateProperty.all(Colors.white),
            thickness: MaterialStateProperty.all(4),
            trackColor: MaterialStateProperty.all(Colors.white30),
            trackBorderColor: MaterialStateProperty.all(Colors.transparent),
          ),
          child: SidebarX(
            controller: sidebarController.controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pink,
              ),
              hoverColor: Colors.red,
              textStyle: const TextStyle(
                  color: Colors.white, fontSize: 18),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              hoverTextStyle: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              itemTextPadding: const EdgeInsets.only(left: 10),
              selectedItemTextPadding: const EdgeInsets.only(left: 10),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white),
              ),
              selectedItemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                  color: Colors.red
              ),
              iconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
            ),
            extendedTheme:  SidebarXTheme(
              width: 200,
              decoration: BoxDecoration(
                color: pink,
              ),
            ),
            footerDivider: Divider(color: Colors.white30),
            headerBuilder: (context, extended) {
              return Container(
                decoration: BoxDecoration(
                  color: pink,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Obx(
                          () =>
                      sidebarController.showsidebar.value == true // Assuming this controls the close button
                          ? Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.clear_sharp,
                              color: Colors.red),
                          onPressed: () {
                            sidebarController
                                .showsidebar
                                .value = false;
                          },
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    Get.width <= 1440
                        ?    SizedBox(
                      height: 150,
                      width: 150,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain, // Ensures the image fits well inside
                      ),
                    )                 //   every call minute price will be set , plat form fee ,
                        : Get.width > 1440 && Get.width <= 2550
                        ?   SizedBox(
                      height: 150,
                      width: 150,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain, // Ensures the image fits well inside
                      ),

                    )
                        :    SizedBox(
                      height: 150,
                      width: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // White circular background
                          shape: BoxShape.circle, // Ensures it's a perfect circle
                        ),
                        alignment: Alignment.center, // Centers the image inside the circle
                        child: Container(
                          height: 110, // Slightly smaller than the parent container
                          width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain, // Ensures the image fits well inside
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,)
                  ],
                ),
              );
            },
            items: [
              SidebarXItem(
                onTap: () {
                  sidebarController.selectedindex.value = 0;
                },
                iconBuilder: (selected, hovered) {
                  return Icon(
                    Icons.people,
                    color: selected
                        ? Colors.white
                        : (hovered
                        ? pink // Orange for Hovered
                        : Colors.white),
                  );
                },
                label: 'User Data',
              ),
              SidebarXItem(
                onTap: () {
                  sidebarController.selectedindex.value = 1;
                },
                iconBuilder: (selected, hovered) {
                  return Icon(
                    Icons.person, // Changed Icon
                    color: selected
                        ? Colors.white
                        : (hovered
                        ? pink // Orange for Hovered
                        : Colors.white),
                  );
                },
                label: 'Resources',
              ),
              SidebarXItem(
                onTap: () {
                  sidebarController.selectedindex.value = 2;
                },
                iconBuilder: (selected, hovered) {
                  return Icon(
                    Icons.person, // Changed Icon
                    color: selected
                        ? Colors.white
                        : (hovered
                        ? pink // Orange for Hovered
                        : Colors.white),
                  );
                },
                label: 'Resources List',
              ),
              SidebarXItem(
                onTap: () {
                  sidebarController.selectedindex.value = 3;
                },
                iconBuilder: (selected, hovered) {
                  return Icon(
                    Icons.book,
                    color: selected
                        ? Colors.white
                        : (hovered
                        ? pink // Orange for Hovered
                        : Colors.white),
                  );
                },
                label: 'Help Centers',
              ),

              SidebarXItem(
                onTap: () {
                  sidebarController.selectedindex.value = 0;
                  sidebarController.controller = SidebarXController(selectedIndex: 0, extended: true);
                  sidebarController.update();
                  _showLogoutDialog();
                },
                iconBuilder: (selected, hovered) {
                  return Icon(
                    Icons.logout,
                    color: selected
                        ? Colors.white
                        : (hovered
                        ? pink // Orange for Hovered
                        : Colors.white),
                  );
                },
                label: 'Log out',
              ),
            ],
          ),
        );
      },
    );
  }
}