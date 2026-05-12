// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_alert.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQueuedAlertCollection on Isar {
  IsarCollection<QueuedAlert> get queuedAlerts => this.collection();
}

const QueuedAlertSchema = CollectionSchema(
  name: r'QueuedAlert',
  id: 1044924505879651219,
  properties: {
    r'clientEventId': PropertySchema(
      id: 0,
      name: r'clientEventId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'esProactiva': PropertySchema(
      id: 2,
      name: r'esProactiva',
      type: IsarType.bool,
    ),
    r'fechaHora': PropertySchema(
      id: 3,
      name: r'fechaHora',
      type: IsarType.dateTime,
    ),
    r'lastAttemptAt': PropertySchema(
      id: 4,
      name: r'lastAttemptAt',
      type: IsarType.dateTime,
    ),
    r'lastError': PropertySchema(
      id: 5,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'latitud': PropertySchema(
      id: 6,
      name: r'latitud',
      type: IsarType.double,
    ),
    r'longitud': PropertySchema(
      id: 7,
      name: r'longitud',
      type: IsarType.double,
    ),
    r'retryCount': PropertySchema(
      id: 8,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
      enumMap: _QueuedAlertstatusEnumValueMap,
    ),
    r'urlAudioContexto': PropertySchema(
      id: 10,
      name: r'urlAudioContexto',
      type: IsarType.string,
    )
  },
  estimateSize: _queuedAlertEstimateSize,
  serialize: _queuedAlertSerialize,
  deserialize: _queuedAlertDeserialize,
  deserializeProp: _queuedAlertDeserializeProp,
  idName: r'id',
  indexes: {
    r'clientEventId': IndexSchema(
      id: -7701764401223387261,
      name: r'clientEventId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'clientEventId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'fechaHora': IndexSchema(
      id: 8556457764403596295,
      name: r'fechaHora',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fechaHora',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _queuedAlertGetId,
  getLinks: _queuedAlertGetLinks,
  attach: _queuedAlertAttach,
  version: '3.1.0+1',
);

int _queuedAlertEstimateSize(
  QueuedAlert object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clientEventId.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.name.length * 3;
  {
    final value = object.urlAudioContexto;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _queuedAlertSerialize(
  QueuedAlert object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.clientEventId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.esProactiva);
  writer.writeDateTime(offsets[3], object.fechaHora);
  writer.writeDateTime(offsets[4], object.lastAttemptAt);
  writer.writeString(offsets[5], object.lastError);
  writer.writeDouble(offsets[6], object.latitud);
  writer.writeDouble(offsets[7], object.longitud);
  writer.writeLong(offsets[8], object.retryCount);
  writer.writeString(offsets[9], object.status.name);
  writer.writeString(offsets[10], object.urlAudioContexto);
}

QueuedAlert _queuedAlertDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QueuedAlert();
  object.clientEventId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.esProactiva = reader.readBool(offsets[2]);
  object.fechaHora = reader.readDateTime(offsets[3]);
  object.id = id;
  object.lastAttemptAt = reader.readDateTimeOrNull(offsets[4]);
  object.lastError = reader.readStringOrNull(offsets[5]);
  object.latitud = reader.readDouble(offsets[6]);
  object.longitud = reader.readDouble(offsets[7]);
  object.retryCount = reader.readLong(offsets[8]);
  object.status =
      _QueuedAlertstatusValueEnumMap[reader.readStringOrNull(offsets[9])] ??
          QueueStatus.pending;
  object.urlAudioContexto = reader.readStringOrNull(offsets[10]);
  return object;
}

P _queuedAlertDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (_QueuedAlertstatusValueEnumMap[reader.readStringOrNull(offset)] ??
          QueueStatus.pending) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _QueuedAlertstatusEnumValueMap = {
  r'pending': r'pending',
  r'sending': r'sending',
  r'sent': r'sent',
  r'failed': r'failed',
};
const _QueuedAlertstatusValueEnumMap = {
  r'pending': QueueStatus.pending,
  r'sending': QueueStatus.sending,
  r'sent': QueueStatus.sent,
  r'failed': QueueStatus.failed,
};

Id _queuedAlertGetId(QueuedAlert object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _queuedAlertGetLinks(QueuedAlert object) {
  return [];
}

void _queuedAlertAttach(
    IsarCollection<dynamic> col, Id id, QueuedAlert object) {
  object.id = id;
}

extension QueuedAlertByIndex on IsarCollection<QueuedAlert> {
  Future<QueuedAlert?> getByClientEventId(String clientEventId) {
    return getByIndex(r'clientEventId', [clientEventId]);
  }

  QueuedAlert? getByClientEventIdSync(String clientEventId) {
    return getByIndexSync(r'clientEventId', [clientEventId]);
  }

  Future<bool> deleteByClientEventId(String clientEventId) {
    return deleteByIndex(r'clientEventId', [clientEventId]);
  }

  bool deleteByClientEventIdSync(String clientEventId) {
    return deleteByIndexSync(r'clientEventId', [clientEventId]);
  }

  Future<List<QueuedAlert?>> getAllByClientEventId(
      List<String> clientEventIdValues) {
    final values = clientEventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'clientEventId', values);
  }

  List<QueuedAlert?> getAllByClientEventIdSync(
      List<String> clientEventIdValues) {
    final values = clientEventIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'clientEventId', values);
  }

  Future<int> deleteAllByClientEventId(List<String> clientEventIdValues) {
    final values = clientEventIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'clientEventId', values);
  }

  int deleteAllByClientEventIdSync(List<String> clientEventIdValues) {
    final values = clientEventIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'clientEventId', values);
  }

  Future<Id> putByClientEventId(QueuedAlert object) {
    return putByIndex(r'clientEventId', object);
  }

  Id putByClientEventIdSync(QueuedAlert object, {bool saveLinks = true}) {
    return putByIndexSync(r'clientEventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClientEventId(List<QueuedAlert> objects) {
    return putAllByIndex(r'clientEventId', objects);
  }

  List<Id> putAllByClientEventIdSync(List<QueuedAlert> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'clientEventId', objects, saveLinks: saveLinks);
  }
}

extension QueuedAlertQueryWhereSort
    on QueryBuilder<QueuedAlert, QueuedAlert, QWhere> {
  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhere> anyFechaHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'fechaHora'),
      );
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension QueuedAlertQueryWhere
    on QueryBuilder<QueuedAlert, QueuedAlert, QWhereClause> {
  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause>
      clientEventIdEqualTo(String clientEventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientEventId',
        value: [clientEventId],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause>
      clientEventIdNotEqualTo(String clientEventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientEventId',
              lower: [],
              upper: [clientEventId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientEventId',
              lower: [clientEventId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientEventId',
              lower: [clientEventId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientEventId',
              lower: [],
              upper: [clientEventId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> fechaHoraEqualTo(
      DateTime fechaHora) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fechaHora',
        value: [fechaHora],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> fechaHoraNotEqualTo(
      DateTime fechaHora) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHora',
              lower: [],
              upper: [fechaHora],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHora',
              lower: [fechaHora],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHora',
              lower: [fechaHora],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHora',
              lower: [],
              upper: [fechaHora],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause>
      fechaHoraGreaterThan(
    DateTime fechaHora, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHora',
        lower: [fechaHora],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> fechaHoraLessThan(
    DateTime fechaHora, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHora',
        lower: [],
        upper: [fechaHora],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> fechaHoraBetween(
    DateTime lowerFechaHora,
    DateTime upperFechaHora, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHora',
        lower: [lowerFechaHora],
        includeLower: includeLower,
        upper: [upperFechaHora],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> statusEqualTo(
      QueueStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> statusNotEqualTo(
      QueueStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> createdAtEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> createdAtNotEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QueuedAlertQueryFilter
    on QueryBuilder<QueuedAlert, QueuedAlert, QFilterCondition> {
  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientEventId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientEventId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientEventId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientEventId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      clientEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientEventId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      esProactivaEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'esProactiva',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      fechaHoraEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaHora',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      fechaHoraGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaHora',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      fechaHoraLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaHora',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      fechaHoraBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaHora',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastAttemptAt',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastAttemptAt',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastAttemptAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastAttemptAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> latitudEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      latitudGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> latitudLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> latitudBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitud',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> longitudEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      longitudGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      longitudLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitud',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> longitudBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitud',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusEqualTo(
    QueueStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      statusGreaterThan(
    QueueStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusLessThan(
    QueueStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusBetween(
    QueueStatus lower,
    QueueStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'urlAudioContexto',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'urlAudioContexto',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'urlAudioContexto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'urlAudioContexto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'urlAudioContexto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'urlAudioContexto',
        value: '',
      ));
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterFilterCondition>
      urlAudioContextoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'urlAudioContexto',
        value: '',
      ));
    });
  }
}

extension QueuedAlertQueryObject
    on QueryBuilder<QueuedAlert, QueuedAlert, QFilterCondition> {}

extension QueuedAlertQueryLinks
    on QueryBuilder<QueuedAlert, QueuedAlert, QFilterCondition> {}

extension QueuedAlertQuerySortBy
    on QueryBuilder<QueuedAlert, QueuedAlert, QSortBy> {
  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByClientEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientEventId', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      sortByClientEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientEventId', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByEsProactiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esProactiva', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByEsProactivaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esProactiva', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByFechaHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHora', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByFechaHoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHora', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      sortByLastAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLatitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByLongitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      sortByUrlAudioContexto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urlAudioContexto', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      sortByUrlAudioContextoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urlAudioContexto', Sort.desc);
    });
  }
}

extension QueuedAlertQuerySortThenBy
    on QueryBuilder<QueuedAlert, QueuedAlert, QSortThenBy> {
  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByClientEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientEventId', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      thenByClientEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientEventId', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByEsProactiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esProactiva', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByEsProactivaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esProactiva', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByFechaHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHora', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByFechaHoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHora', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      thenByLastAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLatitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitud', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByLongitudDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitud', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      thenByUrlAudioContexto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urlAudioContexto', Sort.asc);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QAfterSortBy>
      thenByUrlAudioContextoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'urlAudioContexto', Sort.desc);
    });
  }
}

extension QueuedAlertQueryWhereDistinct
    on QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> {
  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByClientEventId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientEventId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByEsProactiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'esProactiva');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByFechaHora() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaHora');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastAttemptAt');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByLastError(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByLatitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitud');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByLongitud() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitud');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueuedAlert, QueuedAlert, QDistinct> distinctByUrlAudioContexto(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'urlAudioContexto',
          caseSensitive: caseSensitive);
    });
  }
}

extension QueuedAlertQueryProperty
    on QueryBuilder<QueuedAlert, QueuedAlert, QQueryProperty> {
  QueryBuilder<QueuedAlert, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QueuedAlert, String, QQueryOperations> clientEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientEventId');
    });
  }

  QueryBuilder<QueuedAlert, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<QueuedAlert, bool, QQueryOperations> esProactivaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'esProactiva');
    });
  }

  QueryBuilder<QueuedAlert, DateTime, QQueryOperations> fechaHoraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaHora');
    });
  }

  QueryBuilder<QueuedAlert, DateTime?, QQueryOperations>
      lastAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastAttemptAt');
    });
  }

  QueryBuilder<QueuedAlert, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<QueuedAlert, double, QQueryOperations> latitudProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitud');
    });
  }

  QueryBuilder<QueuedAlert, double, QQueryOperations> longitudProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitud');
    });
  }

  QueryBuilder<QueuedAlert, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<QueuedAlert, QueueStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<QueuedAlert, String?, QQueryOperations>
      urlAudioContextoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'urlAudioContexto');
    });
  }
}
