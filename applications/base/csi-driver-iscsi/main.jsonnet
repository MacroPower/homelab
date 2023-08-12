// jsonnet base/csi-driver-iscsi/main.jsonnet -J vendor

std.parseYaml(importstr 'csi-iscsi-driverinfo.yaml')
+ std.parseYaml(importstr 'csi-iscsi-node.yaml')
