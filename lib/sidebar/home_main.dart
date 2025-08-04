import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:herhaven_admin/tabs/resources.dart';
import 'package:herhaven_admin/sidebar/sidebar.dart';
import 'package:herhaven_admin/sidebar/sidebar_controller.dart';
import '../tabs/User_Details.dart';
import '../tabs/add_help.dart';
import '../tabs/resourcesList.dart';


class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  final SidebarController sidebarController = Get.put(SidebarController());



  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context)!.size.width;
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if(sidebarController.showsidebar.value ==true) {
            sidebarController.showsidebar.value =false;
          }
        },
        child: Stack(
          children: [
            Row(
              children: [
                width>=768?ExampleSidebarX():SizedBox.shrink(),
                Expanded(
                    child: Obx(() => sidebarController.selectedindex.value == 0
                        ? UserDetails()
                        : sidebarController.selectedindex.value == 1
                        ? Resources()
                        : sidebarController.selectedindex.value == 2
                        ? ResourcesList()
                        : sidebarController.selectedindex.value == 3
                        ? AdminPanelSinglePage()
                        : UserDetails()))
              ],
            ),
            Obx(()=>sidebarController.showsidebar.value == true? ExampleSidebarX():SizedBox.shrink(),)

          ],
        ),
      ),
    );
  }
}
