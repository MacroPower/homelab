from __future__ import annotations

import asyncio

from hastate.live import read_live
from hastate.plan import plan


class FakeClient:
    ha_version = "2026.10.4"

    def __init__(self, replies: dict[str, object]) -> None:
        self.replies = replies
        self.calls: list[str] = []

    async def call(self, command: str, **fields: object) -> object:
        self.calls.append(command)
        return self.replies[command]


def test_unmanaged_floors_are_still_read_for_area_references():
    client = FakeClient({
        "config/label_registry/list": [],
        "config/floor_registry/list": [{"floor_id": "ground", "name": "Ground"}],
        "config/area_registry/list": [],
    })
    desired = {"format": 1, "prune": [], "areas": {"hall": {"name": "Hall", "floor_id": "ground", "labels": []}}}
    result = plan(desired, asyncio.run(read_live(client, desired)))
    assert result.problems == []
    assert "get_states" not in client.calls
