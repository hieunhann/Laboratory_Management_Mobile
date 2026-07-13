import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/app_theme.dart';

class VnPayWebViewScreen extends StatefulWidget {
  final String url;
  const VnPayWebViewScreen({super.key, required this.url});

  @override
  State<VnPayWebViewScreen> createState() => _VnPayWebViewScreenState();
}

class _VnPayWebViewScreenState extends State<VnPayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            // Chỉ bắt sự kiện redirect khi VNPAY chuyển hướng quay lại trang kết quả của Merchant (hema-link.io.vn hoặc localhost)
            // Tránh đóng WebView sớm khi VNPAY đang chuyển hướng nội bộ trong sandbox.vnpayment.vn
            if (request.url.contains('successBooking') || 
                request.url.contains('failBooking') || 
                request.url.contains('hema-link.io.vn')) {
              
              final responseCode = uri.queryParameters['vnp_ResponseCode'];
              if (responseCode == '00' || request.url.contains('successBooking')) {
                // Thanh toán thành công
                Navigator.pop(context, true);
              } else {
                // Thanh toán thất bại hoặc hủy
                Navigator.pop(context, false);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
          WebViewWidget(controller: _controller),
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
