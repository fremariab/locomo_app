import 'package:flutter/foundation.dart';
import 'package:locomo_app/models/route_model.dart';

class FavoritesService with ChangeNotifier {
  final List<RouteModel> _favoriteRoutes = [];

  List<RouteModel> get favorites => _favoriteRoutes;

  bool isFavorite(RouteModel route) {
    return _favoriteRoutes.any((r) => 
      r.origin == route.origin && 
      r.destination == route.destination &&
      r.price == route.price);
  }

  void addFavorite(RouteModel route) {
    if (!isFavorite(route)) {
      _favoriteRoutes.add(route);
      notifyListeners();
    }
  }

  void removeFavorite(RouteModel route) {
    _favoriteRoutes.removeWhere((r) => 
      r.origin == route.origin && 
      r.destination == route.destination &&
      r.price == route.price);
    notifyListeners();
  }
}