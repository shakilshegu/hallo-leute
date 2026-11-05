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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LearningReason, String> reason =
      GeneratedColumn<String>(
        'reason',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LearningReason>($ProfilesTable.$converterreason);
  @override
  late final GeneratedColumnWithTypeConverter<CefrLevel, String> level =
      GeneratedColumn<String>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CefrLevel>($ProfilesTable.$converterlevel);
  static const VerificationMeta _dailyGoalMeta = const VerificationMeta(
    'dailyGoal',
  );
  @override
  late final GeneratedColumn<int> dailyGoal = GeneratedColumn<int>(
    'daily_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    reason,
    level,
    dailyGoal,
    createdAt,
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
    }
    if (data.containsKey('daily_goal')) {
      context.handle(
        _dailyGoalMeta,
        dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyGoalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
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
      ),
      reason: $ProfilesTable.$converterreason.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reason'],
        )!,
      ),
      level: $ProfilesTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}level'],
        )!,
      ),
      dailyGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_goal'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LearningReason, String, String> $converterreason =
      const EnumNameConverter<LearningReason>(LearningReason.values);
  static JsonTypeConverter2<CefrLevel, String, String> $converterlevel =
      const EnumNameConverter<CefrLevel>(CefrLevel.values);
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String? name;
  final LearningReason reason;
  final CefrLevel level;
  final int dailyGoal;
  final DateTime createdAt;
  const Profile({
    required this.id,
    this.name,
    required this.reason,
    required this.level,
    required this.dailyGoal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    {
      map['reason'] = Variable<String>(
        $ProfilesTable.$converterreason.toSql(reason),
      );
    }
    {
      map['level'] = Variable<String>(
        $ProfilesTable.$converterlevel.toSql(level),
      );
    }
    map['daily_goal'] = Variable<int>(dailyGoal);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      reason: Value(reason),
      level: Value(level),
      dailyGoal: Value(dailyGoal),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      reason: $ProfilesTable.$converterreason.fromJson(
        serializer.fromJson<String>(json['reason']),
      ),
      level: $ProfilesTable.$converterlevel.fromJson(
        serializer.fromJson<String>(json['level']),
      ),
      dailyGoal: serializer.fromJson<int>(json['dailyGoal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'reason': serializer.toJson<String>(
        $ProfilesTable.$converterreason.toJson(reason),
      ),
      'level': serializer.toJson<String>(
        $ProfilesTable.$converterlevel.toJson(level),
      ),
      'dailyGoal': serializer.toJson<int>(dailyGoal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    LearningReason? reason,
    CefrLevel? level,
    int? dailyGoal,
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    reason: reason ?? this.reason,
    level: level ?? this.level,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      reason: data.reason.present ? data.reason.value : this.reason,
      level: data.level.present ? data.level.value : this.level,
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('reason: $reason, ')
          ..write('level: $level, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, reason, level, dailyGoal, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.reason == this.reason &&
          other.level == this.level &&
          other.dailyGoal == this.dailyGoal &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String?> name;
  final Value<LearningReason> reason;
  final Value<CefrLevel> level;
  final Value<int> dailyGoal;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.reason = const Value.absent(),
    this.level = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required LearningReason reason,
    required CefrLevel level,
    required int dailyGoal,
    this.createdAt = const Value.absent(),
  }) : reason = Value(reason),
       level = Value(level),
       dailyGoal = Value(dailyGoal);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? reason,
    Expression<String>? level,
    Expression<int>? dailyGoal,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (reason != null) 'reason': reason,
      if (level != null) 'level': level,
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<LearningReason>? reason,
    Value<CefrLevel>? level,
    Value<int>? dailyGoal,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      reason: reason ?? this.reason,
      level: level ?? this.level,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      createdAt: createdAt ?? this.createdAt,
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
    if (reason.present) {
      map['reason'] = Variable<String>(
        $ProfilesTable.$converterreason.toSql(reason.value),
      );
    }
    if (level.present) {
      map['level'] = Variable<String>(
        $ProfilesTable.$converterlevel.toSql(level.value),
      );
    }
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<int>(dailyGoal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('reason: $reason, ')
          ..write('level: $level, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _germanMeta = const VerificationMeta('german');
  @override
  late final GeneratedColumn<String> german = GeneratedColumn<String>(
    'german',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Article?, String> article =
      GeneratedColumn<String>(
        'article',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Article?>($WordsTable.$converterarticlen);
  static const VerificationMeta _pluralMeta = const VerificationMeta('plural');
  @override
  late final GeneratedColumn<String> plural = GeneratedColumn<String>(
    'plural',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _englishMeta = const VerificationMeta(
    'english',
  );
  @override
  late final GeneratedColumn<String> english = GeneratedColumn<String>(
    'english',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleEnMeta = const VerificationMeta(
    'exampleEn',
  );
  @override
  late final GeneratedColumn<String> exampleEn = GeneratedColumn<String>(
    'example_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CefrLevel, String> level =
      GeneratedColumn<String>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CefrLevel>($WordsTable.$converterlevel);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    german,
    article,
    plural,
    english,
    example,
    exampleEn,
    topic,
    level,
    emoji,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('german')) {
      context.handle(
        _germanMeta,
        german.isAcceptableOrUnknown(data['german']!, _germanMeta),
      );
    } else if (isInserting) {
      context.missing(_germanMeta);
    }
    if (data.containsKey('plural')) {
      context.handle(
        _pluralMeta,
        plural.isAcceptableOrUnknown(data['plural']!, _pluralMeta),
      );
    }
    if (data.containsKey('english')) {
      context.handle(
        _englishMeta,
        english.isAcceptableOrUnknown(data['english']!, _englishMeta),
      );
    } else if (isInserting) {
      context.missing(_englishMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    } else if (isInserting) {
      context.missing(_exampleMeta);
    }
    if (data.containsKey('example_en')) {
      context.handle(
        _exampleEnMeta,
        exampleEn.isAcceptableOrUnknown(data['example_en']!, _exampleEnMeta),
      );
    } else if (isInserting) {
      context.missing(_exampleEnMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      german: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}german'],
      )!,
      article: $WordsTable.$converterarticlen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}article'],
        ),
      ),
      plural: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plural'],
      ),
      english: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      exampleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_en'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      level: $WordsTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}level'],
        )!,
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Article, String, String> $converterarticle =
      const EnumNameConverter<Article>(Article.values);
  static JsonTypeConverter2<Article?, String?, String?> $converterarticlen =
      JsonTypeConverter2.asNullable($converterarticle);
  static JsonTypeConverter2<CefrLevel, String, String> $converterlevel =
      const EnumNameConverter<CefrLevel>(CefrLevel.values);
}

class Word extends DataClass implements Insertable<Word> {
  final String id;
  final String german;
  final Article? article;
  final String? plural;
  final String english;
  final String example;
  final String exampleEn;
  final String topic;
  final CefrLevel level;
  final String emoji;
  const Word({
    required this.id,
    required this.german,
    this.article,
    this.plural,
    required this.english,
    required this.example,
    required this.exampleEn,
    required this.topic,
    required this.level,
    required this.emoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['german'] = Variable<String>(german);
    if (!nullToAbsent || article != null) {
      map['article'] = Variable<String>(
        $WordsTable.$converterarticlen.toSql(article),
      );
    }
    if (!nullToAbsent || plural != null) {
      map['plural'] = Variable<String>(plural);
    }
    map['english'] = Variable<String>(english);
    map['example'] = Variable<String>(example);
    map['example_en'] = Variable<String>(exampleEn);
    map['topic'] = Variable<String>(topic);
    {
      map['level'] = Variable<String>($WordsTable.$converterlevel.toSql(level));
    }
    map['emoji'] = Variable<String>(emoji);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      german: Value(german),
      article: article == null && nullToAbsent
          ? const Value.absent()
          : Value(article),
      plural: plural == null && nullToAbsent
          ? const Value.absent()
          : Value(plural),
      english: Value(english),
      example: Value(example),
      exampleEn: Value(exampleEn),
      topic: Value(topic),
      level: Value(level),
      emoji: Value(emoji),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<String>(json['id']),
      german: serializer.fromJson<String>(json['german']),
      article: $WordsTable.$converterarticlen.fromJson(
        serializer.fromJson<String?>(json['article']),
      ),
      plural: serializer.fromJson<String?>(json['plural']),
      english: serializer.fromJson<String>(json['english']),
      example: serializer.fromJson<String>(json['example']),
      exampleEn: serializer.fromJson<String>(json['exampleEn']),
      topic: serializer.fromJson<String>(json['topic']),
      level: $WordsTable.$converterlevel.fromJson(
        serializer.fromJson<String>(json['level']),
      ),
      emoji: serializer.fromJson<String>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'german': serializer.toJson<String>(german),
      'article': serializer.toJson<String?>(
        $WordsTable.$converterarticlen.toJson(article),
      ),
      'plural': serializer.toJson<String?>(plural),
      'english': serializer.toJson<String>(english),
      'example': serializer.toJson<String>(example),
      'exampleEn': serializer.toJson<String>(exampleEn),
      'topic': serializer.toJson<String>(topic),
      'level': serializer.toJson<String>(
        $WordsTable.$converterlevel.toJson(level),
      ),
      'emoji': serializer.toJson<String>(emoji),
    };
  }

  Word copyWith({
    String? id,
    String? german,
    Value<Article?> article = const Value.absent(),
    Value<String?> plural = const Value.absent(),
    String? english,
    String? example,
    String? exampleEn,
    String? topic,
    CefrLevel? level,
    String? emoji,
  }) => Word(
    id: id ?? this.id,
    german: german ?? this.german,
    article: article.present ? article.value : this.article,
    plural: plural.present ? plural.value : this.plural,
    english: english ?? this.english,
    example: example ?? this.example,
    exampleEn: exampleEn ?? this.exampleEn,
    topic: topic ?? this.topic,
    level: level ?? this.level,
    emoji: emoji ?? this.emoji,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      german: data.german.present ? data.german.value : this.german,
      article: data.article.present ? data.article.value : this.article,
      plural: data.plural.present ? data.plural.value : this.plural,
      english: data.english.present ? data.english.value : this.english,
      example: data.example.present ? data.example.value : this.example,
      exampleEn: data.exampleEn.present ? data.exampleEn.value : this.exampleEn,
      topic: data.topic.present ? data.topic.value : this.topic,
      level: data.level.present ? data.level.value : this.level,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('german: $german, ')
          ..write('article: $article, ')
          ..write('plural: $plural, ')
          ..write('english: $english, ')
          ..write('example: $example, ')
          ..write('exampleEn: $exampleEn, ')
          ..write('topic: $topic, ')
          ..write('level: $level, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    german,
    article,
    plural,
    english,
    example,
    exampleEn,
    topic,
    level,
    emoji,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.german == this.german &&
          other.article == this.article &&
          other.plural == this.plural &&
          other.english == this.english &&
          other.example == this.example &&
          other.exampleEn == this.exampleEn &&
          other.topic == this.topic &&
          other.level == this.level &&
          other.emoji == this.emoji);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<String> id;
  final Value<String> german;
  final Value<Article?> article;
  final Value<String?> plural;
  final Value<String> english;
  final Value<String> example;
  final Value<String> exampleEn;
  final Value<String> topic;
  final Value<CefrLevel> level;
  final Value<String> emoji;
  final Value<int> rowid;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.german = const Value.absent(),
    this.article = const Value.absent(),
    this.plural = const Value.absent(),
    this.english = const Value.absent(),
    this.example = const Value.absent(),
    this.exampleEn = const Value.absent(),
    this.topic = const Value.absent(),
    this.level = const Value.absent(),
    this.emoji = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String id,
    required String german,
    this.article = const Value.absent(),
    this.plural = const Value.absent(),
    required String english,
    required String example,
    required String exampleEn,
    required String topic,
    required CefrLevel level,
    required String emoji,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       german = Value(german),
       english = Value(english),
       example = Value(example),
       exampleEn = Value(exampleEn),
       topic = Value(topic),
       level = Value(level),
       emoji = Value(emoji);
  static Insertable<Word> custom({
    Expression<String>? id,
    Expression<String>? german,
    Expression<String>? article,
    Expression<String>? plural,
    Expression<String>? english,
    Expression<String>? example,
    Expression<String>? exampleEn,
    Expression<String>? topic,
    Expression<String>? level,
    Expression<String>? emoji,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (german != null) 'german': german,
      if (article != null) 'article': article,
      if (plural != null) 'plural': plural,
      if (english != null) 'english': english,
      if (example != null) 'example': example,
      if (exampleEn != null) 'example_en': exampleEn,
      if (topic != null) 'topic': topic,
      if (level != null) 'level': level,
      if (emoji != null) 'emoji': emoji,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith({
    Value<String>? id,
    Value<String>? german,
    Value<Article?>? article,
    Value<String?>? plural,
    Value<String>? english,
    Value<String>? example,
    Value<String>? exampleEn,
    Value<String>? topic,
    Value<CefrLevel>? level,
    Value<String>? emoji,
    Value<int>? rowid,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      german: german ?? this.german,
      article: article ?? this.article,
      plural: plural ?? this.plural,
      english: english ?? this.english,
      example: example ?? this.example,
      exampleEn: exampleEn ?? this.exampleEn,
      topic: topic ?? this.topic,
      level: level ?? this.level,
      emoji: emoji ?? this.emoji,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (german.present) {
      map['german'] = Variable<String>(german.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(
        $WordsTable.$converterarticlen.toSql(article.value),
      );
    }
    if (plural.present) {
      map['plural'] = Variable<String>(plural.value);
    }
    if (english.present) {
      map['english'] = Variable<String>(english.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (exampleEn.present) {
      map['example_en'] = Variable<String>(exampleEn.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(
        $WordsTable.$converterlevel.toSql(level.value),
      );
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('german: $german, ')
          ..write('article: $article, ')
          ..write('plural: $plural, ')
          ..write('english: $english, ')
          ..write('example: $example, ')
          ..write('exampleEn: $exampleEn, ')
          ..write('topic: $topic, ')
          ..write('level: $level, ')
          ..write('emoji: $emoji, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordProgressTable extends WordProgress
    with TableInfo<$WordProgressTable, WordProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _learnedAtMeta = const VerificationMeta(
    'learnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> learnedAt = GeneratedColumn<DateTime>(
    'learned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
    'next_review',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewStreakMeta = const VerificationMeta(
    'reviewStreak',
  );
  @override
  late final GeneratedColumn<int> reviewStreak = GeneratedColumn<int>(
    'review_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    learnedAt,
    nextReview,
    reviewStreak,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('learned_at')) {
      context.handle(
        _learnedAtMeta,
        learnedAt.isAcceptableOrUnknown(data['learned_at']!, _learnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_learnedAtMeta);
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    } else if (isInserting) {
      context.missing(_nextReviewMeta);
    }
    if (data.containsKey('review_streak')) {
      context.handle(
        _reviewStreakMeta,
        reviewStreak.isAcceptableOrUnknown(
          data['review_streak']!,
          _reviewStreakMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordProgressData(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      learnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}learned_at'],
      )!,
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review'],
      )!,
      reviewStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_streak'],
      )!,
    );
  }

  @override
  $WordProgressTable createAlias(String alias) {
    return $WordProgressTable(attachedDatabase, alias);
  }
}

class WordProgressData extends DataClass
    implements Insertable<WordProgressData> {
  final String wordId;
  final DateTime learnedAt;

  /// When the word should come back for review (spaced repetition).
  final DateTime nextReview;

  /// Correct reviews in a row – grows the review interval.
  final int reviewStreak;
  const WordProgressData({
    required this.wordId,
    required this.learnedAt,
    required this.nextReview,
    required this.reviewStreak,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['learned_at'] = Variable<DateTime>(learnedAt);
    map['next_review'] = Variable<DateTime>(nextReview);
    map['review_streak'] = Variable<int>(reviewStreak);
    return map;
  }

  WordProgressCompanion toCompanion(bool nullToAbsent) {
    return WordProgressCompanion(
      wordId: Value(wordId),
      learnedAt: Value(learnedAt),
      nextReview: Value(nextReview),
      reviewStreak: Value(reviewStreak),
    );
  }

  factory WordProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordProgressData(
      wordId: serializer.fromJson<String>(json['wordId']),
      learnedAt: serializer.fromJson<DateTime>(json['learnedAt']),
      nextReview: serializer.fromJson<DateTime>(json['nextReview']),
      reviewStreak: serializer.fromJson<int>(json['reviewStreak']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'learnedAt': serializer.toJson<DateTime>(learnedAt),
      'nextReview': serializer.toJson<DateTime>(nextReview),
      'reviewStreak': serializer.toJson<int>(reviewStreak),
    };
  }

  WordProgressData copyWith({
    String? wordId,
    DateTime? learnedAt,
    DateTime? nextReview,
    int? reviewStreak,
  }) => WordProgressData(
    wordId: wordId ?? this.wordId,
    learnedAt: learnedAt ?? this.learnedAt,
    nextReview: nextReview ?? this.nextReview,
    reviewStreak: reviewStreak ?? this.reviewStreak,
  );
  WordProgressData copyWithCompanion(WordProgressCompanion data) {
    return WordProgressData(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      learnedAt: data.learnedAt.present ? data.learnedAt.value : this.learnedAt,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
      reviewStreak: data.reviewStreak.present
          ? data.reviewStreak.value
          : this.reviewStreak,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressData(')
          ..write('wordId: $wordId, ')
          ..write('learnedAt: $learnedAt, ')
          ..write('nextReview: $nextReview, ')
          ..write('reviewStreak: $reviewStreak')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, learnedAt, nextReview, reviewStreak);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordProgressData &&
          other.wordId == this.wordId &&
          other.learnedAt == this.learnedAt &&
          other.nextReview == this.nextReview &&
          other.reviewStreak == this.reviewStreak);
}

class WordProgressCompanion extends UpdateCompanion<WordProgressData> {
  final Value<String> wordId;
  final Value<DateTime> learnedAt;
  final Value<DateTime> nextReview;
  final Value<int> reviewStreak;
  final Value<int> rowid;
  const WordProgressCompanion({
    this.wordId = const Value.absent(),
    this.learnedAt = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.reviewStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordProgressCompanion.insert({
    required String wordId,
    required DateTime learnedAt,
    required DateTime nextReview,
    this.reviewStreak = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId),
       learnedAt = Value(learnedAt),
       nextReview = Value(nextReview);
  static Insertable<WordProgressData> custom({
    Expression<String>? wordId,
    Expression<DateTime>? learnedAt,
    Expression<DateTime>? nextReview,
    Expression<int>? reviewStreak,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (learnedAt != null) 'learned_at': learnedAt,
      if (nextReview != null) 'next_review': nextReview,
      if (reviewStreak != null) 'review_streak': reviewStreak,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordProgressCompanion copyWith({
    Value<String>? wordId,
    Value<DateTime>? learnedAt,
    Value<DateTime>? nextReview,
    Value<int>? reviewStreak,
    Value<int>? rowid,
  }) {
    return WordProgressCompanion(
      wordId: wordId ?? this.wordId,
      learnedAt: learnedAt ?? this.learnedAt,
      nextReview: nextReview ?? this.nextReview,
      reviewStreak: reviewStreak ?? this.reviewStreak,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (learnedAt.present) {
      map['learned_at'] = Variable<DateTime>(learnedAt.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (reviewStreak.present) {
      map['review_streak'] = Variable<int>(reviewStreak.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressCompanion(')
          ..write('wordId: $wordId, ')
          ..write('learnedAt: $learnedAt, ')
          ..write('nextReview: $nextReview, ')
          ..write('reviewStreak: $reviewStreak, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordProgressTable wordProgress = $WordProgressTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    words,
    wordProgress,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String?> name,
  required LearningReason reason,
  required CefrLevel level,
  required int dailyGoal,
  Value<DateTime> createdAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<LearningReason> reason,
  Value<CefrLevel> level,
  Value<int> dailyGoal,
  Value<DateTime> createdAt,
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

  ColumnWithTypeConverterFilters<LearningReason, LearningReason, String>
  get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CefrLevel, CefrLevel, String> get level =>
      $composableBuilder(
        column: $table.level,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get dailyGoal => $composableBuilder(
    column: $table.dailyGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyGoal => $composableBuilder(
    column: $table.dailyGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  GeneratedColumnWithTypeConverter<LearningReason, String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CefrLevel, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get dailyGoal =>
      $composableBuilder(column: $table.dailyGoal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
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
                Value<String?> name = const Value.absent(),
                Value<LearningReason> reason = const Value.absent(),
                Value<CefrLevel> level = const Value.absent(),
                Value<int> dailyGoal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                reason: reason,
                level: level,
                dailyGoal: dailyGoal,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                required LearningReason reason,
                required CefrLevel level,
                required int dailyGoal,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                reason: reason,
                level: level,
                dailyGoal: dailyGoal,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
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
typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  required String id,
  required String german,
  Value<Article?> article,
  Value<String?> plural,
  required String english,
  required String example,
  required String exampleEn,
  required String topic,
  required CefrLevel level,
  required String emoji,
  Value<int> rowid,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<String> id,
  Value<String> german,
  Value<Article?> article,
  Value<String?> plural,
  Value<String> english,
  Value<String> example,
  Value<String> exampleEn,
  Value<String> topic,
  Value<CefrLevel> level,
  Value<String> emoji,
  Value<int> rowid,
});

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordProgressTable, List<WordProgressData>>
  _wordProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordProgress,
    aliasName: 'words__id__word_progress__word_id',
  );

  $$WordProgressTableProcessedTableManager get wordProgressRefs {
    final manager = $$WordProgressTableTableManager(
      $_db,
      $_db.wordProgress,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Article?, Article, String> get article =>
      $composableBuilder(
        column: $table.article,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get plural => $composableBuilder(
    column: $table.plural,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleEn => $composableBuilder(
    column: $table.exampleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CefrLevel, CefrLevel, String> get level =>
      $composableBuilder(
        column: $table.level,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordProgressRefs(
    Expression<bool> Function($$WordProgressTableFilterComposer f) f,
  ) {
    final $$WordProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgress,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressTableFilterComposer(
            $db: $db,
            $table: $db.wordProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
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

  ColumnOrderings<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get article => $composableBuilder(
    column: $table.article,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plural => $composableBuilder(
    column: $table.plural,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleEn => $composableBuilder(
    column: $table.exampleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get german =>
      $composableBuilder(column: $table.german, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Article?, String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<String> get plural =>
      $composableBuilder(column: $table.plural, builder: (column) => column);

  GeneratedColumn<String> get english =>
      $composableBuilder(column: $table.english, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get exampleEn =>
      $composableBuilder(column: $table.exampleEn, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CefrLevel, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  Expression<T> wordProgressRefs<T extends Object>(
    Expression<T> Function($$WordProgressTableAnnotationComposer a) f,
  ) {
    final $$WordProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgress,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.wordProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({bool wordProgressRefs})
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> german = const Value.absent(),
                Value<Article?> article = const Value.absent(),
                Value<String?> plural = const Value.absent(),
                Value<String> english = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String> exampleEn = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<CefrLevel> level = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                german: german,
                article: article,
                plural: plural,
                english: english,
                example: example,
                exampleEn: exampleEn,
                topic: topic,
                level: level,
                emoji: emoji,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String german,
                Value<Article?> article = const Value.absent(),
                Value<String?> plural = const Value.absent(),
                required String english,
                required String example,
                required String exampleEn,
                required String topic,
                required CefrLevel level,
                required String emoji,
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                german: german,
                article: article,
                plural: plural,
                english: english,
                example: example,
                exampleEn: exampleEn,
                topic: topic,
                level: level,
                emoji: emoji,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordsTable, Word>(table),
                  $$WordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordProgressRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordProgressRefs) db.wordProgress],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordProgressRefs)
                    await $_getPrefetchedDataByColumns<
                      Word,
                      $WordsTable,
                      WordProgressData,
                      $WordProgressTable
                    >(
                      currentTable: table,
                      referencedTable: $$WordsTableReferences
                          ._wordProgressRefsTable(db),
                      managerFromTypedResult: (p0) => $$WordsTableReferences(
                        db,
                        table,
                        p0,
                      ).wordProgressRefs,
                      currentColumn: 'id',
                      referencedColumn: 'word_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({bool wordProgressRefs})
    >;
typedef $$WordProgressTableCreateCompanionBuilder =
    WordProgressCompanion Function({
      required String wordId,
      required DateTime learnedAt,
      required DateTime nextReview,
      Value<int> reviewStreak,
      Value<int> rowid,
    });
typedef $$WordProgressTableUpdateCompanionBuilder =
    WordProgressCompanion Function({
      Value<String> wordId,
      Value<DateTime> learnedAt,
      Value<DateTime> nextReview,
      Value<int> reviewStreak,
      Value<int> rowid,
    });

final class $$WordProgressTableReferences
    extends
        BaseReferences<_$AppDatabase, $WordProgressTable, WordProgressData> {
  $$WordProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_progress__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordProgressTableFilterComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get learnedAt => $composableBuilder(
    column: $table.learnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewStreak => $composableBuilder(
    column: $table.reviewStreak,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get learnedAt => $composableBuilder(
    column: $table.learnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewStreak => $composableBuilder(
    column: $table.reviewStreak,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get learnedAt =>
      $composableBuilder(column: $table.learnedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewStreak => $composableBuilder(
    column: $table.reviewStreak,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordProgressTable,
          WordProgressData,
          $$WordProgressTableFilterComposer,
          $$WordProgressTableOrderingComposer,
          $$WordProgressTableAnnotationComposer,
          $$WordProgressTableCreateCompanionBuilder,
          $$WordProgressTableUpdateCompanionBuilder,
          (WordProgressData, $$WordProgressTableReferences),
          WordProgressData,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordProgressTableTableManager(_$AppDatabase db, $WordProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> wordId = const Value.absent(),
                Value<DateTime> learnedAt = const Value.absent(),
                Value<DateTime> nextReview = const Value.absent(),
                Value<int> reviewStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion(
                wordId: wordId,
                learnedAt: learnedAt,
                nextReview: nextReview,
                reviewStreak: reviewStreak,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordId,
                required DateTime learnedAt,
                required DateTime nextReview,
                Value<int> reviewStreak = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion.insert(
                wordId: wordId,
                learnedAt: learnedAt,
                nextReview: nextReview,
                reviewStreak: reviewStreak,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordProgressTable, WordProgressData>(table),
                  $$WordProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$WordProgressTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$WordProgressTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
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

typedef $$WordProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordProgressTable,
      WordProgressData,
      $$WordProgressTableFilterComposer,
      $$WordProgressTableOrderingComposer,
      $$WordProgressTableAnnotationComposer,
      $$WordProgressTableCreateCompanionBuilder,
      $$WordProgressTableUpdateCompanionBuilder,
      (WordProgressData, $$WordProgressTableReferences),
      WordProgressData,
      PrefetchHooks Function({bool wordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordProgressTableTableManager get wordProgress =>
      $$WordProgressTableTableManager(_db, _db.wordProgress);
}
