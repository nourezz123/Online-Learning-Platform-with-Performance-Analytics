-- ====================================================
-- TRAINLY DATABASE VIEWS - FIXED
-- Reusable view definitions for common queries
-- ====================================================

USE TRAINLY;

-- ===========================
-- COURSE VIEWS
-- ===========================

-- View: Top Courses by Enrollment and Performance
CREATE OR REPLACE VIEW v_top_courses AS
SELECT 
  c.CourseId,
  c.Title,
  c.Category,
  c.Status,
  c.Cost,
  c.AvgRating,
  COUNT(DISTINCT e.StuId) AS EnrolledStudents,
  AVG(sub.Score) AS AvgAssignmentScore,
  SUM(CASE WHEN e.Certification = 1 THEN 1 ELSE 0 END) AS CompletedStudents
FROM Course c
LEFT JOIN CourseEnrollment e ON c.CourseId = e.CourseId
LEFT JOIN Assignment a ON c.CourseId = a.CourseID
LEFT JOIN AssignmentSubmission sub ON a.AssignmentID = sub.AssignmentID
GROUP BY c.CourseId, c.Title, c.Category, c.Status, c.Cost, c.AvgRating
ORDER BY EnrolledStudents DESC;

-- View: Course Details with Instructor Info
CREATE OR REPLACE VIEW v_course_details AS
SELECT 
    c.CourseId,
    c.Title AS CourseTitle,
    c.Category,
    c.Status,
    c.Cost,
    c.DurationHours,
    c.AvgRating,
    CONCAT(u.FirstName, ' ', u.LastName) AS InstructorName,
    f.Title AS InstructorTitle,
    f.Affiliation,
    COUNT(DISTINCT cm.MaterialId) AS TotalMaterials,
    COUNT(DISTINCT ce.StuId) AS EnrolledStudents
FROM Course c
JOIN Faculty f ON c.InstructorId = f.FacultyId
JOIN Users u ON f.UserId = u.UserId
LEFT JOIN CourseMaterial cm ON c.CourseId = cm.CourseId
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
GROUP BY c.CourseId, c.Title, c.Category, c.Status, c.Cost, c.DurationHours, 
         c.AvgRating, InstructorName, f.Title, f.Affiliation;

-- View: Course Prerequisites Chain
CREATE OR REPLACE VIEW v_course_prerequisites AS
SELECT 
    c1.CourseId,
    c1.Title AS CourseName,
    c2.CourseId AS PrerequisiteCourseId,
    c2.Title AS PrerequisiteCourseName
FROM Course c1
JOIN CoursePrerequisite cp ON c1.CourseId = cp.CourseId
JOIN Course c2 ON cp.PrerequisiteCourseId = c2.CourseId;

-- ===========================
-- STUDENT VIEWS
-- ===========================

-- View: Student Ranking by Performance
CREATE OR REPLACE VIEW v_student_ranking AS
SELECT 
  s.StuId,
  u.FirstName,
  u.LastName,
  u.Email,
  COUNT(DISTINCT ce.CourseId) AS CoursesEnrolled,
  SUM(CASE WHEN ce.Certification = 1 THEN 1 ELSE 0 END) AS CoursesCompleted,
  COALESCE(AVG(sub.Score), 0) AS AvgAssignmentScore,
  COALESCE(AVG(qs.Score), 0) AS AvgQuizScore,
  (COALESCE(AVG(sub.Score), 0) + COALESCE(AVG(qs.Score), 0)) / 2 AS TotalScore
FROM Student s
JOIN Users u ON s.UserId = u.UserId
LEFT JOIN CourseEnrollment ce ON s.StuId = ce.StuId
LEFT JOIN AssignmentSubmission sub ON sub.StudentID = s.StuId
LEFT JOIN QuizSubmission qs ON qs.StudentID = s.StuId
GROUP BY s.StuId, u.FirstName, u.LastName, u.Email
ORDER BY TotalScore DESC;

-- View: Student Progress Summary
CREATE OR REPLACE VIEW v_student_progress AS
SELECT 
    s.StuId,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    c.CourseId,
    c.Title AS CourseName,
    ce.EnrollDate,
    ce.CompleteDate,
    ce.Rating,
    ce.Certification,
    COUNT(DISTINCT cm.MaterialId) AS TotalMaterials,
    COUNT(DISTINCT mc.MaterialId) AS CompletedMaterials,
    ROUND(COUNT(DISTINCT mc.MaterialId) * 100.0 / 
          NULLIF(COUNT(DISTINCT cm.MaterialId), 0), 2) AS CompletionPercentage,
    ROUND(SUM(mc.TimeSpent) / 3600.0, 2) AS TotalHoursSpent
FROM Student s
JOIN Users u ON s.UserId = u.UserId
JOIN CourseEnrollment ce ON s.StuId = ce.StuId
JOIN Course c ON ce.CourseId = c.CourseId
LEFT JOIN CourseMaterial cm ON c.CourseId = cm.CourseId
LEFT JOIN MaterialCompletion mc ON s.StuId = mc.StuId AND cm.MaterialId = mc.MaterialId
GROUP BY s.StuId, StudentName, c.CourseId, c.Title, ce.EnrollDate, 
         ce.CompleteDate, ce.Rating, ce.Certification;

-- View: Active Students (Last 30 Days)
CREATE OR REPLACE VIEW v_active_students AS
SELECT 
    s.StuId,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    u.Email,
    MAX(mc.Date) AS LastActivityDate,
    DATEDIFF(CURDATE(), MAX(mc.Date)) AS DaysSinceActivity,
    COUNT(DISTINCT mc.MaterialId) AS RecentMaterialsCompleted,
    COUNT(DISTINCT ce.CourseId) AS ActiveCourses
FROM Student s
JOIN Users u ON s.UserId = u.UserId
JOIN CourseEnrollment ce ON s.StuId = ce.StuId AND ce.CompleteDate IS NULL
LEFT JOIN MaterialCompletion mc ON s.StuId = mc.StuId 
    AND mc.Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY s.StuId, StudentName, u.Email
HAVING LastActivityDate IS NOT NULL;

-- ===========================
-- INSTRUCTOR VIEWS
-- ===========================

-- View: Instructor Dashboard
CREATE OR REPLACE VIEW v_instructor_dashboard AS
SELECT 
    f.FacultyId,
    CONCAT(u.FirstName, ' ', u.LastName) AS InstructorName,
    f.Title,
    f.Affiliation,
    COUNT(DISTINCT c.CourseId) AS TotalCourses,
    COUNT(DISTINCT CASE WHEN c.Status = 'active' THEN c.CourseId END) AS ActiveCourses,
    COUNT(DISTINCT ce.StuId) AS TotalStudents,
    ROUND(AVG(c.AvgRating), 2) AS AvgCourseRating,
    COUNT(DISTINCT a.AssignmentID) AS TotalAssignments,
    COUNT(DISTINCT q.QuizID) AS TotalQuizzes
FROM Faculty f
JOIN Users u ON f.UserId = u.UserId
LEFT JOIN Course c ON f.FacultyId = c.InstructorId
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Assignment a ON c.CourseId = a.CourseID
LEFT JOIN Quiz q ON c.CourseId = q.CourseID
GROUP BY f.FacultyId, InstructorName, f.Title, f.Affiliation;

-- ===========================
-- ASSESSMENT VIEWS
-- ===========================

-- View: Assignment Summary - FIXED (removed duplicate MaxScore)
CREATE OR REPLACE VIEW v_assignment_summary AS
SELECT 
    a.AssignmentID,
    a.Title AS AssignmentTitle,
    c.CourseId,
    c.Title AS CourseName,
    a.DueDate,
    a.MaxScore AS AssignmentMaxScore,
    COUNT(asub.SubmissionID) AS TotalSubmissions,
    ROUND(AVG(asub.Score), 2) AS AvgScore,
    ROUND(MIN(asub.Score), 2) AS MinScore,
    ROUND(MAX(asub.Score), 2) AS MaxScore
FROM Assignment a
JOIN Course c ON a.CourseID = c.CourseId
LEFT JOIN AssignmentSubmission asub ON a.AssignmentID = asub.AssignmentID
GROUP BY a.AssignmentID, a.Title, c.CourseId, c.Title, a.DueDate, a.MaxScore;

-- View: Quiz Summary - FIXED (removed duplicate MaxScore)
CREATE OR REPLACE VIEW v_quiz_summary AS
SELECT 
    q.QuizID,
    q.Title AS QuizTitle,
    c.CourseId,
    c.Title AS CourseName,
    q.MaxScore AS QuizMaxScore,
    q.TimeLimitMinutes,
    q.MaxAttempts,
    COUNT(DISTINCT qs.StudentID) AS TotalAttempts,
    ROUND(AVG(qs.Score), 2) AS AvgScore,
    ROUND((AVG(qs.Score) / q.MaxScore) * 100, 2) AS AvgPercentage
FROM Quiz q
JOIN Course c ON q.CourseID = c.CourseId
LEFT JOIN QuizSubmission qs ON q.QuizID = qs.QuizID
GROUP BY q.QuizID, q.Title, c.CourseId, c.Title, q.MaxScore, 
         q.TimeLimitMinutes, q.MaxAttempts;

-- ===========================
-- ENGAGEMENT VIEWS
-- ===========================

-- View: Discussion Activity
CREATE OR REPLACE VIEW v_discussion_activity AS
SELECT 
    dt.ThreadId,
    dt.Title AS ThreadTitle,
    c.CourseId,
    c.Title AS CourseName,
    CONCAT(u.FirstName, ' ', u.LastName) AS CreatedBy,
    dt.CreatedAt,
    COUNT(dp.PostId) AS TotalPosts,
    COUNT(DISTINCT dp.UserId) AS UniqueParticipants,
    MAX(dp.CreatedAt) AS LastPostDate
FROM DiscussionThread dt
JOIN Course c ON dt.CourseId = c.CourseId
JOIN Users u ON dt.CreatedBy = u.UserId
LEFT JOIN DiscussionPost dp ON dt.ThreadId = dp.ThreadId
GROUP BY dt.ThreadId, dt.Title, c.CourseId, c.Title, CreatedBy, dt.CreatedAt;

-- View: Popular Questions
CREATE OR REPLACE VIEW v_popular_questions AS
SELECT 
    q.QuestionId,
    q.Title AS QuestionTitle,
    LEFT(q.Content, 200) AS ContentPreview,
    CONCAT(u.FirstName, ' ', u.LastName) AS AskedBy,
    q.CreatedAt,
    COUNT(DISTINCT lq.StuId) AS TotalLikes,
    COUNT(DISTINCT fu.FacultyId) AS InstructorResponses,
    MAX(fu.Answer) AS TopAnswer
FROM Question q
JOIN Student s ON q.StuId = s.StuId
JOIN Users u ON s.UserId = u.UserId
LEFT JOIN LikeQuestion lq ON q.QuestionId = lq.QuestionId
LEFT JOIN FindUseful fu ON q.QuestionId = fu.QuestionId AND fu.Visible = 1
GROUP BY q.QuestionId, q.Title, q.Content, AskedBy, q.CreatedAt;

-- ===========================
-- ANALYTICS VIEWS
-- ===========================

-- View: Student Analytics Dashboard
CREATE OR REPLACE VIEW v_student_analytics AS
SELECT 
    a.StudentID,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    c.CourseId,
    c.Title AS CourseName,
    a.AvgGrade,
    a.CompletionRate,
    a.TimeSpentHours,
    a.QuizParticipation,
    a.LastUpdated,
    CASE 
        WHEN a.CompletionRate >= 80 AND a.AvgGrade >= 80 THEN 'Excellent'
        WHEN a.CompletionRate >= 60 AND a.AvgGrade >= 60 THEN 'Good'
        WHEN a.CompletionRate >= 40 OR a.AvgGrade >= 40 THEN 'Fair'
        ELSE 'At Risk'
    END AS PerformanceStatus
FROM Analytics a
JOIN Student s ON a.StudentID = s.StuId
JOIN Users u ON s.UserId = u.UserId
JOIN Course c ON a.CourseID = c.CourseId;

-- View: At-Risk Students
CREATE OR REPLACE VIEW v_at_risk_students AS
SELECT 
    ra.AlertId,
    s.StuId,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    c.CourseId,
    c.Title AS CourseName,
    ra.Reason,
    ra.CreatedAt,
    ra.Resolved,
    DATEDIFF(CURDATE(), ra.CreatedAt) AS DaysSinceAlert
FROM RiskAlert ra
JOIN Student s ON ra.StudentID = s.StuId
JOIN Users u ON s.UserId = u.UserId
JOIN Course c ON ra.CourseID = c.CourseId
WHERE ra.Resolved = 0
ORDER BY ra.CreatedAt DESC;

-- ===========================
-- MATERIAL VIEWS
-- ===========================

-- View: Course Material Overview
CREATE OR REPLACE VIEW v_course_materials AS
SELECT 
    cm.MaterialId,
    cm.CourseId,
    c.Title AS CourseName,
    cm.ModuleIndex,
    cm.LessonIndex,
    cm.Title AS MaterialTitle,
    cm.MaterialType,
    cm.DurationSeconds,
    COUNT(DISTINCT mc.StuId) AS ViewCount,
    ROUND(AVG(mc.TimeSpent), 0) AS AvgTimeSpent
FROM CourseMaterial cm
JOIN Course c ON cm.CourseId = c.CourseId
LEFT JOIN MaterialCompletion mc ON cm.MaterialId = mc.MaterialId
GROUP BY cm.MaterialId, cm.CourseId, c.Title, cm.ModuleIndex, 
         cm.LessonIndex, cm.Title, cm.MaterialType, cm.DurationSeconds;

-- ===========================
-- FINANCIAL VIEWS
-- ===========================

-- View: Revenue Summary
CREATE OR REPLACE VIEW v_revenue_summary AS
SELECT 
    c.CourseId,
    c.Title AS CourseName,
    c.Category,
    c.Cost AS PricePerStudent,
    COUNT(ce.StuId) AS TotalEnrollments,
    c.Cost * COUNT(ce.StuId) AS TotalRevenue,
    DATE_FORMAT(MIN(ce.EnrollDate), '%Y-%m') AS FirstEnrollment,
    DATE_FORMAT(MAX(ce.EnrollDate), '%Y-%m') AS LastEnrollment
FROM Course c
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
GROUP BY c.CourseId, c.Title, c.Category, c.Cost;

-- View: Monthly Revenue Trends
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT 
    DATE_FORMAT(ce.EnrollDate, '%Y-%m') AS Month,
    COUNT(*) AS TotalEnrollments,
    COUNT(DISTINCT ce.StuId) AS UniqueStudents,
    COUNT(DISTINCT ce.CourseId) AS UniqueCourses,
    SUM(c.Cost) AS MonthlyRevenue,
    ROUND(AVG(c.Cost), 2) AS AvgPricePerEnrollment
FROM CourseEnrollment ce
JOIN Course c ON ce.CourseId = c.CourseId
GROUP BY Month
ORDER BY Month DESC;

-- ===========================
-- CERTIFICATION VIEWS
-- ===========================

-- View: Certificate Registry
CREATE OR REPLACE VIEW v_certificate_registry AS
SELECT 
    cert.CertificateId,
    cert.VerificationCode,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    u.Email AS StudentEmail,
    c.Title AS CourseName,
    c.Category,
    cert.IssueDate,
    DATEDIFF(cert.IssueDate, ce.EnrollDate) AS DaysToComplete
FROM Certificate cert
JOIN Student s ON cert.StuId = s.StuId
JOIN Users u ON s.UserId = u.UserId
JOIN Course c ON cert.CourseId = c.CourseId
JOIN CourseEnrollment ce ON s.StuId = ce.StuId AND c.CourseId = ce.CourseId
ORDER BY cert.IssueDate DESC;

-- Verification
SELECT 'Views created successfully!' AS Status;