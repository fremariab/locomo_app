import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'locomo_app.db');
    return await openDatabase(
      path,
      version: 2, // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create favorite routes table
    await db.execute('''
      CREATE TABLE favorite_routes(
        id TEXT PRIMARY KEY,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        fare REAL NOT NULL,
        routeData TEXT,
        createdAt TEXT NOT NULL,
        userId TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create offline routes table for routes searched while offline
    await db.execute('''
      CREATE TABLE offline_routes(
        id TEXT PRIMARY KEY,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        routeData TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add routeData column to favorite_routes table
      await db.execute('ALTER TABLE favorite_routes ADD COLUMN routeData TEXT');
    }
  }

  // Save a favorite route to local database
  Future<int> addFavoriteRoute({
    required String id,
    required String origin,
    required String destination,
    required double fare,
    required String userId,
    Map<String, dynamic>? routeData,
    int synced = 0,
  }) async {
    final db = await database;
    return await db.insert(
      'favorite_routes',
      {
        'id': id,
        'origin': origin,
        'destination': destination,
        'fare': fare,
        'routeData': routeData != null ? jsonEncode(routeData) : null,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'synced': synced,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all favorite routes for a specific user
  Future<List<Map<String, dynamic>>> getFavoriteRoutes(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_routes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    
    // Parse the JSON string back to a Map if it exists
    return maps.map((map) {
      if (map['routeData'] != null) {
        return {
          ...map,
          'routeData': jsonDecode(map['routeData'] as String),
        };
      }
      return map;
    }).toList();
  }

  // Delete a favorite route from local database
  Future<int> deleteFavoriteRoute(String id) async {
    final db = await database;
    return await db.delete(
      'favorite_routes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save a route search result for offline viewing
  Future<int> saveOfflineRoute({
    required String id,
    required String origin,
    required String destination,
    required Map<String, dynamic> routeData,
  }) async {
    final db = await database;
    return await db.insert(
      'offline_routes',
      {
        'id': id,
        'origin': origin,
        'destination': destination,
        'routeData': jsonEncode(routeData),
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all offline routes
  Future<List<Map<String, dynamic>>> getOfflineRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_routes',
      orderBy: 'createdAt DESC',
    );
    
    // Parse the JSON string back to a Map
    return maps.map((map) {
      return {
        ...map,
        'routeData': jsonDecode(map['routeData'] as String),
      };
    }).toList();
  }

  // Get unsynced favorite routes
  Future<List<Map<String, dynamic>>> getUnsyncedFavoriteRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_routes',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    // Parse the JSON string back to a Map if it exists
    return maps.map((map) {
      if (map['routeData'] != null) {
        return {
          ...map,
          'routeData': jsonDecode(map['routeData'] as String),
        };
      }
      return map;
    }).toList();
  }

  // Mark a favorite route as synced
  Future<int> markFavoriteRouteAsSynced(String id) async {
    final db = await database;
    return await db.update(
      'favorite_routes',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 