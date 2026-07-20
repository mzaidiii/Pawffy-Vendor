import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pawffy/main.dart';

class StripeOnboardingWebView extends StatefulWidget {
  final String url;

  const StripeOnboardingWebView({super.key, required this.url});

  @override
  State<StripeOnboardingWebView> createState() => _StripeOnboardingWebViewState();
}

class _StripeOnboardingWebViewState extends State<StripeOnboardingWebView> {
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
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.path.contains('/vendor/payouts/return')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            } else if (uri.path.contains('/vendor/payouts/refresh')) {
              Navigator.pop(context, false);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'STRIPE PARTNER SETUP',
          style: GoogleFonts.barlow(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
        ],
      ),
    );
  }
}
