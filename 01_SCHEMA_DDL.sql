-- ====================================================
-- TRAINLY DATABASE SCHEMA (DDL)
-- Data Definition Language - Tables, Constraints, Indexes
-- ====================================================

DROP DATABASE IF EXISTS TRAINLY;
CREATE DATABASE TRAINLY CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE TRAINLY;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

-- ===========================
-- 1) CORE PLATFORM TABLES
-- ===========================

CREATE TABLE Users (
  UserId INT NOT NULL AUTO_INCREMENT,
  Email VARCHAR(100) NOT NULL,
  FirstName VARCHAR(50) NOT NULL,
  LastName VARCHAR(50) NOT NULL,
  Password VARCHAR(255) DEFAULT NULL,
  Role ENUM('admin','instructor','student') NOT NULL DEFAULT 'student',
  Status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (UserId),
  UNIQUE KEY UK_User_Email (Email),
  INDEX idx_role (Role),
  INDEX idx_status (Status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE UserPreferences (
  PreferenceId INT NOT NULL AUTO_INCREMENT,
  UserId INT NOT NULL,
  Theme ENUM('light','dark') DEFAULT 'light',
  Language VARCHAR(20) DEFAULT 'en',
  NotificationsEnabled TINYINT(1) DEFAULT 1,
  PRIMARY KEY (PreferenceId),
  UNIQUE KEY UK_UserPreferences_User (UserId),
  CONSTRAINT pref_fk_user FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PasswordReset (
  ResetId INT NOT NULL AUTO_INCREMENT,
  UserId INT NOT NULL,
  Token VARCHAR(255) NOT NULL,
  ExpiresAt DATETIME NOT NULL,
  Used TINYINT(1) DEFAULT 0,
  PRIMARY KEY (ResetId),
  UNIQUE KEY UK_Token (Token),
  KEY FK_PasswordReset_User (UserId),
  KEY idx_expires (ExpiresAt),
  CONSTRAINT passwordreset_fk_user FOREIGN KEY (UserId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Administrator (
  AdminId INT NOT NULL AUTO_INCREMENT,
  UserId INT NOT NULL,
  Grantor INT DEFAULT NULL,
  GrantedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (AdminId),
  UNIQUE KEY UK_Admin_User (UserId),
  KEY FK_Admin_Grantor (Grantor),
  CONSTRAINT administrator_ibfk_2 FOREIGN KEY (UserId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT administrator_ibfk_1 FOREIGN KEY (Grantor) REFERENCES Administrator(AdminId)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Faculty (
  FacultyId INT NOT NULL AUTO_INCREMENT,
  UserId INT NOT NULL,
  Title VARCHAR(50),
  Affiliation VARCHAR(150),
  Website VARCHAR(255),
  VerifiedBy INT DEFAULT NULL,
  VerifiedAt TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (FacultyId),
  UNIQUE KEY UK_Faculty_User (UserId),
  KEY FK_Faculty_VerifiedBy (VerifiedBy),
  CONSTRAINT faculty_ibfk_1 FOREIGN KEY (UserId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT faculty_ibfk_2 FOREIGN KEY (VerifiedBy) REFERENCES Users(UserId)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Student (
  StuId INT NOT NULL AUTO_INCREMENT,
  UserId INT NOT NULL,
  PRIMARY KEY (StuId),
  UNIQUE KEY UK_Student_User (UserId),
  CONSTRAINT student_ibfk_1 FOREIGN KEY (UserId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 2) COURSE STRUCTURE
-- ===========================

CREATE TABLE Topic (
  TopicId INT NOT NULL AUTO_INCREMENT,
  Name VARCHAR(200) NOT NULL,
  PRIMARY KEY (TopicId),
  UNIQUE KEY UK_Topic_Name (Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Course (
  CourseId INT NOT NULL AUTO_INCREMENT,
  InstructorId INT NOT NULL,
  Title VARCHAR(255) NOT NULL,
  Category VARCHAR(100),
  DurationHours INT DEFAULT 0,
  Syllabus TEXT,
  Status ENUM('pending','active','archived') DEFAULT 'pending',
  Cost DECIMAL(10,2) DEFAULT 0.00,
  AvgRating DECIMAL(3,2) DEFAULT 0.00,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (CourseId),
  KEY FK_Course_Instructor (InstructorId),
  KEY idx_status (Status),
  KEY idx_category (Category),
  CONSTRAINT chk_duration CHECK (DurationHours >= 0),
  CONSTRAINT chk_cost CHECK (Cost >= 0),
  CONSTRAINT course_ibfk_1 FOREIGN KEY (InstructorId) REFERENCES Faculty(FacultyId) 
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE SecondaryTopics (
  CourseId INT NOT NULL,
  TopicId INT NOT NULL,
  PRIMARY KEY (CourseId,TopicId),
  KEY FK_SecondaryTopics_Topic (TopicId),
  CONSTRAINT secondarytopics_ibfk_1 FOREIGN KEY (CourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT secondarytopics_ibfk_2 FOREIGN KEY (TopicId) REFERENCES Topic(TopicId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CourseCreation (
  CourseId INT NOT NULL,
  FacultyId INT NOT NULL,
  DateCreated DATE NOT NULL,
  PRIMARY KEY (CourseId,FacultyId),
  KEY FK_CourseCreation_Faculty (FacultyId),
  CONSTRAINT coursecreation_ibfk_1 FOREIGN KEY (CourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT coursecreation_ibfk_2 FOREIGN KEY (FacultyId) REFERENCES Faculty(FacultyId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CoursePrerequisite (
  CourseId INT NOT NULL,
  PrerequisiteCourseId INT NOT NULL,
  PRIMARY KEY (CourseId,PrerequisiteCourseId),
  KEY FK_Prereq (PrerequisiteCourseId),
  CONSTRAINT fk_course_prereq_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_course_prereq_prereq FOREIGN KEY (PrerequisiteCourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ModulePrerequisite (
  CourseId INT NOT NULL,
  ModuleIndex INT NOT NULL,
  RequiredModuleIndex INT NOT NULL,
  PRIMARY KEY (CourseId,ModuleIndex,RequiredModuleIndex),
  CONSTRAINT modpre_fk_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CourseAnnouncement (
  AnnouncementId INT NOT NULL AUTO_INCREMENT,
  CourseId INT NOT NULL,
  FacultyId INT NOT NULL,
  Title VARCHAR(255) NOT NULL,
  Message TEXT NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (AnnouncementId),
  KEY idx_course_date (CourseId, CreatedAt),
  CONSTRAINT ann_fk_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ann_fk_faculty FOREIGN KEY (FacultyId) REFERENCES Faculty(FacultyId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE VirtualClassroom (
  SessionId INT NOT NULL AUTO_INCREMENT,
  CourseId INT NOT NULL,
  CreatedBy INT NOT NULL,
  MeetingURL VARCHAR(500) NOT NULL,
  StartTime DATETIME NOT NULL,
  EndTime DATETIME,
  PRIMARY KEY (SessionId),
  KEY idx_course_start (CourseId, StartTime),
  CONSTRAINT chk_end_after_start CHECK (EndTime IS NULL OR EndTime > StartTime),
  CONSTRAINT vc_fk_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT vc_fk_faculty FOREIGN KEY (CreatedBy) REFERENCES Faculty(FacultyId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 3) COURSE MATERIALS
-- ===========================

CREATE TABLE CourseMaterial (
  MaterialId INT NOT NULL AUTO_INCREMENT,
  CourseId INT NOT NULL,
  ModuleIndex INT DEFAULT 1,
  LessonIndex INT DEFAULT 1,
  Title VARCHAR(255) NOT NULL,
  MaterialType ENUM('video','pdf','slide','quiz','assignment','link','post') NOT NULL,
  PathOrUrl VARCHAR(500),
  DurationSeconds INT DEFAULT 0,
  PRIMARY KEY (MaterialId),
  KEY idx_course_module_lesson (CourseId, ModuleIndex, LessonIndex),
  KEY idx_course_type (CourseId, MaterialType),
  CONSTRAINT coursematerial_ibfk_1 FOREIGN KEY (CourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DownloadableFile (
  MaterialId INT NOT NULL,
  Path VARCHAR(400) NOT NULL,
  Size BIGINT NOT NULL,
  Type VARCHAR(40) NOT NULL,
  PRIMARY KEY (MaterialId),
  CONSTRAINT downloadablefile_ibfk_1 FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Link (
  MaterialId INT NOT NULL,
  URL VARCHAR(800) NOT NULL,
  VideoTag TINYINT(1) DEFAULT 0,
  PRIMARY KEY (MaterialId),
  CONSTRAINT link_ibfk_1 FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Post (
  MaterialId INT NOT NULL,
  Text TEXT NOT NULL,
  PRIMARY KEY (MaterialId),
  FULLTEXT KEY ft_text (Text),
  CONSTRAINT post_ibfk_1 FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 4) ENROLLMENT & PROGRESS
-- ===========================

CREATE TABLE CourseEnrollment (
  StuId INT NOT NULL,
  CourseId INT NOT NULL,
  EnrollCode VARCHAR(50) NOT NULL,
  EnrollDate DATE NOT NULL,
  EnrollTime TIME NOT NULL,
  Rating TINYINT DEFAULT NULL CHECK (Rating BETWEEN 1 AND 5),
  Certification TINYINT(1) DEFAULT 0,
  CompleteDate DATE DEFAULT NULL,
  Comment TEXT,
  PRIMARY KEY (StuId,CourseId),
  KEY FK_CourseEnrollment_Course (CourseId),
  KEY idx_enroll_date (EnrollDate),
  KEY idx_student_date (StuId, EnrollDate),
  CONSTRAINT courseenrollment_ibfk_1 FOREIGN KEY (StuId) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT courseenrollment_ibfk_2 FOREIGN KEY (CourseId) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE MaterialCompletion (
  StuId INT NOT NULL,
  MaterialId INT NOT NULL,
  Date DATE NOT NULL,
  Time TIME NOT NULL,
  TimeSpent INT NOT NULL DEFAULT 0,
  PRIMARY KEY (StuId,MaterialId),
  KEY FK_MaterialCompletion_Material (MaterialId),
  KEY idx_date (Date),
  KEY idx_student_date (StuId, Date),
  CONSTRAINT materialcompletion_ibfk_1 FOREIGN KEY (StuId) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT materialcompletion_ibfk_2 FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE MaterialDailyStats (
  StuId INT NOT NULL,
  MaterialId INT NOT NULL,
  Date DATE NOT NULL,
  TimeSpentSeconds INT DEFAULT 0,
  PRIMARY KEY (StuId,MaterialId,Date),
  KEY idx_date (Date),
  CONSTRAINT mds_fk_student FOREIGN KEY (StuId) REFERENCES Student(StuId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT mds_fk_material FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 5) ASSIGNMENTS & RUBRICS
-- ===========================

CREATE TABLE Assignment (
  AssignmentID INT NOT NULL AUTO_INCREMENT,
  CourseID INT NOT NULL,
  Title VARCHAR(255) NOT NULL,
  Description TEXT,
  DueDate DATETIME,
  MaxScore DECIMAL(10,2),
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (AssignmentID),
  KEY idx_course_due (CourseID, DueDate),
  CONSTRAINT chk_assignment_score CHECK (MaxScore > 0),
  CONSTRAINT assignment_fk_course FOREIGN KEY (CourseID) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Rubric (
  RubricId INT NOT NULL AUTO_INCREMENT,
  AssignmentID INT NOT NULL,
  Criterion VARCHAR(255) NOT NULL,
  MaxPoints DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (RubricId),
  KEY idx_assignment (AssignmentID),
  CONSTRAINT chk_rubric_points CHECK (MaxPoints > 0),
  CONSTRAINT rubric_fk_assignment FOREIGN KEY (AssignmentID) REFERENCES Assignment(AssignmentID)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE AssignmentSubmission (
  SubmissionID INT NOT NULL AUTO_INCREMENT,
  AssignmentID INT NOT NULL,
  StudentID INT NOT NULL,
  SubmissionText TEXT,
  FilePath VARCHAR(500),
  SubmittedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  Score DECIMAL(10,2),
  Feedback TEXT,
  PRIMARY KEY (SubmissionID),
  KEY idx_assignment_student (AssignmentID, StudentID),
  KEY idx_submitted (SubmittedAt),
  KEY idx_student (StudentID),
  CONSTRAINT assignsub_fk_assignment FOREIGN KEY (AssignmentID) REFERENCES Assignment(AssignmentID) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT assignsub_fk_student FOREIGN KEY (StudentID) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 6) QUIZZES & TESTS
-- ===========================

CREATE TABLE Quiz (
  QuizID INT NOT NULL AUTO_INCREMENT,
  CourseID INT NOT NULL,
  Title VARCHAR(255),
  Instructions TEXT,
  TimeLimitMinutes INT,
  MaxScore DECIMAL(10,2),
  StartTime DATETIME,
  EndTime DATETIME,
  MaxAttempts INT DEFAULT 1,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (QuizID),
  KEY idx_course (CourseID),
  KEY idx_start_end (StartTime, EndTime),
  CONSTRAINT chk_quiz_time_limit CHECK (TimeLimitMinutes IS NULL OR TimeLimitMinutes > 0),
  CONSTRAINT chk_quiz_attempts CHECK (MaxAttempts > 0),
  CONSTRAINT quiz_fk_course FOREIGN KEY (CourseID) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE QuizQuestion (
  QuestionID INT NOT NULL AUTO_INCREMENT,
  QuizID INT NOT NULL,
  QuestionText TEXT NOT NULL,
  OptionA VARCHAR(500),
  OptionB VARCHAR(500),
  OptionC VARCHAR(500),
  OptionD VARCHAR(500),
  CorrectOption CHAR(1) CHECK (CorrectOption IN ('A','B','C','D')),
  PRIMARY KEY (QuestionID),
  KEY idx_quiz (QuizID),
  CONSTRAINT qq_fk_quiz FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE QuizSubmission (
  QuizSubmissionID INT NOT NULL AUTO_INCREMENT,
  QuizID INT NOT NULL,
  StudentID INT NOT NULL,
  SubmittedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  Score DECIMAL(10,2),
  PRIMARY KEY (QuizSubmissionID),
  KEY idx_quiz_student (QuizID, StudentID),
  KEY idx_student (StudentID),
  KEY idx_submitted (SubmittedAt),
  CONSTRAINT quizsub_fk_quiz FOREIGN KEY (QuizID) REFERENCES Quiz(QuizID) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT quizsub_fk_student FOREIGN KEY (StudentID) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE QuizAnswer (
  QuizAnswerID INT NOT NULL AUTO_INCREMENT,
  QuizSubmissionID INT NOT NULL,
  QuestionID INT NOT NULL,
  ChosenOption CHAR(1) CHECK (ChosenOption IN ('A','B','C','D')),
  IsCorrect TINYINT(1) DEFAULT 0,
  PRIMARY KEY (QuizAnswerID),
  KEY idx_submission (QuizSubmissionID),
  KEY idx_question (QuestionID),
  CONSTRAINT quizanswer_fk_submission FOREIGN KEY (QuizSubmissionID) REFERENCES QuizSubmission(QuizSubmissionID) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT quizanswer_fk_question FOREIGN KEY (QuestionID) REFERENCES QuizQuestion(QuestionID) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 7) EXAMS
-- ===========================

CREATE TABLE Exam (
  ExamID INT NOT NULL AUTO_INCREMENT,
  CourseID INT NOT NULL,
  Title VARCHAR(255),
  Instructions TEXT,
  ExamDate DATETIME,
  MaxScore DECIMAL(10,2),
  PRIMARY KEY (ExamID),
  KEY idx_course (CourseID),
  KEY idx_exam_date (ExamDate),
  CONSTRAINT exam_fk_course FOREIGN KEY (CourseID) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ExamSubmission (
  ExamSubmissionID INT NOT NULL AUTO_INCREMENT,
  ExamID INT NOT NULL,
  StudentID INT NOT NULL,
  SubmittedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  Score DECIMAL(10,2),
  Feedback TEXT,
  PRIMARY KEY (ExamSubmissionID),
  KEY idx_exam_student (ExamID, StudentID),
  KEY idx_student (StudentID),
  CONSTRAINT examsub_fk_exam FOREIGN KEY (ExamID) REFERENCES Exam(ExamID) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT examsub_fk_student FOREIGN KEY (StudentID) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 8) Q&A, FORUMS, & HELP
-- ===========================

CREATE TABLE Question (
  QuestionId INT NOT NULL AUTO_INCREMENT,
  Title VARCHAR(255) NOT NULL,
  Content TEXT NOT NULL,
  StuId INT NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (QuestionId),
  KEY FK_Question_Stu (StuId),
  KEY idx_created (CreatedAt DESC),
  FULLTEXT KEY ft_title_content (Title, Content),
  CONSTRAINT question_ibfk_1 FOREIGN KEY (StuId) REFERENCES Student(StuId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE QuestionRelateTo (
  QuestionId INT NOT NULL,
  MaterialId INT NOT NULL,
  PRIMARY KEY (QuestionId,MaterialId),
  KEY FK_QuestionRelateTo_Material (MaterialId),
  CONSTRAINT questionrelateto_ibfk_1 FOREIGN KEY (QuestionId) REFERENCES Question(QuestionId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT questionrelateto_ibfk_2 FOREIGN KEY (MaterialId) REFERENCES CourseMaterial(MaterialId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LikeQuestion (
  StuId INT NOT NULL,
  QuestionId INT NOT NULL,
  PRIMARY KEY (StuId,QuestionId),
  KEY FK_LikeQuestion_Q (QuestionId),
  CONSTRAINT likequestion_ibfk_2 FOREIGN KEY (StuId) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT likequestion_ibfk_1 FOREIGN KEY (QuestionId) REFERENCES Question(QuestionId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE FindUseful (
  FacultyId INT NOT NULL,
  QuestionId INT NOT NULL,
  Visible TINYINT(1) NOT NULL DEFAULT 1,
  Answer TEXT,
  PRIMARY KEY (FacultyId,QuestionId),
  KEY FK_FindUseful_Q (QuestionId),
  CONSTRAINT finduseful_ibfk_1 FOREIGN KEY (FacultyId) REFERENCES Faculty(FacultyId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT finduseful_ibfk_2 FOREIGN KEY (QuestionId) REFERENCES Question(QuestionId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DiscussionThread (
  ThreadId INT NOT NULL AUTO_INCREMENT,
  CourseId INT NOT NULL,
  CreatedBy INT NOT NULL,
  Title VARCHAR(255) NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ThreadId),
  KEY idx_course_date (CourseId, CreatedAt DESC),
  CONSTRAINT thread_fk_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT thread_fk_user FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE DiscussionPost (
  PostId INT NOT NULL AUTO_INCREMENT,
  ThreadId INT NOT NULL,
  UserId INT NOT NULL,
  Text TEXT NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (PostId),
  KEY idx_thread_date (ThreadId, CreatedAt),
  CONSTRAINT post_fk_thread FOREIGN KEY (ThreadId) REFERENCES DiscussionThread(ThreadId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT post_fk_user FOREIGN KEY (UserId) REFERENCES Users(UserId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 9) MESSAGING
-- ===========================

CREATE TABLE Message (
  MessageId INT NOT NULL AUTO_INCREMENT,
  SenderId INT NOT NULL,
  ReceiverId INT NOT NULL,
  Body TEXT NOT NULL,
  SentAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (MessageId),
  KEY idx_sender_date (SenderId, SentAt DESC),
  KEY idx_receiver_date (ReceiverId, SentAt DESC),
  CONSTRAINT message_fk_sender FOREIGN KEY (SenderId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT message_fk_receiver FOREIGN KEY (ReceiverId) REFERENCES Users(UserId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- 10) ANALYTICS & REPORTING
-- ===========================

CREATE TABLE Analytics (
  AnalyticsID INT NOT NULL AUTO_INCREMENT,
  StudentID INT NOT NULL,
  CourseID INT NOT NULL,
  AvgGrade DECIMAL(5,2),
  CompletionRate DECIMAL(5,2),
  TimeSpentHours DECIMAL(6,2),
  QuizParticipation INT,
  LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (AnalyticsID),
  UNIQUE KEY UK_Student_Course (StudentID, CourseID),
  KEY idx_course (CourseID),
  KEY idx_student (StudentID),
  CONSTRAINT analytics_fk_student FOREIGN KEY (StudentID) REFERENCES Student(StuId) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT analytics_fk_course FOREIGN KEY (CourseID) REFERENCES Course(CourseId) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE RiskAlert (
  AlertId INT NOT NULL AUTO_INCREMENT,
  StudentID INT NOT NULL,
  CourseID INT NOT NULL,
  Reason VARCHAR(255) NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  Resolved TINYINT(1) DEFAULT 0,
  PRIMARY KEY (AlertId),
  KEY idx_student_resolved (StudentID, Resolved),
  KEY idx_course (CourseID),
  CONSTRAINT risk_fk_student FOREIGN KEY (StudentID) REFERENCES Student(StuId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT risk_fk_course FOREIGN KEY (CourseID) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Certificate (
  CertificateId INT NOT NULL AUTO_INCREMENT,
  StuId INT NOT NULL,
  CourseId INT NOT NULL,
  IssueDate DATE NOT NULL,
  VerificationCode VARCHAR(100) NOT NULL UNIQUE,
  PDFPath VARCHAR(500),
  PRIMARY KEY (CertificateId),
  KEY idx_student (StuId),
  KEY idx_course (CourseId),
  KEY idx_verification (VerificationCode),
  CONSTRAINT cert_fk_student FOREIGN KEY (StuId) REFERENCES Student(StuId)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT cert_fk_course FOREIGN KEY (CourseId) REFERENCES Course(CourseId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ReportLog (
  ReportId INT NOT NULL AUTO_INCREMENT,
  GeneratedBy INT NOT NULL,
  ReportType VARCHAR(100) NOT NULL,
  GeneratedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FilePath VARCHAR(500),
  PRIMARY KEY (ReportId),
  KEY idx_generated_by (GeneratedBy),
  KEY idx_generated_at (GeneratedAt),
  CONSTRAINT report_fk_user FOREIGN KEY (GeneratedBy) REFERENCES Users(UserId)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;