import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

double defaultMargin = 18.0;
double defaultRadius = 10.0;

// const Color kPrimaryColor = Color(0xff2B7C79);
const Color kPrimaryColor = Color(0xFF3D979D);
const Color kSecondaryColor = Color(0xFFEbbd6f);
const Color kAccentColor = Color(0xFFaedee8);
const Color kWhiteColor = Color(0xffFFFFFF);

const Color tPrimaryColor = Color(0xff348e99);
// const Color tDarkGreenColor = Color(0xff057C68);
const Color tSecondaryColor = Color(0xff7FBBB1);
const Color tSecondary10Color = Color(0xff009fb5);
const Color tSecondary20Color = Color(0xff034b9a);
const Color tErrorColor = Color(0xffD1495B);
const Color tBlackColor = Color(0xff002c32);
const Color tGreyColor = Color(0xff5d5d5d);

const Color kBackgroundColor = Color(0xffedfaff);
const Color kBackground2Color = Color(0xfffff9fd);
const Color kBoxGreenColor = Color(0xffC7FDF1);
const Color kBoxMensColor = Color(0xffFBFFFE);

TextStyle primaryTextStyle = GoogleFonts.poppins(
    color:tPrimaryColor
);

TextStyle errorTextStyle = GoogleFonts.poppins(
    color:tErrorColor
);

TextStyle secondaryTextStyle = GoogleFonts.poppins(
    color:kSecondaryColor
);

TextStyle titleTextStyle = GoogleFonts.rubikWetPaint(
  color: tPrimaryColor
);

TextStyle blackTextStyle = GoogleFonts.poppins(
    color:tBlackColor
);

TextStyle greyTextStyle = GoogleFonts.poppins(
    color:tGreyColor
);

TextStyle titleWhiteTextStyle = GoogleFonts.rubikWetPaint(
  color: kWhiteColor
);

TextStyle whiteTextStyle = GoogleFonts.poppins(
    color: kWhiteColor
);



FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semiBold = FontWeight.w600;
FontWeight bold = FontWeight.w700;
FontWeight extraBold = FontWeight.w800;
FontWeight black = FontWeight.w900;