-- ====================================================
-- TRAINLY DATABASE SECURITY
-- ====================================================

USE TRAINLY;

-- ===========================
-- USER ROLES CREATION
-- ===========================

-- Drop users if they exist
DROP USER IF EXISTS 'trainly_admin'@'%';
DROP USER IF EXISTS 'trainly_instructor'@'%';
DROP USER IF EXISTS 'trainly_student'@'%';
DROP USER IF EXISTS 'trainly_readonly'@'%';
DROP USER IF EXISTS 'trainly_api'@'%';

-- Create database users with secure passwords
-- NOTE: Change these passwords in production!
CREATE USER 'trainly_admin'@'%' IDENTIFIED BY 'Admin$ecure2024!';
CREATE USER 'trainly_instructor'@'%' IDENTIFIED BY 'Instr$ecure2024!';
CREATE USER 'trainly_student'@'%' IDENTIFIED BY 'Stud$ecure2024!';
CREATE USER 'trainly_readonly'@'%' IDENTIFIED BY 'Read$ecure2024!';
CREATE USER 'trainly_api'@'%' IDENTIFIED BY 'API$ecure2024!';

-- ===========================
-- ADMIN PRIVILEGES (Full Access)
-- ===========================

-- Grant all privileges to admin user
GRANT ALL PRIVILEGES ON TRAINLY.* TO 'trainly_admin'@'%';
GRANT GRANT OPTION ON TRAINLY.* TO 'trainly_admin'@'%';

-- Admin can execute all procedures and view all views
GRANT EXECUTE ON TRAINLY.* TO 'trainly_admin'@'%';

-- ===========================
-- INSTRUCTOR PRIVILEGES
-- ===========================

-- Instructors can read most tables
GRANT SELECT ON TRAINLY.Users TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.Student TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.Faculty TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.Topic TO 'trainly_instructor'@'%';

-- Full access to their courses
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Course TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CourseCreation TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.SecondaryTopics TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CoursePrerequisite TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.ModulePrerequisite TO 'trainly_instructor'@'%';

-- Course materials management
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CourseMaterial TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.DownloadableFile TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Link TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Post TO 'trainly_instructor'@'%';

-- Assignments and grading
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Assignment TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Rubric TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.AssignmentSubmission TO 'trainly_instructor'@'%';

-- Quizzes and exams
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Quiz TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.QuizQuestion TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.QuizSubmission TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.QuizAnswer TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Exam TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.ExamSubmission TO 'trainly_instructor'@'%';

-- Student progress and enrollment
GRANT SELECT ON TRAINLY.CourseEnrollment TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.MaterialCompletion TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.MaterialDailyStats TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.Analytics TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.RiskAlert TO 'trainly_instructor'@'%';

-- Communication
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CourseAnnouncement TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.VirtualClassroom TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT ON TRAINLY.Message TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.DiscussionThread TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.DiscussionPost TO 'trainly_instructor'@'%';

-- Q&A
GRANT SELECT ON TRAINLY.Question TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.QuestionRelateTo TO 'trainly_instructor'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.FindUseful TO 'trainly_instructor'@'%';

-- Certificates
GRANT SELECT, INSERT ON TRAINLY.Certificate TO 'trainly_instructor'@'%';

-- Reports
GRANT SELECT, INSERT ON TRAINLY.ReportLog TO 'trainly_instructor'@'%';

-- Grant access to views
GRANT SELECT ON TRAINLY.v_course_details TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_student_progress TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_instructor_dashboard TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_assignment_summary TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_quiz_summary TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_discussion_activity TO 'trainly_instructor'@'%';
GRANT SELECT ON TRAINLY.v_at_risk_students TO 'trainly_instructor'@'%';

-- Grant execute on instructor procedures
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_weekly_report TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_update_student_analytics TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_identify_at_risk_students TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_auto_grade_quiz TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_issue_certificate TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_update_course_rating TO 'trainly_instructor'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_instructor_summary TO 'trainly_instructor'@'%';

-- ===========================
-- STUDENT PRIVILEGES
-- ===========================

-- Students can view their own information
GRANT SELECT ON TRAINLY.Users TO 'trainly_student'@'%';
GRANT SELECT, UPDATE ON TRAINLY.UserPreferences TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Student TO 'trainly_student'@'%';

-- Course browsing and enrollment
GRANT SELECT ON TRAINLY.Course TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Faculty TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Topic TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.SecondaryTopics TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.CoursePrerequisite TO 'trainly_student'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.CourseEnrollment TO 'trainly_student'@'%';

-- Course materials
GRANT SELECT ON TRAINLY.CourseMaterial TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.DownloadableFile TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Link TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Post TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.CourseAnnouncement TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.VirtualClassroom TO 'trainly_student'@'%';

-- Progress tracking
GRANT SELECT, INSERT ON TRAINLY.MaterialCompletion TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.MaterialDailyStats TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Analytics TO 'trainly_student'@'%';

-- Assignments
GRANT SELECT ON TRAINLY.Assignment TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.Rubric TO 'trainly_student'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.AssignmentSubmission TO 'trainly_student'@'%';

-- Quizzes
GRANT SELECT ON TRAINLY.Quiz TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.QuizQuestion TO 'trainly_student'@'%';
GRANT SELECT, INSERT ON TRAINLY.QuizSubmission TO 'trainly_student'@'%';
GRANT SELECT, INSERT ON TRAINLY.QuizAnswer TO 'trainly_student'@'%';

-- Exams
GRANT SELECT ON TRAINLY.Exam TO 'trainly_student'@'%';
GRANT SELECT, INSERT ON TRAINLY.ExamSubmission TO 'trainly_student'@'%';

-- Q&A and Discussion
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Question TO 'trainly_student'@'%';
GRANT SELECT, INSERT, DELETE ON TRAINLY.QuestionRelateTo TO 'trainly_student'@'%';
GRANT SELECT, INSERT, DELETE ON TRAINLY.LikeQuestion TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.FindUseful TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.DiscussionThread TO 'trainly_student'@'%';
GRANT SELECT, INSERT ON TRAINLY.DiscussionPost TO 'trainly_student'@'%';

-- Messaging
GRANT SELECT, INSERT ON TRAINLY.Message TO 'trainly_student'@'%';

-- Certificates
GRANT SELECT ON TRAINLY.Certificate TO 'trainly_student'@'%';

-- Grant access to views
GRANT SELECT ON TRAINLY.v_top_courses TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.v_course_details TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.v_student_progress TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.v_course_materials TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.v_discussion_activity TO 'trainly_student'@'%';
GRANT SELECT ON TRAINLY.v_popular_questions TO 'trainly_student'@'%';

-- Grant execute on student procedures
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_enroll_student TO 'trainly_student'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_student_report_card TO 'trainly_student'@'%';

-- ===========================
-- READ-ONLY USER (Analytics/Reporting)
-- ===========================

-- Grant SELECT on all tables
GRANT SELECT ON TRAINLY.* TO 'trainly_readonly'@'%';

-- Grant access to all views
GRANT SELECT ON TRAINLY.v_top_courses TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_course_details TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_course_prerequisites TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_student_ranking TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_student_progress TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_active_students TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_instructor_dashboard TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_assignment_summary TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_quiz_summary TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_discussion_activity TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_popular_questions TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_student_analytics TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_at_risk_students TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_course_materials TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_revenue_summary TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_monthly_revenue TO 'trainly_readonly'@'%';
GRANT SELECT ON TRAINLY.v_certificate_registry TO 'trainly_readonly'@'%';

-- Grant execute on reporting procedures
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_weekly_report TO 'trainly_readonly'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_student_report_card TO 'trainly_readonly'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_instructor_summary TO 'trainly_readonly'@'%';

-- ===========================
-- API USER (Application Backend)
-- ===========================

-- API user needs comprehensive access for application operations
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Users TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.UserPreferences TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.PasswordReset TO 'trainly_api'@'%';
GRANT SELECT ON TRAINLY.Administrator TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Faculty TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Student TO 'trainly_api'@'%';

-- Course management
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Course TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CourseMaterial TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.CourseEnrollment TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.MaterialCompletion TO 'trainly_api'@'%';

-- Assessments
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Assignment TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.AssignmentSubmission TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Quiz TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.QuizSubmission TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.QuizAnswer TO 'trainly_api'@'%';

-- Analytics
GRANT SELECT, INSERT, UPDATE ON TRAINLY.Analytics TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE ON TRAINLY.RiskAlert TO 'trainly_api'@'%';

-- Communication
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.Message TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.DiscussionThread TO 'trainly_api'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON TRAINLY.DiscussionPost TO 'trainly_api'@'%';

-- Grant access to all views
GRANT SELECT ON TRAINLY.v_top_courses TO 'trainly_api'@'%';
GRANT SELECT ON TRAINLY.v_course_details TO 'trainly_api'@'%';
GRANT SELECT ON TRAINLY.v_student_progress TO 'trainly_api'@'%';
GRANT SELECT ON TRAINLY.v_student_ranking TO 'trainly_api'@'%';
GRANT SELECT ON TRAINLY.v_instructor_dashboard TO 'trainly_api'@'%';

-- Grant execute on common procedures
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_enroll_student TO 'trainly_api'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_update_student_analytics TO 'trainly_api'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_auto_grade_quiz TO 'trainly_api'@'%';
GRANT EXECUTE ON PROCEDURE TRAINLY.sp_issue_certificate TO 'trainly_api'@'%';

FLUSH PRIVILEGES;