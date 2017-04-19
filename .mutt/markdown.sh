#!/usr/bin/env bash

#
# This script gets the contents of an email from stdin, cuts the signature off,
# and then  uses the `cmark` utility to convert the body and signature into
# HTML. The signature is processed separately and with the `--hardbreaks`
# parameter passed to `cmark` to ensure that non-HTML signatures show up
# correctly after being converted to HTML; otherwise, sections of the signature
# would flow onto a single line in the reader's mail client.
#
# Note that after processing, the signature has a horizontal rule prepended to
# it.
#
body=$(cat /dev/stdin)
sig=$(echo "$body" | tac | sed '/^-- $/q' | tac | tail -n +2)
echo "$body" | head -n -$(echo "$sig" | wc -l) | tac | tail -n +2 | tac | cmark -t html --validate-utf8
echo -e "----\n$sig" | cmark -t html --validate-utf8 --hardbreaks
