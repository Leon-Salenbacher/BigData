"""Read Terraform inputs without evaluating configuration as shell code."""
import json
import re
import sys


def read_config(path):
    with open(path, encoding="utf-8-sig") as stream:
        config = json.load(stream)
    if not isinstance(config, dict):
        raise ValueError("Die Konfiguration muss ein JSON-Objekt sein.")
    values = []
    for key in ("project_id", "instance_name", "zone"):
        value = config.get(key)
        if not isinstance(value, str) or not re.fullmatch(r"[a-z][a-z0-9-]*", value):
            raise ValueError(f"{key} fehlt oder ist ungueltig.")
        values.append(value)
    return values


if __name__ == "__main__":
    try:
        print("\n".join(read_config(sys.argv[1])))
    except (OSError, ValueError, IndexError) as error:
        print(f"Terraform-Konfiguration konnte nicht gelesen werden: {error}", file=sys.stderr)
        sys.exit(1)
