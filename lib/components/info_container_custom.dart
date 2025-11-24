import 'package:flutter/material.dart';

import '../theme/theme.dart';

class InfoContainerCustom extends StatefulWidget {
  final String title;
  final String desc;

  const InfoContainerCustom({
    super.key,
    required this.title,
    required this.desc,
  });

  @override
  State<InfoContainerCustom> createState() => _InfoContainerCustomState();
}

class _InfoContainerCustomState extends State<InfoContainerCustom> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSecondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
            child: InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: primaryTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8,),
                  AnimatedRotation(
                    duration: Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0.0,
                    child: Icon(Icons.expand_more, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                widget.desc,
                style: blackTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
        ],
      ),
    );
  }
}
