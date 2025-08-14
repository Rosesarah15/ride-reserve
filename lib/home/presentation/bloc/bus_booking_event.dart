import 'package:ayinza_commons/bloc/page_event.dart';


class HomeEvent extends PageEvent {}

abstract class BusBookingEvent extends PageEvent {
  const BusBookingEvent();

  @override
  List<Object> get props => [];
}

class NavigationEvent extends HomeEvent {
  final int pageIndex;

 NavigationEvent (this.pageIndex);

} 