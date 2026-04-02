from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class RepoDefinition:
    clone_url: str
    default_branch: str = "main"


@dataclass(frozen=True)
class Settings:
    orchestrator_token: str | None
    repo_registry: dict[str, RepoDefinition]
    workspace_root: Path

    @classmethod
    def from_env(cls) -> "Settings":
        token = os.getenv("ORCHESTRATOR_TOKEN")
        workspace_root = Path(os.getenv("ORCHESTRATOR_WORK_ROOT", ".orchestrator")).resolve()
        parsed = json.loads(load_repo_registry_json())

        if not isinstance(parsed, dict):
            msg = "Allowed repo configuration must be a JSON object"
            raise ValueError(msg)

        repo_registry: dict[str, RepoDefinition] = {}
        for repo_key, repo_value in parsed.items():
            if isinstance(repo_value, str):
                repo_registry[repo_key] = RepoDefinition(clone_url=repo_value)
                continue

            if isinstance(repo_value, dict) and isinstance(repo_value.get("clone_url"), str):
                repo_registry[repo_key] = RepoDefinition(
                    clone_url=repo_value["clone_url"],
                    default_branch=repo_value.get("default_branch", "main"),
                )
                continue

            msg = f"Invalid repo definition for {repo_key!r}"
            raise ValueError(msg)

        return cls(
            orchestrator_token=token,
            repo_registry=repo_registry,
            workspace_root=workspace_root,
        )


def load_repo_registry_json() -> str:
    registry_file = os.getenv("ALLOWED_REPOS_FILE")
    if registry_file:
        return Path(registry_file).read_text(encoding="utf-8")
    return os.getenv("ALLOWED_REPOS_JSON", "{}")
