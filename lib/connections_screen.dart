import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/loading_dialog.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<PublicProfile>? _connections;

  @override
  void initState() {
    super.initState();

    VoidCallback? popDialog;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      popDialog = showBlockingModalDialog(
        context: context,
        builder: (_) => const Loading(),
      );
    });

    final api = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    api.getConnections(uid).then((connections) {
      if (mounted) {
        setState(() => _connections = connections);
        popDialog?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connections = _connections;

    if (connections == null) {
      return const Center(
        child: Text('No Connections'),
      );
    }
    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return ListTile(
          leading: CircleAvatar(
            child: connection.photo != null
                ? Image.network(connection.photo!)
                : Image.asset('assets/images/profile.png'),
          ),
          title: Text(connection.name),
          subtitle: Text(connection.description),
        );
      },
    );
  }
}
