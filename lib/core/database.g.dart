// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cloudflareIdMeta = const VerificationMeta(
    'cloudflareId',
  );
  @override
  late final GeneratedColumn<String> cloudflareId = GeneratedColumn<String>(
    'cloudflare_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
    'dob',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pobMeta = const VerificationMeta('pob');
  @override
  late final GeneratedColumn<String> pob = GeneratedColumn<String>(
    'pob',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _aiInterpretationMeta = const VerificationMeta(
    'aiInterpretation',
  );
  @override
  late final GeneratedColumn<String> aiInterpretation = GeneratedColumn<String>(
    'ai_interpretation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<double> timezone = GeneratedColumn<double>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.5),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cloudflareId,
    name,
    dob,
    pob,
    lat,
    lon,
    createdAt,
    updatedAt,
    needsSync,
    aiInterpretation,
    timezone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cloudflare_id')) {
      context.handle(
        _cloudflareIdMeta,
        cloudflareId.isAcceptableOrUnknown(
          data['cloudflare_id']!,
          _cloudflareIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dob')) {
      context.handle(
        _dobMeta,
        dob.isAcceptableOrUnknown(data['dob']!, _dobMeta),
      );
    } else if (isInserting) {
      context.missing(_dobMeta);
    }
    if (data.containsKey('pob')) {
      context.handle(
        _pobMeta,
        pob.isAcceptableOrUnknown(data['pob']!, _pobMeta),
      );
    } else if (isInserting) {
      context.missing(_pobMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    if (data.containsKey('ai_interpretation')) {
      context.handle(
        _aiInterpretationMeta,
        aiInterpretation.isAcceptableOrUnknown(
          data['ai_interpretation']!,
          _aiInterpretationMeta,
        ),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cloudflareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudflare_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dob: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dob'],
      )!,
      pob: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pob'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      needsSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_sync'],
      )!,
      aiInterpretation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_interpretation'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}timezone'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String? cloudflareId;
  final String name;
  final DateTime dob;
  final String pob;
  final double lat;
  final double lon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;
  final String? aiInterpretation;
  final double timezone;
  const Profile({
    required this.id,
    this.cloudflareId,
    required this.name,
    required this.dob,
    required this.pob,
    required this.lat,
    required this.lon,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
    this.aiInterpretation,
    required this.timezone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cloudflareId != null) {
      map['cloudflare_id'] = Variable<String>(cloudflareId);
    }
    map['name'] = Variable<String>(name);
    map['dob'] = Variable<DateTime>(dob);
    map['pob'] = Variable<String>(pob);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    if (!nullToAbsent || aiInterpretation != null) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation);
    }
    map['timezone'] = Variable<double>(timezone);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      cloudflareId: cloudflareId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudflareId),
      name: Value(name),
      dob: Value(dob),
      pob: Value(pob),
      lat: Value(lat),
      lon: Value(lon),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
      aiInterpretation: aiInterpretation == null && nullToAbsent
          ? const Value.absent()
          : Value(aiInterpretation),
      timezone: Value(timezone),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      cloudflareId: serializer.fromJson<String?>(json['cloudflareId']),
      name: serializer.fromJson<String>(json['name']),
      dob: serializer.fromJson<DateTime>(json['dob']),
      pob: serializer.fromJson<String>(json['pob']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
      aiInterpretation: serializer.fromJson<String?>(json['aiInterpretation']),
      timezone: serializer.fromJson<double>(json['timezone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cloudflareId': serializer.toJson<String?>(cloudflareId),
      'name': serializer.toJson<String>(name),
      'dob': serializer.toJson<DateTime>(dob),
      'pob': serializer.toJson<String>(pob),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
      'aiInterpretation': serializer.toJson<String?>(aiInterpretation),
      'timezone': serializer.toJson<double>(timezone),
    };
  }

  Profile copyWith({
    int? id,
    Value<String?> cloudflareId = const Value.absent(),
    String? name,
    DateTime? dob,
    String? pob,
    double? lat,
    double? lon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
    Value<String?> aiInterpretation = const Value.absent(),
    double? timezone,
  }) => Profile(
    id: id ?? this.id,
    cloudflareId: cloudflareId.present ? cloudflareId.value : this.cloudflareId,
    name: name ?? this.name,
    dob: dob ?? this.dob,
    pob: pob ?? this.pob,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    needsSync: needsSync ?? this.needsSync,
    aiInterpretation: aiInterpretation.present
        ? aiInterpretation.value
        : this.aiInterpretation,
    timezone: timezone ?? this.timezone,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      cloudflareId: data.cloudflareId.present
          ? data.cloudflareId.value
          : this.cloudflareId,
      name: data.name.present ? data.name.value : this.name,
      dob: data.dob.present ? data.dob.value : this.dob,
      pob: data.pob.present ? data.pob.value : this.pob,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
      aiInterpretation: data.aiInterpretation.present
          ? data.aiInterpretation.value
          : this.aiInterpretation,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('cloudflareId: $cloudflareId, ')
          ..write('name: $name, ')
          ..write('dob: $dob, ')
          ..write('pob: $pob, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('timezone: $timezone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cloudflareId,
    name,
    dob,
    pob,
    lat,
    lon,
    createdAt,
    updatedAt,
    needsSync,
    aiInterpretation,
    timezone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.cloudflareId == this.cloudflareId &&
          other.name == this.name &&
          other.dob == this.dob &&
          other.pob == this.pob &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync &&
          other.aiInterpretation == this.aiInterpretation &&
          other.timezone == this.timezone);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String?> cloudflareId;
  final Value<String> name;
  final Value<DateTime> dob;
  final Value<String> pob;
  final Value<double> lat;
  final Value<double> lon;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  final Value<String?> aiInterpretation;
  final Value<double> timezone;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.cloudflareId = const Value.absent(),
    this.name = const Value.absent(),
    this.dob = const Value.absent(),
    this.pob = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.timezone = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.cloudflareId = const Value.absent(),
    required String name,
    required DateTime dob,
    required String pob,
    required double lat,
    required double lon,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.timezone = const Value.absent(),
  }) : name = Value(name),
       dob = Value(dob),
       pob = Value(pob),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? cloudflareId,
    Expression<String>? name,
    Expression<DateTime>? dob,
    Expression<String>? pob,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
    Expression<String>? aiInterpretation,
    Expression<double>? timezone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cloudflareId != null) 'cloudflare_id': cloudflareId,
      if (name != null) 'name': name,
      if (dob != null) 'dob': dob,
      if (pob != null) 'pob': pob,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (aiInterpretation != null) 'ai_interpretation': aiInterpretation,
      if (timezone != null) 'timezone': timezone,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? cloudflareId,
    Value<String>? name,
    Value<DateTime>? dob,
    Value<String>? pob,
    Value<double>? lat,
    Value<double>? lon,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? needsSync,
    Value<String?>? aiInterpretation,
    Value<double>? timezone,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      cloudflareId: cloudflareId ?? this.cloudflareId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cloudflareId.present) {
      map['cloudflare_id'] = Variable<String>(cloudflareId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (pob.present) {
      map['pob'] = Variable<String>(pob.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (aiInterpretation.present) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<double>(timezone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('cloudflareId: $cloudflareId, ')
          ..write('name: $name, ')
          ..write('dob: $dob, ')
          ..write('pob: $pob, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('timezone: $timezone')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String?> cloudflareId,
      required String name,
      required DateTime dob,
      required String pob,
      required double lat,
      required double lon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> needsSync,
      Value<String?> aiInterpretation,
      Value<double> timezone,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String?> cloudflareId,
      Value<String> name,
      Value<DateTime> dob,
      Value<String> pob,
      Value<double> lat,
      Value<double> lon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> needsSync,
      Value<String?> aiInterpretation,
      Value<double> timezone,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pob => $composableBuilder(
    column: $table.pob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dob => $composableBuilder(
    column: $table.dob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pob => $composableBuilder(
    column: $table.pob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get dob =>
      $composableBuilder(column: $table.dob, builder: (column) => column);

  GeneratedColumn<String> get pob =>
      $composableBuilder(column: $table.pob, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  GeneratedColumn<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> cloudflareId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> dob = const Value.absent(),
                Value<String> pob = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<String?> aiInterpretation = const Value.absent(),
                Value<double> timezone = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                cloudflareId: cloudflareId,
                name: name,
                dob: dob,
                pob: pob,
                lat: lat,
                lon: lon,
                createdAt: createdAt,
                updatedAt: updatedAt,
                needsSync: needsSync,
                aiInterpretation: aiInterpretation,
                timezone: timezone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> cloudflareId = const Value.absent(),
                required String name,
                required DateTime dob,
                required String pob,
                required double lat,
                required double lon,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<String?> aiInterpretation = const Value.absent(),
                Value<double> timezone = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                cloudflareId: cloudflareId,
                name: name,
                dob: dob,
                pob: pob,
                lat: lat,
                lon: lon,
                createdAt: createdAt,
                updatedAt: updatedAt,
                needsSync: needsSync,
                aiInterpretation: aiInterpretation,
                timezone: timezone,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
}
