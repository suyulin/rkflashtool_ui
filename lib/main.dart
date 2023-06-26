import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:rkflashtool_ui/pages/buttons_page.dart';

import 'theme.dart';

Future<void> main() async {
  runApp(const MacosUIGalleryApp());
}

class MacosUIGalleryApp extends StatelessWidget {
  const MacosUIGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return MacosApp(
          title: 'macos_ui Widget Gallery',
          theme: MacosThemeData.light(),
          darkTheme: MacosThemeData.dark(),
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          home: const WidgetGallery(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}

class WidgetGallery extends StatefulWidget {
  const WidgetGallery({super.key});

  @override
  State<WidgetGallery> createState() => _WidgetGalleryState();
}

class _WidgetGalleryState extends State<WidgetGallery> {
  double ratingValue = 0;
  double sliderValue = 0;
  bool value = false;

  int pageIndex = 0;

  late final searchFieldController = TextEditingController();

  final List<Widget Function(bool)> pageBuilders = [
    (bool isVisible) => CupertinoTabView(
          builder: (_) => const ButtonsPage(),
        ),
  ];

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [],
      child: MacosWindow(
        endSidebar: Sidebar(
          startWidth: 200,
          minWidth: 200,
          maxWidth: 300,
          shownByDefault: false,
          builder: (context, _) {
            return const Center(
              child: Text('End Sidebar'),
            );
          },
        ),
        child: IndexedStack(
          index: pageIndex,
          children: pageBuilders
              .asMap()
              .map((index, builder) {
                final widget = builder(index == pageIndex);
                return MapEntry(index, widget);
              })
              .values
              .toList(),
        ),
      ),
    );
  }
}
