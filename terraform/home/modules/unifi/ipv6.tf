## https://www.rfc-editor.org/rfc/rfc4890#page-14
## https://github.com/paultyng/go-unifi/blob/main/unifi/firewall_rule.generated.go#L38
##
resource "unifi_firewall_rule" "ipv6_allow_icmpv6_destination_unreachable" {
  name             = "IPv6 Allow ICMPv6 Destination Unreachable"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26000
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "destination-unreachable"
}

resource "unifi_firewall_rule" "ipv6_allow_icmpv6_packet_too_big" {
  name             = "IPv6 Allow ICMPv6 Packet Too Big"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26001
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "packet-too-big"
}

resource "unifi_firewall_rule" "ipv6_allow_icmpv6_time_exceeded" {
  name             = "IPv6 Allow ICMPv6 Time Exceeded"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26002
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "time-exceeded"
}

resource "unifi_firewall_rule" "ipv6_allow_icmpv6_parameter_problem" {
  name             = "IPv6 Allow ICMPv6 Parameter Problem"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26003
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "parameter-problem"
}

resource "unifi_firewall_rule" "ipv6_allow_icmpv6_echo_request" {
  name             = "IPv6 Allow ICMPv6 Echo Request"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26004
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "echo-request"
}

resource "unifi_firewall_rule" "ipv6_allow_icmpv6_echo_response" {
  name             = "IPv6 Allow ICMPv6 Echo Response"
  action           = "accept"
  ruleset          = "WANv6_IN"
  rule_index       = 26005
  protocol_v6      = "icmpv6"
  icmp_v6_typename = "echo-reply"
}
