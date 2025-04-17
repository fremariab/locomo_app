// map_downloader.dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDownloader {
  /// Downloads a single-page PDF containing a Google Static Map
  /// with markers at each station.
  static Future<String> downloadStationsMap({
    required List<LatLng> stations,
    required String fileName,
    int zoom = 12,         // default zoom level
    int width = 800,       // pixel width of the static map
    int height = 600,      // pixel height of the static map
    int scale = 1,         // device pixel ratio
  }) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API key not configured!');
    }
    if (stations.isEmpty) {
      throw Exception('No stations provided.');
    }

    // Compute a simple center: the average latitude & longitude
    final avgLat = stations.map((s) => s.latitude).reduce((a, b) => a + b) / stations.length;
    final avgLng = stations.map((s) => s.longitude).reduce((a, b) => a + b) / stations.length;

    // Build markers parameter for Static Maps (labelled 1..N)
    final stationMarkers = stations.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final s = entry.value;
      return 'markers=color:red%7Clabel:$i%7C${s.latitude},${s.longitude}';
    }).join('&');

    // Construct the Static Maps URL
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/staticmap?'
      'center=$avgLat,$avgLng'
      '&zoom=$zoom'
      '&size=${width}x$height'
      '&scale=$scale'
      '&maptype=roadmap'
      '&$stationMarkers'
      '&key=$apiKey'
    );

    // Download the image bytes
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Static map download failed (${response.statusCode})');
    }
    final imageBytes = response.bodyBytes;

    // Build the PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context _) {
          return pw.Column(
            children: [
              pw.Text('Trotro Stations Map', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Image(pw.MemoryImage(imageBytes)),
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 10),
                child: pw.Row(
                  children: [
                    pw.Container(width: 20, height: 20, color: PdfColors.red),
                    pw.SizedBox(width: 8),
                    pw.Text('Station Markers'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to Downloads (Android) or Documents (iOS)
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${fileName}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    if (!await file.exists()) {
      throw Exception('Failed to save PDF');
    }
    return file.path;
  }
}
