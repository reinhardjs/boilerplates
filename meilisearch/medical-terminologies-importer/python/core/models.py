from pydantic import BaseModel
from typing import Dict, Any

class MeiliDocument(BaseModel):
    id: str
    code: str
    display: str
    context: str
    metadata: Dict[str, Any]
