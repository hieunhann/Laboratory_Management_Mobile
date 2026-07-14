import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../config/app_theme.dart';

class VnPayWebViewScreen extends StatefulWidget {
  final String url;
  const VnPayWebViewScreen({super.key, required this.url});

  @override
  State<VnPayWebViewScreen> createState() => _VnPayWebViewScreenState();
}

class _VnPayWebViewScreenState extends State<VnPayWebViewScreen> {
  bool _isLoading = true;

  void _checkUrl(String url) {
    final uri = Uri.parse(url);
    if (url.contains('successBooking') || 
        url.contains('failBooking') || 
        url.contains('hema-link.io.vn')) {
      
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      if (responseCode == '00' || url.contains('successBooking')) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              javaScriptEnabled: true,
            ),
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // BỎ QUA MỌI LỖI SSL! Chấp nhận mọi chứng chỉ.
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
              if (url != null) _checkUrl(url.toString());
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              if (url != null) _checkUrl(url.toString());
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
