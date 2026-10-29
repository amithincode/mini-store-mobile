import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/order_history_cubit.dart';

/// Returns the order history cubit when the surrounding route provides one.
OrderHistoryCubit? maybeOrderHistoryCubit(BuildContext context) {
  try {
    return BlocProvider.of<OrderHistoryCubit>(context, listen: false);
  } catch (_) {
    return null;
  }
}
