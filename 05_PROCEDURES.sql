-- ====================================================
-- TRAINLY STORED PROCEDURES
-- Reusable database procedures for common operations
-- ====================================================

USE TRAINLY;

DELIMITER $$

-- ===========================
-- ANALYTICS PROCEDURES
-- ===========================

-- Procedure: Calculate Completion Rate for a Course
DROP PROCEDURE IF EXISTS sp_calculate_completion$$
CREATE PROCEDURE sp_calculate_completion(IN inCourseId INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE curStu INT;
  DECLARE totalMaterials INT;
  DECLARE completedMaterials INT;
  DECLARE cur CURSOR FOR 
    SELECT DISTINCT StuId FROM CourseEnrollment WHERE CourseId = inCourseId;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  -- Get total materials for the course
  SELECT COUNT(*) INTO totalMaterials 
  FROM CourseMaterial 
  WHERE CourseId = inCourseId;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO curStu;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;

    -- Count completed materials for this student
    SELECT COUNT(*) INTO completedMaterials
    FROM MaterialCompletion mc
    JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
    WHERE cm.CourseId = inCourseId AND mc.StuId = curStu;

    -- Update or insert analytics record
    INSERT INTO Analytics (StudentID, CourseID, CompletionRate, AvgGrade, TimeSpentHours, QuizParticipation)
    VALUES (curStu, inCourseId, 
      CASE WHEN totalMaterials = 0 THEN 0 
           ELSE (completedMaterials / totalMaterials) * 100 
      END, 0, 0, 0)
    ON DUPLICATE KEY UPDATE 
      CompletionRate = CASE WHEN totalMaterials = 0 THEN 0 
                            ELSE (completedMaterials / totalMaterials) * 100 
                       END,
      LastUpdated = CURRENT_TIMESTAMP;
  END LOOP;
  CLOSE cur;
END$$

-- Procedure: Generate Weekly Course Report
DROP PROCEDURE IF EXISTS sp_weekly_report$$
CREATE PROCEDURE sp_weekly_report(IN inCourseId INT)
BEGIN
  SELECT 
    u.FirstName, 
    u.LastName, 
    an.AvgGrade, 
    an.CompletionRate, 
    an.TimeSpentHours,
    an.QuizParticipation
  FROM Analytics an
  JOIN Student s ON an.StudentID = s.StuId
  JOIN Users u ON s.UserId = u.UserId
  WHERE an.CourseID = inCourseId
  ORDER BY an.AvgGrade DESC, an.CompletionRate DESC;
END$$

-- Procedure: Update Student Analytics
DROP PROCEDURE IF EXISTS sp_update_student_analytics$$
CREATE PROCEDURE sp_update_student_analytics(
  IN inStudentId INT,
  IN inCourseId INT
)
BEGIN
  DECLARE avgAssignmentScore DECIMAL(5,2);
  DECLARE avgQuizScore DECIMAL(5,2);
  DECLARE completionPct DECIMAL(5,2);
  DECLARE totalHours DECIMAL(6,2);
  DECLARE quizCount INT;
  
  -- Calculate average assignment score
  SELECT COALESCE(AVG(asub.Score), 0) INTO avgAssignmentScore
  FROM AssignmentSubmission asub
  JOIN Assignment a ON asub.AssignmentID = a.AssignmentID
  WHERE asub.StudentID = inStudentId AND a.CourseID = inCourseId;
  
  -- Calculate average quiz score
  SELECT COALESCE(AVG(qs.Score), 0) INTO avgQuizScore
  FROM QuizSubmission qs
  JOIN Quiz q ON qs.QuizID = q.QuizID
  WHERE qs.StudentID = inStudentId AND q.CourseID = inCourseId;
  
  -- Calculate completion rate
  SELECT 
    CASE WHEN COUNT(DISTINCT cm.MaterialId) = 0 THEN 0
         ELSE (COUNT(DISTINCT mc.MaterialId) * 100.0 / COUNT(DISTINCT cm.MaterialId))
    END INTO completionPct
  FROM CourseMaterial cm
  LEFT JOIN MaterialCompletion mc ON cm.MaterialId = mc.MaterialId AND mc.StuId = inStudentId
  WHERE cm.CourseId = inCourseId;
  
  -- Calculate total time spent
  SELECT COALESCE(SUM(mc.TimeSpent) / 3600.0, 0) INTO totalHours
  FROM MaterialCompletion mc
  JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
  WHERE mc.StuId = inStudentId AND cm.CourseId = inCourseId;
  
  -- Count quiz participation
  SELECT COUNT(DISTINCT qs.QuizID) INTO quizCount
  FROM QuizSubmission qs
  JOIN Quiz q ON qs.QuizID = q.QuizID
  WHERE qs.StudentID = inStudentId AND q.CourseID = inCourseId;
  
  -- Update analytics
  INSERT INTO Analytics (
    StudentID, CourseID, AvgGrade, CompletionRate, 
    TimeSpentHours, QuizParticipation
  )
  VALUES (
    inStudentId, inCourseId, 
    (avgAssignmentScore + avgQuizScore) / 2,
    completionPct, totalHours, quizCount
  )
  ON DUPLICATE KEY UPDATE
    AvgGrade = (avgAssignmentScore + avgQuizScore) / 2,
    CompletionRate = completionPct,
    TimeSpentHours = totalHours,
    QuizParticipation = quizCount,
    LastUpdated = CURRENT_TIMESTAMP;
END$$

-- ===========================
-- ENROLLMENT PROCEDURES
-- ===========================

-- Procedure: Enroll Student in Course
DROP PROCEDURE IF EXISTS sp_enroll_student$$
CREATE PROCEDURE sp_enroll_student(
  IN inStudentId INT,
  IN inCourseId INT,
  IN inEnrollCode VARCHAR(50)
)
BEGIN
  DECLARE courseStatus VARCHAR(20);
  DECLARE prereqsMet BOOLEAN DEFAULT TRUE;
  
  -- Check if course is active
  SELECT Status INTO courseStatus FROM Course WHERE CourseId = inCourseId;
  
  IF courseStatus != 'active' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot enroll: Course is not active';
  END IF;
  
  -- Check prerequisites
  SELECT COUNT(*) = 0 INTO prereqsMet
  FROM CoursePrerequisite cp
  WHERE cp.CourseId = inCourseId
  AND NOT EXISTS (
    SELECT 1 FROM CourseEnrollment ce
    WHERE ce.StuId = inStudentId 
    AND ce.CourseId = cp.PrerequisiteCourseId
    AND ce.Certification = 1
  );
  
  IF NOT prereqsMet THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot enroll: Prerequisites not met';
  END IF;
  
  -- Enroll student
  INSERT INTO CourseEnrollment (
    StuId, CourseId, EnrollCode, EnrollDate, EnrollTime
  )
  VALUES (
    inStudentId, inCourseId, inEnrollCode, CURDATE(), CURTIME()
  );
  
  -- Initialize analytics
  INSERT INTO Analytics (StudentID, CourseID, AvgGrade, CompletionRate, TimeSpentHours, QuizParticipation)
  VALUES (inStudentId, inCourseId, 0, 0, 0, 0);
  
  SELECT 'Enrollment successful' AS Message;
END$$

-- ===========================
-- RISK ALERT PROCEDURES
-- ===========================

-- Procedure: Identify At-Risk Students
DROP PROCEDURE IF EXISTS sp_identify_at_risk_students$$
CREATE PROCEDURE sp_identify_at_risk_students(IN inCourseId INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE curStudentId INT;
  DECLARE lastActivityDays INT;
  DECLARE completionPct DECIMAL(5,2);
  DECLARE cur CURSOR FOR
    SELECT DISTINCT ce.StuId
    FROM CourseEnrollment ce
    WHERE ce.CourseId = inCourseId AND ce.CompleteDate IS NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  risk_loop: LOOP
    FETCH cur INTO curStudentId;
    IF done = 1 THEN
      LEAVE risk_loop;
    END IF;

    -- Check days since last activity
    SELECT COALESCE(DATEDIFF(CURDATE(), MAX(mc.Date)), 999) INTO lastActivityDays
    FROM MaterialCompletion mc
    JOIN CourseMaterial cm ON mc.MaterialId = cm.MaterialId
    WHERE mc.StuId = curStudentId AND cm.CourseId = inCourseId;

    -- Get completion rate
    SELECT COALESCE(CompletionRate, 0) INTO completionPct
    FROM Analytics
    WHERE StudentID = curStudentId AND CourseID = inCourseId;

    -- Create risk alerts
    IF lastActivityDays > 14 THEN
      INSERT IGNORE INTO RiskAlert (StudentID, CourseID, Reason, Resolved)
      VALUES (curStudentId, inCourseId, 
        CONCAT('No activity for ', lastActivityDays, ' days'), 0);
    END IF;

    IF completionPct < 30 THEN
      INSERT IGNORE INTO RiskAlert (StudentID, CourseID, Reason, Resolved)
      VALUES (curStudentId, inCourseId, 
        CONCAT('Low completion rate: ', completionPct, '%'), 0);
    END IF;
  END LOOP;
  CLOSE cur;
  
  SELECT 'At-risk student identification complete' AS Message;
END$$

-- ===========================
-- GRADING PROCEDURES
-- ===========================

-- Procedure: Auto-Grade Quiz
DROP PROCEDURE IF EXISTS sp_auto_grade_quiz$$
CREATE PROCEDURE sp_auto_grade_quiz(IN inQuizSubmissionId INT)
BEGIN
  DECLARE totalQuestions INT;
  DECLARE correctAnswers INT;
  DECLARE maxScore DECIMAL(10,2);
  DECLARE calculatedScore DECIMAL(10,2);
  DECLARE quizId INT;
  
  -- Get quiz info
  SELECT qs.QuizID INTO quizId
  FROM QuizSubmission qs
  WHERE qs.QuizSubmissionID = inQuizSubmissionId;
  
  SELECT q.MaxScore INTO maxScore
  FROM Quiz q
  WHERE q.QuizID = quizId;
  
  -- Count total questions
  SELECT COUNT(*) INTO totalQuestions
  FROM QuizQuestion
  WHERE QuizID = quizId;
  
  -- Count correct answers
  SELECT COUNT(*) INTO correctAnswers
  FROM QuizAnswer qa
  WHERE qa.QuizSubmissionID = inQuizSubmissionId
  AND qa.IsCorrect = 1;
  
  -- Calculate score
  SET calculatedScore = (correctAnswers * maxScore) / totalQuestions;
  
  -- Update submission
  UPDATE QuizSubmission
  SET Score = calculatedScore
  WHERE QuizSubmissionID = inQuizSubmissionId;
  
  SELECT calculatedScore AS FinalScore, 
         correctAnswers AS CorrectAnswers,
         totalQuestions AS TotalQuestions;
END$$

-- ===========================
-- CERTIFICATE PROCEDURES
-- ===========================

-- Procedure: Issue Certificate
DROP PROCEDURE IF EXISTS sp_issue_certificate$$
CREATE PROCEDURE sp_issue_certificate(
  IN inStudentId INT,
  IN inCourseId INT
)
BEGIN
  DECLARE completionPct DECIMAL(5,2);
  DECLARE avgGrade DECIMAL(5,2);
  DECLARE verificationCode VARCHAR(100);
  DECLARE certificatePath VARCHAR(500);
  
  -- Check if student completed course
  SELECT CompletionRate, AvgGrade INTO completionPct, avgGrade
  FROM Analytics
  WHERE StudentID = inStudentId AND CourseID = inCourseId;
  
  IF completionPct < 80 OR avgGrade < 60 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot issue certificate: Requirements not met';
  END IF;
  
  -- Generate verification code
  SET verificationCode = CONCAT('CERT-', inCourseId, '-', inStudentId, '-', 
                                YEAR(CURDATE()));
  
  -- Generate certificate path
  SET certificatePath = CONCAT('/certs/student', inStudentId, '_course', 
                               inCourseId, '.pdf');
  
  -- Insert certificate
  INSERT INTO Certificate (StuId, CourseId, IssueDate, VerificationCode, PDFPath)
  VALUES (inStudentId, inCourseId, CURDATE(), verificationCode, certificatePath);
  
  -- Update enrollment
  UPDATE CourseEnrollment
  SET Certification = 1, CompleteDate = CURDATE()
  WHERE StuId = inStudentId AND CourseId = inCourseId;
  
  SELECT 'Certificate issued successfully' AS Message,
         verificationCode AS VerificationCode;
END$$

-- ===========================
-- COURSE MANAGEMENT PROCEDURES
-- ===========================

-- Procedure: Update Course Rating
DROP PROCEDURE IF EXISTS sp_update_course_rating$$
CREATE PROCEDURE sp_update_course_rating(IN inCourseId INT)
BEGIN
  DECLARE newAvgRating DECIMAL(3,2);
  
  SELECT AVG(Rating) INTO newAvgRating
  FROM CourseEnrollment
  WHERE CourseId = inCourseId AND Rating IS NOT NULL;
  
  UPDATE Course
  SET AvgRating = COALESCE(newAvgRating, 0.00)
  WHERE CourseId = inCourseId;
  
  SELECT COALESCE(newAvgRating, 0.00) AS UpdatedRating;
END$$

-- Procedure: Archive Old Courses
DROP PROCEDURE IF EXISTS sp_archive_old_courses$$
CREATE PROCEDURE sp_archive_old_courses(IN inDaysInactive INT)
BEGIN
  UPDATE Course c
  SET Status = 'archived'
  WHERE Status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM CourseEnrollment ce
    WHERE ce.CourseId = c.CourseId
    AND ce.EnrollDate >= DATE_SUB(CURDATE(), INTERVAL inDaysInactive DAY)
  );
  
  SELECT ROW_COUNT() AS CoursesArchived;
END$$

-- ===========================
-- REPORTING PROCEDURES
-- ===========================

-- Procedure: Generate Student Report Card
DROP PROCEDURE IF EXISTS sp_student_report_card$$
CREATE PROCEDURE sp_student_report_card(
  IN inStudentId INT,
  IN inCourseId INT
)
BEGIN
  SELECT 
    c.Title AS CourseName,
    c.Category,
    CONCAT(u.FirstName, ' ', u.LastName) AS InstructorName,
    ce.EnrollDate,
    ce.CompleteDate,
    an.CompletionRate,
    an.AvgGrade,
    an.TimeSpentHours,
    ce.Rating AS StudentRating,
    ce.Certification
  FROM CourseEnrollment ce
  JOIN Course c ON ce.CourseId = c.CourseId
  JOIN Faculty f ON c.InstructorId = f.FacultyId
  JOIN Users u ON f.UserId = u.UserId
  LEFT JOIN Analytics an ON ce.StuId = an.StudentID AND ce.CourseId = an.CourseID
  WHERE ce.StuId = inStudentId AND ce.CourseId = inCourseId;
  
  -- Assignment scores
  SELECT 
    a.Title AS AssignmentTitle,
    asub.Score,
    a.MaxScore,
    asub.SubmittedAt,
    asub.Feedback
  FROM Assignment a
  LEFT JOIN AssignmentSubmission asub ON a.AssignmentID = asub.AssignmentID 
    AND asub.StudentID = inStudentId
  WHERE a.CourseID = inCourseId
  ORDER BY a.AssignmentID;
  
  -- Quiz scores
  SELECT 
    q.Title AS QuizTitle,
    qs.Score,
    q.MaxScore,
    qs.SubmittedAt
  FROM Quiz q
  LEFT JOIN QuizSubmission qs ON q.QuizID = qs.QuizID 
    AND qs.StudentID = inStudentId
  WHERE q.CourseID = inCourseId
  ORDER BY q.QuizID;
END$$

-- Procedure: Generate Instructor Summary
DROP PROCEDURE IF EXISTS sp_instructor_summary$$
CREATE PROCEDURE sp_instructor_summary(IN inFacultyId INT)
BEGIN
  SELECT 
    CONCAT(u.FirstName, ' ', u.LastName) AS InstructorName,
    f.Title,
    f.Affiliation,
    COUNT(DISTINCT c.CourseId) AS TotalCourses,
    COUNT(DISTINCT ce.StuId) AS TotalStudents,
    ROUND(AVG(c.AvgRating), 2) AS AvgRating,
    SUM(c.Cost * (SELECT COUNT(*) FROM CourseEnrollment WHERE CourseId = c.CourseId)) AS TotalRevenue
  FROM Faculty f
  JOIN Users u ON f.UserId = u.UserId
  LEFT JOIN Course c ON f.FacultyId = c.InstructorId
  LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
  WHERE f.FacultyId = inFacultyId
  GROUP BY InstructorName, f.Title, f.Affiliation;
  
  -- Course details
  SELECT 
    c.CourseId,
    c.Title,
    c.Status,
    COUNT(DISTINCT ce.StuId) AS Enrollments,
    c.AvgRating
  FROM Course c
  LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
  WHERE c.InstructorId = inFacultyId
  GROUP BY c.CourseId, c.Title, c.Status, c.AvgRating
  ORDER BY Enrollments DESC;
END$$

DELIMITER ;