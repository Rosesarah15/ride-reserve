import 'dart:async';

import 'package:ayinza_commons/bloc/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bus_booking_event.dart';
import 'bus_booking_state.dart';


class HomeBloc extends PageBloc<HomeEvent, HomeState> {

  HomeBloc() : super(HomeStateInitial()){
    on<NavigationEvent>(_onNavigation);
  }

  FutureOr<void> _onNavigation(NavigationEvent event, Emitter<HomeState> emit) async {
      emit(state.copyWith(currentPageIndex: event.pageIndex));
  }
}