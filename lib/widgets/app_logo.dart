import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 150.0});

  @override
  Widget build(BuildContext context) {
    // This is the SVG code for the logo.
    const String svgString = '''
    <svg width="200" height="200" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M100 20C55.8172 20 20 55.8172 20 100C20 144.183 55.8172 180 100 180C144.183 180 180 144.183 180 100C180 55.8172 144.183 20 100 20Z" fill="#E0F2F1"/>
      <path d="M125 90H110V75C110 72.2386 107.761 70 105 70H95C92.2386 70 90 72.2386 90 75V90H75C72.2386 90 70 92.2386 70 95V105C70 107.761 72.2386 110 75 110H90V125C90 127.761 92.2386 130 95 130H105C107.761 130 110 127.761 110 125V110H125C127.761 110 130 107.761 130 105V95C130 92.2386 127.761 90 125 90Z" fill="#4DB6AC"/>
      <path d="M145 65C140.029 65 136 69.0294 136 74C136 85 145 95 145 95C145 95 154 85 154 74C154 69.0294 149.971 65 145 65Z" fill="#81C784"/>
    </svg>
    ''';

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        svgString,
        fit: BoxFit.contain,
      ),
    );
  }
}