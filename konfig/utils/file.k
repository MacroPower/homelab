import yaml
import file

import filepath

current_dir = lambda current: str -> str {
    """Return an absolute path to the directory of current."""
    filepath.dir(current)
}

abs_path = lambda current: str, path: str -> str {
    """Return an absolute path to the file."""
    filepath.join([current_dir(current), path])
}

read_yaml = lambda current: str, path: str -> any {
    """Read YAML data from a file."""
    yaml.decode(file.read(abs_path(current, path)))
}
