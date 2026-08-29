import unittest
from fastapi.testclient import TestClient

import store
from main import app

# A v2 session: 12 questions shown (the 6 fixed openers plus 6 adaptively
# routed follow-ups drawn from the 24-question pool), 3 of them answered.
VALID = {
    "session_id": "session-1",
    "question_version": "money-style-v2",
    "selected_answers": {"1": "rd_open_minimum", "3": "pa_open_upsell", "4": "sb_open_unused"},
    "skipped_question_ids": [2, 5, 6, 7, 10, 13, 16, 19, 22],
    "shown_question_ids": [1, 2, 3, 4, 5, 6, 7, 10, 13, 16, 19, 22],
    "answered_count": 3,
    "confidence_tier": "early_snapshot",
    "archetype_id": "watch_watch_watch",
}

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

    def test_shown_question_ids_are_stored(self):
        saved = self.client.post('/api/money-style', json=VALID).json()
        self.assertEqual(saved['shown_question_ids'], VALID['shown_question_ids'])

    def test_answer_count_must_match(self):
        invalid = {**VALID, 'answered_count': 12}
        self.assertEqual(self.client.post('/api/money-style', json=invalid).status_code, 422)

    def test_pool_question_ids_beyond_twelve_are_accepted(self):
        """Follow-up ids run to 24 now — only a session's length is capped at 12."""
        payload = {
            **VALID,
            'selected_answers': {"1": "rd_open_minimum", "24": "fa_mix_prompt"},
            'skipped_question_ids': [2, 3, 4, 5, 6, 7, 10, 13, 16, 19],
            'shown_question_ids': [1, 2, 3, 4, 5, 6, 7, 10, 13, 16, 19, 24],
            'answered_count': 2,
        }
        self.assertEqual(self.client.post('/api/money-style', json=payload).status_code, 200)

    def test_question_ids_outside_the_pool_are_rejected(self):
        invalid = {
            **VALID,
            'selected_answers': {"25": "not_a_question"},
            'skipped_question_ids': [],
            'shown_question_ids': [25],
            'answered_count': 1,
        }
        self.assertEqual(self.client.post('/api/money-style', json=invalid).status_code, 422)

    def test_a_session_cannot_show_more_than_twelve_questions(self):
        invalid = {**VALID, 'shown_question_ids': list(range(1, 14))}
        self.assertEqual(self.client.post('/api/money-style', json=invalid).status_code, 422)

    def test_answers_must_come_from_shown_questions(self):
        invalid = {**VALID, 'shown_question_ids': [2, 3, 4, 5, 6, 7, 10, 13, 16, 19, 22]}
        self.assertEqual(self.client.post('/api/money-style', json=invalid).status_code, 422)

    def test_a_pre_v2_payload_without_shown_ids_still_validates(self):
        payload = {k: v for k, v in VALID.items() if k != 'shown_question_ids'}
        response = self.client.post('/api/money-style', json=payload)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['shown_question_ids'], [])
