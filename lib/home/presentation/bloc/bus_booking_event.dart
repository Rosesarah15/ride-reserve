import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

abstract class BusBookingEvent extends Equatable {
  const BusBookingEvent();

  @override
  List<Object> get props => [];
}

class NavigationEvent extends HomeEvent {
  final int pageIndex;

  const NavigationEvent(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
} 