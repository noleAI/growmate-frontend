import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/behavioral_signal_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => <Object?>[];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading({this.previous});

  final UserProfile? previous;

  @override
  List<Object?> get props => <Object?>[previous];
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, {this.isSyncing = false});

  final UserProfile profile;
  final bool isSyncing;

  @override
  List<Object?> get props => <Object?>[profile, isSyncing];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message, {this.previous});

  final String message;
  final UserProfile? previous;

  @override
  List<Object?> get props => <Object?>[message, previous];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    SupabaseClient? supabaseClient,
    BehavioralSignalService? signalCollector,
  }) : _repository = repository,
       _supabaseClient = supabaseClient ?? _tryResolveSupabaseClient(),
       _signalCollector = signalCollector ?? BehavioralSignalService.instance,
       super(const ProfileInitial());

  final ProfileRepository _repository;
  final SupabaseClient? _supabaseClient;
  final BehavioralSignalService _signalCollector;

  StreamSubscription<UserProfile>? _profileSubscription;

  Future<void> loadProfile() async {
    final uid = _resolveUid();
    if (uid == null) {
      emit(
        const ProfileError(
          'Mình chưa nhận diện được tài khoản hiện tại. Bạn đăng nhập lại giúp mình nhé.',
        ),
      );
      return;
    }

    final previous = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : null;
    emit(ProfileLoading(previous: previous));

    try {
      final profile = await _repository.fetchProfile(uid);
      if (profile == null) {
        emit(
          const ProfileError(
            'Mình chưa tìm thấy hồ sơ của bạn. Thử tải lại giúp mình nhé.',
          ),
        );
        return;
      }

      _applyBehavioralConsent(profile.consentBehavioral);
      emit(ProfileLoaded(profile));

      await _profileSubscription?.cancel();
      _profileSubscription = _repository
          .profileStream(uid)
          .listen(
            (incoming) {
              _applyBehavioralConsent(incoming.consentBehavioral);
              emit(ProfileLoaded(incoming));
            },
            onError: (error) {
              final safeMessage = _friendlyError(error);
              final current = state is ProfileLoaded
                  ? (state as ProfileLoaded).profile
                  : previous;
              emit(ProfileError(safeMessage, previous: current));
            },
          );
    } catch (error) {
      emit(ProfileError(_friendlyError(error), previous: previous));
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : null;
    emit(ProfileLoading(previous: current));

    try {
      await _repository.updateProfile(profile);
      _applyBehavioralConsent(profile.consentBehavioral);
      emit(ProfileLoaded(profile));
    } catch (error) {
      emit(ProfileError(_friendlyError(error), previous: current));
    }
  }

  Future<void> toggleConsent({
    bool? consentBehavioral,
    bool? consentAnalytics,
  }) async {
    final current = _requireLoadedProfile();
    if (current == null) {
      emit(
        const ProfileError(
          'Mình chưa có dữ liệu hồ sơ để cập nhật. Bạn thử tải lại nhé.',
        ),
      );
      return;
    }

    final updated = current.copyWith(
      consentBehavioral: consentBehavioral ?? current.consentBehavioral,
      consentAnalytics: consentAnalytics ?? current.consentAnalytics,
      updatedAt: DateTime.now().toUtc(),
    );

    await updateProfile(updated);
  }

  Future<void> changeSubscription(String subscriptionTier) async {
    final current = _requireLoadedProfile();
    if (current == null) {
      emit(
        const ProfileError(
          'Mình chưa có dữ liệu hồ sơ để cập nhật gói. Bạn thử tải lại nhé.',
        ),
      );
      return;
    }

    final updated = current.copyWith(
      subscriptionTier: subscriptionTier,
      updatedAt: DateTime.now().toUtc(),
    );

    await updateProfile(updated);
  }

  UserProfile? _requireLoadedProfile() {
    if (state is ProfileLoaded) {
      return (state as ProfileLoaded).profile;
    }
    if (state is ProfileLoading) {
      return (state as ProfileLoading).previous;
    }
    if (state is ProfileError) {
      return (state as ProfileError).previous;
    }
    return null;
  }

  String? _resolveUid() {
    final uid = _supabaseClient?.auth.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }

    // Mock/offline fallback id for local development.
    return 'mock-user';
  }

  void _applyBehavioralConsent(bool consentBehavioral) {
    // Compliance: when consent is false, collector must stop emitting behavioral_signals.
    _signalCollector.setCollectionEnabled(consentBehavioral);
  }

  String _friendlyError(Object error) {
    if (error is ProfileRepositoryException) {
      return error.message;
    }

    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('row-level security')) {
        return 'Bạn chưa có quyền cập nhật mục này. Mình giữ dữ liệu an toàn cho bạn.';
      }
    }

    return 'Mình chưa xử lý được hồ sơ lúc này, bạn thử lại sau một chút nhé.';
  }

  @override
  Future<void> close() async {
    await _profileSubscription?.cancel();
    return super.close();
  }

  static SupabaseClient? _tryResolveSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
