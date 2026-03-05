import 'dart:convert';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../domain/entities/invoice.dart';
import '../domain/entities/invoice_item.dart';
import 'invoice_helpers.dart';
import 'sanitize.dart';

const _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36';

const _specificationsUrl = 'https://suf.purs.gov.rs/specifications';

/// Parse a Serbian fiscal invoice URL.
///
/// Ports the Rust `parser::parse` function. Retries up to [maxAttempts] times
/// when the items API returns a transient error.
Future<Invoice> parseInvoice(String url, {int maxAttempts = 3}) async {
  final client = http.Client();
  try {
    Exception? lastErr;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      try {
        return await _tryParse(url, client);
      } on InvoiceParseException catch (e) {
        final msg = e.message;
        if (msg.contains('fetch items') ||
            msg.contains('token') ||
            msg.contains('Token')) {
          lastErr = e;
        } else {
          rethrow;
        }
      }
    }
    throw lastErr ?? InvoiceParseException('max attempts exhausted');
  } finally {
    client.close();
  }
}

Future<Invoice> _tryParse(String url, http.Client client) async {
  final response = await client.get(
    Uri.parse(url),
    headers: {'User-Agent': _userAgent},
  );
  if (response.statusCode != 200) {
    throw InvoiceParseException('HTTP ${response.statusCode} for $url');
  }
  final body = utf8.decode(response.bodyBytes);
  final doc = html_parser.parse(body);

  String sel(String selector) {
    final el = doc.querySelector(selector);
    if (el == null) throw InvoiceParseException('element not found: $selector');
    return el.text.trim();
  }

  final invoiceNumber = sel('#invoiceNumberLabel');
  final retailer = cyrillicToLatin(sel('#shopFullNameLabel'));
  final dateRaw = sel('#sdcDateTimeLabel');
  final priceRaw = sel('#totalAmountLabel');
  final rawBillText =
      doc.querySelector('#collapse3 > div > pre')?.text.trim() ?? '';

  final date = parseDate(dateRaw);
  final totalPrice = parsePrice(priceRaw);
  final token = _extractToken(body);
  final items = await _fetchItems(client, invoiceNumber, token);

  return Invoice(
    invoiceNumber: invoiceNumber,
    retailer: retailer,
    date: date,
    totalPrice: totalPrice,
    currency: 'RSD',
    country: 'serbia',
    url: url,
    rawBillText: rawBillText,
    items: IList(items),
  );
}

/// Extract the JWT-style view-model token from inline JS.
String _extractToken(String html) {
  const needle = "viewModel.Token('";
  for (final line in html.split('\n')) {
    final start = line.indexOf(needle);
    if (start < 0) continue;
    final rest = line.substring(start + needle.length);
    final end = rest.indexOf("');");
    if (end >= 0) return rest.substring(0, end);
  }
  throw InvoiceParseException('Token not found in page script');
}

Future<List<InvoiceItem>> _fetchItems(
  http.Client client,
  String invoiceNumber,
  String token,
) async {
  final body =
      'invoiceNumber=${percentEncode(invoiceNumber)}'
      '&token=${percentEncode(token)}';

  final response = await client.post(
    Uri.parse(_specificationsUrl),
    headers: {
      'User-Agent': _userAgent,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body,
  );

  if (response.statusCode != 200) {
    throw InvoiceParseException(
      'Failed to fetch items: HTTP ${response.statusCode}',
    );
  }

  final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  if (json['success'] != true) {
    throw InvoiceParseException('Failed to fetch invoice items');
  }

  final rawItems = json['items'] as List<dynamic>?;
  if (rawItems == null) {
    throw InvoiceParseException("Missing 'items' array in API response");
  }

  return rawItems.map((v) {
    final m = v as Map<String, dynamic>;
    return InvoiceItem(
      name: cyrillicToLatin(m['name'] as String? ?? ''),
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (m['total'] as num?)?.toDouble() ?? 0.0,
      gtin: m['gtin'] as String? ?? '',
      label: cyrillicToLatin(m['label'] as String? ?? ''),
      labelRate: (m['labelRate'] as num?)?.toDouble() ?? 0.0,
      taxBaseAmount: (m['taxBaseAmount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (m['vatAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();
}

class InvoiceParseException implements Exception {
  const InvoiceParseException(this.message);
  final String message;

  @override
  String toString() => 'InvoiceParseException: $message';
}
