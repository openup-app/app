import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_number_input.freezed.dart';

class PhoneInput extends StatefulWidget {
  final Color? color;
  final Color? hintTextColor;
  final void Function(String value, bool valid) onChanged;
  final void Function(String? error) onValidationError;
  const PhoneInput({
    super.key,
    this.color,
    this.hintTextColor,
    required this.onChanged,
    required this.onValidationError,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');
  _Country _country = usa;
  late final _countries = List.of(_unsortedCountries)
    ..sort((a, b) => a.name.compareTo(b.name));

  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: PopupMenuButton<_Country>(
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '+ ',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: widget.hintTextColor ??
                              const Color.fromRGBO(0x6C, 0x6C, 0x6C, 1.0),
                        ),
                  ),
                  TextSpan(
                    text: _country.callingCode.toString(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: widget.color ?? Colors.black,
                        ),
                  ),
                ],
              ),
            ),
            onSelected: (country) => setState(() => _country = country),
            itemBuilder: (context) {
              return [
                for (final country in _countries)
                  PopupMenuItem(
                    value: country,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: RichText(
                            textAlign: TextAlign.right,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '+ ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w400,
                                        color: const Color.fromRGBO(
                                            0x6C, 0x6C, 0x6C, 1.0),
                                      ),
                                ),
                                TextSpan(
                                  text: country.callingCode.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(country.flag),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            country.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: const Color.fromRGBO(
                                      0x6C, 0x6C, 0x6C, 1.0),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            onChanged: (_) {
              final error = _validatePhoneNoPrefix(_phoneController.text);
              widget.onValidationError(error);
              widget.onChanged(
                '+${_country.callingCode}${_phoneController.text}',
                error == null,
              );
            },
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
            },
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: widget.color ?? Colors.black,
                ),
            decoration: InputDecoration.collapsed(
              hintText: 'Phone Number',
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: widget.hintTextColor ??
                        const Color.fromRGBO(0x6C, 0x6C, 0x6C, 1.0),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  String? _validatePhoneNoPrefix(String? value) {
    if (value == null) {
      return 'Enter a phone number';
    }

    final phoneNumberWithPrefix = '+${_country.callingCode}$value';
    if (_phoneRegex.stringMatch(phoneNumberWithPrefix) ==
        phoneNumberWithPrefix) {
      return null;
    } else {
      return 'Invalid phone number';
    }
  }
}

@freezed
class _Country with _$_Country {
  const factory _Country({
    required int callingCode,
    required String flag,
    required String countryCode,
    required String name,
  }) = __Country;
}

const usa = __Country(
  callingCode: 1,
  flag: "🇺🇸",
  countryCode: "US",
  name: "United States",
);

// List of countries taken from https://46elks.com/kb/country-codes
// Some inaccuracies (ex. Svalbard and Jan Mayen use no flag, not Norwegian flag, see: https://flaglog.com/country-codes)
// Some official names shortened
// Countries removed: North Korea (DPRK)
const _unsortedCountries = [
  _Country(
    callingCode: 1,
    flag: "🇨🇦",
    countryCode: "CA",
    name: "Canada",
  ),
  _Country(
    callingCode: 1,
    flag: "🇺🇸",
    countryCode: "US",
    name: "United States",
  ),
  _Country(
    callingCode: 1242,
    flag: "🇧🇸",
    countryCode: "BS",
    name: "Bahamas",
  ),
  _Country(
    callingCode: 1246,
    flag: "🇧🇧",
    countryCode: "BB",
    name: "Barbados",
  ),
  _Country(
    callingCode: 1264,
    flag: "🇦🇮",
    countryCode: "AI",
    name: "Anguilla",
  ),
  _Country(
    callingCode: 1268,
    flag: "🇦🇬",
    countryCode: "AG",
    name: "Antigua and Barbuda",
  ),
  _Country(
    callingCode: 1284,
    flag: "🇻🇬",
    countryCode: "VG",
    name: "British Virgin Islands",
  ),
  _Country(
    callingCode: 1441,
    flag: "🇧🇲",
    countryCode: "BM",
    name: "Bermuda",
  ),
  _Country(
    callingCode: 1473,
    flag: "🇬🇩",
    countryCode: "GD",
    name: "Grenada",
  ),
  _Country(
    callingCode: 1649,
    flag: "🇹🇨",
    countryCode: "TC",
    name: "Turks and Caicos Islands",
  ),
  _Country(
    callingCode: 1664,
    flag: "🇲🇸",
    countryCode: "MS",
    name: "Montserrat",
  ),
  _Country(
    callingCode: 1670,
    flag: "🇲🇵",
    countryCode: "MP",
    name: "Northern Mariana Islands",
  ),
  _Country(
    callingCode: 1671,
    flag: "🇬🇺",
    countryCode: "GU",
    name: "Guam",
  ),
  _Country(
    callingCode: 1684,
    flag: "🇦🇸",
    countryCode: "AS",
    name: "American Samoa",
  ),
  _Country(
    callingCode: 1758,
    flag: "🇱🇨",
    countryCode: "LC",
    name: "Saint Lucia",
  ),
  _Country(
    callingCode: 1767,
    flag: "🇩🇲",
    countryCode: "DM",
    name: "Dominica",
  ),
  _Country(
    callingCode: 1784,
    flag: "🇻🇨",
    countryCode: "VC",
    name: "Saint Vincent and the Grenadines",
  ),
  _Country(
    callingCode: 1849,
    flag: "🇩🇴",
    countryCode: "DO",
    name: "Dominican Republic",
  ),
  _Country(
    callingCode: 1868,
    flag: "🇹🇹",
    countryCode: "TT",
    name: "Trinidad and Tobago",
  ),
  _Country(
    callingCode: 1869,
    flag: "🇰🇳",
    countryCode: "KN",
    name: "Saint Kitts and Nevis",
  ),
  _Country(
    callingCode: 1876,
    flag: "🇯🇲",
    countryCode: "JM",
    name: "Jamaica",
  ),
  _Country(
    callingCode: 1939,
    flag: "🇵🇷",
    countryCode: "PR",
    name: "Puerto Rico",
  ),
  _Country(
    callingCode: 20,
    flag: "🇪🇬",
    countryCode: "EG",
    name: "Egypt",
  ),
  _Country(
    callingCode: 211,
    flag: "🇸🇸",
    countryCode: "SS",
    name: "South Sudan",
  ),
  _Country(
    callingCode: 212,
    flag: "🇲🇦",
    countryCode: "MA",
    name: "Morocco",
  ),
  _Country(
    callingCode: 213,
    flag: "🇩🇿",
    countryCode: "DZ",
    name: "Algeria",
  ),
  _Country(
    callingCode: 216,
    flag: "🇹🇳",
    countryCode: "TN",
    name: "Tunisia",
  ),
  _Country(
    callingCode: 218,
    flag: "🇱🇾",
    countryCode: "LY",
    name: "Libya",
  ),
  _Country(
    callingCode: 220,
    flag: "🇬🇲",
    countryCode: "GM",
    name: "Gambia",
  ),
  _Country(
    callingCode: 221,
    flag: "🇸🇳",
    countryCode: "SN",
    name: "Senegal",
  ),
  _Country(
    callingCode: 222,
    flag: "🇲🇷",
    countryCode: "MR",
    name: "Mauritania",
  ),
  _Country(
    callingCode: 223,
    flag: "🇲🇱",
    countryCode: "ML",
    name: "Mali",
  ),
  _Country(
    callingCode: 224,
    flag: "🇬🇳",
    countryCode: "GN",
    name: "Guinea",
  ),
  _Country(
    callingCode: 225,
    flag: "🇨🇮",
    countryCode: "CI",
    name: "Cote d'Ivoire",
  ),
  _Country(
    callingCode: 226,
    flag: "🇧🇫",
    countryCode: "BF",
    name: "Burkina Faso",
  ),
  _Country(
    callingCode: 227,
    flag: "🇳🇪",
    countryCode: "NE",
    name: "Niger",
  ),
  _Country(
    callingCode: 228,
    flag: "🇹🇬",
    countryCode: "TG",
    name: "Togo",
  ),
  _Country(
    callingCode: 229,
    flag: "🇧🇯",
    countryCode: "BJ",
    name: "Benin",
  ),
  _Country(
    callingCode: 230,
    flag: "🇲🇺",
    countryCode: "MU",
    name: "Mauritius",
  ),
  _Country(
    callingCode: 231,
    flag: "🇱🇷",
    countryCode: "LR",
    name: "Liberia",
  ),
  _Country(
    callingCode: 232,
    flag: "🇸🇱",
    countryCode: "SL",
    name: "Sierra Leone",
  ),
  _Country(
    callingCode: 233,
    flag: "🇬🇭",
    countryCode: "GH",
    name: "Ghana",
  ),
  _Country(
    callingCode: 234,
    flag: "🇳🇬",
    countryCode: "NG",
    name: "Nigeria",
  ),
  _Country(
    callingCode: 235,
    flag: "🇹🇩",
    countryCode: "TD",
    name: "Chad",
  ),
  _Country(
    callingCode: 236,
    flag: "🇨🇫",
    countryCode: "CF",
    name: "Central African Republic",
  ),
  _Country(
    callingCode: 237,
    flag: "🇨🇲",
    countryCode: "CM",
    name: "Cameroon",
  ),
  _Country(
    callingCode: 238,
    flag: "🇨🇻",
    countryCode: "CV",
    name: "Cape Verde",
  ),
  _Country(
    callingCode: 239,
    flag: "🇸🇹",
    countryCode: "ST",
    name: "Sao Tome and Principe",
  ),
  _Country(
    callingCode: 240,
    flag: "🇬🇶",
    countryCode: "GQ",
    name: "Equatorial Guinea",
  ),
  _Country(
    callingCode: 241,
    flag: "🇬🇦",
    countryCode: "GA",
    name: "Gabon",
  ),
  _Country(
    callingCode: 242,
    flag: "🇨🇬",
    countryCode: "CG",
    name: "Congo",
  ),
  _Country(
    callingCode: 243,
    flag: "🇨🇩",
    countryCode: "CD",
    name: "Congo, The Democratic Republic of the Congo",
  ),
  _Country(
    callingCode: 244,
    flag: "🇦🇴",
    countryCode: "AO",
    name: "Angola",
  ),
  _Country(
    callingCode: 245,
    flag: "🇬🇼",
    countryCode: "GW",
    name: "Guinea-Bissau",
  ),
  _Country(
    callingCode: 246,
    flag: "🇮🇴",
    countryCode: "IO",
    name: "British Indian Ocean Territory",
  ),
  _Country(
    callingCode: 248,
    flag: "🇸🇨",
    countryCode: "SC",
    name: "Seychelles",
  ),
  _Country(
    callingCode: 249,
    flag: "🇸🇩",
    countryCode: "SD",
    name: "Sudan",
  ),
  _Country(
    callingCode: 250,
    flag: "🇷🇼",
    countryCode: "RW",
    name: "Rwanda",
  ),
  _Country(
    callingCode: 251,
    flag: "🇪🇹",
    countryCode: "ET",
    name: "Ethiopia",
  ),
  _Country(
    callingCode: 252,
    flag: "🇸🇴",
    countryCode: "SO",
    name: "Somalia",
  ),
  _Country(
    callingCode: 253,
    flag: "🇩🇯",
    countryCode: "DJ",
    name: "Djibouti",
  ),
  _Country(
    callingCode: 254,
    flag: "🇰🇪",
    countryCode: "KE",
    name: "Kenya",
  ),
  _Country(
    callingCode: 255,
    flag: "🇹🇿",
    countryCode: "TZ",
    name: "Tanzania, United Republic of Tanzania",
  ),
  _Country(
    callingCode: 256,
    flag: "🇺🇬",
    countryCode: "UG",
    name: "Uganda",
  ),
  _Country(
    callingCode: 1340,
    flag: "🇻🇮",
    countryCode: "VI",
    name: "U.S. Virgin Islands",
  ),
  _Country(
    callingCode: 257,
    flag: "🇧🇮",
    countryCode: "BI",
    name: "Burundi",
  ),
  _Country(
    callingCode: 258,
    flag: "🇲🇿",
    countryCode: "MZ",
    name: "Mozambique",
  ),
  _Country(
    callingCode: 260,
    flag: "🇿🇲",
    countryCode: "ZM",
    name: "Zambia",
  ),
  _Country(
    callingCode: 261,
    flag: "🇲🇬",
    countryCode: "MG",
    name: "Madagascar",
  ),
  _Country(
    callingCode: 262,
    flag: "🇹🇫",
    countryCode: "TF",
    name: "French Southern Territories",
  ),
  _Country(
    callingCode: 262,
    flag: "🇾🇹",
    countryCode: "YT",
    name: "Mayotte",
  ),
  _Country(
    callingCode: 262,
    flag: "🇷🇪",
    countryCode: "RE",
    name: "Reunion",
  ),
  _Country(
    callingCode: 263,
    flag: "🇿🇼",
    countryCode: "ZW",
    name: "Zimbabwe",
  ),
  _Country(
    callingCode: 264,
    flag: "🇳🇦",
    countryCode: "NA",
    name: "Namibia",
  ),
  _Country(
    callingCode: 265,
    flag: "🇲🇼",
    countryCode: "MW",
    name: "Malawi",
  ),
  _Country(
    callingCode: 266,
    flag: "🇱🇸",
    countryCode: "LS",
    name: "Lesotho",
  ),
  _Country(
    callingCode: 267,
    flag: "🇧🇼",
    countryCode: "BW",
    name: "Botswana",
  ),
  _Country(
    callingCode: 268,
    flag: "🇸🇿",
    countryCode: "SZ",
    name: "Swaziland",
  ),
  _Country(
    callingCode: 269,
    flag: "🇰🇲",
    countryCode: "KM",
    name: "Comoros",
  ),
  _Country(
    callingCode: 27,
    flag: "🇿🇦",
    countryCode: "ZA",
    name: "South Africa",
  ),
  _Country(
    callingCode: 290,
    flag: "🇸🇭",
    countryCode: "SH",
    name: "Saint Helena, Ascension and Tristan Da Cunha",
  ),
  _Country(
    callingCode: 291,
    flag: "🇪🇷",
    countryCode: "ER",
    name: "Eritrea",
  ),
  _Country(
    callingCode: 297,
    flag: "🇦🇼",
    countryCode: "AW",
    name: "Aruba",
  ),
  _Country(
    callingCode: 298,
    flag: "🇫🇴",
    countryCode: "FO",
    name: "Faroe Islands",
  ),
  _Country(
    callingCode: 299,
    flag: "🇬🇱",
    countryCode: "GL",
    name: "Greenland",
  ),
  _Country(
    callingCode: 30,
    flag: "🇬🇷",
    countryCode: "GR",
    name: "Greece",
  ),
  _Country(
    callingCode: 31,
    flag: "🇳🇱",
    countryCode: "NL",
    name: "Netherlands",
  ),
  _Country(
    callingCode: 32,
    flag: "🇧🇪",
    countryCode: "BE",
    name: "Belgium",
  ),
  _Country(
    callingCode: 33,
    flag: "🇫🇷",
    countryCode: "FR",
    name: "France",
  ),
  _Country(
    callingCode: 34,
    flag: "🇪🇸",
    countryCode: "ES",
    name: "Spain",
  ),
  _Country(
    callingCode: 345,
    flag: "🇰🇾",
    countryCode: "KY",
    name: "Cayman Islands",
  ),
  _Country(
    callingCode: 350,
    flag: "🇬🇮",
    countryCode: "GI",
    name: "Gibraltar",
  ),
  _Country(
    callingCode: 351,
    flag: "🇵🇹",
    countryCode: "PT",
    name: "Portugal",
  ),
  _Country(
    callingCode: 352,
    flag: "🇱🇺",
    countryCode: "LU",
    name: "Luxembourg",
  ),
  _Country(
    callingCode: 353,
    flag: "🇮🇪",
    countryCode: "IE",
    name: "Ireland",
  ),
  _Country(
    callingCode: 354,
    flag: "🇮🇸",
    countryCode: "IS",
    name: "Iceland",
  ),
  _Country(
    callingCode: 355,
    flag: "🇦🇱",
    countryCode: "AL",
    name: "Albania",
  ),
  _Country(
    callingCode: 356,
    flag: "🇲🇹",
    countryCode: "MT",
    name: "Malta",
  ),
  _Country(
    callingCode: 357,
    flag: "🇨🇾",
    countryCode: "CY",
    name: "Cyprus",
  ),
  _Country(
    callingCode: 358,
    flag: "🇦🇽",
    countryCode: "AX",
    name: "Åland Islands",
  ),
  _Country(
    callingCode: 358,
    flag: "🇫🇮",
    countryCode: "FI",
    name: "Finland",
  ),
  _Country(
    callingCode: 359,
    flag: "🇧🇬",
    countryCode: "BG",
    name: "Bulgaria",
  ),
  _Country(
    callingCode: 36,
    flag: "🇭🇺",
    countryCode: "HU",
    name: "Hungary",
  ),
  _Country(
    callingCode: 370,
    flag: "🇱🇹",
    countryCode: "LT",
    name: "Lithuania",
  ),
  _Country(
    callingCode: 371,
    flag: "🇱🇻",
    countryCode: "LV",
    name: "Latvia",
  ),
  _Country(
    callingCode: 372,
    flag: "🇪🇪",
    countryCode: "EE",
    name: "Estonia",
  ),
  _Country(
    callingCode: 373,
    flag: "🇲🇩",
    countryCode: "MD",
    name: "Moldova",
  ),
  _Country(
    callingCode: 374,
    flag: "🇦🇲",
    countryCode: "AM",
    name: "Armenia",
  ),
  _Country(
    callingCode: 375,
    flag: "🇧🇾",
    countryCode: "BY",
    name: "Belarus",
  ),
  _Country(
    callingCode: 376,
    flag: "🇦🇩",
    countryCode: "AD",
    name: "Andorra",
  ),
  _Country(
    callingCode: 377,
    flag: "🇲🇨",
    countryCode: "MC",
    name: "Monaco",
  ),
  _Country(
    callingCode: 378,
    flag: "🇸🇲",
    countryCode: "SM",
    name: "San Marino",
  ),
  _Country(
    callingCode: 379,
    flag: "🇻🇦",
    countryCode: "VA",
    name: "Holy See (Vatican City State)",
  ),
  _Country(
    callingCode: 380,
    flag: "🇺🇦",
    countryCode: "UA",
    name: "Ukraine",
  ),
  _Country(
    callingCode: 381,
    flag: "🇷🇸",
    countryCode: "RS",
    name: "Serbia",
  ),
  _Country(
    callingCode: 382,
    flag: "🇲🇪",
    countryCode: "ME",
    name: "Montenegro",
  ),
  _Country(
    callingCode: 383,
    flag: "🇽🇰",
    countryCode: "XK",
    name: "Kosovo",
  ),
  _Country(
    callingCode: 385,
    flag: "🇭🇷",
    countryCode: "HR",
    name: "Croatia",
  ),
  _Country(
    callingCode: 386,
    flag: "🇸🇮",
    countryCode: "SI",
    name: "Slovenia",
  ),
  _Country(
    callingCode: 387,
    flag: "🇧🇦",
    countryCode: "BA",
    name: "Bosnia and Herzegovina",
  ),
  _Country(
    callingCode: 389,
    flag: "🇲🇰",
    countryCode: "MK",
    name: "North Macedonia",
  ),
  _Country(
    callingCode: 39,
    flag: "🇮🇹",
    countryCode: "IT",
    name: "Italy",
  ),
  _Country(
    callingCode: 40,
    flag: "🇷🇴",
    countryCode: "RO",
    name: "Romania",
  ),
  _Country(
    callingCode: 41,
    flag: "🇨🇭",
    countryCode: "CH",
    name: "Switzerland",
  ),
  _Country(
    callingCode: 420,
    flag: "🇨🇿",
    countryCode: "CZ",
    name: "Czech Republic",
  ),
  _Country(
    callingCode: 421,
    flag: "🇸🇰",
    countryCode: "SK",
    name: "Slovakia",
  ),
  _Country(
    callingCode: 423,
    flag: "🇱🇮",
    countryCode: "LI",
    name: "Liechtenstein",
  ),
  _Country(
    callingCode: 43,
    flag: "🇦🇹",
    countryCode: "AT",
    name: "Austria",
  ),
  _Country(
    callingCode: 44,
    flag: "🇬🇬",
    countryCode: "GG",
    name: "Guernsey",
  ),
  _Country(
    callingCode: 44,
    flag: "🇮🇲",
    countryCode: "IM",
    name: "Isle of Man",
  ),
  _Country(
    callingCode: 44,
    flag: "🇯🇪",
    countryCode: "JE",
    name: "Jersey",
  ),
  _Country(
    callingCode: 44,
    flag: "🇬🇧",
    countryCode: "GB",
    name: "United Kingdom",
  ),
  _Country(
    callingCode: 45,
    flag: "🇩🇰",
    countryCode: "DK",
    name: "Denmark",
  ),
  _Country(
    callingCode: 46,
    flag: "🇸🇪",
    countryCode: "SE",
    name: "Sweden",
  ),
  _Country(
    callingCode: 47,
    flag: "🇧🇻",
    countryCode: "BV",
    name: "Bouvet Island",
  ),
  _Country(
    callingCode: 47,
    flag: "🇳🇴",
    countryCode: "NO",
    name: "Norway",
  ),
  _Country(
    callingCode: 47,
    flag: "🇸🇯",
    countryCode: "SJ",
    name: "Svalbard and Jan Mayen",
  ),
  _Country(
    callingCode: 48,
    flag: "🇵🇱",
    countryCode: "PL",
    name: "Poland",
  ),
  _Country(
    callingCode: 49,
    flag: "🇩🇪",
    countryCode: "DE",
    name: "Germany",
  ),
  _Country(
    callingCode: 500,
    flag: "🇫🇰",
    countryCode: "FK",
    name: "Falkland Islands (Malvinas)",
  ),
  _Country(
    callingCode: 500,
    flag: "🇬🇸",
    countryCode: "GS",
    name: "South Georgia and the South Sandwich Islands",
  ),
  _Country(
    callingCode: 501,
    flag: "🇧🇿",
    countryCode: "BZ",
    name: "Belize",
  ),
  _Country(
    callingCode: 502,
    flag: "🇬🇹",
    countryCode: "GT",
    name: "Guatemala",
  ),
  _Country(
    callingCode: 503,
    flag: "🇸🇻",
    countryCode: "SV",
    name: "El Salvador",
  ),
  _Country(
    callingCode: 504,
    flag: "🇭🇳",
    countryCode: "HN",
    name: "Honduras",
  ),
  _Country(
    callingCode: 505,
    flag: "🇳🇮",
    countryCode: "NI",
    name: "Nicaragua",
  ),
  _Country(
    callingCode: 506,
    flag: "🇨🇷",
    countryCode: "CR",
    name: "Costa Rica",
  ),
  _Country(
    callingCode: 507,
    flag: "🇵🇦",
    countryCode: "PA",
    name: "Panama",
  ),
  _Country(
    callingCode: 508,
    flag: "🇵🇲",
    countryCode: "PM",
    name: "Saint Pierre and Miquelon",
  ),
  _Country(
    callingCode: 509,
    flag: "🇭🇹",
    countryCode: "HT",
    name: "Haiti",
  ),
  _Country(
    callingCode: 51,
    flag: "🇵🇪",
    countryCode: "PE",
    name: "Peru",
  ),
  _Country(
    callingCode: 52,
    flag: "🇲🇽",
    countryCode: "MX",
    name: "Mexico",
  ),
  _Country(
    callingCode: 53,
    flag: "🇨🇺",
    countryCode: "CU",
    name: "Cuba",
  ),
  _Country(
    callingCode: 54,
    flag: "🇦🇷",
    countryCode: "AR",
    name: "Argentina",
  ),
  _Country(
    callingCode: 55,
    flag: "🇧🇷",
    countryCode: "BR",
    name: "Brazil",
  ),
  _Country(
    callingCode: 56,
    flag: "🇨🇱",
    countryCode: "CL",
    name: "Chile",
  ),
  _Country(
    callingCode: 57,
    flag: "🇨🇴",
    countryCode: "CO",
    name: "Colombia",
  ),
  _Country(
    callingCode: 58,
    flag: "🇻🇪",
    countryCode: "VE",
    name: "Venezuela",
  ),
  _Country(
    callingCode: 590,
    flag: "🇬🇵",
    countryCode: "GP",
    name: "Guadeloupe",
  ),
  _Country(
    callingCode: 590,
    flag: "🇧🇱",
    countryCode: "BL",
    name: "Saint Barthelemy",
  ),
  _Country(
    callingCode: 590,
    flag: "🇲🇫",
    countryCode: "MF",
    name: "Saint Martin",
  ),
  _Country(
    callingCode: 591,
    flag: "🇧🇴",
    countryCode: "BO",
    name: "Bolivia",
  ),
  _Country(
    callingCode: 592,
    flag: "🇬🇾",
    countryCode: "GY",
    name: "Guyana",
  ),
  _Country(
    callingCode: 593,
    flag: "🇪🇨",
    countryCode: "EC",
    name: "Ecuador",
  ),
  _Country(
    callingCode: 594,
    flag: "🇬🇫",
    countryCode: "GF",
    name: "French Guiana",
  ),
  _Country(
    callingCode: 595,
    flag: "🇵🇾",
    countryCode: "PY",
    name: "Paraguay",
  ),
  _Country(
    callingCode: 596,
    flag: "🇲🇶",
    countryCode: "MQ",
    name: "Martinique",
  ),
  _Country(
    callingCode: 597,
    flag: "🇸🇷",
    countryCode: "SR",
    name: "Suriname",
  ),
  _Country(
    callingCode: 598,
    flag: "🇺🇾",
    countryCode: "UY",
    name: "Uruguay",
  ),
  _Country(
    callingCode: 599,
    flag: "",
    countryCode: "AN",
    name: "Netherlands Antilles",
  ),
  _Country(
    callingCode: 60,
    flag: "🇲🇾",
    countryCode: "MY",
    name: "Malaysia",
  ),
  _Country(
    callingCode: 61,
    flag: "🇦🇺",
    countryCode: "AU",
    name: "Australia",
  ),
  _Country(
    callingCode: 61,
    flag: "🇨🇽",
    countryCode: "CX",
    name: "Christmas Island",
  ),
  _Country(
    callingCode: 61,
    flag: "🇨🇨",
    countryCode: "CC",
    name: "Cocos (Keeling) Islands",
  ),
  _Country(
    callingCode: 62,
    flag: "🇮🇩",
    countryCode: "ID",
    name: "Indonesia",
  ),
  _Country(
    callingCode: 63,
    flag: "🇵🇭",
    countryCode: "PH",
    name: "Philippines",
  ),
  _Country(
    callingCode: 64,
    flag: "🇳🇿",
    countryCode: "NZ",
    name: "New Zealand",
  ),
  _Country(
    callingCode: 64,
    flag: "🇵🇳",
    countryCode: "PN",
    name: "Pitcairn",
  ),
  _Country(
    callingCode: 65,
    flag: "🇸🇬",
    countryCode: "SG",
    name: "Singapore",
  ),
  _Country(
    callingCode: 66,
    flag: "🇹🇭",
    countryCode: "TH",
    name: "Thailand",
  ),
  _Country(
    callingCode: 670,
    flag: "🇹🇱",
    countryCode: "TL",
    name: "Timor-Leste",
  ),
  _Country(
    callingCode: 672,
    flag: "🇦🇶",
    countryCode: "AQ",
    name: "Antarctica",
  ),
  _Country(
    callingCode: 672,
    flag: "🇭🇲",
    countryCode: "HM",
    name: "Heard Island and Mcdonald Islands",
  ),
  _Country(
    callingCode: 672,
    flag: "🇳🇫",
    countryCode: "NF",
    name: "Norfolk Island",
  ),
  _Country(
    callingCode: 673,
    flag: "🇧🇳",
    countryCode: "BN",
    name: "Brunei Darussalam",
  ),
  _Country(
    callingCode: 674,
    flag: "🇳🇷",
    countryCode: "NR",
    name: "Nauru",
  ),
  _Country(
    callingCode: 675,
    flag: "🇵🇬",
    countryCode: "PG",
    name: "Papua New Guinea",
  ),
  _Country(
    callingCode: 676,
    flag: "🇹🇴",
    countryCode: "TO",
    name: "Tonga",
  ),
  _Country(
    callingCode: 677,
    flag: "🇸🇧",
    countryCode: "SB",
    name: "Solomon Islands",
  ),
  _Country(
    callingCode: 678,
    flag: "🇻🇺",
    countryCode: "VU",
    name: "Vanuatu",
  ),
  _Country(
    callingCode: 679,
    flag: "🇫🇯",
    countryCode: "FJ",
    name: "Fiji",
  ),
  _Country(
    callingCode: 680,
    flag: "🇵🇼",
    countryCode: "PW",
    name: "Palau",
  ),
  _Country(
    callingCode: 681,
    flag: "🇼🇫",
    countryCode: "WF",
    name: "Wallis and Futuna",
  ),
  _Country(
    callingCode: 682,
    flag: "🇨🇰",
    countryCode: "CK",
    name: "Cook Islands",
  ),
  _Country(
    callingCode: 683,
    flag: "🇳🇺",
    countryCode: "NU",
    name: "Niue",
  ),
  _Country(
    callingCode: 685,
    flag: "🇼🇸",
    countryCode: "WS",
    name: "Samoa",
  ),
  _Country(
    callingCode: 686,
    flag: "🇰🇮",
    countryCode: "KI",
    name: "Kiribati",
  ),
  _Country(
    callingCode: 687,
    flag: "🇳🇨",
    countryCode: "NC",
    name: "New Caledonia",
  ),
  _Country(
    callingCode: 688,
    flag: "🇹🇻",
    countryCode: "TV",
    name: "Tuvalu",
  ),
  _Country(
    callingCode: 689,
    flag: "🇵🇫",
    countryCode: "PF",
    name: "French Polynesia",
  ),
  _Country(
    callingCode: 690,
    flag: "🇹🇰",
    countryCode: "TK",
    name: "Tokelau",
  ),
  _Country(
    callingCode: 691,
    flag: "🇫🇲",
    countryCode: "FM",
    name: "Micronesia",
  ),
  _Country(
    callingCode: 692,
    flag: "🇲🇭",
    countryCode: "MH",
    name: "Marshall Islands",
  ),
  _Country(
    callingCode: 7,
    flag: "🇰🇿",
    countryCode: "KZ",
    name: "Kazakhstan",
  ),
  _Country(
    callingCode: 7,
    flag: "🇷🇺",
    countryCode: "RU",
    name: "Russia",
  ),
  _Country(
    callingCode: 81,
    flag: "🇯🇵",
    countryCode: "JP",
    name: "Japan",
  ),
  _Country(
    callingCode: 82,
    flag: "🇰🇷",
    countryCode: "KR",
    name: "Korea",
  ),
  _Country(
    callingCode: 84,
    flag: "🇻🇳",
    countryCode: "VN",
    name: "Vietnam",
  ),
  _Country(
    callingCode: 852,
    flag: "🇭🇰",
    countryCode: "HK",
    name: "Hong Kong",
  ),
  _Country(
    callingCode: 853,
    flag: "🇲🇴",
    countryCode: "MO",
    name: "Macao",
  ),
  _Country(
    callingCode: 855,
    flag: "🇰🇭",
    countryCode: "KH",
    name: "Cambodia",
  ),
  _Country(
    callingCode: 856,
    flag: "🇱🇦",
    countryCode: "LA",
    name: "Laos",
  ),
  _Country(
    callingCode: 86,
    flag: "🇨🇳",
    countryCode: "CN",
    name: "China",
  ),
  _Country(
    callingCode: 880,
    flag: "🇧🇩",
    countryCode: "BD",
    name: "Bangladesh",
  ),
  _Country(
    callingCode: 886,
    flag: "🇹🇼",
    countryCode: "TW",
    name: "Taiwan",
  ),
  _Country(
    callingCode: 90,
    flag: "🇹🇷",
    countryCode: "TR",
    name: "Türkiye",
  ),
  _Country(
    callingCode: 91,
    flag: "🇮🇳",
    countryCode: "IN",
    name: "India",
  ),
  _Country(
    callingCode: 92,
    flag: "🇵🇰",
    countryCode: "PK",
    name: "Pakistan",
  ),
  _Country(
    callingCode: 93,
    flag: "🇦🇫",
    countryCode: "AF",
    name: "Afghanistan",
  ),
  _Country(
    callingCode: 94,
    flag: "🇱🇰",
    countryCode: "LK",
    name: "Sri Lanka",
  ),
  _Country(
    callingCode: 95,
    flag: "🇲🇲",
    countryCode: "MM",
    name: "Myanmar",
  ),
  _Country(
    callingCode: 960,
    flag: "🇲🇻",
    countryCode: "MV",
    name: "Maldives",
  ),
  _Country(
    callingCode: 961,
    flag: "🇱🇧",
    countryCode: "LB",
    name: "Lebanon",
  ),
  _Country(
    callingCode: 962,
    flag: "🇯🇴",
    countryCode: "JO",
    name: "Jordan",
  ),
  _Country(
    callingCode: 963,
    flag: "🇸🇾",
    countryCode: "SY",
    name: "Syria",
  ),
  _Country(
    callingCode: 964,
    flag: "🇮🇶",
    countryCode: "IQ",
    name: "Iraq",
  ),
  _Country(
    callingCode: 965,
    flag: "🇰🇼",
    countryCode: "KW",
    name: "Kuwait",
  ),
  _Country(
    callingCode: 966,
    flag: "🇸🇦",
    countryCode: "SA",
    name: "Saudi Arabia",
  ),
  _Country(
    callingCode: 967,
    flag: "🇾🇪",
    countryCode: "YE",
    name: "Yemen",
  ),
  _Country(
    callingCode: 968,
    flag: "🇴🇲",
    countryCode: "OM",
    name: "Oman",
  ),
  _Country(
    callingCode: 970,
    flag: "🇵🇸",
    countryCode: "PS",
    name: "Palestine",
  ),
  _Country(
    callingCode: 971,
    flag: "🇦🇪",
    countryCode: "AE",
    name: "United Arab Emirates",
  ),
  _Country(
    callingCode: 972,
    flag: "🇮🇱",
    countryCode: "IL",
    name: "Israel",
  ),
  _Country(
    callingCode: 973,
    flag: "🇧🇭",
    countryCode: "BH",
    name: "Bahrain",
  ),
  _Country(
    callingCode: 974,
    flag: "🇶🇦",
    countryCode: "QA",
    name: "Qatar",
  ),
  _Country(
    callingCode: 975,
    flag: "🇧🇹",
    countryCode: "BT",
    name: "Bhutan",
  ),
  _Country(
    callingCode: 976,
    flag: "🇲🇳",
    countryCode: "MN",
    name: "Mongolia",
  ),
  _Country(
    callingCode: 977,
    flag: "🇳🇵",
    countryCode: "NP",
    name: "Nepal",
  ),
  _Country(
    callingCode: 98,
    flag: "🇮🇷",
    countryCode: "IR",
    name: "Iran",
  ),
  _Country(
    callingCode: 992,
    flag: "🇹🇯",
    countryCode: "TJ",
    name: "Tajikistan",
  ),
  _Country(
    callingCode: 993,
    flag: "🇹🇲",
    countryCode: "TM",
    name: "Turkmenistan",
  ),
  _Country(
    callingCode: 994,
    flag: "🇦🇿",
    countryCode: "AZ",
    name: "Azerbaijan",
  ),
  _Country(
    callingCode: 995,
    flag: "🇬🇪",
    countryCode: "GE",
    name: "Georgia",
  ),
  _Country(
    callingCode: 996,
    flag: "🇰🇬",
    countryCode: "KG",
    name: "Kyrgyzstan",
  ),
  _Country(
    callingCode: 998,
    flag: "🇺🇿",
    countryCode: "UZ",
    name: "Uzbekistan",
  ),
];
