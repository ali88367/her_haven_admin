import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sidebarx/sidebarx.dart';
import '../../colors.dart';
import '../Login.dart';
import 'sidebar_controller.dart';

class ExampleSidebarX extends StatefulWidget {
  const ExampleSidebarX({super.key});

  @override
  State<ExampleSidebarX> createState() => _ExampleSidebarXState();
}

class _ExampleSidebarXState extends State<ExampleSidebarX> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _itemAnimationController;
  late Animation<double> _itemScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize SidebarController only if not already present
    if (!Get.isRegistered<SidebarController>()) {
      Get.put(SidebarController());
    }
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _itemAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _itemScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _itemAnimationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _itemAnimationController.forward();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          elevation: 2,
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: pink,
              fontFamily: 'Mack',
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: black.withOpacity(0.8),
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.find<SidebarController>().selectedindex.value = 0;
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: 14,
                  color: blue,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(100, 40),
              ),
              onPressed: () async {
                Get.find<SidebarController>().selectedindex.value = 0;
                Get.offAll(() => const Login());
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GetBuilder<SidebarController>(
      builder: (sidebarController) {
        return ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbVisibility: const MaterialStatePropertyAll(true),
            thumbColor: MaterialStateProperty.all(Colors.white),
            thickness: const MaterialStatePropertyAll(4),
            trackColor: MaterialStateProperty.all(Colors.white30),
            trackBorderColor: const MaterialStatePropertyAll(Colors.transparent),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SidebarX(
              controller: sidebarController.controller,
              theme: SidebarXTheme(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: pink,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                hoverColor: blue.withOpacity(0.1),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                hoverTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                itemTextPadding: const EdgeInsets.only(left: 12),
                selectedItemTextPadding: const EdgeInsets.only(left: 12),
                itemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                selectedItemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white),
                  color: blue.withOpacity(0.2),
                ),
                iconTheme: const IconThemeData(
                  color: Colors.white,
                  size: 24,
                ),
                selectedIconTheme: const IconThemeData(
                  color: Colors.white,
                  size: 26,
                ),
              ),
              extendedTheme: SidebarXTheme(
                width: width < 768 ? 200 : 240,
                decoration: BoxDecoration(
                  color: pink,
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              footerDivider: Divider(color: Colors.white30, height: 1),
              headerBuilder: (context, extended) {
                return Container(
                  decoration: BoxDecoration(
                    color: pink,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Obx(
                            () => sidebarController.showsidebar.value
                            ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: pink,
                                  size: 20,
                                ),
                                onPressed: () {
                                  sidebarController.showsidebar.value = false;
                                },
                              ),
                            ),
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                      ScaleTransition(
                        scale: _itemScaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            height: width < 768 ? 120 : 140,
                            width: width < 768 ? 120 : 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'User Data',
                ),
                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 1;
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.library_books_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Resources',
                ),
                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 2;
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.list_alt_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Resources List',
                ),
                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 3;
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Help Centers',
                ),
                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 4;
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.report,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Reports',
                ),
                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 5;
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Terms/Privacy',
                ),

                SidebarXItem(
                  onTap: () {
                    sidebarController.selectedindex.value = 0;
                    sidebarController.controller.selectIndex(0);
                    _showLogoutDialog();
                  },
                  iconBuilder: (selected, hovered) {
                    return ScaleTransition(
                      scale: _itemScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? blue.withOpacity(0.2) : (hovered ? blue.withOpacity(0.1) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: selected ? 26 : 24,
                        ),
                      ),
                    );
                  },
                  label: 'Log out',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }
}