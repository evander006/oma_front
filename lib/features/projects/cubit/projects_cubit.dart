import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/renovation_repository.dart';
import 'package:oma/shared/models/renovation_request.dart';

class ProjectsState extends Equatable {
  const ProjectsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<RenovationRequest> items;
  final bool loading;
  final String? error;

  ProjectsState copyWith({
    List<RenovationRequest>? items,
    bool? loading,
    String? error,
  }) {
    return ProjectsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, loading, error];
}

class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit(this._repo) : super(const ProjectsState());

  final RenovationRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repo.list();
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: '$e'));
    }
  }

  Future<RenovationRequest> createDraft() async {
    final draft = await _repo.createDraft();
    await load();
    return draft;
  }

  Future<void> save(RenovationRequest request) async {
    await _repo.save(request);
    await load();
  }

  Future<void> submit(RenovationRequest request) async {
    await _repo.submit(request);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
