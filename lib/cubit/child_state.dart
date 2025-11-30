part of 'child_cubit.dart';

@immutable
abstract class ChildState extends Equatable {
  const ChildState();

  @override
  List<Object?> get props => [];
}

class ChildInitial extends ChildState {}

class ChildLoading extends ChildState {}

class ChildLoaded extends ChildState {
  final List<ChildModel> children;

  const ChildLoaded(this.children);

  @override
  List<Object?> get props => [children];
}

class ChildFailed extends ChildState {
  final String error;

  const ChildFailed(this.error);

  @override
  List<Object?> get props => [error];
}

class ChildAdded extends ChildState {
  final ChildModel child;

  const ChildAdded(this.child);

  @override
  List<Object> get props => [child];
}
