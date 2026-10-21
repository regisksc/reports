import 'package:flutter/material.dart';

abstract final class ReportsStyle {
  static const orange = Color(0xffff9600);
  static const orangeDark = Color(0xffcc7a00);
  static const ink = Color(0xff3c3c3c);
  static const muted = Color(0xff777777);
  static const border = Color(0xffe5e5e5);
  static const surface = Color(0xfff7f7f7);

  static ButtonStyle raisedButtonStyle({
    Color backgroundColor = orange,
    BorderSide side = BorderSide.none,
  }) =>
      FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: ink,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        enableFeedback: false,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ).copyWith(
        backgroundBuilder: (context, states, child) => ReportsRaisedButton(
          states: states,
          backgroundColor: backgroundColor,
          side: side,
          child: child!,
        ),
      );

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      primary: orange,
      onPrimary: ink,
      surface: Colors.white,
      onSurface: ink,
      outline: border,
      error: const Color(0xffb3261e),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Mona Sans',
      scaffoldBackgroundColor: Colors.white,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: ReportsPageTransitionsBuilder(),
          TargetPlatform.macOS: ReportsPageTransitionsBuilder(),
          TargetPlatform.android: ReportsPageTransitionsBuilder(),
          TargetPlatform.linux: ReportsPageTransitionsBuilder(),
          TargetPlatform.windows: ReportsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ReportsPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 35,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 29,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.55),
        bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Helvetica Neue',
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: raisedButtonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: ink,
          side: const BorderSide(color: border, width: 2),
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: orangeDark, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: orange,
        linearTrackColor: border,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 2),
    );
  }
}

class ReportsRaisedButton extends StatelessWidget {
  const ReportsRaisedButton({
    super.key,
    required this.states,
    required this.backgroundColor,
    required this.side,
    required this.child,
  });

  final Set<WidgetState> states;
  final Color backgroundColor;
  final BorderSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = !states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 80);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        AnimatedPositioned(
          duration: duration,
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          top: pressed ? 3 : 0,
          bottom: 4,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: enabled ? backgroundColor : ReportsStyle.border,
              borderRadius: BorderRadius.circular(14),
              border: side == BorderSide.none
                  ? null
                  : Border.fromBorderSide(side),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: ReportsStyle.orangeDark,
                        offset: Offset(0, pressed ? 1 : 4),
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, pressed ? -.5 : -2, 0),
          child: child,
        ),
      ],
    );
  }
}

class ReportsContentTransition extends StatelessWidget {
  const ReportsContentTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedBuilder(
      animation: animation,
      child: FadeTransition(opacity: animation, child: child),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 64 * (1 - animation.value)),
        child: child,
      ),
    );
  }
}

class ReportsPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReportsPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ReportsContentTransition(
      animation: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: child,
    );
  }
}

class ReportsContinuationHint extends StatefulWidget {
  const ReportsContinuationHint({super.key, required this.child});

  final Widget child;

  @override
  State<ReportsContinuationHint> createState() =>
      _ReportsContinuationHintState();
}

class _ReportsContinuationHintState extends State<ReportsContinuationHint> {
  bool _continues = false;
  bool _pending = false;
  bool _scheduled = false;

  void _update(ScrollMetrics metrics) {
    _pending = metrics.extentAfter > 1;
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && _continues != _pending) {
        setState(() => _continues = _pending);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            _update(notification.metrics);
          }
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) {
              _update(notification.metrics);
            }
            return false;
          },
          child: Stack(
            children: [
              widget.child,
              if (_continues)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 5,
                      child: DecoratedBox(
                        key: Key('report-continuation-hint'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x14000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
