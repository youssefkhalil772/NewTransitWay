import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

class AddTicketsScreen extends StatefulWidget {
  const AddTicketsScreen({super.key});

  @override
  State<AddTicketsScreen> createState() => _AddTicketsScreenState();
}

class _AddTicketsScreenState extends State<AddTicketsScreen> {
  bool isDropdownOpen = true;
  int? selectedPrice;
  int ticketCount = 0;

  final List<int> prices = [18, 20, 22, 28];

  final Color green = const Color(0xff39C449);
  final Color borderGreen = const Color(0xffB8E7BE);

  String get totalAmount {
    if (selectedPrice == null) return "0.00";
    return (selectedPrice! * ticketCount).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      //================ APP BAR =================//
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Transit",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "Way",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            SizedBox(width: 3.w),
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Icons.location_on,
                color: green,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 5.w),
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                "Driver",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),

      //================ BODY =================//
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // Select Price
            GestureDetector(
              onTap: () {
                setState(() {
                  isDropdownOpen = !isDropdownOpen;
                });
              },
              child: Container(
                height: 55.h,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: borderGreen, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedPrice == null
                            ? "Select Price - EGP"
                            : "$selectedPrice - EGP",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Dropdown List
            if (isDropdownOpen)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: borderGreen, width: 2),
                ),
                child: Column(
                  children: List.generate(prices.length, (index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedPrice = prices[index];
                          ticketCount++;
                          isDropdownOpen = false;
                        });
                      },
                      child: Container(
                        height: 60.h,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        decoration: BoxDecoration(
                          border: index != prices.length - 1
                              ? Border(
                            bottom: BorderSide(
                              color: borderGreen,
                              width: 1.5,
                            ),
                          )
                              : null,
                        ),
                        child: Text(
                          "${prices[index]} EGP",
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            SizedBox(height: 25.h),

            buildInfoBox(
              "Number Of Manual Tickets",
              "$ticketCount",
            ),

            SizedBox(height: 18.h),

            buildInfoBox(
              "Total Amount",
              "$totalAmount EGP",
            ),

            SizedBox(height: 25.h),

            //================ ADD TICKET BUTTON (WITH NAVIGATION) =================//
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                  RoutesManager.navigateTo(context, RoutesManager.driverRoutes);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Add Ticket",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),

    );
  }

  Widget buildInfoBox(String title, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}
