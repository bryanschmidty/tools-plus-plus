# JSON templates

## Behavior pack manifest

```json
{
  "format_version": 2,
  "header": {
    "name": "Tools++ Behavior Pack",
    "description": "Tools++ addon",
    "uuid": "48c0a12f-2012-4b7d-be80-2ff0eef48154",
    "version": [1, 0, 0],
    "min_engine_version": [1, 21, 0]
  },
  "modules": [
    {
      "type": "data",
      "uuid": "f5a02e35-689c-4ec4-89b8-67123ee69eeb",
      "version": [1, 0, 0]
    }
  ],
  "dependencies": [
    {
      "uuid": "eea31dcf-46f3-4013-808d-e457953cd5af",
      "version": [1, 0, 0]
    }
  ]
}
```

## Resource pack manifest

```json
{
  "format_version": 2,
  "header": {
    "name": "Tools++ Resource Pack",
    "description": "Tools++ addon",
    "uuid": "eea31dcf-46f3-4013-808d-e457953cd5af",
    "version": [1, 0, 0],
    "min_engine_version": [1, 21, 0]
  },
  "modules": [
    {
      "type": "resources",
      "uuid": "9c140079-5b53-4750-8f44-e7565c9d2a84",
      "version": [1, 0, 0]
    }
  ]
}
```

## Shaped recipe

```json
{
  "format_version": "1.20.10",
  "minecraft:recipe_shaped": {
    "description": {
      "identifier": "toolsplusplus:ruby_from_gems"
    },
    "tags": ["crafting_table"],
    "pattern": ["RDR", "RER", "RRR"],
    "key": {
      "R": { "item": "minecraft:redstone" },
      "D": { "item": "minecraft:diamond" },
      "E": { "item": "minecraft:emerald" }
    },
    "result": {
      "item": "toolsplusplus:ruby",
      "count": 1
    }
  }
}
```
