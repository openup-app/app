import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:pay/pay.dart';

class PayTest extends StatefulWidget {
  const PayTest({super.key});

  @override
  State<PayTest> createState() => _PayTestState();
}

class _PayTestState extends State<PayTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          center: Text('Pay Test'),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ApplePayButton(
              paymentConfiguration: PaymentConfiguration.fromJsonString(
                _applePayJsonConfigString(),
              ),
              paymentItems: const [
                PaymentItem(
                  label: 'Total',
                  amount: '19.99',
                  status: PaymentItemStatus.final_price,
                ),
              ],
              type: ApplePayButtonType.buy,
              onPaymentResult: _onApplePayResult,
              loadingIndicator: const LoadingIndicator(),
            ),
          ),
          Center(
            child: GooglePayButton(
              paymentConfiguration: PaymentConfiguration.fromJsonString(
                _googlePayJsonConfigString(),
              ),
              paymentItems: const [
                PaymentItem(
                  label: 'Total',
                  amount: '19.99',
                  status: PaymentItemStatus.final_price,
                ),
              ],
              type: GooglePayButtonType.pay,
              onPaymentResult: _onGooglePayResult,
              loadingIndicator: const LoadingIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  void _onApplePayResult(Map<String, dynamic> result) {
    print('#### Apple Pay Result');
    print(result);
  }

  void _onGooglePayResult(Map<String, dynamic> result) {
    print('#### Google Pay Result');
    print(result);
  }

  String _applePayJsonConfigString() {
    return '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.openupdating",
    "displayName": "Sam's Fish",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
    "countryCode": "US",
    "currencyCode": "USD",
    "requiredBillingContactFields": ["emailAddress", "name", "phoneNumber", "postalAddress"],
    "requiredShippingContactFields": [],
    "shippingMethods": [
      {
        "amount": "0.00",
        "detail": "Available within an hour",
        "identifier": "in_store_pickup",
        "label": "In-Store Pickup"
      },
      {
        "amount": "4.99",
        "detail": "5-8 Business Days",
        "identifier": "flat_rate_shipping_id_2",
        "label": "UPS Ground"
      },
      {
        "amount": "29.99",
        "detail": "1-3 Business Days",
        "identifier": "flat_rate_shipping_id_1",
        "label": "FedEx Priority Mail"
      }
    ]
  }
}''';
  }

  String _googlePayJsonConfigString() {
    return '''{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "gatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "Example Merchant Name"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}''';
  }
}
