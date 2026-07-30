import 'package:flutter/material.dart';

/// Lets long-lived tab content know when another full page covers its route.
final RouteObserver<PageRoute<dynamic>> everCareRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
