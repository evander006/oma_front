import 'package:flutter_test/flutter_test.dart';
import 'package:oma/core/repositories/renovation_repository.dart';
import 'package:oma/features/projects/cubit/projects_cubit.dart';
import 'package:oma/shared/models/renovation_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ProjectsCubit creates, saves and submits draft', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalRenovationRepository(prefs);
    final cubit = ProjectsCubit(repo);

    await cubit.load();
    expect(cubit.state.items, isEmpty);

    final draft = await cubit.createDraft();
    expect(draft.status, RenovationProjectStatus.draft);
    expect(cubit.state.items, isNotEmpty);

    final updated = draft.copyWith(
      propertyKind: RenovationPropertyKind.apartment,
      areaSqm: 54,
      consentPersonalData: true,
      address: 'Минск',
      contactPhone: '+375291112233',
    );
    await cubit.save(updated);
    expect(cubit.state.items.first.areaSqm, 54);

    await cubit.submit(updated);
    expect(
      cubit.state.items.first.status,
      RenovationProjectStatus.submitted,
    );

    await cubit.delete(draft.id);
    expect(cubit.state.items, isEmpty);
  });
}
