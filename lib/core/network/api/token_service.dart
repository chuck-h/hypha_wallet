import 'package:hypha_wallet/core/crypto/eos_models/eos_name.dart';
import 'package:hypha_wallet/core/crypto/eos_models/eos_symbol.dart';
import 'package:hypha_wallet/core/error_handler/model/hypha_error.dart';
import 'package:hypha_wallet/core/network/api/endpoints.dart';
import 'package:hypha_wallet/core/network/models/symbol_model.dart';
import 'package:hypha_wallet/core/network/models/token_model.dart';
import 'package:hypha_wallet/core/network/models/token_value.dart';
import 'package:hypha_wallet/core/network/networking_manager.dart';
import 'package:hypha_wallet/ui/architecture/result/result.dart';

class TokenSymbolScope {
  final String symbol;
  final String scope;
  final String tokenContract;
  TokenSymbolScope({required this.symbol, required this.scope, required this.tokenContract});
}

class TokenService {
  final NetworkingManager networkingManager;

  TokenService(this.networkingManager);

  Future<Result<TokenValue, HyphaError>> getTokenBalance({
    required String userAccount,
    required String tokenContract,
    required String symbol,
  }) async {
    try {
      final requestBody = '''
      { 
        "account": "$userAccount",
        "code": "$tokenContract",
        "symbol": "$symbol",
      }''';
      final res = await networkingManager.post(Endpoints.getCurrencyBalance, data: requestBody);
      final tokenString = res.data[0];
      return Result.value(TokenValue.fromString(tokenString, tokenContract));
    } catch (error) {
      return Result.error(HyphaError.fromError(error));
    }
  }

  Future<Result<List<TokenSymbolScope>, HyphaError>> getTokenSymbols({
    required String tokenContract,
  }) async {
    try {
      final requestBody = '''
      { 
        "code": "$tokenContract",
        "table": "stat",
        "lower_bound": "",
        "upper_bound": "",
        "limit": 1000,
        "reverse": false,
      }''';
      final res = await networkingManager.post(Endpoints.getTableScopes, data: requestBody);
      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(res.data['rows']);
      final tokenSymbolScopes = List<TokenSymbolScope>.from(list.map((e) {
        final scope = e['scope'];
        final eosName = EosName.from(scope);
        final eosSymbol = EosSymbol(eosName.value);
        return TokenSymbolScope(symbol: eosSymbol.toString(), scope: scope, tokenContract: tokenContract);
      }));
      return Result.value(tokenSymbolScopes);
    } catch (error) {
      print('Error getTokenSymbols $error');
      return Result.error(HyphaError.fromError(error));
    }
  }

  Future<Result<SymbolModel, HyphaError>> getCurrencySymbol({
    required String tokenContract,
    required String symbol,
  }) async {
    try {
      final requestBody = '''
      { 
        "json": true,
        "code": "$tokenContract",
        "symbol": "$symbol"
      }''';
      final res = await networkingManager.post(Endpoints.getCurrencyStats, data: requestBody);
      final json = res.data;
      // flutter: res: {HYPHA: {supply: 47738747.41 HYPHA, max_supply: -1.00 HYPHA, issuer: dao.hypha}}
      final symbolString = json[symbol]['max_supply'];
      final tokenModel = TokenModel.fromString(symbolString, tokenContract);
      return Result.value(tokenModel.symbol);
    } catch (error) {
      print('Error getTokenSymbols $error');
      return Result.error(HyphaError.fromError(error));
    }
  }
}
