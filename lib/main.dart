import 'dart:io';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/download_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/constants.dart';
import 'views/auth_gate.dart';

void main(List<String> args) {
  if (runWebViewTitleBarWidget(
    args,
    builder: _buildCustomWebviewTitleBar,
  )) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VMwareGetApp());
}

Widget _buildCustomWebviewTitleBar(BuildContext context) {
  final state = TitleBarWebViewState.of(context);
  final controller = TitleBarWebViewController.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    height: 42,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF6F8FA),
      border: Border(
        bottom: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.8,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Safe inset for macOS native window traffic light buttons (🔴 🟡 🟢)
        if (Platform.isMacOS) const SizedBox(width: 78),
        const SizedBox(width: 4),
        IconButton(
          iconSize: 15,
          splashRadius: 16,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: !state.canGoBack ? null : controller.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        IconButton(
          iconSize: 15,
          splashRadius: 16,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: !state.canGoForward ? null : controller.forward,
          icon: const Icon(Icons.arrow_forward_ios_rounded),
        ),
        IconButton(
          iconSize: 16,
          splashRadius: 16,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: state.isLoading ? controller.stop : controller.reload,
          icon: Icon(state.isLoading ? Icons.close_rounded : Icons.refresh_rounded),
        ),
        const SizedBox(width: 12),
        // Centered security & domain badge
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'support.broadcom.com',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  if (state.isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Balance layout spacing on the right side
        const SizedBox(width: 80),
      ],
    ),
  );
}


class VMwareGetApp extends StatelessWidget {
  const VMwareGetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme(),
            darkTheme: ThemeProvider.darkTheme(),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
