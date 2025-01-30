import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NavigationWebView extends StatelessWidget {
  final double destLat;
  final double destLng;

  NavigationWebView({required this.destLat, required this.destLng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navegación'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebView(
        initialUrl: 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
