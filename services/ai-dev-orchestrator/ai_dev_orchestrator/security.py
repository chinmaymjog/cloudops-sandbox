from __future__ import annotations

from fastapi import Header, HTTPException, status


def verify_token(configured_token: str | None, provided_token: str | None) -> None:
    if not configured_token:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="ORCHESTRATOR_TOKEN is not configured",
        )

    if provided_token != configured_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid orchestrator token",
        )


async def require_orchestrator_token(
    x_orchestrator_token: str | None = Header(default=None),
) -> str | None:
    return x_orchestrator_token
