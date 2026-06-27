import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/couple_info.dart';
import '../models/wedding_category.dart';
import '../models/checklist_item.dart';
import '../models/guest_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wedding_planner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // SQLite handles booleans as 0 or 1

    // Couple Info table
    await db.execute('''
      CREATE TABLE couple_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        maleUid $textType,
        femaleUid $textType,
        weddingDate $textType,
        budgetGoal $integerType
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name $textType,
        groupName $textType,
        status $textType,
        estimatedCost $integerType,
        actualCost $integerType,
        notes $textType,
        vendorName $textType,
        vendorPhone $textType,
        updatedBy $textType,
        updatedAt $textType
      )
    ''');

    // Category Photos table
    await db.execute('''
      CREATE TABLE category_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId $textType,
        url $textType,
        caption $textType,
        uploadedBy $textType,
        uploadedAt $textType
      )
    ''');

    // Checklist table
    await db.execute('''
      CREATE TABLE checklist (
        id TEXT PRIMARY KEY,
        phase $textType,
        title $textType,
        isDone $boolType,
        linkedCategoryId $textNullable,
        createdBy $textType
      )
    ''');

    // Guests table
    await db.execute('''
      CREATE TABLE guests (
        id TEXT PRIMARY KEY,
        name $textType,
        phone $textType,
        side $textType,
        mealConfirmed $boolType,
        attended $boolType
      )
    ''');

    // Memos table
    await db.execute('''
      CREATE TABLE memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text $textType,
        sender $textType,
        time $textType
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        categoryId TEXT,
        date TEXT,
        title TEXT,
        reminderDays INTEGER
      )
    ''');
  }

  // --- Schedules DB Operations ---
  Future<List<CategorySchedule>> getAllSchedules() async {
    final db = await instance.database;
    final maps = await db.query('schedules');
    return maps.map((map) {
      return CategorySchedule(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        title: map['title'] as String,
        reminderDays: map['reminderDays'] as int,
      );
    }).toList();
  }

  Future<void> addSchedule(String categoryId, CategorySchedule schedule) async {
    final db = await instance.database;
    await db.insert('schedules', {
      'id': schedule.id,
      'categoryId': categoryId,
      'date': schedule.date.toIso8601String(),
      'title': schedule.title,
      'reminderDays': schedule.reminderDays,
    });
  }

  Future<void> deleteSchedule(String id) async {
    final db = await instance.database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Couple Info CRU ---
  Future<CoupleInfo?> getCoupleInfo() async {
    final db = await instance.database;
    final maps = await db.query('couple_info', limit: 1);
    if (maps.isNotEmpty) {
      final map = maps.first;
      return CoupleInfo(
        maleUid: map['maleUid'] as String?,
        femaleUid: map['femaleUid'] as String?,
        weddingDate: map['weddingDate'] != null ? DateTime.parse(map['weddingDate'] as String) : null,
        budgetGoal: map['budgetGoal'] as int,
      );
    }
    return null;
  }

  Future<void> saveCoupleInfo(CoupleInfo info) async {
    final db = await instance.database;
    final map = {
      'maleUid': info.maleUid,
      'femaleUid': info.femaleUid,
      'weddingDate': info.weddingDate?.toIso8601String(),
      'budgetGoal': info.budgetGoal,
    };
    final count = await db.update('couple_info', map);
    if (count == 0) {
      await db.insert('couple_info', map);
    }
  }

  // --- Categories DB Operations ---
  Future<List<WeddingCategory>> getCategories() async {
    final db = await instance.database;
    final catMaps = await db.query('categories');
    
    List<WeddingCategory> categories = [];
    for (var map in catMaps) {
      final id = map['id'] as String;
      final photoMaps = await db.query(
        'category_photos',
        where: 'categoryId = ?',
        whereArgs: [id],
      );

      final photos = photoMaps.map((p) {
        return CategoryPhoto(
          url: p['url'] as String,
          caption: p['caption'] as String,
          uploadedBy: p['uploadedBy'] as String,
          uploadedAt: DateTime.parse(p['uploadedAt'] as String),
        );
      }).toList();

      final statusStr = map['status'] as String;
      final status = PreparationStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => PreparationStatus.none,
      );

      categories.add(
        WeddingCategory(
          id: id,
          name: map['name'] as String,
          groupName: map['groupName'] as String,
          status: status,
          estimatedCost: map['estimatedCost'] as int,
          actualCost: map['actualCost'] as int,
          notes: map['notes'] as String,
          vendorName: map['vendorName'] as String,
          vendorPhone: map['vendorPhone'] as String,
          schedules: [], // Schedule feature to be synced in Sprint 3
          photos: photos,
          updatedBy: map['updatedBy'] as String,
          updatedAt: DateTime.parse(map['updatedAt'] as String),
        ),
      );
    }
    return categories;
  }

  Future<void> saveCategories(List<WeddingCategory> categories) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var cat in categories) {
      batch.insert(
        'categories',
        {
          'id': cat.id,
          'name': cat.name,
          'groupName': cat.groupName,
          'status': cat.status.name,
          'estimatedCost': cat.estimatedCost,
          'actualCost': cat.actualCost,
          'notes': cat.notes,
          'vendorName': cat.vendorName,
          'vendorPhone': cat.vendorPhone,
          'updatedBy': cat.updatedBy,
          'updatedAt': cat.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Clean up and re-insert photos
      batch.delete('category_photos', where: 'categoryId = ?', whereArgs: [cat.id]);
      for (var photo in cat.photos) {
        batch.insert('category_photos', {
          'categoryId': cat.id,
          'url': photo.url,
          'caption': photo.caption,
          'uploadedBy': photo.uploadedBy,
          'uploadedAt': photo.uploadedAt.toIso8601String(),
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateCategory(WeddingCategory cat) async {
    final db = await instance.database;
    await db.update(
      'categories',
      {
        'status': cat.status.name,
        'estimatedCost': cat.estimatedCost,
        'actualCost': cat.actualCost,
        'notes': cat.notes,
        'vendorName': cat.vendorName,
        'vendorPhone': cat.vendorPhone,
        'updatedBy': cat.updatedBy,
        'updatedAt': cat.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cat.id],
    );

    // Update photos
    await db.delete('category_photos', where: 'categoryId = ?', whereArgs: [cat.id]);
    for (var photo in cat.photos) {
      await db.insert('category_photos', {
        'categoryId': cat.id,
        'url': photo.url,
        'caption': photo.caption,
        'uploadedBy': photo.uploadedBy,
        'uploadedAt': photo.uploadedAt.toIso8601String(),
      });
    }
  }

  // --- Checklist DB Operations ---
  Future<List<TimelineChecklistItem>> getChecklist() async {
    final db = await instance.database;
    final maps = await db.query('checklist');
    return maps.map((map) {
      return TimelineChecklistItem(
        id: map['id'] as String,
        phase: map['phase'] as String,
        title: map['title'] as String,
        isDone: (map['isDone'] as int) == 1,
        linkedCategoryId: map['linkedCategoryId'] as String?,
        createdBy: map['createdBy'] as String,
      );
    }).toList();
  }

  Future<void> saveChecklist(List<TimelineChecklistItem> items) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var item in items) {
      batch.insert(
        'checklist',
        {
          'id': item.id,
          'phase': item.phase,
          'title': item.title,
          'isDone': item.isDone ? 1 : 0,
          'linkedCategoryId': item.linkedCategoryId,
          'createdBy': item.createdBy,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateChecklistItem(String id, bool isDone) async {
    final db = await instance.database;
    await db.update(
      'checklist',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Guests DB Operations ---
  Future<List<GuestItem>> getGuests() async {
    final db = await instance.database;
    final maps = await db.query('guests');
    return maps.map((map) {
      return GuestItem(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String,
        side: map['side'] as String,
        mealConfirmed: (map['mealConfirmed'] as int) == 1,
        attended: (map['attended'] as int) == 1,
      );
    }).toList();
  }

  Future<void> saveGuests(List<GuestItem> guests) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var guest in guests) {
      batch.insert(
        'guests',
        {
          'id': guest.id,
          'name': guest.name,
          'phone': guest.phone,
          'side': guest.side,
          'mealConfirmed': guest.mealConfirmed ? 1 : 0,
          'attended': guest.attended ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> addGuest(GuestItem guest) async {
    final db = await instance.database;
    await db.insert('guests', {
      'id': guest.id,
      'name': guest.name,
      'phone': guest.phone,
      'side': guest.side,
      'mealConfirmed': guest.mealConfirmed ? 1 : 0,
      'attended': guest.attended ? 1 : 0,
    });
  }

  Future<void> updateGuestMeal(String id, bool mealConfirmed) async {
    final db = await instance.database;
    await db.update(
      'guests',
      {'mealConfirmed': mealConfirmed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Memos DB Operations ---
  Future<List<Map<String, dynamic>>> getMemos() async {
    final db = await instance.database;
    final maps = await db.query('memos', orderBy: 'id ASC');
    return maps.map((map) {
      return {
        'text': map['text'] as String,
        'sender': map['sender'] as String,
        'time': map['time'] as String,
      };
    }).toList();
  }

  Future<void> addMemo(Map<String, dynamic> memo) async {
    final db = await instance.database;
    await db.insert('memos', {
      'text': memo['text'] as String,
      'sender': memo['sender'] as String,
      'time': memo['time'] as String,
    });
  }
}
