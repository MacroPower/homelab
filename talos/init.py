import yaml
import subprocess

def iterate_and_print_yaml(yaml_content):
    def process_node(prefix, node):
        # If the node is a dictionary, iterate through its items
        if isinstance(node, dict):
            for key, value in node.items():
                new_prefix = f"{prefix}{key.upper()}_"
                process_node(new_prefix, value)
        else:
            # If the node is a value, print the key-value pair
            subprocess.run(["doppler", "-p", "talhelper", "-c", "main", "secrets", "set", f"{prefix[:-1]}={node}"])

    # Load YAML content into a Python object
    data = yaml.safe_load(yaml_content)

    # Start processing the YAML content
    process_node("", data)

# Example YAML content
yaml_content = subprocess.check_output(["talhelper", "gensecret"])

# Run the script
iterate_and_print_yaml(yaml_content)
