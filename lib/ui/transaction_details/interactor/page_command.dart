part of 'transaction_details_bloc.dart';

@freezed
class PageCommand with _$PageCommand {
  const factory PageCommand.transactionCancelled() = _TransactionCancelled;
}