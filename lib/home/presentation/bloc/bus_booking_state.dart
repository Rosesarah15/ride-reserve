import 'package:ayinza_commons/bloc/page_state.dart';



class HomeState extends PageState {
  final int currentPageIndex;
  const HomeState({
    this.currentPageIndex = 0,
    super.triggerComponentKey,
    super.triggerComponentValue,
  });

  HomeState copyWith({
    int? currentPageIndex,
    String? triggerComponentKey,
    String? triggerComponentValue,
  }) {
    return HomeState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      triggerComponentKey: triggerComponentKey ?? this.triggerComponentKey,
      triggerComponentValue:
          triggerComponentValue ?? this.triggerComponentValue,
    );
  }

  HomeState.fromPreviousState({required HomeState previousState})
    : this(
        currentPageIndex: previousState.currentPageIndex,
        triggerComponentKey: previousState.triggerComponentKey,
        triggerComponentValue: previousState.triggerComponentValue,
      );

  @override
  List<Object?> get props => [
    currentPageIndex,
    triggerComponentKey,
    triggerComponentValue,
  ];
}

class HomeStateInitial extends HomeState with FieldInitialState {}
