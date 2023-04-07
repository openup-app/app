import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/invite_friends.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _filterString = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_filterString != _searchController.text) {
        setState(() => _filterString = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/people_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Container(
                  height: 31,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0xD9, 0xD9, 0xD9, 0.1),
                    border: Border.all(),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: TextFormField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Search',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        if (_filterString.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Button(
                              onPressed: () {
                                setState(() => _searchController.text = "");
                                FocusScope.of(context).unfocus();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InviteFriends(
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: MediaQuery.of(context).padding.bottom + 72,
                    ),
                    filter: _filterString,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
