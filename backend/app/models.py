from typing import Any, Literal
from pydantic import BaseModel, Field

Status = Literal["settled", "delayed", "failed", "mismatched", "unknown"]

class TimelineStage(BaseModel):
    stage: str
    status: str
    timestamp: str | None = None
    source: str
    raw_fields: dict[str, Any] = Field(default_factory=dict)

class ExceptionItem(BaseModel):
    field: str
    severity: Literal["info", "warning", "critical"]
    message: str

class TraceResult(BaseModel):
    transaction_id: str
    overall_status: Status
    confidence: float
    timeline: list[TimelineStage]
    explanation: str
    exceptions: list[ExceptionItem]
    generated_at: str

class TraceQuery(BaseModel):
    transaction_id: str | None = None
    date: str | None = None
