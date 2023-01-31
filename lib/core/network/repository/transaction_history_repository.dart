import 'package:dio/dio.dart';
import 'package:hypha_wallet/core/error_handler/model/hypha_error.dart';
import 'package:hypha_wallet/core/network/api/transaction_history_service.dart';
import 'package:hypha_wallet/core/network/dio_exception.dart';
import 'package:hypha_wallet/core/network/models/transaction_model.dart';
import 'package:hypha_wallet/ui/architecture/result/result.dart';

class TransactionHistoryRepository {
  final TransactionHistoryService service;

  TransactionHistoryRepository({required this.service});

  Future<Result<List<TransactionModel>, HyphaError>> getTransactions(String userAccount) async {
    try {
      final Response response = await service.getTransactions(userAccount);
      final List<dynamic> transfers = response.data['actions'].toList();
      return Result.value(transfers.map((transfer) => TransactionModel.fromJson(transfer)).toList());
    } on DioError catch (e) {
      final errorMessage = DioExceptions.fromDioError(e).toString();
      return Result.error(HyphaError.api(errorMessage));
    }
  }
}