from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class TaskPayload(BaseModel):
    model_config = ConfigDict(extra="forbid")

    issue_key: str = Field(min_length=2, max_length=64)
    repo: str = Field(min_length=1, max_length=128)
    summary: str = Field(min_length=1, max_length=300)
    description: str = Field(min_length=1, max_length=20000)


class TriggerResponse(BaseModel):
    status: str
    issue_key: str
    repo: str
    branch: str
    run_id: str
    message: str


class HealthResponse(BaseModel):
    status: str
