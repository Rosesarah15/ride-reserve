import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final int currentPageIndex;

  const HomeState({
    this.currentPageIndex = 0,
  });

  HomeState copyWith({
    int? currentPageIndex,
  }) {
    return HomeState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [currentPageIndex];
}

class HomeStateInitial extends HomeState {
  const HomeStateInitial() : super(currentPageIndex: 0);
}
