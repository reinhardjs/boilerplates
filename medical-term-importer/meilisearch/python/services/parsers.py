from typing import Dict, Any, Optional
from core.models import MeiliDocument

class Parser:
    def __init__(self, context: str, doc_type: str, delimiter: str):
        self.context = context
        self.doc_type = doc_type
        self.delimiter = delimiter
        self.column_map = self._get_column_map()

    def _get_column_map(self) -> Dict[str, int]:
        maps = {
            "snomed-ct-description": {
                "id": 0,
                "effectiveTime": 1,
                "active": 2,
                "moduleId": 3,
                "conceptId": 4,
                "languageCode": 5,
                "typeId": 6,
                "term": 7,
                "caseSignificanceId": 8
            },
            "icd-10-gm-code": {
                "level": 0,
                "isTerminal": 1,
                "codeType": 2,
                "chapterNumber": 3,
                "groupFrom": 4,
                "code": 5,
                "normalizedCode": 6,
                "codeNoDot": 7,
                "title": 8,
                "threeDigitTitle": 9,
                "fourDigitTitle": 10,
                "fiveDigitTitle": 11,
                "use295": 12,
                "use301": 13,
                "mortalityList1": 14,
                "mortalityList2": 15,
                "mortalityList3": 16,
                "mortalityList3": 17,
                "morbidityList": 18,
                "sexCode": 19,
                "sexErrorType": 20,
                "ageFrom": 21,
                "ageTo": 22,
                "ageErrorType": 23,
                "exotic": 24,
                "occupied": 25,
                "ifsgMeldung": 26,
                "ifsgLabor": 27,
            }
        }
        return maps.get(self.doc_type, {})

    def parse(self, line: str) -> Optional[MeiliDocument]:
        record = line.split(self.delimiter)
        if not record:
            return None

        metadata = {
            field: record[idx]
            for field, idx in self.column_map.items()
            if idx < len(record)
        }

        maps = {
            "snomed-ct-description": MeiliDocument(
                id=f"{self.doc_type}-{metadata.get('id')}-{metadata.get('effectiveTime')}",
                code=metadata.get('conceptId', ''),
                display=metadata.get('term', ''),
                context=self.context,
                metadata=metadata
            ),
            "icd-10-gm-code": MeiliDocument(
                id=f"{self.doc_type}-{metadata.get('codeNoDot')}",
                code=metadata.get('code', ''),
                display=metadata.get('title', ''),
                context=self.context,
                metadata=metadata
            ),
        }

        return maps.get(self.doc_type, {})
