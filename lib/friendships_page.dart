import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class FriendshipsPage extends StatelessWidget {
  const FriendshipsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const SizedBox(height: 8),
        Text(
          'Growing Friendships',
          style: Theming.of(context).text.body,
        ),
        Container(
          height: 43,
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 33.0),
              child: Text(
                'Search',
                style: Theming.of(context).text.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color.fromRGBO(0x4A, 0x4A, 0x4A, 1.0)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            text: TextSpan(
              style: Theming.of(context).text.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
              children: [
                const TextSpan(text: 'To maintain '),
                TextSpan(
                  text: 'friendships ',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const TextSpan(text: 'on openup, you must talk to '),
                TextSpan(
                  text: 'each other ',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const TextSpan(
                    text:
                        'once every 72 hours. Not doing so will result in your friendship '),
                TextSpan(
                  text: 'falling apart (deleted)',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromRGBO(0xFF, 0x0, 0x0, 1.0),
                      ),
                ),
                const TextSpan(text: '. This app is for people who are '),
                TextSpan(
                  text: 'serious ',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const TextSpan(text: 'about making '),
                TextSpan(
                  text: 'friends',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Expanded(
          child: _ConversationList(),
        ),
      ],
    );
  }
}

class _ConversationList extends ConsumerStatefulWidget {
  const _ConversationList({Key? key}) : super(key: key);

  @override
  ConsumerState<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<_ConversationList> {
  bool _loading = true;
  var _chatrooms = <Chatroom>[];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;
    final result = await api.getChatrooms(uid);

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    result.fold(
      (l) {
        final message = errorToMessage(l);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      (r) => setState(() => _chatrooms = r),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_chatrooms.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Invite someone to chat,\nthen continue the conversation here',
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _fetchConversations();
                },
                child: Text('Refresh', style: Theming.of(context).text.body),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        itemCount: _chatrooms.length,
        separatorBuilder: (context, _) {
          return Container(
            height: 1,
            margin: const EdgeInsets.only(left: 99),
            color: const Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
          );
        },
        itemBuilder: (context, index) {
          final chatroom = _chatrooms[index];
          return Button(
            onPressed: () {
              Navigator.of(context).pushNamed(
                'chat',
                arguments: ChatPageArguments(
                  otherUid: chatroom.profile.uid,
                  otherProfile: chatroom.profile,
                  otherLocation: chatroom.location,
                  online: chatroom.online,
                  endTime: chatroom.endTime,
                ),
              );
            },
            child: SizedBox(
              height: 86,
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          if (chatroom.firstContact) {
                            return Text(
                              chatroom.firstContact ? 'new' : '',
                              style: Theming.of(context)
                                  .text
                                  .body
                                  .copyWith(fontWeight: FontWeight.w300),
                            );
                          } else if (chatroom.hasUnread) {
                            return Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ProfileImage(
                          chatroom.profile.photo,
                          blur: chatroom.profile.blurPhotos,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: chatroom.online
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chatroom.profile.name,
                          style: Theming.of(context).text.body,
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          chatroom.location,
                          maxFontSize: 16,
                          maxLines: 1,
                          style: Theming.of(context)
                              .text
                              .body
                              .copyWith(fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CountdownTimer(
                              endTime: chatroom.endTime,
                              onDone: () => setState(() =>
                                  _chatrooms.removeWhere((c) =>
                                      c.profile.uid == chatroom.profile.uid)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topicLabel(chatroom.topic),
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
