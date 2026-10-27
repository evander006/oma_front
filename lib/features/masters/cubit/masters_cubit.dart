import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oma/core/repositories/masters_repository.dart';
import 'package:oma/shared/models/master.dart';

class MastersState extends Equatable {
  const MastersState({
    this.masters = const [],
    this.clientRequests = const [],
    this.contractorRequests = const [],
    this.selectedSpecialty,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  final List<MasterProfile> masters;
  final List<MasterWorkRequest> clientRequests;
  final List<MasterWorkRequest> contractorRequests;
  final String? selectedSpecialty;
  final bool loading;
  final bool saving;
  final String? error;

  List<MasterProfile> get visibleMasters {
    final specialty = selectedSpecialty;
    if (specialty == null || specialty.isEmpty) return masters;
    return masters
        .where((profile) => profile.specialties.contains(specialty))
        .toList(growable: false);
  }

  List<MasterProfile> get favorites => masters
      .where((profile) => profile.isFavorite)
      .toList(growable: false);

  List<String> get specialties {
    final values = <String>{
      for (final profile in masters) ...profile.specialties,
    }.toList()
      ..sort();
    return values;
  }

  bool get isDemo => masters.any((profile) => profile.isDemo) ||
      clientRequests.any((request) => request.isDemo) ||
      contractorRequests.any((request) => request.isDemo);

  MasterProfile? byId(String id) {
    for (final profile in masters) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  MastersState copyWith({
    List<MasterProfile>? masters,
    List<MasterWorkRequest>? clientRequests,
    List<MasterWorkRequest>? contractorRequests,
    String? selectedSpecialty,
    bool clearSpecialty = false,
    bool? loading,
    bool? saving,
    String? error,
  }) {
    return MastersState(
      masters: masters ?? this.masters,
      clientRequests: clientRequests ?? this.clientRequests,
      contractorRequests: contractorRequests ?? this.contractorRequests,
      selectedSpecialty:
          clearSpecialty ? null : (selectedSpecialty ?? this.selectedSpecialty),
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        masters,
        clientRequests,
        contractorRequests,
        selectedSpecialty,
        loading,
        saving,
        error,
      ];
}

class MastersCubit extends Cubit<MastersState> {
  MastersCubit(this._repository) : super(const MastersState());

  final MastersRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, saving: false, error: null));
    try {
      final masters = await _repository.masters();
      final clientRequests = await _repository.myRequests();
      final contractorRequests = await _repository.contractorRequests();
      emit(state.copyWith(
        masters: masters,
        clientRequests: clientRequests,
        contractorRequests: contractorRequests,
        loading: false,
        saving: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        loading: false,
        saving: false,
        error: '$error',
      ));
    }
  }

  void selectSpecialty(String? specialty) {
    if (specialty == null || specialty == state.selectedSpecialty) {
      emit(state.copyWith(clearSpecialty: true, error: null));
    } else {
      emit(state.copyWith(selectedSpecialty: specialty, error: null));
    }
  }

  Future<void> toggleFavorite(MasterProfile profile) async {
    final favorite = !profile.isFavorite;
    final optimistic = state.masters
        .map((item) => item.id == profile.id
            ? item.copyWith(isFavorite: favorite)
            : item)
        .toList(growable: false);
    emit(state.copyWith(masters: optimistic, saving: true, error: null));
    try {
      await _repository.setFavorite(profile.id, favorite: favorite);
      emit(state.copyWith(saving: false));
    } catch (error) {
      emit(state.copyWith(
        masters: state.masters
            .map((item) => item.id == profile.id
                ? item.copyWith(isFavorite: !favorite)
                : item)
            .toList(growable: false),
        saving: false,
        error: '$error',
      ));
    }
  }

  Future<MasterWorkRequest?> submitRequest(MasterRequestDraft draft) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      final created = await _repository.createRequest(draft);
      final clientRequests = await _repository.myRequests();
      final contractorRequests = await _repository.contractorRequests();
      emit(state.copyWith(
        clientRequests: clientRequests,
        contractorRequests: contractorRequests,
        saving: false,
      ));
      return created;
    } catch (error) {
      emit(state.copyWith(saving: false, error: '$error'));
      return null;
    }
  }

  Future<void> refreshHistory() async {
    try {
      final clientRequests = await _repository.myRequests();
      emit(state.copyWith(clientRequests: clientRequests, error: null));
    } catch (error) {
      emit(state.copyWith(error: '$error'));
    }
  }

  Future<void> refreshDashboard() async {
    try {
      final requests = await _repository.contractorRequests();
      emit(state.copyWith(contractorRequests: requests, error: null));
    } catch (error) {
      emit(state.copyWith(error: '$error'));
    }
  }

  Future<void> updateStatus(
    String requestId,
    MasterRequestStatus status,
  ) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      final updated = await _repository.updateStatus(requestId, status);
      List<MasterWorkRequest> replace(List<MasterWorkRequest> requests) {
        return requests
            .map((request) => request.id == updated.id ? updated : request)
            .toList(growable: false);
      }

      emit(state.copyWith(
        clientRequests: replace(state.clientRequests),
        contractorRequests: replace(state.contractorRequests),
        saving: false,
      ));
    } catch (error) {
      emit(state.copyWith(saving: false, error: '$error'));
    }
  }
}
