import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supplies the configured Supabase client without coupling screens to the
/// global singleton. Widget tests may omit this scope and render honest empty
/// states without making requests to the live project.
class EverCareBackendScope extends InheritedWidget {
  const EverCareBackendScope({
    required this.client,
    required super.child,
    super.key,
  });

  final SupabaseClient client;

  static SupabaseClient? maybeClient(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EverCareBackendScope>()
      ?.client;

  static SupabaseClient read(BuildContext context) {
    final client = maybeClient(context);
    assert(client != null, 'EverCareBackendScope is missing above this page.');
    return client!;
  }

  @override
  bool updateShouldNotify(EverCareBackendScope oldWidget) =>
      !identical(client, oldWidget.client);
}
