-- ====================================================
-- TRAINLY DATABASE REPORTS (DQL)
-- Various analytical reports using SELECT queries
-- ====================================================

USE TRAINLY;

-- ====================================================
-- REPORT 1: COURSE PERFORMANCE DASHBOARD
-- ====================================================

-- Relational Algebra:
-- π CourseId, Title, Category, EnrolledCount, AvgCompletionRate, AvgGrade, TotalRevenue
--   (γ CourseId, Title, Category; COUNT(StuId)→EnrolledCount, AVG(CompletionRate)→AvgCompletionRate, 
--    AVG(AvgGrade)→AvgGrade, SUM(Cost)→TotalRevenue
--    (Course ⨝ CourseId=CourseID Analytics ⨝ CourseId=CourseId CourseEnrollment))

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    c.Category,
    c.Status,
    c.Cost AS Price,
    c.AvgRating,
    COUNT(DISTINCT ce.StuId) AS EnrolledStudents,
    COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.StuId END) AS CertifiedStudents,
    ROUND(AVG(a.CompletionRate), 2) AS AvgCompletionRate,
    ROUND(AVG(a.AvgGrade), 2) AS AvgGrade,
    ROUND(AVG(a.TimeSpentHours), 2) AS AvgHoursSpent,
    c.Cost * COUNT(DISTINCT ce.StuId) AS TotalRevenue,
    ROUND((COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.StuId END) * 100.0 / 
           NULLIF(COUNT(DISTINCT ce.StuId), 0)), 2) AS CertificationRate
FROM Course c
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Analytics a ON c.CourseId = a.CourseID AND ce.StuId = a.StudentID
GROUP BY c.CourseId, c.Title, c.Category, c.Status, c.Cost, c.AvgRating
ORDER BY EnrolledStudents DESC, AvgGrade DESC;

-- ====================================================
-- REPORT 2: STUDENT LEARNING ANALYTICS
-- ====================================================

-- Relational Algebra:
-- π StudentID, StudentName, TotalCourses, CoursesCompleted, TotalTimeSpent, AvgCompletionRate, AvgGrade
--   (γ StudentID; COUNT(CourseID)→TotalCourses, SUM(CASE Certification=1 THEN 1 ELSE 0)→CoursesCompleted,
--    SUM(TimeSpentHours)→TotalTimeSpent, AVG(CompletionRate)→AvgCompletionRate, AVG(AvgGrade)→AvgGrade
--    (Analytics ⨝ StudentID=StuId Student ⨝ UserId=UserId Users))

SELECT 
    s.StuId AS StudentID,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    u.Email,
    COUNT(DISTINCT a.CourseID) AS TotalCoursesEnrolled,
    COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.CourseId END) AS CoursesCompleted,
    COUNT(DISTINCT cert.CertificateId) AS CertificatesEarned,
    ROUND(SUM(a.TimeSpentHours), 2) AS TotalHoursSpent,
    ROUND(AVG(a.CompletionRate), 2) AS AvgCompletionRate,
    ROUND(AVG(a.AvgGrade), 2) AS AvgGrade,
    ROUND(SUM(c.Cost), 2) AS TotalTuitionValue,
    CASE 
        WHEN AVG(a.CompletionRate) >= 80 AND AVG(a.AvgGrade) >= 80 THEN 'Excellent'
        WHEN AVG(a.CompletionRate) >= 60 AND AVG(a.AvgGrade) >= 60 THEN 'Good'
        WHEN AVG(a.CompletionRate) >= 40 OR AVG(a.AvgGrade) >= 40 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS PerformanceCategory
FROM Student s
JOIN Users u ON s.UserId = u.UserId
LEFT JOIN Analytics a ON s.StuId = a.StudentID
LEFT JOIN CourseEnrollment ce ON s.StuId = ce.StuId AND a.CourseID = ce.CourseId
LEFT JOIN Certificate cert ON s.StuId = cert.StuId AND ce.CourseId = cert.CourseId
LEFT JOIN Course c ON ce.CourseId = c.CourseId
GROUP BY s.StuId, u.FirstName, u.LastName, u.Email
ORDER BY AvgGrade DESC, TotalHoursSpent DESC;

-- ====================================================
-- REPORT 3: INSTRUCTOR PERFORMANCE REPORT
-- ====================================================

-- Relational Algebra:
-- π InstructorId, InstructorName, Title, TotalCourses, ActiveCourses, TotalStudents, 
--   AvgCourseRating, TotalRevenue
--   (γ InstructorId; COUNT(CourseId)→TotalCourses, 
--    COUNT(CASE Status='active' THEN CourseId)→ActiveCourses,
--    COUNT(DISTINCT StuId)→TotalStudents, AVG(AvgRating)→AvgCourseRating,
--    SUM(Cost * EnrollmentCount)→TotalRevenue
--    (Faculty ⨝ FacultyId=InstructorId Course ⨝ CourseId=CourseId CourseEnrollment))

SELECT 
    f.FacultyId,
    CONCAT(u.FirstName, ' ', u.LastName) AS InstructorName,
    f.Title AS InstructorTitle,
    f.Affiliation,
    COUNT(DISTINCT c.CourseId) AS TotalCourses,
    COUNT(DISTINCT CASE WHEN c.Status = 'active' THEN c.CourseId END) AS ActiveCourses,
    COUNT(DISTINCT ce.StuId) AS TotalStudents,
    COUNT(DISTINCT cert.CertificateId) AS CertificatesIssued,
    ROUND(AVG(c.AvgRating), 2) AS AvgCourseRating,
    ROUND(SUM(c.Cost * (SELECT COUNT(*) FROM CourseEnrollment WHERE CourseId = c.CourseId)), 2) AS TotalRevenue,
    ROUND(AVG(a.AvgGrade), 2) AS AvgStudentGrade,
    ROUND(AVG(a.CompletionRate), 2) AS AvgCompletionRate
FROM Faculty f
JOIN Users u ON f.UserId = u.UserId
LEFT JOIN Course c ON f.FacultyId = c.InstructorId
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Certificate cert ON ce.CourseId = cert.CourseId AND ce.StuId = cert.StuId
LEFT JOIN Analytics a ON ce.StuId = a.StudentID AND ce.CourseId = a.CourseID
GROUP BY f.FacultyId, u.FirstName, u.LastName, f.Title, f.Affiliation
ORDER BY TotalRevenue DESC, AvgCourseRating DESC;

-- ====================================================
-- REPORT 4: ASSESSMENT ANALYSIS REPORT
-- ====================================================

-- Relational Algebra:
-- π CourseId, CourseName, AssessmentType, TotalAssessments, TotalSubmissions, 
--   AvgScore, SubmissionRate, AvgTimeSpent
--   ((SELECT CourseId, 'Assignment' AS Type FROM Assignment)
--    ∪
--    (SELECT CourseId, 'Quiz' AS Type FROM Quiz)
--    ∪
--    (SELECT CourseId, 'Exam' AS Type FROM Exam))
--   ⨝ CourseId=CourseId Course

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    'Assignment' AS AssessmentType,
    COUNT(DISTINCT a.AssignmentID) AS TotalAssignments,
    COUNT(DISTINCT asub.SubmissionID) AS TotalSubmissions,
    COUNT(DISTINCT s.StuId) AS EnrolledStudents,
    ROUND((COUNT(DISTINCT asub.SubmissionID) * 100.0 / 
           NULLIF(COUNT(DISTINCT s.StuId) * COUNT(DISTINCT a.AssignmentID), 0)), 2) AS SubmissionRate,
    ROUND(AVG(asub.Score), 2) AS AvgScore,
    ROUND(MIN(asub.Score), 2) AS MinScore,
    ROUND(MAX(asub.Score), 2) AS MaxScore
FROM Course c
JOIN Assignment a ON c.CourseId = a.CourseID
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Student s ON ce.StuId = s.StuId
LEFT JOIN AssignmentSubmission asub ON a.AssignmentID = asub.AssignmentID AND s.StuId = asub.StudentID
GROUP BY c.CourseId, c.Title

UNION ALL

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    'Quiz' AS AssessmentType,
    COUNT(DISTINCT q.QuizID) AS TotalQuizzes,
    COUNT(DISTINCT qs.QuizSubmissionID) AS TotalSubmissions,
    COUNT(DISTINCT s.StuId) AS EnrolledStudents,
    ROUND((COUNT(DISTINCT qs.QuizSubmissionID) * 100.0 / 
           NULLIF(COUNT(DISTINCT s.StuId) * COUNT(DISTINCT q.QuizID), 0)), 2) AS SubmissionRate,
    ROUND(AVG(qs.Score), 2) AS AvgScore,
    ROUND(MIN(qs.Score), 2) AS MinScore,
    ROUND(MAX(qs.Score), 2) AS MaxScore
FROM Course c
JOIN Quiz q ON c.CourseId = q.CourseID
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Student s ON ce.StuId = s.StuId
LEFT JOIN QuizSubmission qs ON q.QuizID = qs.QuizID AND s.StuId = qs.StudentID
GROUP BY c.CourseId, c.Title

UNION ALL

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    'Exam' AS AssessmentType,
    COUNT(DISTINCT e.ExamID) AS TotalExams,
    COUNT(DISTINCT es.ExamSubmissionID) AS TotalSubmissions,
    COUNT(DISTINCT s.StuId) AS EnrolledStudents,
    ROUND((COUNT(DISTINCT es.ExamSubmissionID) * 100.0 / 
           NULLIF(COUNT(DISTINCT s.StuId) * COUNT(DISTINCT e.ExamID), 0)), 2) AS SubmissionRate,
    ROUND(AVG(es.Score), 2) AS AvgScore,
    ROUND(MIN(es.Score), 2) AS MinScore,
    ROUND(MAX(es.Score), 2) AS MaxScore
FROM Course c
LEFT JOIN Exam e ON c.CourseId = e.CourseID
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Student s ON ce.StuId = s.StuId
LEFT JOIN ExamSubmission es ON e.ExamID = es.ExamID AND s.StuId = es.StudentID
GROUP BY c.CourseId, c.Title
ORDER BY CourseId, AssessmentType;

-- ====================================================
-- REPORT 5: ENGAGEMENT & ACTIVITY METRICS
-- ====================================================

-- Relational Algebra:
-- π CourseId, CourseName, TotalMaterials, AvgCompletionTime, 
--   TotalQuestions, TotalDiscussions, ActiveStudents
--   (γ CourseId; COUNT(MaterialId)→TotalMaterials, AVG(DurationSeconds)→AvgDuration,
--    COUNT(QuestionId)→TotalQuestions, COUNT(ThreadId)→TotalDiscussions,
--    COUNT(DISTINCT CASE LastActivityDate >= DATE_SUB(NOW(), 30) THEN StuId)→ActiveStudents
--    (CourseMaterial ⨝ CourseId=CourseId Course 
--     ⟕ (QuestionRelateTo ⨝ MaterialId=MaterialId Question)
--     ⟕ (DiscussionThread ⨝ CourseId=CourseId)
--     ⟕ (MaterialCompletion ⨝ MaterialId=MaterialId)))

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    COUNT(DISTINCT cm.MaterialId) AS TotalMaterials,
    ROUND(AVG(cm.DurationSeconds) / 60, 2) AS AvgMaterialMinutes,
    COUNT(DISTINCT mc.MaterialId) AS MaterialsAccessed,
    ROUND((COUNT(DISTINCT mc.MaterialId) * 100.0 / NULLIF(COUNT(DISTINCT cm.MaterialId), 0)), 2) AS MaterialAccessRate,
    COUNT(DISTINCT q.QuestionId) AS TotalQuestionsAsked,
    COUNT(DISTINCT dt.ThreadId) AS TotalDiscussionThreads,
    COUNT(DISTINCT dp.PostId) AS TotalDiscussionPosts,
    COUNT(DISTINCT CASE 
        WHEN mc.Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
        THEN mc.StuId 
    END) AS ActiveStudents30Days,
    COUNT(DISTINCT CASE 
        WHEN mc.Date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) 
        THEN mc.StuId 
    END) AS ActiveStudents7Days,
    ROUND(AVG(mc.TimeSpent), 2) AS AvgTimeSpentPerMaterial
FROM Course c
LEFT JOIN CourseMaterial cm ON c.CourseId = cm.CourseId
LEFT JOIN MaterialCompletion mc ON cm.MaterialId = mc.MaterialId
LEFT JOIN QuestionRelateTo qrt ON cm.MaterialId = qrt.MaterialId
LEFT JOIN Question q ON qrt.QuestionId = q.QuestionId
LEFT JOIN DiscussionThread dt ON c.CourseId = dt.CourseId
LEFT JOIN DiscussionPost dp ON dt.ThreadId = dp.ThreadId
GROUP BY c.CourseId, c.Title
ORDER BY ActiveStudents30Days DESC, TotalQuestionsAsked DESC;

-- ====================================================
-- REPORT 6: REVENUE & FINANCIAL ANALYSIS
-- ====================================================

-- Relational Algebra:
-- π Month, TotalEnrollments, UniqueStudents, UniqueCourses, MonthlyRevenue, 
--   AvgPrice, RevenueGrowth
--   (γ DATE_FORMAT(EnrollDate, '%Y-%m'); COUNT(*)→TotalEnrollments,
--    COUNT(DISTINCT StuId)→UniqueStudents, COUNT(DISTINCT CourseId)→UniqueCourses,
--    SUM(Cost)→MonthlyRevenue, AVG(Cost)→AvgPrice
--    (CourseEnrollment ⨝ CourseId=CourseId Course))

SELECT 
    c.CourseId,
    c.Title AS CourseName,
    c.Category,
    c.Cost AS Price,
    COUNT(DISTINCT ce.StuId) AS TotalEnrollments,
    ROUND(SUM(c.Cost), 2) AS TotalRevenue,
    COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.StuId END) AS CertifiedStudents,
    ROUND(COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.StuId END) * c.Cost, 2) AS RevenueFromCertified,
    ROUND(AVG(ce.Rating), 2) AS AvgRating,
    MIN(ce.EnrollDate) AS FirstEnrollment,
    MAX(ce.EnrollDate) AS LastEnrollment
FROM Course c
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
GROUP BY c.CourseId, c.Title, c.Category, c.Cost
ORDER BY TotalRevenue DESC;

-- ====================================================
-- REPORT 7: RISK & RETENTION ANALYSIS
-- ====================================================

-- Relational Algebra:
-- π StudentID, StudentName, CourseName, CompletionRate, AvgGrade, 
--   DaysSinceLastActivity, RiskLevel, RiskReason
--   (σ CompletionRate < 30 ∨ AvgGrade < 50 ∨ DaysSinceLastActivity > 14
--    (Analytics ⨝ StudentID=StuId Student ⨝ UserId=UserId Users 
--     ⨝ CourseID=CourseId Course))

SELECT 
    a.StudentID,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    c.Title AS CourseName,
    a.CompletionRate,
    a.AvgGrade,
    a.TimeSpentHours,
    a.QuizParticipation,
    DATEDIFF(CURDATE(), COALESCE(
        (SELECT MAX(mc.Date) 
         FROM MaterialCompletion mc 
         JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
         WHERE mc.StuId = a.StudentID AND cm.CourseId = a.CourseID),
        ce.EnrollDate
    )) AS DaysSinceLastActivity,
    CASE 
        WHEN a.CompletionRate < 20 OR a.AvgGrade < 40 THEN 'High Risk'
        WHEN a.CompletionRate < 30 OR a.AvgGrade < 50 THEN 'Medium Risk'
        WHEN a.CompletionRate < 40 OR a.AvgGrade < 60 THEN 'Low Risk'
        ELSE 'On Track'
    END AS RiskLevel,
    CASE 
        WHEN a.CompletionRate < 20 THEN 'Very low completion rate'
        WHEN a.CompletionRate < 30 THEN 'Low completion rate'
        WHEN a.AvgGrade < 40 THEN 'Very low grades'
        WHEN a.AvgGrade < 50 THEN 'Low grades'
        WHEN DATEDIFF(CURDATE(), COALESCE(
            (SELECT MAX(mc.Date) FROM MaterialCompletion mc 
             JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
             WHERE mc.StuId = a.StudentID AND cm.CourseId = a.CourseID),
            ce.EnrollDate
        )) > 21 THEN 'No activity for 3+ weeks'
        WHEN a.QuizParticipation = 0 THEN 'No quiz participation'
        ELSE 'Multiple factors'
    END AS RiskReason,
    ra.Reason AS ExistingAlert,
    ra.CreatedAt AS AlertDate
FROM Analytics a
JOIN Student s ON a.StudentID = s.StuId
JOIN Users u ON s.UserId = u.UserId
JOIN Course c ON a.CourseID = c.CourseId
JOIN CourseEnrollment ce ON a.StudentID = ce.StuId AND a.CourseID = ce.CourseId
LEFT JOIN RiskAlert ra ON a.StudentID = ra.StudentID AND a.CourseID = ra.CourseID AND ra.Resolved = 0
WHERE (a.CompletionRate < 30 OR a.AvgGrade < 50 OR 
       DATEDIFF(CURDATE(), COALESCE(
           (SELECT MAX(mc.Date) FROM MaterialCompletion mc 
            JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
            WHERE mc.StuId = a.StudentID AND cm.CourseId = a.CourseID),
           ce.EnrollDate
       )) > 14)
ORDER BY RiskLevel DESC, a.CompletionRate ASC;

-- ====================================================
-- REPORT 8: TOPIC & CATEGORY ANALYSIS
-- ====================================================

-- Relational Algebra:
-- π TopicName, TotalCourses, TotalEnrollments, AvgRating, AvgCost, 
--   CertificationRate, TotalRevenue
--   (γ TopicId; COUNT(CourseId)→TotalCourses, COUNT(StuId)→TotalEnrollments,
--    AVG(AvgRating)→AvgRating, AVG(Cost)→AvgCost,
--    AVG(CASE Certification=1 THEN 1 ELSE 0)→CertificationRate,
--    SUM(Cost)→TotalRevenue
--    (Topic ⨝ TopicId=TopicId SecondaryTopics ⨝ CourseId=CourseId Course 
--     ⨝ CourseId=CourseId CourseEnrollment))

SELECT 
    t.Name AS TopicName,
    COUNT(DISTINCT c.CourseId) AS TotalCourses,
    COUNT(DISTINCT CASE WHEN c.Status = 'active' THEN c.CourseId END) AS ActiveCourses,
    COUNT(DISTINCT ce.StuId) AS TotalEnrollments,
    ROUND(AVG(c.AvgRating), 2) AS AvgRating,
    ROUND(AVG(c.Cost), 2) AS AvgPrice,
    ROUND(AVG(a.AvgGrade), 2) AS AvgStudentGrade,
    ROUND(AVG(a.CompletionRate), 2) AS AvgCompletionRate,
    ROUND((COUNT(DISTINCT CASE WHEN ce.Certification = 1 THEN ce.StuId END) * 100.0 / 
           NULLIF(COUNT(DISTINCT ce.StuId), 0)), 2) AS CertificationRate,
    ROUND(SUM(c.Cost), 2) AS TotalRevenue,
    ROUND(SUM(c.Cost * (SELECT COUNT(*) FROM CourseEnrollment WHERE CourseId = c.CourseId)), 2) AS PotentialRevenue
FROM Topic t
LEFT JOIN SecondaryTopics st ON t.TopicId = st.TopicId
LEFT JOIN Course c ON st.CourseId = c.CourseId
LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
LEFT JOIN Analytics a ON ce.StuId = a.StudentID AND ce.CourseId = a.CourseID
GROUP BY t.TopicId, t.Name
HAVING TotalCourses > 0
ORDER BY TotalEnrollments DESC, AvgRating DESC;

-- ====================================================
-- REPORT 9: MATERIAL EFFECTIVENESS ANALYSIS
-- ====================================================

-- Relational Algebra:
-- π CourseName, MaterialType, TotalMaterials, MaterialsCompleted, 
--   AvgCompletionTime, AvgTimeSpent, QuestionCount
--   (γ CourseId, MaterialType; COUNT(MaterialId)→TotalMaterials,
--    COUNT(StuId)→MaterialsCompleted, AVG(DurationSeconds)→AvgDuration,
--    AVG(TimeSpent)→AvgTimeSpent, COUNT(QuestionId)→QuestionCount
--    (CourseMaterial ⨝ CourseId=CourseId Course 
--     ⟕ MaterialCompletion ⨝ MaterialId=MaterialId
--     ⟕ QuestionRelateTo ⨝ MaterialId=MaterialId))

SELECT 
    c.Title AS CourseName,
    cm.MaterialType,
    COUNT(DISTINCT cm.MaterialId) AS TotalMaterials,
    COUNT(DISTINCT mc.MaterialId) AS MaterialsAccessed,
    COUNT(DISTINCT mc.StuId) AS UniqueStudentsAccessed,
    ROUND(AVG(cm.DurationSeconds), 2) AS AvgMaterialDuration,
    ROUND(AVG(mc.TimeSpent), 2) AS AvgTimeSpentSeconds,
    ROUND((AVG(mc.TimeSpent) * 100.0 / NULLIF(AVG(cm.DurationSeconds), 0)), 2) AS EngagementPercentage,
    COUNT(DISTINCT q.QuestionId) AS QuestionsRelated,
    COUNT(DISTINCT CASE 
        WHEN mc.TimeSpent >= cm.DurationSeconds * 0.8 
        THEN mc.MaterialId 
    END) AS HighlyEngagedMaterials,
    ROUND((COUNT(DISTINCT mc.MaterialId) * 100.0 / 
           NULLIF(COUNT(DISTINCT cm.MaterialId), 0)), 2) AS MaterialAccessRate
FROM Course c
JOIN CourseMaterial cm ON c.CourseId = cm.CourseId
LEFT JOIN MaterialCompletion mc ON cm.MaterialId = mc.MaterialId
LEFT JOIN QuestionRelateTo qrt ON cm.MaterialId = qrt.MaterialId
LEFT JOIN Question q ON qrt.QuestionId = q.QuestionId
GROUP BY c.CourseId, c.Title, cm.MaterialType
ORDER BY c.Title, cm.MaterialType, EngagementPercentage DESC;

-- ====================================================
-- REPORT 10: CERTIFICATION & COMPLETION TRACKING
-- ====================================================

-- Relational Algebra:
-- π Month, TotalCertifications, TotalCompletions, AvgDaysToComplete, 
--   TotalRevenueFromCertified, TopCourse
--   (γ DATE_FORMAT(IssueDate, '%Y-%m'); COUNT(CertificateId)→TotalCertifications,
--    COUNT(DISTINCT CourseId)→UniqueCourses, AVG(DaysToComplete)→AvgDaysToComplete,
--    SUM(Cost)→TotalRevenue
--    (Certificate ⨝ StuId=StuId, CourseId=CourseId CourseEnrollment 
--     ⨝ CourseId=CourseId Course))

SELECT 
    cert.CertificateId,
    cert.VerificationCode,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    c.Title AS CourseName,
    c.Category,
    ce.EnrollDate,
    cert.IssueDate,
    DATEDIFF(cert.IssueDate, ce.EnrollDate) AS DaysToComplete,
    a.AvgGrade,
    a.CompletionRate,
    a.TimeSpentHours,
    c.Cost AS CoursePrice,
    CASE 
        WHEN DATEDIFF(cert.IssueDate, ce.EnrollDate) <= 30 THEN 'Fast (≤30 days)'
        WHEN DATEDIFF(cert.IssueDate, ce.EnrollDate) <= 60 THEN 'Moderate (31-60 days)'
        ELSE 'Slow (>60 days)'
    END AS CompletionSpeed,
    CASE 
        WHEN a.AvgGrade >= 90 THEN 'A (Excellent)'
        WHEN a.AvgGrade >= 80 THEN 'B (Good)'
        WHEN a.AvgGrade >= 70 THEN 'C (Average)'
        WHEN a.AvgGrade >= 60 THEN 'D (Passing)'
        ELSE 'F (Failing)'
    END AS GradeCategory
FROM Certificate cert
JOIN Student s ON cert.StuId = s.StuId
JOIN Users u ON s.UserId = u.UserId
JOIN Course c ON cert.CourseId = c.CourseId
JOIN CourseEnrollment ce ON cert.StuId = ce.StuId AND cert.CourseId = ce.CourseId
LEFT JOIN Analytics a ON cert.StuId = a.StudentID AND cert.CourseId = a.CourseID
ORDER BY cert.IssueDate DESC;

-- ====================================================
-- BONUS REPORT: STUDENT LEARNING PATH ANALYSIS
-- ====================================================

/*
RELATIONAL ALGEBRA EXPRESSION:

τ_{TotalCertificates DESC, OverallAvgGrade DESC}(
    σ_{TotalCoursesTaken > 0}(
        π_{
            StuId → StudentID,
            CONCAT(FirstName, ' ', LastName) → StudentName,
            TotalCoursesTaken,
            TotalCertificates,
            LearningPath,
            FirstEnrollment,
            LastEnrollment,
            LearningDurationDays,
            ROUND(OverallAvgGrade, 2) → OverallAvgGrade,
            ROUND(OverallCompletionRate, 2) → OverallCompletionRate,
            TotalTuitionValue,
            LearningStage
        }(
            γ_{
                StuId, FirstName, LastName;
                
                -- Aggregations
                COUNT(DISTINCT CourseId) → TotalCoursesTaken,
                COUNT(DISTINCT CertificateId) → TotalCertificates,
                MIN(EnrollDate) → FirstEnrollment,
                MAX(EnrollDate) → LastEnrollment,
                AVG(AvgGrade) → OverallAvgGrade,
                AVG(CompletionRate) → OverallCompletionRate,
                SUM(Cost) → TotalTuitionValue,
                
                -- Derived Calculations
                DATEDIFF(MAX(EnrollDate), MIN(EnrollDate)) → LearningDurationDays,
                GROUP_CONCAT(DISTINCT Category ORDER BY EnrollDate SEPARATOR ' → ') → LearningPath,
                
                -- Conditional Classification
                CASE
                    WHEN COUNT(DISTINCT CertificateId) ≥ 3 THEN 'Advanced Learner'
                    WHEN COUNT(DISTINCT CertificateId) ≥ 1 THEN 'Active Learner'
                    WHEN COUNT(DISTINCT CourseId) ≥ 2 THEN 'Explorer'
                    ELSE 'New Student'
                END → LearningStage
            }(
                ((Student ⨝_{UserId=UserId} Users)
                 ⟕_{StuId=StuId} CourseEnrollment)
                ⟕_{CourseId=CourseId} Course)
                ⟕_{StuId=StuId ∧ CourseId=CourseId} Certificate)
                ⟕_{StudentID=StuId ∧ CourseID=CourseId} Analytics
            )
        )
    )
)
*/

SELECT 
    s.StuId AS StudentID,
    CONCAT(u.FirstName, ' ', u.LastName) AS StudentName,
    COUNT(DISTINCT ce.CourseId) AS TotalCoursesTaken,
    COUNT(DISTINCT cert.CertificateId) AS TotalCertificates,
    GROUP_CONCAT(DISTINCT c.Category ORDER BY ce.EnrollDate SEPARATOR ' → ') AS LearningPath,
    MIN(ce.EnrollDate) AS FirstEnrollment,
    MAX(ce.EnrollDate) AS LastEnrollment,
    DATEDIFF(MAX(ce.EnrollDate), MIN(ce.EnrollDate)) AS LearningDurationDays,
    ROUND(AVG(a.AvgGrade), 2) AS OverallAvgGrade,
    ROUND(AVG(a.CompletionRate), 2) AS OverallCompletionRate,
    SUM(c.Cost) AS TotalTuitionValue,
    CASE 
        WHEN COUNT(DISTINCT cert.CertificateId) >= 3 THEN 'Advanced Learner'
        WHEN COUNT(DISTINCT cert.CertificateId) >= 1 THEN 'Active Learner'
        WHEN COUNT(DISTINCT ce.CourseId) >= 2 THEN 'Explorer'
        ELSE 'New Student'
    END AS LearningStage
FROM Student s
JOIN Users u ON s.UserId = u.UserId
LEFT JOIN CourseEnrollment ce ON s.StuId = ce.StuId
LEFT JOIN Course c ON ce.CourseId = c.CourseId
LEFT JOIN Certificate cert ON s.StuId = cert.StuId AND ce.CourseId = cert.CourseId
LEFT JOIN Analytics a ON s.StuId = a.StudentID AND ce.CourseId = a.CourseID
GROUP BY s.StuId, u.FirstName, u.LastName
HAVING TotalCoursesTaken > 0
ORDER BY TotalCertificates DESC, OverallAvgGrade DESC;