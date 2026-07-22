// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tableView)
const tableViewProvider = TableViewProvider._();

final class TableViewProvider
    extends $FunctionalProvider<TableViewState, TableViewState, TableViewState>
    with $Provider<TableViewState> {
  const TableViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableViewHash();

  @$internal
  @override
  $ProviderElement<TableViewState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TableViewState create(Ref ref) {
    return tableView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TableViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TableViewState>(value),
    );
  }
}

String _$tableViewHash() => r'406359e82fb4ea18df03398c0c0731aa6c16d65a';
