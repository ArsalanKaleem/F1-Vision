import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/standings.dart';
import 'services/jolpica_service.dart';

/// Historical championship standings, sourced from Jolpica.
class StandingsRepository {
  StandingsRepository(this._jolpica);
  final JolpicaService _jolpica;

  Future<Result<List<DriverStanding>>> drivers(String season) =>
      _guard(() => _jolpica.driverStandings(season));

  Future<Result<List<ConstructorStanding>>> constructors(String season) =>
      _guard(() => _jolpica.constructorStandings(season));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
