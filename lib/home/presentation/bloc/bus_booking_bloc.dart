import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bus_booking_event.dart';
import 'bus_booking_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeStateInitial()) {
    on<NavigationEvent>(_onNavigation);
  }

  FutureOr<void> _onNavigation(
    NavigationEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(currentPageIndex: event.pageIndex));
  }
}