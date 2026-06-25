import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_record.dart';
import '../../data/datasources/activity_record_datasource.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {}

class AddRecord extends HistoryEvent {
  final ActivityRecord record;
  AddRecord(this.record);
  @override
  List<Object?> get props => [record];
}

class UpdateRecord extends HistoryEvent {
  final ActivityRecord record;
  UpdateRecord(this.record);
  @override
  List<Object?> get props => [record];
}

class DeleteRecord extends HistoryEvent {
  final int id;
  DeleteRecord(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteAllRecords extends HistoryEvent {}

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<ActivityRecord> records;
  HistoryLoaded(this.records);
  @override
  List<Object?> get props => [records];
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ActivityRecordDataSource _dataSource;

  HistoryBloc({ActivityRecordDataSource? dataSource})
      : _dataSource = dataSource ?? ActivityRecordDataSource(),
        super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<AddRecord>(_onAddRecord);
    on<UpdateRecord>(_onUpdateRecord);
    on<DeleteRecord>(_onDeleteRecord);
    on<DeleteAllRecords>(_onDeleteAllRecords);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final records = await _dataSource.getAllRecords();
      emit(HistoryLoaded(records));
    } catch (e) {
      emit(HistoryError('Error al cargar historial: $e'));
    }
  }

  Future<void> _onAddRecord(
    AddRecord event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _dataSource.insertRecord(event.record);
      add(LoadHistory());
    } catch (e) {
      emit(HistoryError('Error al guardar registro: $e'));
    }
  }

  Future<void> _onUpdateRecord(
    UpdateRecord event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _dataSource.updateRecord(event.record);
      add(LoadHistory());
    } catch (e) {
      emit(HistoryError('Error al actualizar registro: $e'));
    }
  }

  Future<void> _onDeleteRecord(
    DeleteRecord event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _dataSource.deleteRecord(event.id);
      add(LoadHistory());
    } catch (e) {
      emit(HistoryError('Error al eliminar registro: $e'));
    }
  }

  Future<void> _onDeleteAllRecords(
    DeleteAllRecords event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _dataSource.deleteAllRecords();
      add(LoadHistory());
    } catch (e) {
      emit(HistoryError('Error al eliminar registros: $e'));
    }
  }
}
