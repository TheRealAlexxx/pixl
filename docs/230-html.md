---
title: HTML guide
group: Guides
description: If you've never built a website before, this is the place to start.
---

# HTML guide

If you've never built a website before, this is the place to start. HTML is the skeleton of every website you'll ever see, it's what tells the browser "this is a heading, this is a paragraph, this is a button."

## Getting set up

You don't need anything fancy. Open VS Code, make a new folder for your project, and create a file called `index.html`. That's it, that's your website.

## The basics

Every HTML page starts with a bit of boilerplate:

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Site</title>
</head>
<body>
  <h1>Hello world</h1>
  <p>This is my first page.</p>
</body>
</html>
```

Save that file and open it in your browser. Congrats, you just built a website.

## A few tags worth knowing

- `<h1>` through `<h6>` for headings, biggest to smallest
- `<p>` for paragraphs
- `<a href="...">` for links
- `<img src="...">` for images
- `<button>` for buttons
- `<div>` for grouping stuff together

## Making it not look terrible

HTML alone gives you the structure but no style. That's what CSS is for. You can either put styles in a separate `style.css` file and link it, or just throw a `<style>` tag in the `<head>`. Something like:

```html
<style>
  body {
    font-family: sans-serif;
    background: #111;
    color: white;
  }
</style>
```

That alone already looks better than plain HTML.

## For a Zara style storefront trial

Think about what a real storefront needs: a header with the merchant's name, a list of items with images and prices, and a contact form at the bottom. Build it section by section instead of trying to do the whole page at once. Ship something simple and working before you try to make it fancy.
