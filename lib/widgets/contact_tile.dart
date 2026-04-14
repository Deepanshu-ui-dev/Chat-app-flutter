import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String about;
  final VoidCallback onTap;

  const ContactTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.about,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    about,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
