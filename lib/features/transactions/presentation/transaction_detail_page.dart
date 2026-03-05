import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/transaction_ui_item.dart';

/// Displays all fields of a single transaction.
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({required this.item, super.key});

  final TransactionUiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Product name ───────────────────────────────────────────────
          Text(item.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(item.retailer, style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          )),
          const SizedBox(height: 16),

          // ── Price summary ──────────────────────────────────────────────
          _SectionCard(
            title: 'Price',
            children: [
              _DetailRow(label: 'Quantity', value: item.quantityLabel),
              _DetailRow(label: 'Unit price', value: item.unitPriceLabel),
              _DetailRow(
                label: 'Total',
                value: item.priceLabel,
                valueStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              _DetailRow(label: 'Currency', value: item.currency),
            ],
          ),

          // ── Location & time ────────────────────────────────────────────
          _SectionCard(
            title: 'Details',
            children: [
              _DetailRow(label: 'Date', value: item.dateLabel),
              _DetailRow(label: 'Country', value: item.country),
              _DetailRow(label: 'ID', value: item.id),
            ],
          ),

          // ── Tags ───────────────────────────────────────────────────────
          if (item.tags.isNotEmpty)
            _SectionCard(
              title: 'Tags',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: item.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ],
            ),

          // ── Notes ──────────────────────────────────────────────────────
          if (item.notes != null && item.notes!.isNotEmpty)
            _SectionCard(
              title: 'Notes',
              children: [
                Text(item.notes!, style: theme.textTheme.bodyMedium),
              ],
            ),

          // ── Link ───────────────────────────────────────────────────────
          if (item.link != null && item.link!.isNotEmpty)
            _SectionCard(
              title: 'Invoice link',
              children: [
                GestureDetector(
                  onTap: () => _copyToClipboard(context, item.link!),
                  child: Text(
                    item.link!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to copy',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),

          // ── Metadata ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Metadata',
            children: [
              _DetailRow(label: 'Last updated', value: item.updatedAtLabel),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
