# Embedded Fonts

This directory contains embedded font files for PDF generation. These are used as a fallback when the external fonts in the assets/fonts directory are not available or not working properly.

The fonts are embedded as byte arrays in the Dart code to ensure they are always available, regardless of external file availability.