import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_form.dart';
import 'package:openup/widgets/theming.dart';

class AttributesScreen extends ConsumerStatefulWidget {
  final Attributes initialAttributes;

  const AttributesScreen({
    Key? key,
    required this.initialAttributes,
  }) : super(key: key);

  @override
  _AttributesScreenState createState() => _AttributesScreenState();
}

class _AttributesScreenState extends ConsumerState<AttributesScreen> {
  late Attributes _attributes;

  bool _uploading = false;
  int? _expandedSection;

  @override
  void initState() {
    super.initState();
    _attributes = widget.initialAttributes;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_expandedSection != null) {
          setState(() => _expandedSection = null);
        }
      },
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 24,
            child: const CloseButton(
              color: Colors.black,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + 32,
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Introduce yourself',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                        fontWeight: FontWeight.w400,
                        fontSize: 30,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Fill out the following information so others can find the real you',
                  textAlign: TextAlign.center,
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: ListView(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: AttributesForm(
                            attributes: _attributes,
                            onChanged: (attributes) {
                              setState(() => _attributes = attributes);
                            },
                            expandedSection: _expandedSection,
                            onExpansion: (index) =>
                                setState(() => _expandedSection = index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const MaleFemaleConnectionImageApart(),
                Button(
                  onPressed: () => _submit(context, ref),
                  child: Container(
                    height: 100,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(0xFF, 0xA1, 0xA1, 1.0),
                          Color.fromRGBO(0xFF, 0xCC, 0xCC, 1.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: _uploading
                        ? const CircularProgressIndicator()
                        : const Text('Complete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, WidgetRef ref) async {
    setState(() => _uploading = true);
    final userState = ref.read(userProvider);
    final api = GetIt.instance.get<Api>();
    final attributes = _attributes;
    final result = await api.updateAttributes(userState.uid, attributes);
    if (!mounted) {
      return;
    }
    setState(() => _uploading = false);
    result.fold(
      (l) => displayError(context, l),
      (r) {
        ref
            .read(userProvider.notifier)
            .update(userState.copyWith(attributes: attributes));
        Navigator.of(context).pop();
      },
    );
  }
}
