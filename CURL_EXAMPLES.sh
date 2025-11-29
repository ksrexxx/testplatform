#!/bin/bash
# Примеры curl запросов для тестирования API

BASE_URL="http://localhost:8000"

echo "=== Exam Platform Backend - API Test Commands ==="
echo ""

# 1. Health Check
echo "1. Health Check"
echo "curl ${BASE_URL}/health"
echo ""

# 2. Register Admin (if not exists)
echo "2. Register Admin User"
echo 'curl -X POST ${BASE_URL}/api/v1/auth/register \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "email": "admin@exam.kz",
    "password": "admin123456",
    "full_name": "System Administrator",
    "role": "admin"
  }'"'"
echo ""

# 3. Login as Admin
echo "3. Login as Admin"
echo 'curl -X POST ${BASE_URL}/api/v1/auth/login \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "email": "admin@exam.kz",
    "password": "admin123456"
  }'"'"' | jq -r .access_token'
echo ""
echo "# Save token:"
echo 'ADMIN_TOKEN=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login -H "Content-Type: application/json" -d '"'"'{"email": "admin@exam.kz", "password": "admin123456"}'"'"' | jq -r .access_token)'
echo ""

# 4. Upload Question Bank
echo "4. Upload Question Bank"
echo 'curl -X POST ${BASE_URL}/api/v1/admin/banks/upload \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN" \'
echo '  -F "file=@sample_bank.xlsx"'
echo ""
echo "# Save task ID:"
echo 'TASK_ID=$(curl -s -X POST ${BASE_URL}/api/v1/admin/banks/upload -H "Authorization: Bearer $ADMIN_TOKEN" -F "file=@sample_bank.xlsx" | jq -r .task_id)'
echo ""

# 5. Check Task Status
echo "5. Check Import Task Status"
echo 'curl ${BASE_URL}/api/v1/admin/banks/task/$TASK_ID \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN"'
echo ""

# 6. List Banks
echo "6. List Question Banks"
echo 'curl ${BASE_URL}/api/v1/admin/banks \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN"'
echo ""

# 7. Publish Bank
echo "7. Publish Question Bank"
echo 'curl -X POST ${BASE_URL}/api/v1/admin/banks/publish \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"bank_id": 1}'"'"
echo ""

# 8. Get Specialties
echo "8. Get Specialties"
echo 'curl ${BASE_URL}/api/v1/references/specialties \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN"'
echo ""

# 9. Get Subjects
echo "9. Get Subjects"
echo 'curl ${BASE_URL}/api/v1/references/subjects \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN"'
echo ""

# 10. Create Exam Template
echo "10. Create Exam Template"
echo 'curl -X POST ${BASE_URL}/api/v1/exams/templates \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "title": "КТ M120 Зима 2024",
    "specialty_id": 1,
    "rules": {
      "sections": [
        {"name": "English", "subject_id": 1, "question_count": 2},
        {"name": "TGO", "subject_id": 2, "question_count": 2},
        {"name": "Geodesy", "subject_id": 3, "question_count": 2},
        {"name": "Marksheider", "subject_id": 4, "question_count": 2}
      ],
      "shuffle": true,
      "time_limit_minutes": 120
    }
  }'"'"
echo ""

# 11. Create Exam Instance
echo "11. Create Exam Instance"
echo 'curl -X POST ${BASE_URL}/api/v1/exams/instances \'
echo '  -H "Authorization: Bearer $ADMIN_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "template_id": 1,
    "title": "КТ M120 - Зимняя сессия 2024",
    "start_time": "2024-01-01T00:00:00Z",
    "end_time": "2025-12-31T23:59:59Z",
    "is_proctored": true
  }'"'"
echo ""

# 12. Register Student
echo "12. Register Student"
echo 'curl -X POST ${BASE_URL}/api/v1/auth/register \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "email": "student@test.kz",
    "password": "student123",
    "full_name": "Test Student",
    "role": "student"
  }'"'"
echo ""

# 13. Login as Student
echo "13. Login as Student"
echo 'STUDENT_TOKEN=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login -H "Content-Type: application/json" -d '"'"'{"email": "student@test.kz", "password": "student123"}'"'"' | jq -r .access_token)'
echo ""

# 14. Start Attempt
echo "14. Start Exam Attempt"
echo 'curl -X POST ${BASE_URL}/api/v1/attempts/start \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"instance_id": 1}'"'"
echo ""
echo "# Save attempt ID:"
echo 'ATTEMPT_ID=$(curl -s -X POST ${BASE_URL}/api/v1/attempts/start -H "Authorization: Bearer $STUDENT_TOKEN" -H "Content-Type: application/json" -d '"'"'{"instance_id": 1}'"'"' | jq -r .attempt_id)'
echo ""

# 15. Get Attempt Questions
echo "15. Get Attempt Questions"
echo 'curl ${BASE_URL}/api/v1/attempts/$ATTEMPT_ID \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN"'
echo ""

# 16. Submit Answer
echo "16. Submit Answer"
echo 'curl -X POST ${BASE_URL}/api/v1/attempts/answer \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "attempt_item_id": 1,
    "answer_nonce": "NONCE_FROM_QUESTION",
    "selected_labels": ["A"]
  }'"'"
echo ""

# 17. Submit Proctor Events
echo "17. Submit Proctoring Events"
echo 'curl -X POST ${BASE_URL}/api/v1/proctor/events \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "attempt_id": '"$ATTEMPT_ID"',
    "events": [
      {"event_type": "TAB_BLUR", "timestamp": "2024-12-15T09:35:00Z"},
      {"event_type": "TAB_FOCUS", "timestamp": "2024-12-15T09:35:15Z"}
    ]
  }'"'"
echo ""

# 18. Submit Attempt
echo "18. Submit Exam Attempt"
echo 'curl -X POST ${BASE_URL}/api/v1/attempts/submit \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"attempt_id": '"$ATTEMPT_ID"'}'"'"
echo ""

# 19. Get Proctoring Summary
echo "19. Get Proctoring Summary"
echo 'curl ${BASE_URL}/api/v1/proctor/summary/$ATTEMPT_ID \'
echo '  -H "Authorization: Bearer $STUDENT_TOKEN"'
echo ""

# 20. Register Curator
echo "20. Register Curator"
echo 'curl -X POST ${BASE_URL}/api/v1/auth/register \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{
    "email": "curator@test.kz",
    "password": "curator123",
    "full_name": "Test Curator",
    "role": "curator"
  }'"'"
echo ""

# 21. Login as Curator
echo "21. Login as Curator"
echo 'CURATOR_TOKEN=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login -H "Content-Type: application/json" -d '"'"'{"email": "curator@test.kz", "password": "curator123"}'"'"' | jq -r .access_token)'
echo ""

# 22. View Student Progress
echo "22. View Student Progress"
echo 'curl "${BASE_URL}/api/v1/curator/progress?instance_id=1&page=1&page_size=20" \'
echo '  -H "Authorization: Bearer $CURATOR_TOKEN"'
echo ""

# 23. Generate Report
echo "23. Generate Report"
echo 'curl -X POST ${BASE_URL}/api/v1/curator/reports/generate \'
echo '  -H "Authorization: Bearer $CURATOR_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"instance_id": 1, "format": "xlsx"}'"'"
echo ""
echo "# Save report task ID:"
echo 'REPORT_TASK_ID=$(curl -s -X POST ${BASE_URL}/api/v1/curator/reports/generate -H "Authorization: Bearer $CURATOR_TOKEN" -H "Content-Type: application/json" -d '"'"'{"instance_id": 1, "format": "xlsx"}'"'"' | jq -r .task_id)'
echo ""

# 24. Check Report Status
echo "24. Check Report Task Status"
echo 'curl ${BASE_URL}/api/v1/curator/reports/task/$REPORT_TASK_ID \'
echo '  -H "Authorization: Bearer $CURATOR_TOKEN"'
echo ""

echo "=== Complete Test Flow Script ==="
echo ""
echo "Run this complete flow:"
echo ""
cat << 'EOF'
#!/bin/bash
BASE_URL="http://localhost:8000"

# Login as admin
ADMIN_TOKEN=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@exam.kz", "password": "admin123456"}' | jq -r .access_token)

echo "Admin token: $ADMIN_TOKEN"

# Upload and publish question bank
TASK_ID=$(curl -s -X POST ${BASE_URL}/api/v1/admin/banks/upload \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "file=@sample_bank.xlsx" | jq -r .task_id)

echo "Upload task: $TASK_ID"
sleep 5

# Check task status
curl -s ${BASE_URL}/api/v1/admin/banks/task/$TASK_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq .

# Publish bank
curl -s -X POST ${BASE_URL}/api/v1/admin/banks/publish \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"bank_id": 1}' | jq .

# Create exam template
curl -s -X POST ${BASE_URL}/api/v1/exams/templates \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "КТ M120 Test",
    "specialty_id": 1,
    "rules": {
      "sections": [
        {"name": "English", "subject_id": 1, "question_count": 2},
        {"name": "TGO", "subject_id": 2, "question_count": 2},
        {"name": "Geodesy", "subject_id": 3, "question_count": 2},
        {"name": "Marksheider", "subject_id": 4, "question_count": 2}
      ]
    }
  }' | jq .

# Create exam instance
curl -s -X POST ${BASE_URL}/api/v1/exams/instances \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": 1,
    "title": "Test Exam",
    "start_time": "2024-01-01T00:00:00Z",
    "end_time": "2025-12-31T23:59:59Z",
    "is_proctored": true
  }' | jq .

# Register and login student
curl -s -X POST ${BASE_URL}/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@test.kz",
    "password": "student123",
    "full_name": "Test Student",
    "role": "student"
  }' | jq .

STUDENT_TOKEN=$(curl -s -X POST ${BASE_URL}/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "student@test.kz", "password": "student123"}' | jq -r .access_token)

echo "Student token: $STUDENT_TOKEN"

# Start attempt
ATTEMPT_ID=$(curl -s -X POST ${BASE_URL}/api/v1/attempts/start \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"instance_id": 1}' | jq -r .attempt_id)

echo "Attempt ID: $ATTEMPT_ID"

# Get questions
curl -s ${BASE_URL}/api/v1/attempts/$ATTEMPT_ID \
  -H "Authorization: Bearer $STUDENT_TOKEN" | jq .

echo "Test flow completed!"
EOF
