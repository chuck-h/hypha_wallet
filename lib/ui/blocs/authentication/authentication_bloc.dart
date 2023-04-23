import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hypha_wallet/core/local/models/user_auth_data.dart';
import 'package:hypha_wallet/core/local/services/secure_storage_service.dart';
import 'package:hypha_wallet/core/logging/log_helper.dart';
import 'package:hypha_wallet/core/network/models/user_profile_data.dart';
import 'package:hypha_wallet/core/network/repository/auth_repository.dart';
import 'package:hypha_wallet/core/shared_preferences/hypha_shared_prefs.dart';

part 'authentication_bloc.freezed.dart';
part 'authentication_event.dart';
part 'authentication_state.dart';

/// AuthenticationBloc will handle all Auth things in the app. Logout/Login/CreateAccount/Etc
/// This is to be used as a top level Bloc
class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository _authRepository;
  final HyphaSharedPrefs _appSharedPrefs;
  final SecureStorageService _secureStorageService;
  late StreamSubscription<AuthenticationStatus> _authenticationStatusSubscription;
  late StreamSubscription<UserProfileData?> _authSubscription;

  AuthenticationBloc(
    this._authRepository,
    this._appSharedPrefs,
    this._secureStorageService,
  ) : super(const AuthenticationState()) {
    on<_InitialAuthentication>(_initial);
    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<_AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
    on<_OnAuthenticatedDataChanged>(_onAuthenticatedDataChanged);
    _authenticationStatusSubscription = _authRepository.status.listen(
      (status) => add(AuthenticationEvent.authenticationStatusChanged(status)),
    );

    _authSubscription = _appSharedPrefs.watchProfile().listen((UserProfileData? profile) {
      if (profile != null) {
        add(AuthenticationEvent.onUserProfileDataChanged(profile));
      }
    });
  }

  @override
  Future<void> close() {
    _authenticationStatusSubscription.cancel();
    _authSubscription.cancel();
    return super.close();
  }

  FutureOr<void> _initial(_InitialAuthentication event, Emitter<AuthenticationState> emit) async {
    try {
      final userProfileData = await _appSharedPrefs.getUserProfileData();
      final authData = await _secureStorageService.getUserAuthData();
      if (userProfileData != null && authData != null) {
        emit(state.copyWith(
          authStatus: AuthenticationStatus.authenticated,
          userAuthData: authData,
          userProfileData: userProfileData,
        ));
      } else {
        emit(state.copyWith(authStatus: AuthenticationStatus.unauthenticated));
      }
    } catch (error, stacktrace) {
      LogHelper.e('Error during user sign-in status', error: error, stacktrace: stacktrace);
      emit(state.copyWith(authStatus: AuthenticationStatus.unauthenticated));
    }
  }

  void _onAuthenticationStatusChanged(
    _AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        return emit(state.copyWith(authStatus: AuthenticationStatus.unauthenticated));
      case AuthenticationStatus.authenticated:
        final profileData = await _appSharedPrefs.getUserProfileData();
        final authData = await _secureStorageService.getUserAuthData();
        if (profileData != null && authData != null) {
          return emit(
            state.copyWith(
              authStatus: AuthenticationStatus.authenticated,
              userProfileData: profileData,
              userAuthData: authData,
            ),
          );
        } else {
          return emit(state.copyWith(authStatus: AuthenticationStatus.unauthenticated));
        }
      case AuthenticationStatus.unknown:
        return emit(state.copyWith(authStatus: AuthenticationStatus.unknown));
    }
  }

  Future<void> _onAuthenticationLogoutRequested(
    _AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _authRepository.logOut();
  }

  FutureOr<void> _onAuthenticatedDataChanged(_OnAuthenticatedDataChanged event, Emitter<AuthenticationState> emit) {
    emit(state.copyWith(userProfileData: event.data));
  }
}
