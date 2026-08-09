---
title: Pixel art guide
group: Guides
description: Trials like Loot's item shop icons come down to producing a batch of small, clean, consistent sprites, which is its own skill separate from just drawing.
---

# Pixel art guide

Trials like Loot's item shop icons come down to producing a batch of small, clean, consistent sprites, which is its own skill separate from just drawing.

## Picking a tool

Aseprite is the standard for this kind of work, it's built specifically for pixel art and animation, and it's cheap for what it does. Piskel is a solid free browser based alternative if you don't want to buy anything yet.

## Starting a sprite

Set your canvas small on purpose, something like 32x32 or 16x16 for icons. Working small forces you to make clean, deliberate choices instead of getting lost in detail that won't even read at that size.

## Keeping a consistent palette

Pick a small color palette before you start, somewhere around 8 to 16 colors, and stick to it across every sprite in the set. This is the single biggest thing that makes a batch of icons look like they belong together instead of like they were made on different days.

## Outlining and shading

A dark outline around the edge of each sprite helps it read clearly against different backgrounds. For shading, pick one light source direction and stay consistent, usually top left, and use it the same way on every sprite so the whole set feels like one lighting setup.

## Exporting the set

Export each sprite as a PNG at its native pixel size, don't scale it up in the export, scale it up with CSS or in whatever engine you're using instead so it stays crisp. If you're building a whole set, keep them in one folder with clear names like `potion_health.png`, `sword_iron.png`, that kind of thing.

## Building the storefront around them

Loot's trial also wants a website to show the icons off, so treat it as two halves: the sprite sheet itself, and a simple gallery style page that displays each icon with its name, similar in spirit to the HTML guide above. Remember art can only count for half your submitted time on this one, the website half matters just as much.
