import 'package:flutter/material.dart';
import 'package:thoughtnav/constants/color_constants.dart';
import 'package:thoughtnav/constants/string_constants.dart';

class ResetPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PROJECT_GREEN,
        title: Text(
          APP_NAME,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: screenHeight * 0.1,
          ),
          Container(
            alignment: Alignment.center,
            child: Container(
              width: screenWidth,
              height: screenHeight * 0.4,
              child: Stack(
                children: [
                  Positioned(
                      child: Image(
                        width: screenWidth * 0.5,
                        image: AssetImage(
                            'images/login_screen_left.png'
                        ),
                      ),
                      left: 20.0
                  ),
                  Positioned(
                    right: 20.0,
                    top: 20.0,
                    child: Image(
                      width: screenWidth * 0.5,
                      image: AssetImage(
                          'images/login_screen_right.png'
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            APP_NAME,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: screenHeight * 0.025,
          ),
          Text(
            'ThoughtNav is an online focus group platform.\nResearchers use ThoughtNav to get quality\ninsights from participants like you!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 14.0,
            ),
          ),
          SizedBox(
            height: screenHeight * 0.01,
          ),
          GestureDetector(
            child: Text(
              'Learn More',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00CC66),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: screenHeight * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'New Password',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 0,
                        style: BorderStyle.solid,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'Confirm New Password',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 0,
                        style: BorderStyle.solid,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
