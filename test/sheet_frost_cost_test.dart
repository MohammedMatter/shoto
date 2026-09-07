import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';

/// When a sheet is allowed to spend a blur, and when it must not.
///
/// A `BackdropFilter` is the most expensive thing this app draws and it is
/// charged **per frame in which anything repaints over it** — not once, when
/// it appears. That makes the question "is this frost being looked at?" a
/// performance question rather than a taste one, and there are two answers
/// this file pins down, both measured on the device rather than reasoned about:
///
/// * **While the sheet is travelling.** Already true before these tests, and
///   already documented on [SheetSurface].
/// * **While another route is on top of it.** This one was missed for as long
///   as the app has been able to open a sheet from a sheet. Spinning the
///   minute wheel of the time picker, with the reminder sheet parked invisibly
///   underneath it, cost 30–35ms of raster a frame; with that hidden blur
///   switched off, 16–18ms. The user cannot see the surface at all, and it was
///   costing most of a frame budget.
void main() {
  Widget host({required Widget sheetChild, double? sigma}) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) =>
          MaterialApp(home: child),
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAppSheet<void>(
                context: context,
                builder: (BuildContext sheetContext) =>
                    SheetSurface(sigma: sigma, child: sheetChild),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  /// How many backdrop blurs are in the tree.
  ///
  /// The count is the whole measurement, and that is a fact about [GlassLayer]
  /// rather than a shortcut: it drops the filter entirely at a sigma of zero,
  /// because a `BackdropFilter` costs a `saveLayer` and a full filter pass over
  /// its region whether or not the blur amounts to anything. So a
  /// `BackdropFilter` in the tree *is* the cost, and none in the tree is the
  /// only way to not pay it.
  int blurs(WidgetTester tester) =>
      tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)).length;

  testWidgets('a sheet does not blur while it is still arriving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(sheetChild: const Text('body')));
    await tester.tap(find.text('open'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(blurs(tester), 0);

    await tester.pumpAndSettle();
    expect(blurs(tester), 1);
  });

  testWidgets('a sheet stops blurring once another sheet covers it', (
    WidgetTester tester,
  ) async {
    late BuildContext sheetContext;

    await tester.pumpWidget(
      host(
        sheetChild: Builder(
          builder: (BuildContext context) {
            sheetContext = context;
            return const Text('body');
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(blurs(tester), 1);

    // The second sheet takes no frost of its own, so anything left in the tree
    // belongs to the one underneath.
    showAppSheet<void>(
      context: sheetContext,
      builder: (BuildContext _) =>
          const SheetSurface(sigma: 0, child: Text('on top')),
    );
    await tester.pumpAndSettle();

    expect(blurs(tester), 0);
  });

  testWidgets('the frost comes back when the cover is dismissed', (
    WidgetTester tester,
  ) async {
    late BuildContext sheetContext;

    await tester.pumpWidget(
      host(
        sheetChild: Builder(
          builder: (BuildContext context) {
            sheetContext = context;
            return const Text('body');
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    showAppSheet<void>(
      context: sheetContext,
      builder: (BuildContext _) =>
          const SheetSurface(sigma: 0, child: Text('on top')),
    );
    await tester.pumpAndSettle();
    expect(blurs(tester), 0);

    Navigator.of(sheetContext).pop();
    await tester.pumpAndSettle();

    expect(blurs(tester), 1);
  });

  testWidgets('a sheet waiting on a second sheet keeps its own context', (
    WidgetTester tester,
  ) async {
    // **The regression this file exists for as much as the frost itself.**
    //
    // Turning the blur off changes the shape of the tree, not a property, and
    // the first version of that optimisation therefore threw away the element
    // underneath. Any sheet doing the ordinary thing — open a second sheet,
    // await its answer, act on it — found its own `BuildContext` unmounted by
    // the time the answer arrived, and silently did nothing. This is that
    // exact shape, and it fails without the `GlobalKey` in `SheetSurface`.
    late BuildContext sheetContext;
    DateTime? answered;
    bool wasMounted = false;

    await tester.pumpWidget(
      host(
        sheetChild: Builder(
          builder: (BuildContext context) {
            sheetContext = context;
            return const Text('body');
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(blurs(tester), 1);

    // The first sheet opens a second and waits, exactly as "Pick a time" does.
    // **Captured once, before the await** — which is the whole point. The real
    // call site is `onTap: () => _pick(context)`, a closure holding the context
    // it was built with. Re-reading the field after the await would silently
    // pick up whatever element replaced it and prove nothing.
    final BuildContext held = sheetContext;
    final Future<void> pick = () async {
      final DateTime? at = await showAppSheet<DateTime>(
        context: held,
        builder: (BuildContext inner) => SheetSurface(
          sigma: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(inner).pop(DateTime(2030, 6, 1, 9)),
              child: const Text('confirm'),
            ),
          ),
        ),
      );
      wasMounted = held.mounted;
      if (at == null || !held.mounted) return;
      answered = at;
    }();

    await tester.pumpAndSettle();
    // The frost is gone while it is covered — the optimisation still holds.
    expect(blurs(tester), 0);

    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();
    await pick;

    expect(
      wasMounted,
      isTrue,
      reason: 'the waiting sheet was torn down while a sheet covered it',
    );
    expect(
      answered,
      DateTime(2030, 6, 1, 9),
      reason: 'the answer from the second sheet was dropped',
    );
  });

  testWidgets('a sheet that asked for no frost never pays for one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(sheetChild: const Text('body'), sigma: AppBlur.tallSheet),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(blurs(tester), 0);
  });
}
