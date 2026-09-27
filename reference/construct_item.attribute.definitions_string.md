# Construct the Attribute Definitions Sentence for Prompts

Builds a single sentence listing the user-supplied definitions for the
given attributes, numbered in the order the attributes are listed.
Attributes without a definition are skipped.

## Usage

``` r
construct_item.attribute.definitions_string(
  attributes,
  item.attribute.definitions
)
```

## Arguments

- attributes:

  A character vector of (normalized) attributes for one item type.

- item.attribute.definitions:

  A validated named list of attribute definitions, or NULL.

## Value

A single string such as
`"Here are the precise definitions of some of these attributes in this context: (1) worry: <def>; (2) sadness: <def>."`,
or `""` if none of `attributes` has a definition.
