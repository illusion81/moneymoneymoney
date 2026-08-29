import unittest
from fastapi.testclient import TestClient

import store
from main import app

VALID = {"session_id": "session-1", "question_version": "money-style-v1", "selected_answers": {"1": "q01_plan", "3": "q03_pause", "4": "q04_talk"}, "skipped_question_ids": [2, 5, 6, 7, 8, 9, 10, 11, 12], "answered_count": 3, "confidence_tier": "early_snapshot", "archetype_id": "steady_pause_collaborative"}

class MoneyStyleApiTest(unittest.TestCase):
    def setUp(self):
        store.reset()
        self.client = TestClient(app)

    def test_submission_does_not_create_financial_profile(self):
        self.assertEqual(self.client.post('/api/money-style', json=VALID).status_code, 200)
        self.assertEqual(self.client.get('/api/profile').status_code, 409)

    def test_round_trip(self):
        saved = self.client.post('/api/money-style', json=VALID).json()
        self.assertEqual(self.client.get('/api/money-style').json(), saved)

    def test_answer_count_must_match(self):
        invalid = {**VALID, 'answered_count': 12}
        self.assertEqual(self.client.post('/api/money-style', json=invalid).status_code, 422)
