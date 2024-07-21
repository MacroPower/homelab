#!/bin/bash

# TODO: Convert to Task

helm schema
kcl import -m jsonschema values.schema.json --force
rm values.schema.json
