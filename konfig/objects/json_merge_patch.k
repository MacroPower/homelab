import json_merge_patch as p

json_merge_patch = lambda a: any, b: any -> any {
    """
    `json_merge_patch` merges two JSON objects using a JSON Merge Patch.
    """
    p.merge(a, b)
}
