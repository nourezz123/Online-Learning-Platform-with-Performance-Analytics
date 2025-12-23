-- ====================================================
-- TRAINLY DATABASE TRIGGERS
-- Automated actions for data integrity and analytics
-- ====================================================

USE TRAINLY;

DELIMITER $$

-- ===========================
-- QUIZ SUBMISSION TRIGGERS
-- ===========================

-- Trigger: Update Analytics After Quiz Submission
DROP TRIGGER IF EXISTS trg_after_quiz_submission$$
CREATE TRIGGER trg_after_quiz_submission
AFTER INSERT ON QuizSubmission
FOR EACH ROW
BEGIN
  DECLARE courseId INT;
  DECLARE avgAss DECIMAL(6,2);

  -- Get course ID for this quiz
  SELECT CourseID INTO courseId FROM Quiz WHERE QuizID = NEW.QuizID;

  -- Calculate average assignment score for this student in this course
  SELECT AVG(sub.Score) INTO avgAss
  FROM AssignmentSubmission sub
  JOIN Assignment a ON sub.AssignmentID = a.AssignmentID
  WHERE sub.StudentID = NEW.StudentID AND a.CourseID = courseId;

  -- Update or insert analytics record
  INSERT INTO Analytics (StudentID, CourseID, AvgGrade, CompletionRate, TimeSpentHours, QuizParticipation)
  VALUES (NEW.StudentID, courseId, COALESCE(avgAss,0), 0, 0, 1)
  ON DUPLICATE KEY UPDATE 
    AvgGrade = COALESCE(avgAss, AvgGrade),
    QuizParticipation = QuizParticipation + 1,
    LastUpdated = CURRENT_TIMESTAMP;
END$$

-- ===========================
-- ASSIGNMENT SUBMISSION TRIGGERS
-- ===========================

-- Trigger: Update Analytics After Assignment Submission
DROP TRIGGER IF EXISTS trg_after_assignment_submission$$
CREATE TRIGGER trg_after_assignment_submission
AFTER INSERT ON AssignmentSubmission
FOR EACH ROW
BEGIN
  DECLARE courseId INT;
  DECLARE avgScore DECIMAL(6,2);
  
  -- Get course ID
  SELECT CourseID INTO courseId FROM Assignment WHERE AssignmentID = NEW.AssignmentID;
  
  -- Calculate average for this student
  SELECT AVG(asub.Score) INTO avgScore
  FROM AssignmentSubmission asub
  JOIN Assignment a ON asub.AssignmentID = a.AssignmentID
  WHERE asub.StudentID = NEW.StudentID AND a.CourseID = courseId;
  
  -- Update analytics
  INSERT INTO Analytics (StudentID, CourseID, AvgGrade, CompletionRate, TimeSpentHours, QuizParticipation)
  VALUES (NEW.StudentID, courseId, COALESCE(avgScore, 0), 0, 0, 0)
  ON DUPLICATE KEY UPDATE
    AvgGrade = COALESCE(avgScore, AvgGrade),
    LastUpdated = CURRENT_TIMESTAMP;
END$$

-- Trigger: Update Analytics After Assignment Score Update
DROP TRIGGER IF EXISTS trg_after_assignment_score_update$$
CREATE TRIGGER trg_after_assignment_score_update
AFTER UPDATE ON AssignmentSubmission
FOR EACH ROW
BEGIN
  DECLARE courseId INT;
  DECLARE avgScore DECIMAL(6,2);
  
  IF NEW.Score != OLD.Score OR (NEW.Score IS NOT NULL AND OLD.Score IS NULL) THEN
    -- Get course ID
    SELECT CourseID INTO courseId FROM Assignment WHERE AssignmentID = NEW.AssignmentID;
    
    -- Calculate new average
    SELECT AVG(asub.Score) INTO avgScore
    FROM AssignmentSubmission asub
    JOIN Assignment a ON asub.AssignmentID = a.AssignmentID
    WHERE asub.StudentID = NEW.StudentID AND a.CourseID = courseId;
    
    -- Update analytics
    UPDATE Analytics
    SET AvgGrade = COALESCE(avgScore, AvgGrade),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StudentID = NEW.StudentID AND CourseID = courseId;
  END IF;
END$$

-- ===========================
-- COURSE ENROLLMENT TRIGGERS
-- ===========================

-- Trigger: Initialize Analytics on Enrollment
DROP TRIGGER IF EXISTS trg_after_course_enrollment$$
CREATE TRIGGER trg_after_course_enrollment
AFTER INSERT ON CourseEnrollment
FOR EACH ROW
BEGIN
  -- Create initial analytics record
  INSERT IGNORE INTO Analytics (
    StudentID, CourseID, AvgGrade, CompletionRate, 
    TimeSpentHours, QuizParticipation
  )
  VALUES (NEW.StuId, NEW.CourseId, 0, 0, 0, 0);
END$$

-- Trigger: Update Course Rating After Review
DROP TRIGGER IF EXISTS trg_after_rating_update$$
CREATE TRIGGER trg_after_rating_update
AFTER UPDATE ON CourseEnrollment
FOR EACH ROW
BEGIN
  DECLARE newAvgRating DECIMAL(3,2);
  
  IF NEW.Rating != OLD.Rating OR (NEW.Rating IS NOT NULL AND OLD.Rating IS NULL) THEN
    -- Calculate new average rating
    SELECT AVG(Rating) INTO newAvgRating
    FROM CourseEnrollment
    WHERE CourseId = NEW.CourseId AND Rating IS NOT NULL;
    
    -- Update course
    UPDATE Course
    SET AvgRating = COALESCE(newAvgRating, 0.00)
    WHERE CourseId = NEW.CourseId;
  END IF;
END$$

-- ===========================
-- MATERIAL COMPLETION TRIGGERS
-- ===========================

-- Trigger: Update Analytics After Material Completion
DROP TRIGGER IF EXISTS trg_after_material_completion$$
CREATE TRIGGER trg_after_material_completion
AFTER INSERT ON MaterialCompletion
FOR EACH ROW
BEGIN
  DECLARE courseId INT;
  DECLARE totalMaterials INT;
  DECLARE completedMaterials INT;
  DECLARE completionPct DECIMAL(5,2);
  DECLARE totalTimeHours DECIMAL(6,2);
  
  -- Get course ID
  SELECT CourseId INTO courseId 
  FROM CourseMaterial 
  WHERE MaterialId = NEW.MaterialId;
  
  -- Count total materials in course
  SELECT COUNT(*) INTO totalMaterials
  FROM CourseMaterial
  WHERE CourseId = courseId;
  
  -- Count completed materials by this student
  SELECT COUNT(*) INTO completedMaterials
  FROM MaterialCompletion mc
  JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
  WHERE mc.StuId = NEW.StuId AND cm.CourseId = courseId;
  
  -- Calculate completion percentage
  SET completionPct = (completedMaterials * 100.0) / totalMaterials;
  
  -- Calculate total time spent
  SELECT SUM(mc.TimeSpent) / 3600.0 INTO totalTimeHours
  FROM MaterialCompletion mc
  JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
  WHERE mc.StuId = NEW.StuId AND cm.CourseId = courseId;
  
  -- Update analytics
  INSERT INTO Analytics (
    StudentID, CourseID, AvgGrade, CompletionRate, 
    TimeSpentHours, QuizParticipation
  )
  VALUES (NEW.StuId, courseId, 0, completionPct, totalTimeHours, 0)
  ON DUPLICATE KEY UPDATE
    CompletionRate = completionPct,
    TimeSpentHours = totalTimeHours,
    LastUpdated = CURRENT_TIMESTAMP;
    
  -- Update daily stats
  INSERT INTO MaterialDailyStats (StuId, MaterialId, Date, TimeSpentSeconds)
  VALUES (NEW.StuId, NEW.MaterialId, NEW.Date, NEW.TimeSpent)
  ON DUPLICATE KEY UPDATE
    TimeSpentSeconds = TimeSpentSeconds + NEW.TimeSpent;
END$$

-- ===========================
-- RISK ALERT TRIGGERS
-- ===========================

-- Trigger: Create Risk Alert for Low Completion
DROP TRIGGER IF EXISTS trg_check_completion_risk$$
CREATE TRIGGER trg_check_completion_risk
AFTER UPDATE ON Analytics
FOR EACH ROW
BEGIN
  IF NEW.CompletionRate < 30 AND NEW.CompletionRate != OLD.CompletionRate THEN
    INSERT IGNORE INTO RiskAlert (StudentID, CourseID, Reason, Resolved)
    VALUES (
      NEW.StudentID, 
      NEW.CourseID, 
      CONCAT('Low completion rate: ', ROUND(NEW.CompletionRate, 2), '%'),
      0
    );
  END IF;
  
  IF NEW.AvgGrade < 50 AND NEW.AvgGrade != OLD.AvgGrade AND NEW.AvgGrade > 0 THEN
    INSERT IGNORE INTO RiskAlert (StudentID, CourseID, Reason, Resolved)
    VALUES (
      NEW.StudentID,
      NEW.CourseID,
      CONCAT('Low average grade: ', ROUND(NEW.AvgGrade, 2)),
      0
    );
  END IF;
END$$

-- ===========================
-- CERTIFICATE TRIGGERS
-- ===========================

-- Trigger: Update Enrollment Status on Certificate Issue
DROP TRIGGER IF EXISTS trg_after_certificate_issue$$
CREATE TRIGGER trg_after_certificate_issue
AFTER INSERT ON Certificate
FOR EACH ROW
BEGIN
  -- Mark enrollment as certified and completed
  UPDATE CourseEnrollment
  SET Certification = 1,
      CompleteDate = NEW.IssueDate
  WHERE StuId = NEW.StuId AND CourseId = NEW.CourseId;
END$$

-- ===========================
-- USER MANAGEMENT TRIGGERS
-- ===========================

-- Trigger: Create User Preferences on User Creation
DROP TRIGGER IF EXISTS trg_after_user_insert$$
CREATE TRIGGER trg_after_user_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
  -- Create default preferences for new user
  INSERT INTO UserPreferences (UserId, Theme, Language, NotificationsEnabled)
  VALUES (NEW.UserId, 'light', 'en', 1);
END$$

-- ===========================
-- QUIZ ANSWER TRIGGERS
-- ===========================

-- Trigger: Mark Quiz Answer as Correct/Incorrect
DROP TRIGGER IF EXISTS trg_before_quiz_answer_insert$$
CREATE TRIGGER trg_before_quiz_answer_insert
BEFORE INSERT ON QuizAnswer
FOR EACH ROW
BEGIN
  DECLARE correctOpt CHAR(1);
  
  -- Get the correct option for this question
  SELECT CorrectOption INTO correctOpt
  FROM QuizQuestion
  WHERE QuestionID = NEW.QuestionID;
  
  -- Set IsCorrect based on comparison
  IF NEW.ChosenOption = correctOpt THEN
    SET NEW.IsCorrect = 1;
  ELSE
    SET NEW.IsCorrect = 0;
  END IF;
END$$

-- ===========================
-- COURSE MANAGEMENT TRIGGERS
-- ===========================

-- Trigger: Validate Course Prerequisites Before Enrollment
DROP TRIGGER IF EXISTS trg_before_enrollment_insert$$
CREATE TRIGGER trg_before_enrollment_insert
BEFORE INSERT ON CourseEnrollment
FOR EACH ROW
BEGIN
  DECLARE prereqCount INT;
  DECLARE metPrereqCount INT;
  
  -- Count total prerequisites for this course
  SELECT COUNT(*) INTO prereqCount
  FROM CoursePrerequisite
  WHERE CourseId = NEW.CourseId;
  
  -- Count met prerequisites
  SELECT COUNT(*) INTO metPrereqCount
  FROM CoursePrerequisite cp
  WHERE cp.CourseId = NEW.CourseId
  AND EXISTS (
    SELECT 1 FROM CourseEnrollment ce
    WHERE ce.StuId = NEW.StuId 
    AND ce.CourseId = cp.PrerequisiteCourseId
    AND ce.Certification = 1
  );
  
  -- If prerequisites exist but not all are met, prevent enrollment
  IF prereqCount > 0 AND metPrereqCount < prereqCount THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot enroll: Course prerequisites not met';
  END IF;
END$$

-- ===========================
-- PASSWORD RESET TRIGGERS
-- ===========================

-- Trigger: Expire Old Password Reset Tokens
DROP TRIGGER IF EXISTS trg_after_password_reset_insert$$
CREATE TRIGGER trg_after_password_reset_insert
AFTER INSERT ON PasswordReset
FOR EACH ROW
BEGIN
  -- Mark all previous unused tokens for this user as used
  UPDATE PasswordReset
  SET Used = 1
  WHERE UserId = NEW.UserId 
  AND ResetId != NEW.ResetId 
  AND Used = 0;
END$$

-- ===========================
-- DISCUSSION TRIGGERS
-- ===========================

-- Trigger: Log Report Generation
DROP TRIGGER IF EXISTS trg_after_report_generation$$
CREATE TRIGGER trg_after_report_generation
AFTER INSERT ON ReportLog
FOR EACH ROW
BEGIN
  -- Could trigger notifications or additional logging here
  -- This is a placeholder for future enhancements
  SET @last_report_id = NEW.ReportId;
END$$

DELIMITER ;