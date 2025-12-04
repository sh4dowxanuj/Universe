/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, SH4DOWXANUJ
 */

import 'dart:io';

import 'package:blackhole/Models/image_quality.dart';
import 'package:blackhole/Models/url_image_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget imageCard({
  required String imageUrl,
  bool localImage = false,
  double elevation = 0,
  EdgeInsetsGeometry margin = EdgeInsets.zero,
  double borderRadius = 12.0,
  double? boxDimension = 55.0,
  ImageProvider placeholderImage = const AssetImage(
    'assets/cover.jpg',
  ),
  bool selected = false,
  ImageQuality imageQuality = ImageQuality.low,
  Function(Object, StackTrace?)? localErrorFunction,
}) {
  return Container(
    margin: margin,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: elevation > 0
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: elevation * 2,
                offset: Offset(0, elevation / 2),
              ),
            ]
          : null,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: boxDimension,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (localImage || imageUrl == '')
              Image(
                fit: BoxFit.cover,
                errorBuilder: (context, error, stacktrace) {
                  if (localErrorFunction != null) {
                    localErrorFunction(error, stacktrace);
                  }
                  return Image(
                    fit: BoxFit.cover,
                    image: placeholderImage,
                  );
                },
                image: FileImage(
                  File(
                    imageUrl,
                  ),
                ),
              )
            else
              CachedNetworkImage(
                fit: BoxFit.cover,
                errorWidget: (context, _, __) => Image(
                  fit: BoxFit.cover,
                  image: placeholderImage,
                ),
                imageUrl:
                    UrlImageGetter([imageUrl]).getImageUrl(quality: imageQuality),
                placeholder: (context, url) => Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: Image(
                    fit: BoxFit.cover,
                    image: placeholderImage,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                ),
              ),
            if (selected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
