import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

//repo

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:your_app/models/user_model.dart';

part 'user_repository.g.dart';

@RestApi(baseUrl: "https://your-api-base-url.com")
abstract class UserRepository {
  factory UserRepository(Dio dio, {String baseUrl}) = _UserRepository;

  @GET("/users")
  Future<List<User>> getUsers();

  @GET("/users/{id}")
  Future<User> getUser(@Path("id") String id);

  @POST("/users")
  Future<User> createUser(@Body() User user);

  @PUT("/users/{id}")
  Future<User> updateUser(@Path("id") String id, @Body() User user);

  @DELETE("/users/{id}")
  Future<void> deleteUser(@Path("id") String id);
}

//notifier


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/models/user_state.dart';
import 'package:your_app/repositories/user_repository.dart';
import 'package:dio/dio.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.read(dioProvider);
  return UserRepository(dio);
});

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = ref.read(userRepositoryProvider);
  return UserNotifier(repository);
});

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repository;

  UserNotifier(this._repository) : super(const UserState()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(loading: true);
    try {
      final users = await _repository.getUsers();
      state = state.copyWith(users: users, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> addUser(User user) async {
    state = state.copyWith(loading: true);
    try {
      await _repository.createUser(user);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> updateUser(User user) async {
    state = state.copyWith(loading: true);
    try {
      await _repository.updateUser(user.id, user);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> deleteUser(String id) async {
    state = state.copyWith(loading: true);
    try {
      await _repository.deleteUser(id);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(loading: false);
    }
  }

  void selectUser(User user) {
    state = state.copyWith(selectedUser: user);
  }
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:your_app/providers/user_notifier.dart';

class UserList extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userNotifierProvider);
    final notifier = ref.read(userNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: state.loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  onTap: () {
                    notifier.selectUser(user);
                    Navigator.pushNamed(context, '/userDetails');
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/userForm');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:your_app/models/user_model.dart';
import 'package:your_app/providers/user_notifier.dart';

class UserForm extends HookConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(userNotifierProvider.notifier);
    final selectedUser = ref.watch(userNotifierProvider).selectedUser;

    if (selectedUser != null) {
      _nameController.text = selectedUser.name;
      _emailController.text = selectedUser.email;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedUser == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final user = User(
                      id: selectedUser?.id ?? '',
                      name: _nameController.text,
                      email: _emailController.text,
                    );
                    if (selectedUser == null) {
                      notifier.addUser(user);
                    } else {
                      notifier.updateUser(user);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(selectedUser == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:your_app/providers/user_notifier.dart';

class UserDetails extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userNotifierProvider);
    final notifier = ref.read(userNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              notifier.deleteUser(state.selectedUser!.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${state.selectedUser?.name ?? ''}'),
            SizedBox(height: 10),
            Text('Email: ${state.selectedUser?.email ?? ''}'),
          ],
        ),
      ),
    );
  }
}
