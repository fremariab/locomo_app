import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:locomo_app/services/firebase_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapDownloader {
  static Future<String> downloadMapAsPdf({
    required LatLngBounds bounds,
    required String fileName,
    int minZoom = 12,
    int maxZoom = 14,
    void Function(double)? onProgress,
  }) async {
    try {
      // 1. Download map tiles
      final tiles = await _downloadTiles(bounds, minZoom, maxZoom, onProgress);

      // 2. Create PDF
      final pdf = pw.Document();
      for (final tile in tiles) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Stack(
              children: [
                pw.Image(pw.MemoryImage(tile.bytes)),
                pw.Positioned(
                  bottom: 10,
                  left: 10,
                  child: pw.Text(
                    '© OpenStreetMap contributors',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      background: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xB3000000),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 3. Get the right directory
      Directory dir;
      if (Platform.isAndroid) {
        try {
          // Try external storage first
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

// 4. Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${fileName}_$timestamp.pdf');

// 5. Save and verify
      await file.writeAsBytes(await pdf.save());

      if (!await file.exists()) {
        throw Exception('Failed to save PDF file');
      }

      return file.path;
    } catch (e) {
      debugPrint('PDF generation error: $e');
      rethrow;
    }
  }
// In MapDownloader class
static Future<String> downloadMapForLocation({
  required LatLng location,
  required String fileName,
  double radius = 1000.0, // meters
  int minZoom = 12,
  int maxZoom = 14,
}) async {
  // 1. Get nearby stations
  final nearbyStations = await FirebaseService().getNearbyStations(
    location.latitude,
    location.longitude,
    radius,
  );

  // 2. Calculate bounds
  final bounds = calculateBoundsFromStations(nearbyStations);

  // 3. Download map
  return await downloadMapAsPdf(
    bounds: bounds,
    fileName: fileName,
    minZoom: minZoom,
    maxZoom: maxZoom,
  );
}
  static Future<List<TileData>> _downloadTiles(
    LatLngBounds bounds,
    int minZoom,
    int maxZoom,
    void Function(double)? onProgress,
  ) async {
    final tiles = <TileData>[];
    int totalTiles = 0;
    int downloadedTiles = 0;

    // Calculate total tiles first
    for (var zoom = minZoom; zoom <= maxZoom; zoom++) {
      final (x1, x2, y1, y2) = _boundsToTileRange(bounds, zoom);
      totalTiles += (x2 - x1 + 1) * (y2 - y1 + 1);
    }

    // Download tiles
    for (var zoom = minZoom; zoom <= maxZoom; zoom++) {
      final (x1, x2, y1, y2) = _boundsToTileRange(bounds, zoom);

      for (var x = x1; x <= x2; x++) {
        for (var y = y1; y <= y2; y++) {
          final uri = Uri.parse(
            'https://tile.openstreetmap.org/$zoom/$x/$y.png',
          );

          final response = await http.get(uri);
          if (response.statusCode == 200) {
            tiles.add(TileData(x, y, zoom, response.bodyBytes));
          }

          downloadedTiles++;
          onProgress?.call(downloadedTiles / totalTiles);
        }
      }
    }
    return tiles;
  }

  // Convert lat/lng bounds to tile coordinates at given zoom level
  static (int x1, int x2, int y1, int y2) _boundsToTileRange(
    LatLngBounds bounds,
    int zoom,
  ) {
    final topLeft = _latLngToTileCoords(bounds.northWest, zoom);
    final bottomRight = _latLngToTileCoords(bounds.southEast, zoom);

    return (
      topLeft.$1,
      bottomRight.$1,
      topLeft.$2,
      bottomRight.$2,
    );
  }

  // Convert lat/lng to tile coordinates
  static (int x, int y) _latLngToTileCoords(LatLng point, int zoom) {
    final latRad = point.latitude * pi / 180;
    final n = pow(2.0, zoom);
    final x = ((point.longitude + 180.0) / 360.0 * n).floor();
    final y = ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / 2.0 * n).floor());

    return (x, y);
  }

  static LatLngBounds calculateBoundsFromStations(
      List<Map<String, dynamic>> stations) {
    if (stations.isEmpty) throw Exception("No stations provided");

    double minLat = stations[0]['coordinates']['lat'];
    double maxLat = minLat;
    double minLng = stations[0]['coordinates']['lng'];
    double maxLng = minLng;

    for (final station in stations) {
      final lat = station['coordinates']['lat'];
      final lng = station['coordinates']['lng'];

      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    // Add 10% padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }
}

class TileData {
  final int x;
  final int y;
  final int z;
  final Uint8List bytes;

  TileData(this.x, this.y, this.z, this.bytes);
}
