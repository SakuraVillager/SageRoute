import 'package:flutter/material.dart';

import '../models/article_record.dart';
import '../theme/color_schemes.dart';

/// Minimal reading surface for the initial `Article` model.
class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.article});

  final ArticleRecord article;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    appBar: AppBar(backgroundColor: AppColors.white),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.topic,
              style: const TextStyle(color: AppColors.brandDark),
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.brandInk,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
              ),
            ),
            if (article.summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                article.summary,
                style: const TextStyle(color: AppColors.sageMuted, height: 1.5),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              article.content.isEmpty ? '文章内容暂未提供。' : article.content,
              style: const TextStyle(
                color: AppColors.brandInk,
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
