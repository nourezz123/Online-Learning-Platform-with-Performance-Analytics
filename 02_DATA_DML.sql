-- ====================================================
-- TRAINLY - FIXED DATA MANIPULATION LANGUAGE (DML)
-- Complete INSERT Statements - CORRECTED VERSION
-- ====================================================

USE TRAINLY;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

-- ===========================
-- 1) USERS - FIXED PASSWORDS
-- ===========================

-- ADMIN USER (with SHA-256 password)
INSERT IGNORE INTO Users (Email, FirstName, LastName, Password, Role, Status)
VALUES ('admin@trainly.com', 'Admin', 'User', SHA2('admin123', 256), 'admin', 'active');

-- STUDENTS (plain text passwords for testing)
INSERT IGNORE INTO Users (Email, FirstName, LastName, Password, Role, Status) VALUES
('sara.ali@student.com','Sara','Ali','student123','student','active'),
('mohamed.hassan@student.com','Mohamed','Hassan','student123','student','active'),
('omar.khaled@student.com','Omar','Khaled','student123','student','active'),
('nour.ezz@student.com','Nour','Ezz','student123','student','active'),
('ammar.ibrahim@student.com','Ammar','Ibrahim','student123','student','active'),
('ahmed.ashraf@student.com','Ahmed','Ashraf','student123','student','active'),
('rawan.hossam@student.com','Rawan','Hossam','student123','student','active'),
('ahmed.haytham@student.com','Ahmed','Haytham','student123','student','active'),
('nasser.hossam@student.com','Nasser','Hossam','student123','student','active'),
('leila.farid@student.com','Leila','Farid','student123','student','active'),
('mariam.salah@student.com','Mariam','Salah','student123','student','active'),
('youssef.mostafa@student.com','Youssef','Mostafa','student123','student','active'),
('dina.fathi@student.com','Dina','Fathi','student123','student','active'),
('ahmed.mohsen@student.com','Ahmed','Mohsen','student123','student','active'),
('fatma.gamal@student.com','Fatma','Gamal','student123','student','active');

-- INSTRUCTORS (plain text passwords for testing)
INSERT IGNORE INTO Users (Email, FirstName, LastName, Password, Role, Status) VALUES
('mohamed.eissa@instructor.com','Mohamed','Eissa','instructor123','instructor','active'),
('sama.elqasaby@instructor.com','Sama','Elqasaby','instructor123','instructor','active'),
('ahmed.fathi@instructor.com','Ahmed','Fathi','instructor123','instructor','active'),
('dina.khaled@instructor.com','Dina','Khaled','instructor123','instructor','active'),
('youssef.ashraf@instructor.com','Youssef','Ashraf','instructor123','instructor','active');

-- ===========================
-- 2) ADMINISTRATOR TABLE
-- ===========================
INSERT INTO Administrator (UserId, Grantor)
SELECT UserId, NULL
FROM Users
WHERE Role = 'admin'
AND UserId NOT IN (SELECT UserId FROM Administrator)
LIMIT 1;

-- ===========================
-- 3) FACULTY TABLE
-- ===========================
INSERT INTO Faculty (UserId, Title, Affiliation, Website, VerifiedBy, VerifiedAt)
SELECT u.UserId, v.Title, v.Affiliation, v.Website, v.VerifiedBy, v.VerifiedAt
FROM (
    SELECT 
        (SELECT UserId FROM Users WHERE Email='mohamed.eissa@instructor.com') AS UserId,
        'Dr.' AS Title,
        'Egypt-Japan University' AS Affiliation,
        'https://ejust.edu.eg' AS Website,
        (SELECT UserId FROM Users WHERE Role='admin' LIMIT 1) AS VerifiedBy,
        NOW() AS VerifiedAt
    UNION ALL
    SELECT 
        (SELECT UserId FROM Users WHERE Email='sama.elqasaby@instructor.com'),
        'Ms.', 'Egypt-Japan University', 'https://ejust.edu.eg',
        (SELECT UserId FROM Users WHERE Role='admin' LIMIT 1), NOW()
    UNION ALL
    SELECT 
        (SELECT UserId FROM Users WHERE Email='ahmed.fathi@instructor.com'),
        'Dr.', 'Cairo University', 'https://cu.edu.eg',
        (SELECT UserId FROM Users WHERE Role='admin' LIMIT 1), NOW()
    UNION ALL
    SELECT 
        (SELECT UserId FROM Users WHERE Email='dina.khaled@instructor.com'),
        'Dr.', 'Alexandria University', 'https://alexu.edu.eg',
        (SELECT UserId FROM Users WHERE Role='admin' LIMIT 1), NOW()
    UNION ALL
    SELECT 
        (SELECT UserId FROM Users WHERE Email='youssef.ashraf@instructor.com'),
        'Dr.', 'Mansoura University', 'https://mans.edu.eg',
        (SELECT UserId FROM Users WHERE Role='admin' LIMIT 1), NOW()
) AS v
LEFT JOIN Users u ON u.UserId = v.UserId
WHERE v.UserId NOT IN (SELECT UserId FROM Faculty);

-- ===========================
-- 4) STUDENT TABLE
-- ===========================
INSERT INTO Student (UserId)
SELECT UserId
FROM Users
WHERE Role = 'student'
AND UserId NOT IN (SELECT UserId FROM Student);

-- ===========================
-- 5) TOPICS
-- ===========================
INSERT IGNORE INTO Topic (Name) VALUES
('Web Development'),
('Data Science'),
('Cloud Computing'),
('Database Systems'),
('Machine Learning'),
('Neural Networks'),
('Python Programming'),
('Java Programming'),
('Cybersecurity'),
('Artificial Intelligence'),
('Computer Science'),
('Mathematics'),
('Physics'),
('Networking');

-- ===========================
-- 6) COURSES
-- ===========================

-- Instructor 1: Mohamed Eissa
INSERT IGNORE INTO Course (InstructorId, Title, Category, DurationHours, Syllabus, Status, Cost, AvgRating, CreatedAt) VALUES
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='mohamed.eissa@instructor.com')), 
 'Advanced SQL & Database Design', 'Database Systems', 40, 'Covers relational algebra, normalization, and advanced indexing.', 'active', 99.99, 4.50, '2023-01-15 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='mohamed.eissa@instructor.com')), 
 'Web Development with React', 'Web Development', 35, 'Building modern web applications with React and Node.js.', 'active', 89.99, 4.60, '2023-02-01 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='mohamed.eissa@instructor.com')), 
 'Data Structures and Algorithms', 'Computer Science', 50, 'Comprehensive coverage of essential data structures and algorithms.', 'active', 109.99, 4.80, '2023-02-15 10:00:00');

-- Instructor 2: Sama Elqasaby
INSERT IGNORE INTO Course (InstructorId, Title, Category, DurationHours, Syllabus, Status, Cost, AvgRating, CreatedAt) VALUES
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='sama.elqasaby@instructor.com')), 
 'Introduction to Python for Data', 'Programming', 30, 'Basic Python syntax, NumPy, and Pandas.', 'active', 59.99, 4.20, '2023-01-20 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='sama.elqasaby@instructor.com')), 
 'Neural Networks Fundamentals', 'Data Science', 40, 'Feedforward and Convolutional Neural Networks.', 'active', 119.99, 4.50, '2023-02-10 10:00:00');

-- Instructor 3: Ahmed Fathi
INSERT IGNORE INTO Course (InstructorId, Title, Category, DurationHours, Syllabus, Status, Cost, AvgRating, CreatedAt) VALUES
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='ahmed.fathi@instructor.com')), 
 'Cloud Computing with AWS', 'Cloud Computing', 50, 'Deploying scalable functions and managed databases.', 'active', 149.99, 4.40, '2023-01-25 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='ahmed.fathi@instructor.com')), 
 'Database Administration', 'Database Systems', 45, 'DB backup, indexing, and optimization.', 'active', 109.99, 4.50, '2023-02-05 10:00:00');

-- Instructor 4: Dina Khaled
INSERT IGNORE INTO Course (InstructorId, Title, Category, DurationHours, Syllabus, Status, Cost, AvgRating, CreatedAt) VALUES
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='dina.khaled@instructor.com')), 
 'Machine Learning Fundamentals', 'Data Science', 45, 'Introduction to supervised and unsupervised learning algorithms.', 'active', 129.99, 4.75, '2023-02-01 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='dina.khaled@instructor.com')), 
 'Artificial Intelligence Basics', 'Intelligent Systems', 40, 'AI principles, search, and planning.', 'active', 119.99, 4.60, '2023-02-20 10:00:00');

-- Instructor 5: Youssef Ashraf
INSERT IGNORE INTO Course (InstructorId, Title, Category, DurationHours, Syllabus, Status, Cost, AvgRating, CreatedAt) VALUES
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='youssef.ashraf@instructor.com')), 
 'Data Science with Python', 'Data Science', 40, 'NumPy, Pandas, and data visualization.', 'active', 99.99, 4.50, '2023-01-30 10:00:00'),
((SELECT FacultyId FROM Faculty WHERE UserId = (SELECT UserId FROM Users WHERE Email='youssef.ashraf@instructor.com')), 
 'Computer Security Basics', 'Cybersecurity', 45, 'Introduction to encryption, firewalls, and risk management.', 'active', 119.99, 4.60, '2023-02-25 10:00:00');

-- ===========================
-- 7) COURSE CREATION RECORDS
-- ===========================
INSERT IGNORE INTO CourseCreation (CourseId, FacultyId, DateCreated)
SELECT c.CourseId, c.InstructorId, DATE(c.CreatedAt)
FROM Course c
WHERE NOT EXISTS (
    SELECT 1 FROM CourseCreation cc 
    WHERE cc.CourseId = c.CourseId AND cc.FacultyId = c.InstructorId
);

-- ===========================
-- 8) SECONDARY TOPICS
-- ===========================
INSERT IGNORE INTO SecondaryTopics (CourseId, TopicId) VALUES 
((SELECT CourseId FROM Course WHERE Title='Advanced SQL & Database Design' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Database Systems' LIMIT 1)),
((SELECT CourseId FROM Course WHERE Title='Web Development with React' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Web Development' LIMIT 1)),
((SELECT CourseId FROM Course WHERE Title='Introduction to Python for Data' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Python Programming' LIMIT 1)),
((SELECT CourseId FROM Course WHERE Title='Data Science with Python' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Data Science' LIMIT 1)),
((SELECT CourseId FROM Course WHERE Title='Neural Networks Fundamentals' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Neural Networks' LIMIT 1)),
((SELECT CourseId FROM Course WHERE Title='Machine Learning Fundamentals' LIMIT 1), 
 (SELECT TopicId FROM Topic WHERE Name='Machine Learning' LIMIT 1));

-- ===========================
-- 9) COURSE ENROLLMENTS - FIXED WITH PROPER ASSOCIATIONS
-- ===========================

-- Variables for easier reference
SET @student1 = (SELECT StuId FROM Student WHERE UserId = (SELECT UserId FROM Users WHERE Email='sara.ali@student.com'));
SET @student2 = (SELECT StuId FROM Student WHERE UserId = (SELECT UserId FROM Users WHERE Email='mohamed.hassan@student.com'));
SET @student3 = (SELECT StuId FROM Student WHERE UserId = (SELECT UserId FROM Users WHERE Email='omar.khaled@student.com'));
SET @student4 = (SELECT StuId FROM Student WHERE UserId = (SELECT UserId FROM Users WHERE Email='nour.ezz@student.com'));
SET @student5 = (SELECT StuId FROM Student WHERE UserId = (SELECT UserId FROM Users WHERE Email='ammar.ibrahim@student.com'));

SET @course1 = (SELECT CourseId FROM Course WHERE Title='Advanced SQL & Database Design' LIMIT 1);
SET @course2 = (SELECT CourseId FROM Course WHERE Title='Introduction to Python for Data' LIMIT 1);
SET @course3 = (SELECT CourseId FROM Course WHERE Title='Neural Networks Fundamentals' LIMIT 1);
SET @course4 = (SELECT CourseId FROM Course WHERE Title='Machine Learning Fundamentals' LIMIT 1);
SET @course5 = (SELECT CourseId FROM Course WHERE Title='Web Development with React' LIMIT 1);
SET @course6 = (SELECT CourseId FROM Course WHERE Title='Data Structures and Algorithms' LIMIT 1);
SET @course7 = (SELECT CourseId FROM Course WHERE Title='Data Science with Python' LIMIT 1);

-- Enrollments with proper data
INSERT IGNORE INTO CourseEnrollment (StuId, CourseId, EnrollCode, EnrollDate, EnrollTime, Rating, Certification, CompleteDate, Comment) VALUES
-- Student 1: Sara Ali - Active in multiple courses
(@student1, @course1, 'SQLVIP001', '2024-01-15', '10:00:00', 5, 1, '2024-02-28', 'Excellent course, highly recommend!'),
(@student1, @course2, 'PYDATA001', '2024-02-01', '09:00:00', 5, 1, '2024-03-15', 'Great introduction to Python!'),
(@student1, @course3, 'NN2024001', '2024-03-01', '09:00:00', NULL, 0, NULL, NULL),
(@student1, @course7, 'DS2024001', '2024-03-15', '10:00:00', NULL, 0, NULL, NULL),

-- Student 2: Mohamed Hassan
(@student2, @course1, 'SQLREG001', '2024-01-20', '11:30:00', 4, 1, '2024-03-05', 'Solid foundation, some topics were rushed.'),
(@student2, @course2, 'PYDATA002', '2024-02-05', '13:00:00', 4, 0, NULL, NULL),
(@student2, @course5, 'REACT001', '2024-03-10', '14:00:00', NULL, 0, NULL, NULL),

-- Student 3: Omar Khaled
(@student3, @course1, 'SQLREG002', '2024-01-25', '14:00:00', NULL, 0, NULL, NULL),
(@student3, @course2, 'PYDATA003', '2024-02-10', '10:30:00', NULL, 0, NULL, NULL),
(@student3, @course6, 'DSA001', '2024-03-05', '11:00:00', NULL, 0, NULL, NULL),

-- Student 4: Nour Ezz
(@student4, @course1, 'SQLREG003', '2024-01-18', '09:00:00', 5, 1, '2024-02-25', 'Best database course I have taken!'),
(@student4, @course4, 'ML2024001', '2024-02-20', '10:00:00', NULL, 0, NULL, NULL),
(@student4, @course7, 'DS2024002', '2024-03-12', '13:00:00', NULL, 0, NULL, NULL),

-- Student 5: Ammar Ibrahim
(@student5, @course2, 'PYDATA004', '2024-02-12', '11:00:00', NULL, 0, NULL, NULL),
(@student5, @course5, 'REACT002', '2024-03-08', '15:00:00', NULL, 0, NULL, NULL),
(@student5, @course6, 'DSA002', '2024-03-15', '09:00:00', NULL, 0, NULL, NULL);

-- ===========================
-- 10) COURSE MATERIALS
-- ===========================
INSERT IGNORE INTO CourseMaterial (CourseId, ModuleIndex, LessonIndex, Title, MaterialType, PathOrUrl, DurationSeconds) VALUES
-- Course 1: Advanced SQL
(@course1, 1, 1, 'Welcome to Advanced SQL', 'post', NULL, 300),
(@course1, 1, 2, 'Video: Relational Algebra Review', 'video', '/videos/course1/relational_algebra.mp4', 900),
(@course1, 2, 1, 'Document: Normalization Guide', 'pdf', '/files/course1/normalization_guide.pdf', 600),
(@course1, 2, 2, 'Quiz: Normalization Checkup', 'quiz', NULL, 0),
(@course1, 3, 1, 'Video: Query Optimization', 'video', '/videos/course1/query_optimization.mp4', 1200),

-- Course 2: Python
(@course2, 1, 1, 'Python Setup and Basics', 'video', '/videos/course2/python_basics.mp4', 1200),
(@course2, 1, 2, 'Quiz: Python Syntax', 'quiz', NULL, 0),
(@course2, 2, 1, 'NumPy Array Manipulation', 'video', '/videos/course2/numpy_arrays.mp4', 1800),
(@course2, 2, 2, 'Pandas DataFrames Tutorial', 'video', '/videos/course2/pandas_tutorial.mp4', 2100),

-- Course 5: React
(@course5, 1, 1, 'React Fundamentals', 'video', '/videos/course5/react_fundamentals.mp4', 1400),
(@course5, 1, 2, 'Components and Props', 'video', '/videos/course5/components_props.mp4', 1600),
(@course5, 2, 1, 'State Management', 'video', '/videos/course5/state_management.mp4', 1900);

-- ===========================
-- 11) MATERIAL COMPLETION
-- ===========================
SET @mat1 = (SELECT MaterialId FROM CourseMaterial WHERE CourseId=@course1 AND ModuleIndex=1 AND LessonIndex=1 LIMIT 1);
SET @mat2 = (SELECT MaterialId FROM CourseMaterial WHERE CourseId=@course1 AND ModuleIndex=1 AND LessonIndex=2 LIMIT 1);
SET @mat3 = (SELECT MaterialId FROM CourseMaterial WHERE CourseId=@course1 AND ModuleIndex=2 AND LessonIndex=1 LIMIT 1);
SET @mat4 = (SELECT MaterialId FROM CourseMaterial WHERE CourseId=@course2 AND ModuleIndex=1 AND LessonIndex=1 LIMIT 1);
SET @mat5 = (SELECT MaterialId FROM CourseMaterial WHERE CourseId=@course2 AND ModuleIndex=1 AND LessonIndex=2 LIMIT 1);

INSERT IGNORE INTO MaterialCompletion (StuId, MaterialId, Date, Time, TimeSpent) VALUES
-- Student 1 progress in Course 1
(@student1, @mat1, '2024-01-15', '10:05:00', 300),
(@student1, @mat2, '2024-01-15', '10:30:00', 900),
(@student1, @mat3, '2024-01-16', '11:00:00', 600),

-- Student 1 progress in Course 2
(@student1, @mat4, '2024-02-01', '09:30:00', 1200),
(@student1, @mat5, '2024-02-01', '11:00:00', 300),

-- Student 2 progress
(@student2, @mat1, '2024-01-20', '11:45:00', 320),
(@student2, @mat2, '2024-01-21', '10:00:00', 900),

-- Student 4 progress
(@student4, @mat1, '2024-01-18', '09:30:00', 320),
(@student4, @mat2, '2024-01-19', '10:00:00', 900),
(@student4, @mat3, '2024-01-20', '11:00:00', 600);

-- ===========================
-- 12) ANALYTICS
-- ===========================
INSERT IGNORE INTO Analytics (StudentID, CourseID, AvgGrade, CompletionRate, TimeSpentHours, QuizParticipation, LastUpdated) VALUES
(@student1, @course1, 96.50, 100.00, 12.5, 2, NOW()),
(@student1, @course2, 92.00, 100.00, 8.3, 1, NOW()),
(@student1, @course3, 0.00, 25.00, 2.5, 0, NOW()),
(@student2, @course1, 80.00, 100.00, 10.2, 2, NOW()),
(@student2, @course2, 0.00, 40.00, 3.5, 1, NOW()),
(@student3, @course1, 0.00, 33.33, 2.1, 0, NOW()),
(@student4, @course1, 98.00, 100.00, 13.0, 2, NOW()),
(@student4, @course4, 0.00, 15.00, 2.0, 0, NOW());

-- ===========================
-- 13) ASSIGNMENTS
-- ===========================
INSERT IGNORE INTO Assignment (CourseID, Title, Description, DueDate, MaxScore, CreatedAt) VALUES 
(@course1, 'Normalization Project', 'Design a fully normalized schema for an e-commerce platform.', '2024-03-15 23:59:59', 100.00, NOW()),
(@course2, 'Data Analysis with Pandas', 'Analyze the provided dataset and create visualizations.', '2024-03-20 23:59:59', 100.00, NOW()),
(@course5, 'React Todo App', 'Build a complete todo application with React.', '2024-04-15 23:59:59', 100.00, NOW());

-- ===========================
-- 14) QUIZZES
-- ===========================
INSERT IGNORE INTO Quiz (CourseID, Title, Instructions, TimeLimitMinutes, MaxScore, StartTime, EndTime, MaxAttempts, CreatedAt) VALUES 
(@course1, 'Normalization Quiz', 'Test your understanding of database normalization.', 20, 20.00, '2024-02-01 00:00:00', '2024-12-31 23:59:59', 2, NOW()),
(@course2, 'Python Basics Checkup', 'Test your knowledge of fundamental Python concepts.', 15, 10.00, '2024-02-15 00:00:00', '2024-12-31 23:59:59', 3, NOW());

-- ===========================
-- 15) CERTIFICATES
-- ===========================
INSERT IGNORE INTO Certificate (StuId, CourseId, IssueDate, VerificationCode, PDFPath) VALUES
(@student1, @course1, '2024-02-29', 'CERT-SQL-2024-001', '/certs/student1_course1.pdf'),
(@student1, @course2, '2024-03-16', 'CERT-PY-2024-001', '/certs/student1_course2.pdf'),
(@student2, @course1, '2024-03-06', 'CERT-SQL-2024-002', '/certs/student2_course1.pdf'),
(@student4, @course1, '2024-02-26', 'CERT-SQL-2024-003', '/certs/student4_course1.pdf');

-- ===========================
-- 16) USER PREFERENCES
-- ===========================
-- These are automatically created by trigger, but we can add custom ones
UPDATE UserPreferences SET Theme='dark' WHERE UserId IN (SELECT UserId FROM Users WHERE Email='sara.ali@student.com');
UPDATE UserPreferences SET Theme='dark' WHERE UserId IN (SELECT UserId FROM Users WHERE Email='mohamed.hassan@student.com');

SET FOREIGN_KEY_CHECKS = 1;

-- Verify data
SELECT 'Data insertion complete!' AS Status;
SELECT COUNT(*) AS TotalUsers FROM Users;
SELECT COUNT(*) AS TotalCourses FROM Course;
SELECT COUNT(*) AS TotalEnrollments FROM CourseEnrollment;
SELECT COUNT(*) AS TotalMaterials FROM CourseMaterial;