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
  static const VerificationMeta _tzNameMeta = const VerificationMeta('tzName');
  @override
  late final GeneratedColumn<String> tzName = GeneratedColumn<String>(
    'tz_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dob,
    pob,
    lat,
    lon,
    createdAt,
    updatedAt,
    aiInterpretation,
    timezone,
    tzName,
    gender,
    cloudflareId,
    needsSync,
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
    if (data.containsKey('tz_name')) {
      context.handle(
        _tzNameMeta,
        tzName.isAcceptableOrUnknown(data['tz_name']!, _tzNameMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
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
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
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
      aiInterpretation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_interpretation'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}timezone'],
      )!,
      tzName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz_name'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      cloudflareId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloudflare_id'],
      ),
      needsSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_sync'],
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
  final String name;
  final DateTime dob;
  final String pob;
  final double lat;
  final double lon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aiInterpretation;

  /// UTC offset in hours at the time of birth (e.g. 5.5 for IST).
  final double timezone;

  /// IANA time zone of the birth place, when chosen from the city list.
  final String? tzName;

  /// 'Male' / 'Female' (optional).
  final String? gender;

  /// Id of this profile on the sync server (null until first uploaded).
  final String? cloudflareId;

  /// True when local changes have not been uploaded yet.
  final bool needsSync;
  const Profile({
    required this.id,
    required this.name,
    required this.dob,
    required this.pob,
    required this.lat,
    required this.lon,
    required this.createdAt,
    required this.updatedAt,
    this.aiInterpretation,
    required this.timezone,
    this.tzName,
    this.gender,
    this.cloudflareId,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['dob'] = Variable<DateTime>(dob);
    map['pob'] = Variable<String>(pob);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || aiInterpretation != null) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation);
    }
    map['timezone'] = Variable<double>(timezone);
    if (!nullToAbsent || tzName != null) {
      map['tz_name'] = Variable<String>(tzName);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || cloudflareId != null) {
      map['cloudflare_id'] = Variable<String>(cloudflareId);
    }
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      dob: Value(dob),
      pob: Value(pob),
      lat: Value(lat),
      lon: Value(lon),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      aiInterpretation: aiInterpretation == null && nullToAbsent
          ? const Value.absent()
          : Value(aiInterpretation),
      timezone: Value(timezone),
      tzName: tzName == null && nullToAbsent
          ? const Value.absent()
          : Value(tzName),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      cloudflareId: cloudflareId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudflareId),
      needsSync: Value(needsSync),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dob: serializer.fromJson<DateTime>(json['dob']),
      pob: serializer.fromJson<String>(json['pob']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      aiInterpretation: serializer.fromJson<String?>(json['aiInterpretation']),
      timezone: serializer.fromJson<double>(json['timezone']),
      tzName: serializer.fromJson<String?>(json['tzName']),
      gender: serializer.fromJson<String?>(json['gender']),
      cloudflareId: serializer.fromJson<String?>(json['cloudflareId']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dob': serializer.toJson<DateTime>(dob),
      'pob': serializer.toJson<String>(pob),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'aiInterpretation': serializer.toJson<String?>(aiInterpretation),
      'timezone': serializer.toJson<double>(timezone),
      'tzName': serializer.toJson<String?>(tzName),
      'gender': serializer.toJson<String?>(gender),
      'cloudflareId': serializer.toJson<String?>(cloudflareId),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    DateTime? dob,
    String? pob,
    double? lat,
    double? lon,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> aiInterpretation = const Value.absent(),
    double? timezone,
    Value<String?> tzName = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<String?> cloudflareId = const Value.absent(),
    bool? needsSync,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    dob: dob ?? this.dob,
    pob: pob ?? this.pob,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    aiInterpretation: aiInterpretation.present
        ? aiInterpretation.value
        : this.aiInterpretation,
    timezone: timezone ?? this.timezone,
    tzName: tzName.present ? tzName.value : this.tzName,
    gender: gender.present ? gender.value : this.gender,
    cloudflareId: cloudflareId.present ? cloudflareId.value : this.cloudflareId,
    needsSync: needsSync ?? this.needsSync,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dob: data.dob.present ? data.dob.value : this.dob,
      pob: data.pob.present ? data.pob.value : this.pob,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      aiInterpretation: data.aiInterpretation.present
          ? data.aiInterpretation.value
          : this.aiInterpretation,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      tzName: data.tzName.present ? data.tzName.value : this.tzName,
      gender: data.gender.present ? data.gender.value : this.gender,
      cloudflareId: data.cloudflareId.present
          ? data.cloudflareId.value
          : this.cloudflareId,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dob: $dob, ')
          ..write('pob: $pob, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('timezone: $timezone, ')
          ..write('tzName: $tzName, ')
          ..write('gender: $gender, ')
          ..write('cloudflareId: $cloudflareId, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dob,
    pob,
    lat,
    lon,
    createdAt,
    updatedAt,
    aiInterpretation,
    timezone,
    tzName,
    gender,
    cloudflareId,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.dob == this.dob &&
          other.pob == this.pob &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.aiInterpretation == this.aiInterpretation &&
          other.timezone == this.timezone &&
          other.tzName == this.tzName &&
          other.gender == this.gender &&
          other.cloudflareId == this.cloudflareId &&
          other.needsSync == this.needsSync);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> dob;
  final Value<String> pob;
  final Value<double> lat;
  final Value<double> lon;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> aiInterpretation;
  final Value<double> timezone;
  final Value<String?> tzName;
  final Value<String?> gender;
  final Value<String?> cloudflareId;
  final Value<bool> needsSync;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dob = const Value.absent(),
    this.pob = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.timezone = const Value.absent(),
    this.tzName = const Value.absent(),
    this.gender = const Value.absent(),
    this.cloudflareId = const Value.absent(),
    this.needsSync = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime dob,
    required String pob,
    required double lat,
    required double lon,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.aiInterpretation = const Value.absent(),
    this.timezone = const Value.absent(),
    this.tzName = const Value.absent(),
    this.gender = const Value.absent(),
    this.cloudflareId = const Value.absent(),
    this.needsSync = const Value.absent(),
  }) : name = Value(name),
       dob = Value(dob),
       pob = Value(pob),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? dob,
    Expression<String>? pob,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? aiInterpretation,
    Expression<double>? timezone,
    Expression<String>? tzName,
    Expression<String>? gender,
    Expression<String>? cloudflareId,
    Expression<bool>? needsSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dob != null) 'dob': dob,
      if (pob != null) 'pob': pob,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (aiInterpretation != null) 'ai_interpretation': aiInterpretation,
      if (timezone != null) 'timezone': timezone,
      if (tzName != null) 'tz_name': tzName,
      if (gender != null) 'gender': gender,
      if (cloudflareId != null) 'cloudflare_id': cloudflareId,
      if (needsSync != null) 'needs_sync': needsSync,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? dob,
    Value<String>? pob,
    Value<double>? lat,
    Value<double>? lon,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? aiInterpretation,
    Value<double>? timezone,
    Value<String?>? tzName,
    Value<String?>? gender,
    Value<String?>? cloudflareId,
    Value<bool>? needsSync,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      timezone: timezone ?? this.timezone,
      tzName: tzName ?? this.tzName,
      gender: gender ?? this.gender,
      cloudflareId: cloudflareId ?? this.cloudflareId,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (aiInterpretation.present) {
      map['ai_interpretation'] = Variable<String>(aiInterpretation.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<double>(timezone.value);
    }
    if (tzName.present) {
      map['tz_name'] = Variable<String>(tzName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (cloudflareId.present) {
      map['cloudflare_id'] = Variable<String>(cloudflareId.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dob: $dob, ')
          ..write('pob: $pob, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aiInterpretation: $aiInterpretation, ')
          ..write('timezone: $timezone, ')
          ..write('tzName: $tzName, ')
          ..write('gender: $gender, ')
          ..write('cloudflareId: $cloudflareId, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }
}

class $PendingDeletionsTable extends PendingDeletions
    with TableInfo<$PendingDeletionsTable, PendingDeletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDeletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cloudId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingDeletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  PendingDeletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingDeletion(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
    );
  }

  @override
  $PendingDeletionsTable createAlias(String alias) {
    return $PendingDeletionsTable(attachedDatabase, alias);
  }
}

class PendingDeletion extends DataClass implements Insertable<PendingDeletion> {
  final String cloudId;
  const PendingDeletion({required this.cloudId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    return map;
  }

  PendingDeletionsCompanion toCompanion(bool nullToAbsent) {
    return PendingDeletionsCompanion(cloudId: Value(cloudId));
  }

  factory PendingDeletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingDeletion(
      cloudId: serializer.fromJson<String>(json['cloudId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'cloudId': serializer.toJson<String>(cloudId)};
  }

  PendingDeletion copyWith({String? cloudId}) =>
      PendingDeletion(cloudId: cloudId ?? this.cloudId);
  PendingDeletion copyWithCompanion(PendingDeletionsCompanion data) {
    return PendingDeletion(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletion(')
          ..write('cloudId: $cloudId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => cloudId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingDeletion && other.cloudId == this.cloudId);
}

class PendingDeletionsCompanion extends UpdateCompanion<PendingDeletion> {
  final Value<String> cloudId;
  final Value<int> rowid;
  const PendingDeletionsCompanion({
    this.cloudId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingDeletionsCompanion.insert({
    required String cloudId,
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId);
  static Insertable<PendingDeletion> custom({
    Expression<String>? cloudId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingDeletionsCompanion copyWith({
    Value<String>? cloudId,
    Value<int>? rowid,
  }) {
    return PendingDeletionsCompanion(
      cloudId: cloudId ?? this.cloudId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDeletionsCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $PendingDeletionsTable pendingDeletions = $PendingDeletionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    pendingDeletions,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required DateTime dob,
      required String pob,
      required double lat,
      required double lon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> aiInterpretation,
      Value<double> timezone,
      Value<String?> tzName,
      Value<String?> gender,
      Value<String?> cloudflareId,
      Value<bool> needsSync,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> dob,
      Value<String> pob,
      Value<double> lat,
      Value<double> lon,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> aiInterpretation,
      Value<double> timezone,
      Value<String?> tzName,
      Value<String?> gender,
      Value<String?> cloudflareId,
      Value<bool> needsSync,
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

  ColumnFilters<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tzName => $composableBuilder(
    column: $table.tzName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
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

  ColumnOrderings<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tzName => $composableBuilder(
    column: $table.tzName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
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

  GeneratedColumn<String> get aiInterpretation => $composableBuilder(
    column: $table.aiInterpretation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get tzName =>
      $composableBuilder(column: $table.tzName, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get cloudflareId => $composableBuilder(
    column: $table.cloudflareId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);
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
                Value<String> name = const Value.absent(),
                Value<DateTime> dob = const Value.absent(),
                Value<String> pob = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> aiInterpretation = const Value.absent(),
                Value<double> timezone = const Value.absent(),
                Value<String?> tzName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> cloudflareId = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                dob: dob,
                pob: pob,
                lat: lat,
                lon: lon,
                createdAt: createdAt,
                updatedAt: updatedAt,
                aiInterpretation: aiInterpretation,
                timezone: timezone,
                tzName: tzName,
                gender: gender,
                cloudflareId: cloudflareId,
                needsSync: needsSync,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime dob,
                required String pob,
                required double lat,
                required double lon,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> aiInterpretation = const Value.absent(),
                Value<double> timezone = const Value.absent(),
                Value<String?> tzName = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> cloudflareId = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                dob: dob,
                pob: pob,
                lat: lat,
                lon: lon,
                createdAt: createdAt,
                updatedAt: updatedAt,
                aiInterpretation: aiInterpretation,
                timezone: timezone,
                tzName: tzName,
                gender: gender,
                cloudflareId: cloudflareId,
                needsSync: needsSync,
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
typedef $$PendingDeletionsTableCreateCompanionBuilder =
    PendingDeletionsCompanion Function({
      required String cloudId,
      Value<int> rowid,
    });
typedef $$PendingDeletionsTableUpdateCompanionBuilder =
    PendingDeletionsCompanion Function({
      Value<String> cloudId,
      Value<int> rowid,
    });

class $$PendingDeletionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingDeletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingDeletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingDeletionsTable> {
  $$PendingDeletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);
}

class $$PendingDeletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingDeletionsTable,
          PendingDeletion,
          $$PendingDeletionsTableFilterComposer,
          $$PendingDeletionsTableOrderingComposer,
          $$PendingDeletionsTableAnnotationComposer,
          $$PendingDeletionsTableCreateCompanionBuilder,
          $$PendingDeletionsTableUpdateCompanionBuilder,
          (
            PendingDeletion,
            BaseReferences<
              _$AppDatabase,
              $PendingDeletionsTable,
              PendingDeletion
            >,
          ),
          PendingDeletion,
          PrefetchHooks Function()
        > {
  $$PendingDeletionsTableTableManager(
    _$AppDatabase db,
    $PendingDeletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDeletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDeletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDeletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletionsCompanion(cloudId: cloudId, rowid: rowid),
          createCompanionCallback:
              ({
                required String cloudId,
                Value<int> rowid = const Value.absent(),
              }) => PendingDeletionsCompanion.insert(
                cloudId: cloudId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingDeletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingDeletionsTable,
      PendingDeletion,
      $$PendingDeletionsTableFilterComposer,
      $$PendingDeletionsTableOrderingComposer,
      $$PendingDeletionsTableAnnotationComposer,
      $$PendingDeletionsTableCreateCompanionBuilder,
      $$PendingDeletionsTableUpdateCompanionBuilder,
      (
        PendingDeletion,
        BaseReferences<_$AppDatabase, $PendingDeletionsTable, PendingDeletion>,
      ),
      PendingDeletion,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$PendingDeletionsTableTableManager get pendingDeletions =>
      $$PendingDeletionsTableTableManager(_db, _db.pendingDeletions);
}
