// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_mood.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TableMoodController)
const tableMoodControllerProvider = TableMoodControllerProvider._();

final class TableMoodControllerProvider
    extends $NotifierProvider<TableMoodController, TableMood> {
  const TableMoodControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableMoodControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableMoodControllerHash();

  @$internal
  @override
  TableMoodController create() => TableMoodController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TableMood value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TableMood>(value),
    );
  }
}

String _$tableMoodControllerHash() =>
    r'411e2c6ce2e2ef3d3b72440011422b32ed3196b8';

abstract class _$TableMoodController extends $Notifier<TableMood> {
  TableMood build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TableMood, TableMood>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TableMood, TableMood>,
              TableMood,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
