import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

sealed class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

final class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing({required this.itemCount, required this.total});

  final int itemCount;
  final double total;

  @override
  List<Object?> get props => [itemCount, total];
}

final class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

final class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
