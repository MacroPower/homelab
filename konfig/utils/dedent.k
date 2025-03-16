import regex

# Copyright 2024 The KCL Authors.
# Modifications copyright 2025 Jacob Colvin.
# Licensed under the Apache License, Version 2.0.
# https://github.com/kcl-lang/modules/tree/main/outdent

dedent = lambda text: str {
    """
    `dedent` removes common leading whitespace from multi-line strings.
    """
    # Split the text into lines, preserving line endings
    lines = regex.split(text, "\r\n|\n")
    # Function to get leading whitespace
    get_leading_whitespace = lambda line: str {
        whitespace = regex.findall(line, "^\s+")
        whitespace[0] if whitespace else ""
    }
    # Find non-empty lines and their indentations
    non_empty_lines = [line for line in lines if line.strip()]
    indents = [get_leading_whitespace(line) for line in non_empty_lines]
    indentations = [len(get_leading_whitespace(line)) for line in non_empty_lines]
    # Find the minimum indentation
    min_indent = min([""] | indentations)
    # Remove the common indent and join the lines
    dedented_lines = [line[min_indent::] if line.strip() else line for line in lines]
    result = "\n".join(dedented_lines)
    # Trim leading and trailing blank lines
    regex.replace(result, r'^\s*\n|\n\s*$', '')
}
