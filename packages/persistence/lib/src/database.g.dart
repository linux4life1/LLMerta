// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ConnectionsTable extends Connections
    with TableInfo<$ConnectionsTable, Connection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProviderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProviderKind>($ConnectionsTable.$converterkind);
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultModelMeta = const VerificationMeta(
    'defaultModel',
  );
  @override
  late final GeneratedColumn<String> defaultModel = GeneratedColumn<String>(
    'default_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelsFetchedAtMeta = const VerificationMeta(
    'modelsFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modelsFetchedAt =
      GeneratedColumn<DateTime>(
        'models_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    kind,
    baseUrl,
    defaultModel,
    modelsFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Connection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('default_model')) {
      context.handle(
        _defaultModelMeta,
        defaultModel.isAcceptableOrUnknown(
          data['default_model']!,
          _defaultModelMeta,
        ),
      );
    }
    if (data.containsKey('models_fetched_at')) {
      context.handle(
        _modelsFetchedAtMeta,
        modelsFetchedAt.isAcceptableOrUnknown(
          data['models_fetched_at']!,
          _modelsFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Connection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Connection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: $ConnectionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      defaultModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_model'],
      ),
      modelsFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}models_fetched_at'],
      ),
    );
  }

  @override
  $ConnectionsTable createAlias(String alias) {
    return $ConnectionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProviderKind, String, String> $converterkind =
      const EnumNameConverter<ProviderKind>(ProviderKind.values);
}

class Connection extends DataClass implements Insertable<Connection> {
  final String id;
  final String label;
  final ProviderKind kind;
  final String baseUrl;
  final String? defaultModel;
  final DateTime? modelsFetchedAt;
  const Connection({
    required this.id,
    required this.label,
    required this.kind,
    required this.baseUrl,
    this.defaultModel,
    this.modelsFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    {
      map['kind'] = Variable<String>(
        $ConnectionsTable.$converterkind.toSql(kind),
      );
    }
    map['base_url'] = Variable<String>(baseUrl);
    if (!nullToAbsent || defaultModel != null) {
      map['default_model'] = Variable<String>(defaultModel);
    }
    if (!nullToAbsent || modelsFetchedAt != null) {
      map['models_fetched_at'] = Variable<DateTime>(modelsFetchedAt);
    }
    return map;
  }

  ConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsCompanion(
      id: Value(id),
      label: Value(label),
      kind: Value(kind),
      baseUrl: Value(baseUrl),
      defaultModel: defaultModel == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultModel),
      modelsFetchedAt: modelsFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modelsFetchedAt),
    );
  }

  factory Connection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Connection(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      kind: $ConnectionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      defaultModel: serializer.fromJson<String?>(json['defaultModel']),
      modelsFetchedAt: serializer.fromJson<DateTime?>(json['modelsFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<String>(
        $ConnectionsTable.$converterkind.toJson(kind),
      ),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'defaultModel': serializer.toJson<String?>(defaultModel),
      'modelsFetchedAt': serializer.toJson<DateTime?>(modelsFetchedAt),
    };
  }

  Connection copyWith({
    String? id,
    String? label,
    ProviderKind? kind,
    String? baseUrl,
    Value<String?> defaultModel = const Value.absent(),
    Value<DateTime?> modelsFetchedAt = const Value.absent(),
  }) => Connection(
    id: id ?? this.id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    baseUrl: baseUrl ?? this.baseUrl,
    defaultModel: defaultModel.present ? defaultModel.value : this.defaultModel,
    modelsFetchedAt: modelsFetchedAt.present
        ? modelsFetchedAt.value
        : this.modelsFetchedAt,
  );
  Connection copyWithCompanion(ConnectionsCompanion data) {
    return Connection(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      defaultModel: data.defaultModel.present
          ? data.defaultModel.value
          : this.defaultModel,
      modelsFetchedAt: data.modelsFetchedAt.present
          ? data.modelsFetchedAt.value
          : this.modelsFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Connection(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('modelsFetchedAt: $modelsFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, kind, baseUrl, defaultModel, modelsFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Connection &&
          other.id == this.id &&
          other.label == this.label &&
          other.kind == this.kind &&
          other.baseUrl == this.baseUrl &&
          other.defaultModel == this.defaultModel &&
          other.modelsFetchedAt == this.modelsFetchedAt);
}

class ConnectionsCompanion extends UpdateCompanion<Connection> {
  final Value<String> id;
  final Value<String> label;
  final Value<ProviderKind> kind;
  final Value<String> baseUrl;
  final Value<String?> defaultModel;
  final Value<DateTime?> modelsFetchedAt;
  final Value<int> rowid;
  const ConnectionsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.defaultModel = const Value.absent(),
    this.modelsFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionsCompanion.insert({
    required String id,
    required String label,
    required ProviderKind kind,
    required String baseUrl,
    this.defaultModel = const Value.absent(),
    this.modelsFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       kind = Value(kind),
       baseUrl = Value(baseUrl);
  static Insertable<Connection> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? kind,
    Expression<String>? baseUrl,
    Expression<String>? defaultModel,
    Expression<DateTime>? modelsFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
      if (baseUrl != null) 'base_url': baseUrl,
      if (defaultModel != null) 'default_model': defaultModel,
      if (modelsFetchedAt != null) 'models_fetched_at': modelsFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<ProviderKind>? kind,
    Value<String>? baseUrl,
    Value<String?>? defaultModel,
    Value<DateTime?>? modelsFetchedAt,
    Value<int>? rowid,
  }) {
    return ConnectionsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      baseUrl: baseUrl ?? this.baseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      modelsFetchedAt: modelsFetchedAt ?? this.modelsFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ConnectionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (defaultModel.present) {
      map['default_model'] = Variable<String>(defaultModel.value);
    }
    if (modelsFetchedAt.present) {
      map['models_fetched_at'] = Variable<DateTime>(modelsFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('modelsFetchedAt: $modelsFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedModelsTable extends CachedModels
    with TableInfo<$CachedModelsTable, CachedModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [connectionId, modelId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedModel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, modelId};
  @override
  CachedModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedModel(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      )!,
    );
  }

  @override
  $CachedModelsTable createAlias(String alias) {
    return $CachedModelsTable(attachedDatabase, alias);
  }
}

class CachedModel extends DataClass implements Insertable<CachedModel> {
  final String connectionId;
  final String modelId;
  const CachedModel({required this.connectionId, required this.modelId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<String>(connectionId);
    map['model_id'] = Variable<String>(modelId);
    return map;
  }

  CachedModelsCompanion toCompanion(bool nullToAbsent) {
    return CachedModelsCompanion(
      connectionId: Value(connectionId),
      modelId: Value(modelId),
    );
  }

  factory CachedModel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedModel(
      connectionId: serializer.fromJson<String>(json['connectionId']),
      modelId: serializer.fromJson<String>(json['modelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<String>(connectionId),
      'modelId': serializer.toJson<String>(modelId),
    };
  }

  CachedModel copyWith({String? connectionId, String? modelId}) => CachedModel(
    connectionId: connectionId ?? this.connectionId,
    modelId: modelId ?? this.modelId,
  );
  CachedModel copyWithCompanion(CachedModelsCompanion data) {
    return CachedModel(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedModel(')
          ..write('connectionId: $connectionId, ')
          ..write('modelId: $modelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(connectionId, modelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedModel &&
          other.connectionId == this.connectionId &&
          other.modelId == this.modelId);
}

class CachedModelsCompanion extends UpdateCompanion<CachedModel> {
  final Value<String> connectionId;
  final Value<String> modelId;
  final Value<int> rowid;
  const CachedModelsCompanion({
    this.connectionId = const Value.absent(),
    this.modelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedModelsCompanion.insert({
    required String connectionId,
    required String modelId,
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       modelId = Value(modelId);
  static Insertable<CachedModel> custom({
    Expression<String>? connectionId,
    Expression<String>? modelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (modelId != null) 'model_id': modelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedModelsCompanion copyWith({
    Value<String>? connectionId,
    Value<String>? modelId,
    Value<int>? rowid,
  }) {
    return CachedModelsCompanion(
      connectionId: connectionId ?? this.connectionId,
      modelId: modelId ?? this.modelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedModelsCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('modelId: $modelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomPersonasTable extends CustomPersonas
    with TableInfo<$CustomPersonasTable, CustomPersona> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomPersonasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archetypeMeta = const VerificationMeta(
    'archetype',
  );
  @override
  late final GeneratedColumn<String> archetype = GeneratedColumn<String>(
    'archetype',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quirkMeta = const VerificationMeta('quirk');
  @override
  late final GeneratedColumn<String> quirk = GeneratedColumn<String>(
    'quirk',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceSampleMeta = const VerificationMeta(
    'voiceSample',
  );
  @override
  late final GeneratedColumn<String> voiceSample = GeneratedColumn<String>(
    'voice_sample',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    archetype,
    style,
    quirk,
    avatarPath,
    voiceSample,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_personas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomPersona> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archetype')) {
      context.handle(
        _archetypeMeta,
        archetype.isAcceptableOrUnknown(data['archetype']!, _archetypeMeta),
      );
    } else if (isInserting) {
      context.missing(_archetypeMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('quirk')) {
      context.handle(
        _quirkMeta,
        quirk.isAcceptableOrUnknown(data['quirk']!, _quirkMeta),
      );
    } else if (isInserting) {
      context.missing(_quirkMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('voice_sample')) {
      context.handle(
        _voiceSampleMeta,
        voiceSample.isAcceptableOrUnknown(
          data['voice_sample']!,
          _voiceSampleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  CustomPersona map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomPersona(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      archetype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archetype'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      quirk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quirk'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      voiceSample: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_sample'],
      ),
    );
  }

  @override
  $CustomPersonasTable createAlias(String alias) {
    return $CustomPersonasTable(attachedDatabase, alias);
  }
}

class CustomPersona extends DataClass implements Insertable<CustomPersona> {
  final String name;
  final String archetype;
  final String style;
  final String quirk;
  final String? avatarPath;
  final String? voiceSample;
  const CustomPersona({
    required this.name,
    required this.archetype,
    required this.style,
    required this.quirk,
    this.avatarPath,
    this.voiceSample,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['archetype'] = Variable<String>(archetype);
    map['style'] = Variable<String>(style);
    map['quirk'] = Variable<String>(quirk);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || voiceSample != null) {
      map['voice_sample'] = Variable<String>(voiceSample);
    }
    return map;
  }

  CustomPersonasCompanion toCompanion(bool nullToAbsent) {
    return CustomPersonasCompanion(
      name: Value(name),
      archetype: Value(archetype),
      style: Value(style),
      quirk: Value(quirk),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      voiceSample: voiceSample == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceSample),
    );
  }

  factory CustomPersona.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomPersona(
      name: serializer.fromJson<String>(json['name']),
      archetype: serializer.fromJson<String>(json['archetype']),
      style: serializer.fromJson<String>(json['style']),
      quirk: serializer.fromJson<String>(json['quirk']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      voiceSample: serializer.fromJson<String?>(json['voiceSample']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'archetype': serializer.toJson<String>(archetype),
      'style': serializer.toJson<String>(style),
      'quirk': serializer.toJson<String>(quirk),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'voiceSample': serializer.toJson<String?>(voiceSample),
    };
  }

  CustomPersona copyWith({
    String? name,
    String? archetype,
    String? style,
    String? quirk,
    Value<String?> avatarPath = const Value.absent(),
    Value<String?> voiceSample = const Value.absent(),
  }) => CustomPersona(
    name: name ?? this.name,
    archetype: archetype ?? this.archetype,
    style: style ?? this.style,
    quirk: quirk ?? this.quirk,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    voiceSample: voiceSample.present ? voiceSample.value : this.voiceSample,
  );
  CustomPersona copyWithCompanion(CustomPersonasCompanion data) {
    return CustomPersona(
      name: data.name.present ? data.name.value : this.name,
      archetype: data.archetype.present ? data.archetype.value : this.archetype,
      style: data.style.present ? data.style.value : this.style,
      quirk: data.quirk.present ? data.quirk.value : this.quirk,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      voiceSample: data.voiceSample.present
          ? data.voiceSample.value
          : this.voiceSample,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomPersona(')
          ..write('name: $name, ')
          ..write('archetype: $archetype, ')
          ..write('style: $style, ')
          ..write('quirk: $quirk, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('voiceSample: $voiceSample')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, archetype, style, quirk, avatarPath, voiceSample);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomPersona &&
          other.name == this.name &&
          other.archetype == this.archetype &&
          other.style == this.style &&
          other.quirk == this.quirk &&
          other.avatarPath == this.avatarPath &&
          other.voiceSample == this.voiceSample);
}

class CustomPersonasCompanion extends UpdateCompanion<CustomPersona> {
  final Value<String> name;
  final Value<String> archetype;
  final Value<String> style;
  final Value<String> quirk;
  final Value<String?> avatarPath;
  final Value<String?> voiceSample;
  final Value<int> rowid;
  const CustomPersonasCompanion({
    this.name = const Value.absent(),
    this.archetype = const Value.absent(),
    this.style = const Value.absent(),
    this.quirk = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.voiceSample = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomPersonasCompanion.insert({
    required String name,
    required String archetype,
    required String style,
    required String quirk,
    this.avatarPath = const Value.absent(),
    this.voiceSample = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       archetype = Value(archetype),
       style = Value(style),
       quirk = Value(quirk);
  static Insertable<CustomPersona> custom({
    Expression<String>? name,
    Expression<String>? archetype,
    Expression<String>? style,
    Expression<String>? quirk,
    Expression<String>? avatarPath,
    Expression<String>? voiceSample,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (archetype != null) 'archetype': archetype,
      if (style != null) 'style': style,
      if (quirk != null) 'quirk': quirk,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (voiceSample != null) 'voice_sample': voiceSample,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomPersonasCompanion copyWith({
    Value<String>? name,
    Value<String>? archetype,
    Value<String>? style,
    Value<String>? quirk,
    Value<String?>? avatarPath,
    Value<String?>? voiceSample,
    Value<int>? rowid,
  }) {
    return CustomPersonasCompanion(
      name: name ?? this.name,
      archetype: archetype ?? this.archetype,
      style: style ?? this.style,
      quirk: quirk ?? this.quirk,
      avatarPath: avatarPath ?? this.avatarPath,
      voiceSample: voiceSample ?? this.voiceSample,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archetype.present) {
      map['archetype'] = Variable<String>(archetype.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (quirk.present) {
      map['quirk'] = Variable<String>(quirk.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (voiceSample.present) {
      map['voice_sample'] = Variable<String>(voiceSample.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomPersonasCompanion(')
          ..write('name: $name, ')
          ..write('archetype: $archetype, ')
          ..write('style: $style, ')
          ..write('quirk: $quirk, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('voiceSample: $voiceSample, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String key;
  final String value;
  const Pref({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(key: Value(key), value: Value(value));
  }

  factory Pref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Pref copyWith({String? key, String? value}) =>
      Pref(key: key ?? this.key, value: value ?? this.value);
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pref && other.key == this.key && other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Pref> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _townNameMeta = const VerificationMeta(
    'townName',
  );
  @override
  late final GeneratedColumn<String> townName = GeneratedColumn<String>(
    'town_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _winnerMeta = const VerificationMeta('winner');
  @override
  late final GeneratedColumn<String> winner = GeneratedColumn<String>(
    'winner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _humanSeatMeta = const VerificationMeta(
    'humanSeat',
  );
  @override
  late final GeneratedColumn<int> humanSeat = GeneratedColumn<int>(
    'human_seat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rngSeedMeta = const VerificationMeta(
    'rngSeed',
  );
  @override
  late final GeneratedColumn<int> rngSeed = GeneratedColumn<int>(
    'rng_seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grudgeModeMeta = const VerificationMeta(
    'grudgeMode',
  );
  @override
  late final GeneratedColumn<bool> grudgeMode = GeneratedColumn<bool>(
    'grudge_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("grudge_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _namesJsonMeta = const VerificationMeta(
    'namesJson',
  );
  @override
  late final GeneratedColumn<String> namesJson = GeneratedColumn<String>(
    'names_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _badgesJsonMeta = const VerificationMeta(
    'badgesJson',
  );
  @override
  late final GeneratedColumn<String> badgesJson = GeneratedColumn<String>(
    'badges_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _castingJsonMeta = const VerificationMeta(
    'castingJson',
  );
  @override
  late final GeneratedColumn<String> castingJson = GeneratedColumn<String>(
    'casting_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sceneJsonMeta = const VerificationMeta(
    'sceneJson',
  );
  @override
  late final GeneratedColumn<String> sceneJson = GeneratedColumn<String>(
    'scene_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventsJsonMeta = const VerificationMeta(
    'eventsJson',
  );
  @override
  late final GeneratedColumn<String> eventsJson = GeneratedColumn<String>(
    'events_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    townName,
    savedAt,
    finished,
    winner,
    humanSeat,
    rngSeed,
    difficulty,
    grudgeMode,
    namesJson,
    badgesJson,
    castingJson,
    configJson,
    sceneJson,
    eventsJson,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('town_name')) {
      context.handle(
        _townNameMeta,
        townName.isAcceptableOrUnknown(data['town_name']!, _townNameMeta),
      );
    } else if (isInserting) {
      context.missing(_townNameMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    }
    if (data.containsKey('winner')) {
      context.handle(
        _winnerMeta,
        winner.isAcceptableOrUnknown(data['winner']!, _winnerMeta),
      );
    }
    if (data.containsKey('human_seat')) {
      context.handle(
        _humanSeatMeta,
        humanSeat.isAcceptableOrUnknown(data['human_seat']!, _humanSeatMeta),
      );
    } else if (isInserting) {
      context.missing(_humanSeatMeta);
    }
    if (data.containsKey('rng_seed')) {
      context.handle(
        _rngSeedMeta,
        rngSeed.isAcceptableOrUnknown(data['rng_seed']!, _rngSeedMeta),
      );
    } else if (isInserting) {
      context.missing(_rngSeedMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('grudge_mode')) {
      context.handle(
        _grudgeModeMeta,
        grudgeMode.isAcceptableOrUnknown(data['grudge_mode']!, _grudgeModeMeta),
      );
    }
    if (data.containsKey('names_json')) {
      context.handle(
        _namesJsonMeta,
        namesJson.isAcceptableOrUnknown(data['names_json']!, _namesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_namesJsonMeta);
    }
    if (data.containsKey('badges_json')) {
      context.handle(
        _badgesJsonMeta,
        badgesJson.isAcceptableOrUnknown(data['badges_json']!, _badgesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_badgesJsonMeta);
    }
    if (data.containsKey('casting_json')) {
      context.handle(
        _castingJsonMeta,
        castingJson.isAcceptableOrUnknown(
          data['casting_json']!,
          _castingJsonMeta,
        ),
      );
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('scene_json')) {
      context.handle(
        _sceneJsonMeta,
        sceneJson.isAcceptableOrUnknown(data['scene_json']!, _sceneJsonMeta),
      );
    }
    if (data.containsKey('events_json')) {
      context.handle(
        _eventsJsonMeta,
        eventsJson.isAcceptableOrUnknown(data['events_json']!, _eventsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_eventsJsonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      townName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}town_name'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
      winner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner'],
      ),
      humanSeat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}human_seat'],
      )!,
      rngSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rng_seed'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      grudgeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}grudge_mode'],
      )!,
      namesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}names_json'],
      )!,
      badgesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badges_json'],
      )!,
      castingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}casting_json'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      sceneJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scene_json'],
      ),
      eventsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}events_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class Game extends DataClass implements Insertable<Game> {
  final String id;
  final String townName;
  final DateTime savedAt;
  final bool finished;
  final String? winner;
  final int humanSeat;
  final int rngSeed;
  final String difficulty;
  final bool grudgeMode;
  final String namesJson;
  final String badgesJson;
  final String castingJson;
  final String configJson;
  final String? sceneJson;
  final String eventsJson;
  final String notes;
  const Game({
    required this.id,
    required this.townName,
    required this.savedAt,
    required this.finished,
    this.winner,
    required this.humanSeat,
    required this.rngSeed,
    required this.difficulty,
    required this.grudgeMode,
    required this.namesJson,
    required this.badgesJson,
    required this.castingJson,
    required this.configJson,
    this.sceneJson,
    required this.eventsJson,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['town_name'] = Variable<String>(townName);
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['finished'] = Variable<bool>(finished);
    if (!nullToAbsent || winner != null) {
      map['winner'] = Variable<String>(winner);
    }
    map['human_seat'] = Variable<int>(humanSeat);
    map['rng_seed'] = Variable<int>(rngSeed);
    map['difficulty'] = Variable<String>(difficulty);
    map['grudge_mode'] = Variable<bool>(grudgeMode);
    map['names_json'] = Variable<String>(namesJson);
    map['badges_json'] = Variable<String>(badgesJson);
    map['casting_json'] = Variable<String>(castingJson);
    map['config_json'] = Variable<String>(configJson);
    if (!nullToAbsent || sceneJson != null) {
      map['scene_json'] = Variable<String>(sceneJson);
    }
    map['events_json'] = Variable<String>(eventsJson);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      townName: Value(townName),
      savedAt: Value(savedAt),
      finished: Value(finished),
      winner: winner == null && nullToAbsent
          ? const Value.absent()
          : Value(winner),
      humanSeat: Value(humanSeat),
      rngSeed: Value(rngSeed),
      difficulty: Value(difficulty),
      grudgeMode: Value(grudgeMode),
      namesJson: Value(namesJson),
      badgesJson: Value(badgesJson),
      castingJson: Value(castingJson),
      configJson: Value(configJson),
      sceneJson: sceneJson == null && nullToAbsent
          ? const Value.absent()
          : Value(sceneJson),
      eventsJson: Value(eventsJson),
      notes: Value(notes),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<String>(json['id']),
      townName: serializer.fromJson<String>(json['townName']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      finished: serializer.fromJson<bool>(json['finished']),
      winner: serializer.fromJson<String?>(json['winner']),
      humanSeat: serializer.fromJson<int>(json['humanSeat']),
      rngSeed: serializer.fromJson<int>(json['rngSeed']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      grudgeMode: serializer.fromJson<bool>(json['grudgeMode']),
      namesJson: serializer.fromJson<String>(json['namesJson']),
      badgesJson: serializer.fromJson<String>(json['badgesJson']),
      castingJson: serializer.fromJson<String>(json['castingJson']),
      configJson: serializer.fromJson<String>(json['configJson']),
      sceneJson: serializer.fromJson<String?>(json['sceneJson']),
      eventsJson: serializer.fromJson<String>(json['eventsJson']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'townName': serializer.toJson<String>(townName),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'finished': serializer.toJson<bool>(finished),
      'winner': serializer.toJson<String?>(winner),
      'humanSeat': serializer.toJson<int>(humanSeat),
      'rngSeed': serializer.toJson<int>(rngSeed),
      'difficulty': serializer.toJson<String>(difficulty),
      'grudgeMode': serializer.toJson<bool>(grudgeMode),
      'namesJson': serializer.toJson<String>(namesJson),
      'badgesJson': serializer.toJson<String>(badgesJson),
      'castingJson': serializer.toJson<String>(castingJson),
      'configJson': serializer.toJson<String>(configJson),
      'sceneJson': serializer.toJson<String?>(sceneJson),
      'eventsJson': serializer.toJson<String>(eventsJson),
      'notes': serializer.toJson<String>(notes),
    };
  }

  Game copyWith({
    String? id,
    String? townName,
    DateTime? savedAt,
    bool? finished,
    Value<String?> winner = const Value.absent(),
    int? humanSeat,
    int? rngSeed,
    String? difficulty,
    bool? grudgeMode,
    String? namesJson,
    String? badgesJson,
    String? castingJson,
    String? configJson,
    Value<String?> sceneJson = const Value.absent(),
    String? eventsJson,
    String? notes,
  }) => Game(
    id: id ?? this.id,
    townName: townName ?? this.townName,
    savedAt: savedAt ?? this.savedAt,
    finished: finished ?? this.finished,
    winner: winner.present ? winner.value : this.winner,
    humanSeat: humanSeat ?? this.humanSeat,
    rngSeed: rngSeed ?? this.rngSeed,
    difficulty: difficulty ?? this.difficulty,
    grudgeMode: grudgeMode ?? this.grudgeMode,
    namesJson: namesJson ?? this.namesJson,
    badgesJson: badgesJson ?? this.badgesJson,
    castingJson: castingJson ?? this.castingJson,
    configJson: configJson ?? this.configJson,
    sceneJson: sceneJson.present ? sceneJson.value : this.sceneJson,
    eventsJson: eventsJson ?? this.eventsJson,
    notes: notes ?? this.notes,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      townName: data.townName.present ? data.townName.value : this.townName,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      finished: data.finished.present ? data.finished.value : this.finished,
      winner: data.winner.present ? data.winner.value : this.winner,
      humanSeat: data.humanSeat.present ? data.humanSeat.value : this.humanSeat,
      rngSeed: data.rngSeed.present ? data.rngSeed.value : this.rngSeed,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      grudgeMode: data.grudgeMode.present
          ? data.grudgeMode.value
          : this.grudgeMode,
      namesJson: data.namesJson.present ? data.namesJson.value : this.namesJson,
      badgesJson: data.badgesJson.present
          ? data.badgesJson.value
          : this.badgesJson,
      castingJson: data.castingJson.present
          ? data.castingJson.value
          : this.castingJson,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      sceneJson: data.sceneJson.present ? data.sceneJson.value : this.sceneJson,
      eventsJson: data.eventsJson.present
          ? data.eventsJson.value
          : this.eventsJson,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('townName: $townName, ')
          ..write('savedAt: $savedAt, ')
          ..write('finished: $finished, ')
          ..write('winner: $winner, ')
          ..write('humanSeat: $humanSeat, ')
          ..write('rngSeed: $rngSeed, ')
          ..write('difficulty: $difficulty, ')
          ..write('grudgeMode: $grudgeMode, ')
          ..write('namesJson: $namesJson, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('castingJson: $castingJson, ')
          ..write('configJson: $configJson, ')
          ..write('sceneJson: $sceneJson, ')
          ..write('eventsJson: $eventsJson, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    townName,
    savedAt,
    finished,
    winner,
    humanSeat,
    rngSeed,
    difficulty,
    grudgeMode,
    namesJson,
    badgesJson,
    castingJson,
    configJson,
    sceneJson,
    eventsJson,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.townName == this.townName &&
          other.savedAt == this.savedAt &&
          other.finished == this.finished &&
          other.winner == this.winner &&
          other.humanSeat == this.humanSeat &&
          other.rngSeed == this.rngSeed &&
          other.difficulty == this.difficulty &&
          other.grudgeMode == this.grudgeMode &&
          other.namesJson == this.namesJson &&
          other.badgesJson == this.badgesJson &&
          other.castingJson == this.castingJson &&
          other.configJson == this.configJson &&
          other.sceneJson == this.sceneJson &&
          other.eventsJson == this.eventsJson &&
          other.notes == this.notes);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<String> id;
  final Value<String> townName;
  final Value<DateTime> savedAt;
  final Value<bool> finished;
  final Value<String?> winner;
  final Value<int> humanSeat;
  final Value<int> rngSeed;
  final Value<String> difficulty;
  final Value<bool> grudgeMode;
  final Value<String> namesJson;
  final Value<String> badgesJson;
  final Value<String> castingJson;
  final Value<String> configJson;
  final Value<String?> sceneJson;
  final Value<String> eventsJson;
  final Value<String> notes;
  final Value<int> rowid;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.townName = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.finished = const Value.absent(),
    this.winner = const Value.absent(),
    this.humanSeat = const Value.absent(),
    this.rngSeed = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.grudgeMode = const Value.absent(),
    this.namesJson = const Value.absent(),
    this.badgesJson = const Value.absent(),
    this.castingJson = const Value.absent(),
    this.configJson = const Value.absent(),
    this.sceneJson = const Value.absent(),
    this.eventsJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String id,
    required String townName,
    required DateTime savedAt,
    this.finished = const Value.absent(),
    this.winner = const Value.absent(),
    required int humanSeat,
    required int rngSeed,
    required String difficulty,
    this.grudgeMode = const Value.absent(),
    required String namesJson,
    required String badgesJson,
    this.castingJson = const Value.absent(),
    required String configJson,
    this.sceneJson = const Value.absent(),
    required String eventsJson,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       townName = Value(townName),
       savedAt = Value(savedAt),
       humanSeat = Value(humanSeat),
       rngSeed = Value(rngSeed),
       difficulty = Value(difficulty),
       namesJson = Value(namesJson),
       badgesJson = Value(badgesJson),
       configJson = Value(configJson),
       eventsJson = Value(eventsJson);
  static Insertable<Game> custom({
    Expression<String>? id,
    Expression<String>? townName,
    Expression<DateTime>? savedAt,
    Expression<bool>? finished,
    Expression<String>? winner,
    Expression<int>? humanSeat,
    Expression<int>? rngSeed,
    Expression<String>? difficulty,
    Expression<bool>? grudgeMode,
    Expression<String>? namesJson,
    Expression<String>? badgesJson,
    Expression<String>? castingJson,
    Expression<String>? configJson,
    Expression<String>? sceneJson,
    Expression<String>? eventsJson,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (townName != null) 'town_name': townName,
      if (savedAt != null) 'saved_at': savedAt,
      if (finished != null) 'finished': finished,
      if (winner != null) 'winner': winner,
      if (humanSeat != null) 'human_seat': humanSeat,
      if (rngSeed != null) 'rng_seed': rngSeed,
      if (difficulty != null) 'difficulty': difficulty,
      if (grudgeMode != null) 'grudge_mode': grudgeMode,
      if (namesJson != null) 'names_json': namesJson,
      if (badgesJson != null) 'badges_json': badgesJson,
      if (castingJson != null) 'casting_json': castingJson,
      if (configJson != null) 'config_json': configJson,
      if (sceneJson != null) 'scene_json': sceneJson,
      if (eventsJson != null) 'events_json': eventsJson,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? id,
    Value<String>? townName,
    Value<DateTime>? savedAt,
    Value<bool>? finished,
    Value<String?>? winner,
    Value<int>? humanSeat,
    Value<int>? rngSeed,
    Value<String>? difficulty,
    Value<bool>? grudgeMode,
    Value<String>? namesJson,
    Value<String>? badgesJson,
    Value<String>? castingJson,
    Value<String>? configJson,
    Value<String?>? sceneJson,
    Value<String>? eventsJson,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      townName: townName ?? this.townName,
      savedAt: savedAt ?? this.savedAt,
      finished: finished ?? this.finished,
      winner: winner ?? this.winner,
      humanSeat: humanSeat ?? this.humanSeat,
      rngSeed: rngSeed ?? this.rngSeed,
      difficulty: difficulty ?? this.difficulty,
      grudgeMode: grudgeMode ?? this.grudgeMode,
      namesJson: namesJson ?? this.namesJson,
      badgesJson: badgesJson ?? this.badgesJson,
      castingJson: castingJson ?? this.castingJson,
      configJson: configJson ?? this.configJson,
      sceneJson: sceneJson ?? this.sceneJson,
      eventsJson: eventsJson ?? this.eventsJson,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (townName.present) {
      map['town_name'] = Variable<String>(townName.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (winner.present) {
      map['winner'] = Variable<String>(winner.value);
    }
    if (humanSeat.present) {
      map['human_seat'] = Variable<int>(humanSeat.value);
    }
    if (rngSeed.present) {
      map['rng_seed'] = Variable<int>(rngSeed.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (grudgeMode.present) {
      map['grudge_mode'] = Variable<bool>(grudgeMode.value);
    }
    if (namesJson.present) {
      map['names_json'] = Variable<String>(namesJson.value);
    }
    if (badgesJson.present) {
      map['badges_json'] = Variable<String>(badgesJson.value);
    }
    if (castingJson.present) {
      map['casting_json'] = Variable<String>(castingJson.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (sceneJson.present) {
      map['scene_json'] = Variable<String>(sceneJson.value);
    }
    if (eventsJson.present) {
      map['events_json'] = Variable<String>(eventsJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('townName: $townName, ')
          ..write('savedAt: $savedAt, ')
          ..write('finished: $finished, ')
          ..write('winner: $winner, ')
          ..write('humanSeat: $humanSeat, ')
          ..write('rngSeed: $rngSeed, ')
          ..write('difficulty: $difficulty, ')
          ..write('grudgeMode: $grudgeMode, ')
          ..write('namesJson: $namesJson, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('castingJson: $castingJson, ')
          ..write('configJson: $configJson, ')
          ..write('sceneJson: $sceneJson, ')
          ..write('eventsJson: $eventsJson, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConnectionsTable connections = $ConnectionsTable(this);
  late final $CachedModelsTable cachedModels = $CachedModelsTable(this);
  late final $CustomPersonasTable customPersonas = $CustomPersonasTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $GamesTable games = $GamesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    connections,
    cachedModels,
    customPersonas,
    prefs,
    games,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cached_models', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConnectionsTableCreateCompanionBuilder =
    ConnectionsCompanion Function({
      required String id,
      required String label,
      required ProviderKind kind,
      required String baseUrl,
      Value<String?> defaultModel,
      Value<DateTime?> modelsFetchedAt,
      Value<int> rowid,
    });
typedef $$ConnectionsTableUpdateCompanionBuilder =
    ConnectionsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<ProviderKind> kind,
      Value<String> baseUrl,
      Value<String?> defaultModel,
      Value<DateTime?> modelsFetchedAt,
      Value<int> rowid,
    });

final class $$ConnectionsTableReferences
    extends BaseReferences<_$AppDatabase, $ConnectionsTable, Connection> {
  $$ConnectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CachedModelsTable, List<CachedModel>>
  _cachedModelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedModels,
    aliasName: 'connections__id__cached_models__connection_id',
  );

  $$CachedModelsTableProcessedTableManager get cachedModelsRefs {
    final manager = $$CachedModelsTableTableManager(
      $_db,
      $_db.cachedModels,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedModelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConnectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProviderKind, ProviderKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultModel => $composableBuilder(
    column: $table.defaultModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modelsFetchedAt => $composableBuilder(
    column: $table.modelsFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedModelsRefs(
    Expression<bool> Function($$CachedModelsTableFilterComposer f) f,
  ) {
    final $$CachedModelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedModels,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedModelsTableFilterComposer(
            $db: $db,
            $table: $db.cachedModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultModel => $composableBuilder(
    column: $table.defaultModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modelsFetchedAt => $composableBuilder(
    column: $table.modelsFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProviderKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get defaultModel => $composableBuilder(
    column: $table.defaultModel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get modelsFetchedAt => $composableBuilder(
    column: $table.modelsFetchedAt,
    builder: (column) => column,
  );

  Expression<T> cachedModelsRefs<T extends Object>(
    Expression<T> Function($$CachedModelsTableAnnotationComposer a) f,
  ) {
    final $$CachedModelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedModels,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedModelsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedModels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionsTable,
          Connection,
          $$ConnectionsTableFilterComposer,
          $$ConnectionsTableOrderingComposer,
          $$ConnectionsTableAnnotationComposer,
          $$ConnectionsTableCreateCompanionBuilder,
          $$ConnectionsTableUpdateCompanionBuilder,
          (Connection, $$ConnectionsTableReferences),
          Connection,
          PrefetchHooks Function({bool cachedModelsRefs})
        > {
  $$ConnectionsTableTableManager(_$AppDatabase db, $ConnectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<ProviderKind> kind = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String?> defaultModel = const Value.absent(),
                Value<DateTime?> modelsFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion(
                id: id,
                label: label,
                kind: kind,
                baseUrl: baseUrl,
                defaultModel: defaultModel,
                modelsFetchedAt: modelsFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required ProviderKind kind,
                required String baseUrl,
                Value<String?> defaultModel = const Value.absent(),
                Value<DateTime?> modelsFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion.insert(
                id: id,
                label: label,
                kind: kind,
                baseUrl: baseUrl,
                defaultModel: defaultModel,
                modelsFetchedAt: modelsFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedModelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cachedModelsRefs) db.cachedModels],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedModelsRefs)
                    await $_getPrefetchedData<
                      Connection,
                      $ConnectionsTable,
                      CachedModel
                    >(
                      currentTable: table,
                      referencedTable: $$ConnectionsTableReferences
                          ._cachedModelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConnectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedModelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.connectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionsTable,
      Connection,
      $$ConnectionsTableFilterComposer,
      $$ConnectionsTableOrderingComposer,
      $$ConnectionsTableAnnotationComposer,
      $$ConnectionsTableCreateCompanionBuilder,
      $$ConnectionsTableUpdateCompanionBuilder,
      (Connection, $$ConnectionsTableReferences),
      Connection,
      PrefetchHooks Function({bool cachedModelsRefs})
    >;
typedef $$CachedModelsTableCreateCompanionBuilder =
    CachedModelsCompanion Function({
      required String connectionId,
      required String modelId,
      Value<int> rowid,
    });
typedef $$CachedModelsTableUpdateCompanionBuilder =
    CachedModelsCompanion Function({
      Value<String> connectionId,
      Value<String> modelId,
      Value<int> rowid,
    });

final class $$CachedModelsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedModelsTable, CachedModel> {
  $$CachedModelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) => db
      .connections
      .createAlias('cached_models__connection_id__connections__id');

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedModelsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedModelsTable> {
  $$CachedModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedModelsTable> {
  $$CachedModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedModelsTable> {
  $$CachedModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedModelsTable,
          CachedModel,
          $$CachedModelsTableFilterComposer,
          $$CachedModelsTableOrderingComposer,
          $$CachedModelsTableAnnotationComposer,
          $$CachedModelsTableCreateCompanionBuilder,
          $$CachedModelsTableUpdateCompanionBuilder,
          (CachedModel, $$CachedModelsTableReferences),
          CachedModel,
          PrefetchHooks Function({bool connectionId})
        > {
  $$CachedModelsTableTableManager(_$AppDatabase db, $CachedModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> connectionId = const Value.absent(),
                Value<String> modelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedModelsCompanion(
                connectionId: connectionId,
                modelId: modelId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String connectionId,
                required String modelId,
                Value<int> rowid = const Value.absent(),
              }) => CachedModelsCompanion.insert(
                connectionId: connectionId,
                modelId: modelId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedModelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable: $$CachedModelsTableReferences
                                    ._connectionIdTable(db),
                                referencedColumn: $$CachedModelsTableReferences
                                    ._connectionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedModelsTable,
      CachedModel,
      $$CachedModelsTableFilterComposer,
      $$CachedModelsTableOrderingComposer,
      $$CachedModelsTableAnnotationComposer,
      $$CachedModelsTableCreateCompanionBuilder,
      $$CachedModelsTableUpdateCompanionBuilder,
      (CachedModel, $$CachedModelsTableReferences),
      CachedModel,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$CustomPersonasTableCreateCompanionBuilder =
    CustomPersonasCompanion Function({
      required String name,
      required String archetype,
      required String style,
      required String quirk,
      Value<String?> avatarPath,
      Value<String?> voiceSample,
      Value<int> rowid,
    });
typedef $$CustomPersonasTableUpdateCompanionBuilder =
    CustomPersonasCompanion Function({
      Value<String> name,
      Value<String> archetype,
      Value<String> style,
      Value<String> quirk,
      Value<String?> avatarPath,
      Value<String?> voiceSample,
      Value<int> rowid,
    });

class $$CustomPersonasTableFilterComposer
    extends Composer<_$AppDatabase, $CustomPersonasTable> {
  $$CustomPersonasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quirk => $composableBuilder(
    column: $table.quirk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceSample => $composableBuilder(
    column: $table.voiceSample,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomPersonasTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomPersonasTable> {
  $$CustomPersonasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archetype => $composableBuilder(
    column: $table.archetype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quirk => $composableBuilder(
    column: $table.quirk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceSample => $composableBuilder(
    column: $table.voiceSample,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomPersonasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomPersonasTable> {
  $$CustomPersonasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get archetype =>
      $composableBuilder(column: $table.archetype, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get quirk =>
      $composableBuilder(column: $table.quirk, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceSample => $composableBuilder(
    column: $table.voiceSample,
    builder: (column) => column,
  );
}

class $$CustomPersonasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomPersonasTable,
          CustomPersona,
          $$CustomPersonasTableFilterComposer,
          $$CustomPersonasTableOrderingComposer,
          $$CustomPersonasTableAnnotationComposer,
          $$CustomPersonasTableCreateCompanionBuilder,
          $$CustomPersonasTableUpdateCompanionBuilder,
          (
            CustomPersona,
            BaseReferences<_$AppDatabase, $CustomPersonasTable, CustomPersona>,
          ),
          CustomPersona,
          PrefetchHooks Function()
        > {
  $$CustomPersonasTableTableManager(
    _$AppDatabase db,
    $CustomPersonasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomPersonasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomPersonasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomPersonasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> archetype = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> quirk = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> voiceSample = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomPersonasCompanion(
                name: name,
                archetype: archetype,
                style: style,
                quirk: quirk,
                avatarPath: avatarPath,
                voiceSample: voiceSample,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String archetype,
                required String style,
                required String quirk,
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> voiceSample = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomPersonasCompanion.insert(
                name: name,
                archetype: archetype,
                style: style,
                quirk: quirk,
                avatarPath: avatarPath,
                voiceSample: voiceSample,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomPersonasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomPersonasTable,
      CustomPersona,
      $$CustomPersonasTableFilterComposer,
      $$CustomPersonasTableOrderingComposer,
      $$CustomPersonasTableAnnotationComposer,
      $$CustomPersonasTableCreateCompanionBuilder,
      $$CustomPersonasTableUpdateCompanionBuilder,
      (
        CustomPersona,
        BaseReferences<_$AppDatabase, $CustomPersonasTable, CustomPersona>,
      ),
      CustomPersona,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder =
    PrefsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PrefsTableUpdateCompanionBuilder =
    PrefsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PrefsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      required String id,
      required String townName,
      required DateTime savedAt,
      Value<bool> finished,
      Value<String?> winner,
      required int humanSeat,
      required int rngSeed,
      required String difficulty,
      Value<bool> grudgeMode,
      required String namesJson,
      required String badgesJson,
      Value<String> castingJson,
      required String configJson,
      Value<String?> sceneJson,
      required String eventsJson,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<String> id,
      Value<String> townName,
      Value<DateTime> savedAt,
      Value<bool> finished,
      Value<String?> winner,
      Value<int> humanSeat,
      Value<int> rngSeed,
      Value<String> difficulty,
      Value<bool> grudgeMode,
      Value<String> namesJson,
      Value<String> badgesJson,
      Value<String> castingJson,
      Value<String> configJson,
      Value<String?> sceneJson,
      Value<String> eventsJson,
      Value<String> notes,
      Value<int> rowid,
    });

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get townName => $composableBuilder(
    column: $table.townName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get humanSeat => $composableBuilder(
    column: $table.humanSeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rngSeed => $composableBuilder(
    column: $table.rngSeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get grudgeMode => $composableBuilder(
    column: $table.grudgeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namesJson => $composableBuilder(
    column: $table.namesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get castingJson => $composableBuilder(
    column: $table.castingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sceneJson => $composableBuilder(
    column: $table.sceneJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventsJson => $composableBuilder(
    column: $table.eventsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get townName => $composableBuilder(
    column: $table.townName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get humanSeat => $composableBuilder(
    column: $table.humanSeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rngSeed => $composableBuilder(
    column: $table.rngSeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get grudgeMode => $composableBuilder(
    column: $table.grudgeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namesJson => $composableBuilder(
    column: $table.namesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get castingJson => $composableBuilder(
    column: $table.castingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sceneJson => $composableBuilder(
    column: $table.sceneJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventsJson => $composableBuilder(
    column: $table.eventsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get townName =>
      $composableBuilder(column: $table.townName, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  GeneratedColumn<String> get winner =>
      $composableBuilder(column: $table.winner, builder: (column) => column);

  GeneratedColumn<int> get humanSeat =>
      $composableBuilder(column: $table.humanSeat, builder: (column) => column);

  GeneratedColumn<int> get rngSeed =>
      $composableBuilder(column: $table.rngSeed, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get grudgeMode => $composableBuilder(
    column: $table.grudgeMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namesJson =>
      $composableBuilder(column: $table.namesJson, builder: (column) => column);

  GeneratedColumn<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get castingJson => $composableBuilder(
    column: $table.castingJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sceneJson =>
      $composableBuilder(column: $table.sceneJson, builder: (column) => column);

  GeneratedColumn<String> get eventsJson => $composableBuilder(
    column: $table.eventsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, BaseReferences<_$AppDatabase, $GamesTable, Game>),
          Game,
          PrefetchHooks Function()
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> townName = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<String?> winner = const Value.absent(),
                Value<int> humanSeat = const Value.absent(),
                Value<int> rngSeed = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<bool> grudgeMode = const Value.absent(),
                Value<String> namesJson = const Value.absent(),
                Value<String> badgesJson = const Value.absent(),
                Value<String> castingJson = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<String?> sceneJson = const Value.absent(),
                Value<String> eventsJson = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                townName: townName,
                savedAt: savedAt,
                finished: finished,
                winner: winner,
                humanSeat: humanSeat,
                rngSeed: rngSeed,
                difficulty: difficulty,
                grudgeMode: grudgeMode,
                namesJson: namesJson,
                badgesJson: badgesJson,
                castingJson: castingJson,
                configJson: configJson,
                sceneJson: sceneJson,
                eventsJson: eventsJson,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String townName,
                required DateTime savedAt,
                Value<bool> finished = const Value.absent(),
                Value<String?> winner = const Value.absent(),
                required int humanSeat,
                required int rngSeed,
                required String difficulty,
                Value<bool> grudgeMode = const Value.absent(),
                required String namesJson,
                required String badgesJson,
                Value<String> castingJson = const Value.absent(),
                required String configJson,
                Value<String?> sceneJson = const Value.absent(),
                required String eventsJson,
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                townName: townName,
                savedAt: savedAt,
                finished: finished,
                winner: winner,
                humanSeat: humanSeat,
                rngSeed: rngSeed,
                difficulty: difficulty,
                grudgeMode: grudgeMode,
                namesJson: namesJson,
                badgesJson: badgesJson,
                castingJson: castingJson,
                configJson: configJson,
                sceneJson: sceneJson,
                eventsJson: eventsJson,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, BaseReferences<_$AppDatabase, $GamesTable, Game>),
      Game,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConnectionsTableTableManager get connections =>
      $$ConnectionsTableTableManager(_db, _db.connections);
  $$CachedModelsTableTableManager get cachedModels =>
      $$CachedModelsTableTableManager(_db, _db.cachedModels);
  $$CustomPersonasTableTableManager get customPersonas =>
      $$CustomPersonasTableTableManager(_db, _db.customPersonas);
  $$PrefsTableTableManager get prefs =>
      $$PrefsTableTableManager(_db, _db.prefs);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
}
