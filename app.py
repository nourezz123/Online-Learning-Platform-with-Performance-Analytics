"""
TRAINLY - Complete Learning Management System
Professional Streamlit Application - COMPLETE VERSION
"""

import streamlit as st
import mysql.connector
from mysql.connector import Error
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import hashlib
from functools import wraps
from decimal import Decimal

# ==========================================
# DATABASE CONNECTION
# ==========================================

def create_connection():
    """Create database connection"""
    try:
        connection = mysql.connector.connect(
            host='localhost',
            port=3306,
            database='TRAINLY',
            user='root',
            password='Nourezz2025!'
        )
        return connection
    except Error as e:
        st.error(f"Database connection error: {e}")
        return None

def execute_query(query, params=None, fetch=True):
    """Execute database query"""
    connection = create_connection()
    if connection:
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.execute(query, params or ())
            if fetch:
                result = cursor.fetchall()
                cursor.close()
                connection.close()
                return result
            else:
                connection.commit()
                cursor.close()
                connection.close()
                return True
        except Error as e:
            st.error(f"Query error: {e}")
            return None if fetch else False
    return None if fetch else False

# ==========================================
# HELPER FUNCTIONS
# ==========================================

def convert_to_float(value):
    """Convert Decimal/None to float"""
    if value is None:
        return 0.0
    if isinstance(value, Decimal):
        return float(value)
    return float(value)

def safe_progress(value):
    """Safely convert value to 0.0-1.0 range for progress bar"""
    val = convert_to_float(value)
    return max(0.0, min(1.0, val / 100.0))

# ==========================================
# AUTHENTICATION
# ==========================================

def hash_password(password):
    """Hash password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

def authenticate_user(email, password):
    """Authenticate user credentials"""
    query = """
        SELECT UserId, Email, FirstName, LastName, Role, Status, Password
        FROM Users 
        WHERE Email = %s AND Status = 'active'
    """
    result = execute_query(query, (email,))
    
    if not result:
        return None
    
    user = result[0]
    stored_password = user['Password']
    del user['Password']
    
    if stored_password == password or stored_password == hash_password(password):
        return user
    
    return None

def login_required(role=None):
    """Decorator for protected pages"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if 'user' not in st.session_state:
                st.warning("Please login to access this page")
                st.stop()
            if role and st.session_state.user['Role'] != role:
                st.error("You don't have permission to access this page")
                st.stop()
            return func(*args, **kwargs)
        return wrapper
    return decorator

# ==========================================
# PAGE CONFIGURATION
# ==========================================

st.set_page_config(
    page_title="TRAINLY - Learning Management System",
    page_icon="📚",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Enhanced CSS with better visibility
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 1rem;
    }
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 1.5rem;
        border-radius: 10px;
        color: white;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        margin-bottom: 1rem;
    }
    .metric-card h3 {
        color: white;
        margin: 0;
        font-size: 1rem;
    }
    .metric-card h1 {
        color: white;
        margin: 0.5rem 0;
        font-size: 2.5rem;
    }
    .metric-card p {
        color: rgba(255,255,255,0.8);
        margin: 0;
    }
    .course-card {
        border: 2px solid #667eea;
        border-radius: 10px;
        padding: 1.5rem;
        margin: 1rem 0;
        background: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        transition: transform 0.2s;
    }
    .course-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 4px 12px rgba(102,126,234,0.3);
    }
    .course-card h4 {
        color: #667eea;
        margin-top: 0;
    }
    .stButton>button {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        border-radius: 5px;
        padding: 0.5rem 2rem;
        font-weight: bold;
    }
    .stButton>button:hover {
        background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }
    .info-box {
        background: #f0f2f6;
        padding: 1rem;
        border-radius: 10px;
        border-left: 4px solid #667eea;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# ==========================================
# SESSION STATE
# ==========================================

if 'user' not in st.session_state:
    st.session_state.user = None
if 'page' not in st.session_state:
    st.session_state.page = 'login'

# ==========================================
# NAVIGATION
# ==========================================

def show_navigation():
    """Show navigation sidebar"""
    with st.sidebar:
        st.markdown("# 📚 TRAINLY")
        st.markdown("---")
        
        if st.session_state.user:
            st.success(f"👤 {st.session_state.user['FirstName']} {st.session_state.user['LastName']}")
            st.caption(f"Role: {st.session_state.user['Role'].title()}")
            st.markdown("---")
            
            role = st.session_state.user['Role']
            
            if st.button("🏠 Dashboard", use_container_width=True):
                st.session_state.page = 'dashboard'
                st.rerun()
            
            if role == 'student':
                if st.button("📚 My Courses", use_container_width=True):
                    st.session_state.page = 'my_courses'
                    st.rerun()
                if st.button("🔍 Browse Courses", use_container_width=True):
                    st.session_state.page = 'browse_courses'
                    st.rerun()
                if st.button("📊 My Progress", use_container_width=True):
                    st.session_state.page = 'student_progress'
                    st.rerun()
                if st.button("🏆 Certificates", use_container_width=True):
                    st.session_state.page = 'certificates'
                    st.rerun()
            
            elif role == 'instructor':
                if st.button("📚 My Courses", use_container_width=True):
                    st.session_state.page = 'instructor_courses'
                    st.rerun()
                if st.button("👥 Students", use_container_width=True):
                    st.session_state.page = 'manage_students'
                    st.rerun()
                if st.button("📊 Analytics", use_container_width=True):
                    st.session_state.page = 'instructor_analytics'
                    st.rerun()
            
            elif role == 'admin':
                if st.button("👥 Manage Users", use_container_width=True):
                    st.session_state.page = 'manage_users'
                    st.rerun()
                if st.button("📚 Manage Courses", use_container_width=True):
                    st.session_state.page = 'manage_courses'
                    st.rerun()
                if st.button("📊 System Analytics", use_container_width=True):
                    st.session_state.page = 'system_analytics'
                    st.rerun()
            
            st.markdown("---")
            if st.button("🚪 Logout", use_container_width=True):
                st.session_state.user = None
                st.session_state.page = 'login'
                st.rerun()

# ==========================================
# LOGIN PAGE
# ==========================================

def login_page():
    """Login page"""
    col1, col2, col3 = st.columns([1, 2, 1])
    
    with col2:
        st.markdown("<h1 class='main-header' style='text-align: center;'>📚 TRAINLY</h1>", unsafe_allow_html=True)
        st.markdown("<p style='text-align: center; color: #666; font-size: 1.2rem;'>Learn. Grow. Excel.</p>", unsafe_allow_html=True)
        st.markdown("---")
        
        tab1, tab2 = st.tabs(["Login", "Register"])
        
        with tab1:
            with st.form("login_form"):
                email = st.text_input("Email", placeholder="your.email@example.com")
                password = st.text_input("Password", type="password")
                submit = st.form_submit_button("Login", use_container_width=True)
                
                if submit:
                    if email and password:
                        user = authenticate_user(email, password)
                        if user:
                            st.session_state.user = user
                            st.session_state.page = 'dashboard'
                            st.success("Login successful!")
                            st.rerun()
                        else:
                            st.error("Invalid credentials")
                    else:
                        st.warning("Please fill in all fields")
            
            # Show test credentials
            st.info("""
            **Test Accounts:**
            - Student: `sara.ali@student.com` / `student123`
            - Instructor: `mohamed.eissa@instructor.com` / `instructor123`
            - Admin: `admin@trainly.com` / `admin123`
            """)
        
        with tab2:
            with st.form("register_form"):
                st.subheader("Create New Account")
                first_name = st.text_input("First Name")
                last_name = st.text_input("Last Name")
                email = st.text_input("Email")
                password = st.text_input("Password", type="password")
                confirm_password = st.text_input("Confirm Password", type="password")
                role = st.selectbox("I am a", ["student", "instructor"])
                
                register = st.form_submit_button("Register", use_container_width=True)
                
                if register:
                    if all([first_name, last_name, email, password, confirm_password]):
                        if password == confirm_password:
                            check_query = "SELECT Email FROM Users WHERE Email = %s"
                            existing = execute_query(check_query, (email,))
                            
                            if not existing:
                                insert_query = """
                                    INSERT INTO Users (Email, FirstName, LastName, Password, Role, Status)
                                    VALUES (%s, %s, %s, %s, %s, 'active')
                                """
                                success = execute_query(insert_query, (email, first_name, last_name, password, role), fetch=False)
                                
                                if success:
                                    user_query = "SELECT UserId FROM Users WHERE Email = %s"
                                    user_result = execute_query(user_query, (email,))
                                    
                                    if user_result:
                                        user_id = user_result[0]['UserId']
                                        
                                        if role == 'student':
                                            role_query = "INSERT INTO Student (UserId) VALUES (%s)"
                                        else:
                                            role_query = "INSERT INTO Faculty (UserId, Title, Affiliation) VALUES (%s, 'Mr./Ms.', 'Independent')"
                                        
                                        execute_query(role_query, (user_id,), fetch=False)
                                        st.success("✅ Registration successful! Please login.")
                                else:
                                    st.error("Registration failed")
                            else:
                                st.error("Email already exists")
                        else:
                            st.error("Passwords do not match")
                    else:
                        st.warning("Please fill in all fields")

# ==========================================
# STUDENT DASHBOARD
# ==========================================

def student_dashboard():
    """Student dashboard"""
    user_id = st.session_state.user['UserId']
    
    stu_query = "SELECT StuId FROM Student WHERE UserId = %s"
    stu_result = execute_query(stu_query, (user_id,))
    
    if not stu_result:
        st.error("Student profile not found")
        return
    
    stu_id = stu_result[0]['StuId']
    
    # Metrics Row
    col1, col2, col3, col4 = st.columns(4)
    
    enrolled_query = "SELECT COUNT(*) as count FROM CourseEnrollment WHERE StuId = %s"
    enrolled = execute_query(enrolled_query, (stu_id,))[0]['count']
    
    completed_query = "SELECT COUNT(*) as count FROM CourseEnrollment WHERE StuId = %s AND Certification = 1"
    completed = execute_query(completed_query, (stu_id,))[0]['count']
    
    avg_query = "SELECT AVG(AvgGrade) as avg FROM Analytics WHERE StudentID = %s"
    avg_result = execute_query(avg_query, (stu_id,))
    avg_grade = round(convert_to_float(avg_result[0]['avg']), 2)
    
    hours_query = "SELECT SUM(TimeSpentHours) as total FROM Analytics WHERE StudentID = %s"
    hours_result = execute_query(hours_query, (stu_id,))
    total_hours = round(convert_to_float(hours_result[0]['total']), 2)
    
    with col1:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📚 Enrolled</h3>
            <h1>{enrolled}</h1>
            <p>Courses</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col2:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>✅ Completed</h3>
            <h1>{completed}</h1>
            <p>Courses</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col3:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📊 Avg Grade</h3>
            <h1>{avg_grade}%</h1>
            <p>Overall</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col4:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>⏱️ Study Time</h3>
            <h1>{total_hours}</h1>
            <p>Hours</p>
        </div>
        """, unsafe_allow_html=True)
    
    st.markdown("---")
    
    # Current courses
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📖 Continue Learning")
        progress_query = """
            SELECT c.CourseId, c.Title, c.Category, an.CompletionRate, an.AvgGrade
            FROM CourseEnrollment ce
            JOIN Course c ON ce.CourseId = c.CourseId
            LEFT JOIN Analytics an ON ce.StuId = an.StudentID AND ce.CourseId = an.CourseID
            WHERE ce.StuId = %s AND ce.Certification = 0
            ORDER BY ce.EnrollDate DESC
            LIMIT 5
        """
        courses = execute_query(progress_query, (stu_id,))
        
        if courses:
            for course in courses:
                completion = convert_to_float(course['CompletionRate'])
                st.markdown(f"""
                <div class='course-card'>
                    <h4>{course['Title']}</h4>
                    <p style='color: #666;'>{course['Category']}</p>
                </div>
                """, unsafe_allow_html=True)
                st.progress(safe_progress(completion))
                st.caption(f"**{completion:.1f}% Complete**")
                st.markdown("<br>", unsafe_allow_html=True)
        else:
            st.info("📌 No active courses. Browse courses to get started!")
    
    with col2:
        st.subheader("📊 Performance Analytics")
        
        perf_query = """
            SELECT c.Title, an.CompletionRate, an.AvgGrade
            FROM Analytics an
            JOIN Course c ON an.CourseID = c.CourseId
            WHERE an.StudentID = %s AND an.CompletionRate > 0
            ORDER BY an.LastUpdated DESC
            LIMIT 5
        """
        perf_data = execute_query(perf_query, (stu_id,))
        
        if perf_data:
            for row in perf_data:
                row['CompletionRate'] = convert_to_float(row['CompletionRate'])
                row['AvgGrade'] = convert_to_float(row['AvgGrade'])
            
            df = pd.DataFrame(perf_data)
            
            fig = go.Figure()
            fig.add_trace(go.Bar(
                name='Completion Rate',
                x=df['Title'],
                y=df['CompletionRate'],
                marker_color='#667eea'
            ))
            fig.add_trace(go.Bar(
                name='Average Grade',
                x=df['Title'],
                y=df['AvgGrade'],
                marker_color='#764ba2'
            ))
            
            fig.update_layout(
                barmode='group',
                xaxis_title='Course',
                yaxis_title='Percentage',
                height=300,
                showlegend=True
            )
            
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("📌 No performance data available yet")

# ==========================================
# INSTRUCTOR DASHBOARD
# ==========================================

def instructor_dashboard():
    """Instructor dashboard"""
    user_id = st.session_state.user['UserId']
    
    fac_query = "SELECT FacultyId FROM Faculty WHERE UserId = %s"
    fac_result = execute_query(fac_query, (user_id,))
    
    if not fac_result:
        st.error("Instructor profile not found")
        return
    
    fac_id = fac_result[0]['FacultyId']
    
    # Metrics
    col1, col2, col3, col4 = st.columns(4)
    
    courses_query = "SELECT COUNT(*) as count FROM Course WHERE InstructorId = %s"
    total_courses = execute_query(courses_query, (fac_id,))[0]['count']
    
    active_query = "SELECT COUNT(*) as count FROM Course WHERE InstructorId = %s AND Status = 'active'"
    active_courses = execute_query(active_query, (fac_id,))[0]['count']
    
    students_query = """
        SELECT COUNT(DISTINCT ce.StuId) as count
        FROM CourseEnrollment ce
        JOIN Course c ON ce.CourseId = c.CourseId
        WHERE c.InstructorId = %s
    """
    total_students = execute_query(students_query, (fac_id,))[0]['count']
    
    rating_query = "SELECT AVG(AvgRating) as avg FROM Course WHERE InstructorId = %s"
    avg_rating = round(convert_to_float(execute_query(rating_query, (fac_id,))[0]['avg']), 2)
    
    with col1:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📚 Total Courses</h3>
            <h1>{total_courses}</h1>
            <p>{active_courses} Active</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col2:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>👥 Students</h3>
            <h1>{total_students}</h1>
            <p>Total Enrolled</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col3:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>⭐ Rating</h3>
            <h1>{avg_rating}</h1>
            <p>Average</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col4:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📝 Materials</h3>
            <h1>-</h1>
            <p>Total</p>
        </div>
        """, unsafe_allow_html=True)
    
    st.markdown("---")
    
    # Course overview
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📚 Your Courses")
        courses_query = """
            SELECT c.CourseId, c.Title, c.Status, c.AvgRating, 
                   COUNT(DISTINCT ce.StuId) as Enrollments
            FROM Course c
            LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
            WHERE c.InstructorId = %s
            GROUP BY c.CourseId, c.Title, c.Status, c.AvgRating
            ORDER BY Enrollments DESC
            LIMIT 5
        """
        courses = execute_query(courses_query, (fac_id,))
        
        if courses:
            for course in courses:
                status_color = {'active': '🟢', 'pending': '🟡', 'archived': '⚪'}
                rating = convert_to_float(course['AvgRating'])
                st.markdown(f"""
                <div class='course-card'>
                    <h4>{status_color.get(course['Status'], '⚫')} {course['Title']}</h4>
                    <p>⭐ {rating:.1f} | 👥 {course['Enrollments']} Students</p>
                </div>
                """, unsafe_allow_html=True)
        else:
            st.info("📌 No courses yet")
    
    with col2:
        st.subheader("📊 Enrollment Distribution")
        
        trend_query = """
            SELECT c.Title, COUNT(ce.StuId) as Enrollments
            FROM Course c
            LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
            WHERE c.InstructorId = %s
            GROUP BY c.CourseId, c.Title
            ORDER BY Enrollments DESC
            LIMIT 5
        """
        trend_data = execute_query(trend_query, (fac_id,))
        
        if trend_data:
            df = pd.DataFrame(trend_data)
            fig = px.pie(df, values='Enrollments', names='Title', 
                        title='Student Distribution')
            fig.update_traces(textposition='inside', textinfo='percent+label')
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("📌 No enrollment data")

# ==========================================
# ADMIN DASHBOARD
# ==========================================

def admin_dashboard():
    """Admin dashboard"""
    st.subheader("🎛️ System Overview")
    
    col1, col2, col3, col4 = st.columns(4)
    
    users_query = "SELECT COUNT(*) as count FROM Users WHERE Status = 'active'"
    total_users = execute_query(users_query)[0]['count']
    
    courses_query = "SELECT COUNT(*) as count FROM Course WHERE Status = 'active'"
    total_courses = execute_query(courses_query)[0]['count']
    
    enrollments_query = "SELECT COUNT(*) as count FROM CourseEnrollment"
    total_enrollments = execute_query(enrollments_query)[0]['count']
    
    revenue_query = """
        SELECT SUM(c.Cost) as total
        FROM CourseEnrollment ce
        JOIN Course c ON ce.CourseId = c.CourseId
    """
    total_revenue = convert_to_float(execute_query(revenue_query)[0]['total'])
    
    with col1:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>👥 Users</h3>
            <h1>{total_users}</h1>
            <p>Active</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col2:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📚 Courses</h3>
            <h1>{total_courses}</h1>
            <p>Active</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col3:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>📝 Enrollments</h3>
            <h1>{total_enrollments}</h1>
            <p>Total</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col4:
        st.markdown(f"""
        <div class='metric-card'>
            <h3>💰 Revenue</h3>
            <h1>${total_revenue:,.0f}</h1>
            <p>Total</p>
        </div>
        """, unsafe_allow_html=True)
    
    st.markdown("---")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 Course Categories")
        
        category_query = """
            SELECT Category, COUNT(*) as Count
            FROM Course
            WHERE Status = 'active'
            GROUP BY Category
            ORDER BY Count DESC
            LIMIT 10
        """
        category_data = execute_query(category_query)
        
        if category_data:
            df = pd.DataFrame(category_data)
            fig = px.bar(df, x='Category', y='Count', color='Count',
                        title='Courses by Category')
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("🕒 Recent Enrollments")
        
        enroll_query = """
            SELECT u.FirstName, u.LastName, c.Title, ce.EnrollDate
            FROM CourseEnrollment ce
            JOIN Student s ON ce.StuId = s.StuId
            JOIN Users u ON s.UserId = u.UserId
            JOIN Course c ON ce.CourseId = c.CourseId
            ORDER BY ce.EnrollDate DESC, ce.EnrollTime DESC
            LIMIT 5
        """
        enrollments = execute_query(enroll_query)
        
        if enrollments:
            for enroll in enrollments:
                st.write(f"✅ **{enroll['FirstName']} {enroll['LastName']}** enrolled in _{enroll['Title']}_ on {enroll['EnrollDate']}")
        else:
            st.info("No recent enrollments")

# ==========================================
# BROWSE COURSES
# ==========================================

@login_required(role='student')
def browse_courses_page():
    """Browse and enroll in courses"""
    st.markdown("<h1 class='main-header'>🔍 Browse Courses</h1>", unsafe_allow_html=True)
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        category_query = "SELECT DISTINCT Category FROM Course WHERE Status = 'active' ORDER BY Category"
        categories = execute_query(category_query)
        category_options = ['All'] + [c['Category'] for c in categories if c['Category']]
        selected_category = st.selectbox("Category", category_options)
    
    with col2:
        search = st.text_input("Search courses", placeholder="Enter course name...")
    
    with col3:
        sort_by = st.selectbox("Sort by", ["Most Popular", "Highest Rated", "Newest"])
    
    st.markdown("---")
    
    query = """
        SELECT c.CourseId, c.Title, c.Category, c.Cost, c.AvgRating, c.DurationHours,
               c.Syllabus, COUNT(DISTINCT ce.StuId) as Enrollments,
               CONCAT(u.FirstName, ' ', u.LastName) as InstructorName,
               f.Title as InstructorTitle
        FROM Course c
        JOIN Faculty f ON c.InstructorId = f.FacultyId
        JOIN Users u ON f.UserId = u.UserId
        LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
        WHERE c.Status = 'active'
    """
    
    params = []
    
    if selected_category != 'All':
        query += " AND c.Category = %s"
        params.append(selected_category)
    
    if search:
        query += " AND c.Title LIKE %s"
        params.append(f"%{search}%")
    
    query += " GROUP BY c.CourseId, c.Title, c.Category, c.Cost, c.AvgRating, c.DurationHours, c.Syllabus, InstructorName, f.Title"
    
    if sort_by == "Most Popular":
        query += " ORDER BY Enrollments DESC"
    elif sort_by == "Highest Rated":
        query += " ORDER BY c.AvgRating DESC"
    else:
        query += " ORDER BY c.CreatedAt DESC"
    
    courses = execute_query(query, tuple(params))
    
    if courses:
        for course in courses:
            with st.container():
                st.markdown(f"""
                <div class='course-card'>
                    <h3>{course['Title']}</h3>
                    <p><strong>👨‍🏫 {course['InstructorTitle']} {course['InstructorName']}</strong></p>
                    <p>📁 {course['Category']} | ⏱️ {course['DurationHours']} hours | ⭐ {convert_to_float(course['AvgRating']):.1f} | 👥 {course['Enrollments']} students</p>
                    <p style='color: #666;'>{course['Syllabus'][:200]}...</p>
                    <h2 style='color: #667eea;'>${convert_to_float(course['Cost']):.2f}</h2>
                </div>
                """, unsafe_allow_html=True)
                
                if st.button(f"Enroll Now", key=f"enroll_{course['CourseId']}"):
                    enroll_in_course(course['CourseId'])
    else:
        st.info("No courses found")

def enroll_in_course(course_id):
    """Enroll student in a course"""
    user_id = st.session_state.user['UserId']
    
    stu_query = "SELECT StuId FROM Student WHERE UserId = %s"
    stu_result = execute_query(stu_query, (user_id,))
    
    if not stu_result:
        st.error("Student profile not found")
        return
    
    stu_id = stu_result[0]['StuId']
    
    check_query = "SELECT * FROM CourseEnrollment WHERE StuId = %s AND CourseId = %s"
    existing = execute_query(check_query, (stu_id, course_id))
    
    if existing:
        st.warning("You are already enrolled in this course!")
        return
    
    enroll_code = f"ENR{course_id}{stu_id}"
    
    enroll_query = """
        INSERT INTO CourseEnrollment (StuId, CourseId, EnrollCode, EnrollDate, EnrollTime)
        VALUES (%s, %s, %s, CURDATE(), CURTIME())
    """
    
    success = execute_query(enroll_query, (stu_id, course_id, enroll_code), fetch=False)
    
    if success:
        st.success("✅ Successfully enrolled!")
        st.balloons()
    else:
        st.error("Enrollment failed")

# ==========================================
# MY COURSES
# ==========================================

@login_required(role='student')
def my_courses_page():
    """Student's enrolled courses"""
    st.markdown("<h1 class='main-header'>📚 My Courses</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    
    stu_query = "SELECT StuId FROM Student WHERE UserId = %s"
    stu_result = execute_query(stu_query, (user_id,))
    
    if not stu_result:
        st.error("Student profile not found")
        return
    
    stu_id = stu_result[0]['StuId']
    
    tab1, tab2 = st.tabs(["📖 Active Courses", "✅ Completed Courses"])
    
    with tab1:
        active_query = """
            SELECT c.CourseId, c.Title, c.Category, c.DurationHours,
                   CONCAT(u.FirstName, ' ', u.LastName) as InstructorName,
                   ce.EnrollDate, an.CompletionRate, an.AvgGrade
            FROM CourseEnrollment ce
            JOIN Course c ON ce.CourseId = c.CourseId
            JOIN Faculty f ON c.InstructorId = f.FacultyId
            JOIN Users u ON f.UserId = u.UserId
            LEFT JOIN Analytics an ON ce.StuId = an.StudentID AND ce.CourseId = an.CourseID
            WHERE ce.StuId = %s AND ce.Certification = 0
            ORDER BY ce.EnrollDate DESC
        """
        active_courses = execute_query(active_query, (stu_id,))
        
        if active_courses:
            for course in active_courses:
                completion = convert_to_float(course['CompletionRate'])
                grade = convert_to_float(course['AvgGrade'])
                
                with st.expander(f"📖 {course['Title']}", expanded=False):
                    col1, col2 = st.columns([2, 1])
                    
                    with col1:
                        st.write(f"**Category:** {course['Category']}")
                        st.write(f"**Instructor:** {course['InstructorName']}")
                        st.write(f"**Duration:** {course['DurationHours']} hours")
                        st.write(f"**Enrolled:** {course['EnrollDate']}")
                        
                        st.progress(safe_progress(completion))
                        st.write(f"**Progress:** {completion:.1f}%")
                        
                        if grade > 0:
                            st.write(f"**Current Grade:** {grade:.1f}%")
                    
                    with col2:
                        st.button("Continue Learning", key=f"continue_{course['CourseId']}")
        else:
            st.info("📌 No active courses")
    
    with tab2:
        completed_query = """
            SELECT c.CourseId, c.Title, c.Category,
                   CONCAT(u.FirstName, ' ', u.LastName) as InstructorName,
                   ce.CompleteDate, ce.Rating, cert.VerificationCode
            FROM CourseEnrollment ce
            JOIN Course c ON ce.CourseId = c.CourseId
            JOIN Faculty f ON c.InstructorId = f.FacultyId
            JOIN Users u ON f.UserId = u.UserId
            LEFT JOIN Certificate cert ON ce.StuId = cert.StuId AND ce.CourseId = cert.CourseId
            WHERE ce.StuId = %s AND ce.Certification = 1
            ORDER BY ce.CompleteDate DESC
        """
        completed_courses = execute_query(completed_query, (stu_id,))
        
        if completed_courses:
            for course in completed_courses:
                with st.expander(f"✅ {course['Title']}", expanded=False):
                    st.write(f"**Category:** {course['Category']}")
                    st.write(f"**Instructor:** {course['InstructorName']}")
                    st.write(f"**Completed:** {course['CompleteDate']}")
                    
                    if course['VerificationCode']:
                        st.success(f"🏆 Certificate: {course['VerificationCode']}")
                    
                    if course['Rating']:
                        st.write(f"**Your Rating:** {'⭐' * course['Rating']}")
        else:
            st.info("📌 No completed courses yet")

# ==========================================
# STUDENT PROGRESS
# ==========================================

@login_required(role='student')
def student_progress_page():
    """Detailed student progress"""
    st.markdown("<h1 class='main-header'>📊 My Progress</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    stu_query = "SELECT StuId FROM Student WHERE UserId = %s"
    stu_result = execute_query(stu_query, (user_id,))
    
    if not stu_result:
        st.error("Student profile not found")
        return
    
    stu_id = stu_result[0]['StuId']
    
    query = """
        SELECT c.Title, an.CompletionRate, an.AvgGrade, an.TimeSpentHours, an.QuizParticipation
        FROM Analytics an
        JOIN Course c ON an.CourseID = c.CourseId
        WHERE an.StudentID = %s
        ORDER BY an.LastUpdated DESC
    """
    data = execute_query(query, (stu_id,))
    
    if data:
        for row in data:
            row['CompletionRate'] = convert_to_float(row['CompletionRate'])
            row['AvgGrade'] = convert_to_float(row['AvgGrade'])
            row['TimeSpentHours'] = convert_to_float(row['TimeSpentHours'])
        
        df = pd.DataFrame(data)
        
        st.subheader("📈 Course Performance")
        st.dataframe(df, use_container_width=True)
        
        fig = px.bar(df, x='Title', y=['CompletionRate', 'AvgGrade'],
                    title='Completion vs Grade', barmode='group')
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("📌 No progress data available")

# ==========================================
# CERTIFICATES
# ==========================================

@login_required(role='student')
def certificates_page():
    """Student certificates"""
    st.markdown("<h1 class='main-header'>🏆 My Certificates</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    stu_query = "SELECT StuId FROM Student WHERE UserId = %s"
    stu_result = execute_query(stu_query, (user_id,))
    
    if not stu_result:
        st.error("Student profile not found")
        return
    
    stu_id = stu_result[0]['StuId']
    
    query = """
        SELECT c.Title, cert.IssueDate, cert.VerificationCode, c.Category
        FROM Certificate cert
        JOIN Course c ON cert.CourseId = c.CourseId
        WHERE cert.StuId = %s
        ORDER BY cert.IssueDate DESC
    """
    certs = execute_query(query, (stu_id,))
    
    if certs:
        for cert in certs:
            st.markdown(f"""
            <div class='course-card'>
                <h3>🏆 {cert['Title']}</h3>
                <p><strong>Issued:</strong> {cert['IssueDate']}</p>
                <p><strong>Verification Code:</strong> <code>{cert['VerificationCode']}</code></p>
                <p><strong>Category:</strong> {cert['Category']}</p>
            </div>
            """, unsafe_allow_html=True)
    else:
        st.info("📌 No certificates earned yet")

# ==========================================
# INSTRUCTOR COURSES
# ==========================================

@login_required(role='instructor')
def instructor_courses_page():
    """Instructor's courses"""
    st.markdown("<h1 class='main-header'>📚 My Courses</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    fac_query = "SELECT FacultyId FROM Faculty WHERE UserId = %s"
    fac_result = execute_query(fac_query, (user_id,))
    
    if not fac_result:
        st.error("Instructor profile not found")
        return
    
    fac_id = fac_result[0]['FacultyId']
    
    query = """
        SELECT c.CourseId, c.Title, c.Category, c.Status, c.AvgRating,
               COUNT(DISTINCT ce.StuId) as Enrollments
        FROM Course c
        LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
        WHERE c.InstructorId = %s
        GROUP BY c.CourseId, c.Title, c.Category, c.Status, c.AvgRating
        ORDER BY Enrollments DESC
    """
    courses = execute_query(query, (fac_id,))
    
    if courses:
        for course in courses:
            status_emoji = {'active': '🟢', 'pending': '🟡', 'archived': '⚪'}
            rating = convert_to_float(course['AvgRating'])
            
            st.markdown(f"""
            <div class='course-card'>
                <h3>{status_emoji.get(course['Status'], '⚫')} {course['Title']}</h3>
                <p>📁 {course['Category']} | ⭐ {rating:.1f} | 👥 {course['Enrollments']} Students</p>
                <p><strong>Status:</strong> {course['Status'].title()}</p>
            </div>
            """, unsafe_allow_html=True)
    else:
        st.info("📌 No courses yet")

# ==========================================
# MANAGE STUDENTS
# ==========================================

@login_required(role='instructor')
def manage_students_page():
    """Manage enrolled students"""
    st.markdown("<h1 class='main-header'>👥 My Students</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    fac_query = "SELECT FacultyId FROM Faculty WHERE UserId = %s"
    fac_result = execute_query(fac_query, (user_id,))
    
    if not fac_result:
        st.error("Instructor profile not found")
        return
    
    fac_id = fac_result[0]['FacultyId']
    
    query = """
        SELECT DISTINCT u.FirstName, u.LastName, u.Email, c.Title as CourseName,
               ce.EnrollDate, an.CompletionRate, an.AvgGrade
        FROM CourseEnrollment ce
        JOIN Student s ON ce.StuId = s.StuId
        JOIN Users u ON s.UserId = u.UserId
        JOIN Course c ON ce.CourseId = c.CourseId
        LEFT JOIN Analytics an ON s.StuId = an.StudentID AND c.CourseId = an.CourseID
        WHERE c.InstructorId = %s
        ORDER BY ce.EnrollDate DESC
    """
    students = execute_query(query, (fac_id,))
    
    if students:
        for row in students:
            if row['CompletionRate']:
                row['CompletionRate'] = convert_to_float(row['CompletionRate'])
            if row['AvgGrade']:
                row['AvgGrade'] = convert_to_float(row['AvgGrade'])
        
        df = pd.DataFrame(students)
        st.dataframe(df, use_container_width=True)
    else:
        st.info("📌 No students enrolled yet")

# ==========================================
# INSTRUCTOR ANALYTICS
# ==========================================

@login_required(role='instructor')
def instructor_analytics_page():
    """Instructor analytics"""
    st.markdown("<h1 class='main-header'>📊 Analytics</h1>", unsafe_allow_html=True)
    
    user_id = st.session_state.user['UserId']
    fac_query = "SELECT FacultyId FROM Faculty WHERE UserId = %s"
    fac_result = execute_query(fac_query, (user_id,))
    
    if not fac_result:
        st.error("Instructor profile not found")
        return
    
    fac_id = fac_result[0]['FacultyId']
    
    query = """
        SELECT c.Title, COUNT(DISTINCT ce.StuId) as Students, 
               AVG(an.AvgGrade) as AvgGrade, AVG(an.CompletionRate) as AvgCompletion
        FROM Course c
        LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
        LEFT JOIN Analytics an ON c.CourseId = an.CourseID
        WHERE c.InstructorId = %s
        GROUP BY c.CourseId, c.Title
    """
    data = execute_query(query, (fac_id,))
    
    if data:
        for row in data:
            row['AvgGrade'] = convert_to_float(row['AvgGrade'])
            row['AvgCompletion'] = convert_to_float(row['AvgCompletion'])
        
        df = pd.DataFrame(data)
        
        fig = px.bar(df, x='Title', y=['AvgGrade', 'AvgCompletion'],
                    title='Course Performance', barmode='group')
        st.plotly_chart(fig, use_container_width=True)
        
        st.subheader("📈 Detailed Statistics")
        st.dataframe(df, use_container_width=True)
    else:
        st.info("📌 No analytics data available")

# ==========================================
# ADMIN PAGES
# ==========================================

@login_required(role='admin')
def manage_users_page():
    """Manage users"""
    st.markdown("<h1 class='main-header'>👥 Manage Users</h1>", unsafe_allow_html=True)
    
    # Add tabs for different user types
    tab1, tab2, tab3, tab4 = st.tabs(["All Users", "Students", "Instructors", "Recent Registrations"])
    
    with tab1:
        st.subheader("All Users")
        query = """
            SELECT u.UserId, u.Email, u.FirstName, u.LastName, u.Role, u.Status, u.CreatedAt,
                   CASE 
                       WHEN u.Role = 'student' THEN s.StuId
                       WHEN u.Role = 'instructor' THEN f.FacultyId
                       WHEN u.Role = 'admin' THEN a.AdminId
                   END as RoleSpecificId
            FROM Users u
            LEFT JOIN Student s ON u.UserId = s.UserId
            LEFT JOIN Faculty f ON u.UserId = f.UserId
            LEFT JOIN Administrator a ON u.UserId = a.UserId
            ORDER BY u.CreatedAt DESC
        """
        users = execute_query(query)
        
        if users:
            df = pd.DataFrame(users)
            st.dataframe(df, use_container_width=True)
            st.caption(f"Total Users: {len(users)}")
        else:
            st.info("No users found")
    
    with tab2:
        st.subheader("Students")
        query = """
            SELECT s.StuId, u.UserId, u.Email, u.FirstName, u.LastName, u.Status, u.CreatedAt,
                   COUNT(DISTINCT ce.CourseId) as EnrolledCourses
            FROM Student s
            JOIN Users u ON s.UserId = u.UserId
            LEFT JOIN CourseEnrollment ce ON s.StuId = ce.StuId
            GROUP BY s.StuId, u.UserId, u.Email, u.FirstName, u.LastName, u.Status, u.CreatedAt
            ORDER BY u.CreatedAt DESC
        """
        students = execute_query(query)
        
        if students:
            df = pd.DataFrame(students)
            st.dataframe(df, use_container_width=True)
            st.caption(f"Total Students: {len(students)}")
        else:
            st.info("No students found")
    
    with tab3:
        st.subheader("Instructors")
        query = """
            SELECT f.FacultyId, u.UserId, u.Email, u.FirstName, u.LastName, f.Title, 
                   f.Affiliation, u.Status, u.CreatedAt,
                   COUNT(DISTINCT c.CourseId) as TotalCourses
            FROM Faculty f
            JOIN Users u ON f.UserId = u.UserId
            LEFT JOIN Course c ON f.FacultyId = c.InstructorId
            GROUP BY f.FacultyId, u.UserId, u.Email, u.FirstName, u.LastName, 
                     f.Title, f.Affiliation, u.Status, u.CreatedAt
            ORDER BY u.CreatedAt DESC
        """
        instructors = execute_query(query)
        
        if instructors:
            df = pd.DataFrame(instructors)
            st.dataframe(df, use_container_width=True)
            st.caption(f"Total Instructors: {len(instructors)}")
        else:
            st.info("No instructors found")
    
    with tab4:
        st.subheader("Recent Registrations (Last 30 Days)")
        query = """
            SELECT u.UserId, u.Email, u.FirstName, u.LastName, u.Role, u.CreatedAt,
                   CASE 
                       WHEN u.Role = 'student' THEN CONCAT('Student ID: ', s.StuId)
                       WHEN u.Role = 'instructor' THEN CONCAT('Faculty ID: ', f.FacultyId)
                       WHEN u.Role = 'admin' THEN CONCAT('Admin ID: ', a.AdminId)
                   END as RoleInfo
            FROM Users u
            LEFT JOIN Student s ON u.UserId = s.UserId
            LEFT JOIN Faculty f ON u.UserId = f.UserId
            LEFT JOIN Administrator a ON u.UserId = a.UserId
            WHERE u.CreatedAt >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            ORDER BY u.CreatedAt DESC
        """
        recent = execute_query(query)
        
        if recent:
            for user in recent:
                st.markdown(f"""
                <div class='info-box'>
                    <h4>✅ {user['FirstName']} {user['LastName']}</h4>
                    <p><strong>Email:</strong> {user['Email']}</p>
                    <p><strong>Role:</strong> {user['Role'].title()}</p>
                    <p><strong>{user['RoleInfo']}</strong></p>
                    <p><strong>Registered:</strong> {user['CreatedAt']}</p>
                </div>
                """, unsafe_allow_html=True)
            st.caption(f"Total New Registrations: {len(recent)}")
        else:
            st.info("No registrations in the last 30 days")

@login_required(role='admin')
def manage_courses_page():
    """Manage courses"""
    st.markdown("<h1 class='main-header'>📚 Manage Courses</h1>", unsafe_allow_html=True)
    
    query = """
        SELECT c.CourseId, c.Title, c.Category, c.Status, c.Cost, c.AvgRating,
               CONCAT(u.FirstName, ' ', u.LastName) as Instructor,
               COUNT(DISTINCT ce.StuId) as Enrollments
        FROM Course c
        JOIN Faculty f ON c.InstructorId = f.FacultyId
        JOIN Users u ON f.UserId = u.UserId
        LEFT JOIN CourseEnrollment ce ON c.CourseId = ce.CourseId
        GROUP BY c.CourseId, c.Title, c.Category, c.Status, c.Cost, c.AvgRating, Instructor
        ORDER BY c.CreatedAt DESC
    """
    courses = execute_query(query)
    
    if courses:
        for row in courses:
            row['Cost'] = convert_to_float(row['Cost'])
            row['AvgRating'] = convert_to_float(row['AvgRating'])
        
        df = pd.DataFrame(courses)
        st.dataframe(df, use_container_width=True)
    else:
        st.info("No courses found")

@login_required(role='admin')
def system_analytics_page():
    """System analytics"""
    st.markdown("<h1 class='main-header'>📊 System Analytics</h1>", unsafe_allow_html=True)
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📈 User Growth")
        query = """
            SELECT DATE_FORMAT(CreatedAt, '%Y-%m') as Month, COUNT(*) as Users
            FROM Users
            WHERE CreatedAt >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY Month
            ORDER BY Month
        """
        data = execute_query(query)
        
        if data:
            df = pd.DataFrame(data)
            fig = px.line(df, x='Month', y='Users', markers=True)
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("💰 Revenue Trends")
        query = """
            SELECT DATE_FORMAT(ce.EnrollDate, '%Y-%m') as Month, SUM(c.Cost) as Revenue
            FROM CourseEnrollment ce
            JOIN Course c ON ce.CourseId = c.CourseId
            WHERE ce.EnrollDate >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY Month
            ORDER BY Month
        """
        data = execute_query(query)
        
        if data:
            for row in data:
                row['Revenue'] = convert_to_float(row['Revenue'])
            
            df = pd.DataFrame(data)
            fig = px.area(df, x='Month', y='Revenue')
            st.plotly_chart(fig, use_container_width=True)

# ==========================================
# MAIN APP
# ==========================================

def main():
    """Main application"""
    show_navigation()
    
    page = st.session_state.page
    
    if page == 'login' or not st.session_state.user:
        login_page()
    elif page == 'dashboard':
        st.markdown("<h1 class='main-header'>Welcome back, {}! 👋</h1>".format(
            st.session_state.user['FirstName']), unsafe_allow_html=True)
        st.markdown("---")
        
        if st.session_state.user['Role'] == 'student':
            student_dashboard()
        elif st.session_state.user['Role'] == 'instructor':
            instructor_dashboard()
        elif st.session_state.user['Role'] == 'admin':
            admin_dashboard()
    elif page == 'browse_courses':
        browse_courses_page()
    elif page == 'my_courses':
        my_courses_page()
    elif page == 'student_progress':
        student_progress_page()
    elif page == 'certificates':
        certificates_page()
    elif page == 'instructor_courses':
        instructor_courses_page()
    elif page == 'manage_students':
        manage_students_page()
    elif page == 'instructor_analytics':
        instructor_analytics_page()
    elif page == 'manage_users':
        manage_users_page()
    elif page == 'manage_courses':
        manage_courses_page()
    elif page == 'system_analytics':
        system_analytics_page()
    else:
        st.info(f"Page '{page}' is under development")

if __name__ == "__main__":
    main()