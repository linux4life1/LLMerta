import 'package:llm/llm.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'persona_pool.g.dart';

@riverpod
List<Persona> personaPool(Ref ref) => personaLibrary;
