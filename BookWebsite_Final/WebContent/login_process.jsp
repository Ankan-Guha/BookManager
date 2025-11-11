<%@ page import="java.sql.*, java.security.*, java.util.*, java.time.*" %>
<%@ include file="db_connection.jsp" %>

<%
// Get form parameters
String email = request.getParameter("email");
String password = request.getParameter("password");
String remember = request.getParameter("remember");

// Basic validation
if(email == null || password == null || email.trim().isEmpty() || password.trim().isEmpty()) {
    response.sendRedirect("LOGIN.html?error=Please fill all required fields");
    return;
}

Connection con = null;
PreparedStatement pst = null;
ResultSet rs = null;

try {
    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/online_bookstore", "username", "password");
    
    // Check if account is locked
    pst = con.prepareStatement("SELECT lock_time FROM users WHERE email = ? AND account_locked = TRUE");
    pst.setString(1, email);
    rs = pst.executeQuery();
    
    if(rs.next()) {
        Timestamp lockTime = rs.getTimestamp("lock_time");
        LocalDateTime unlockTime = lockTime.toLocalDateTime().plusHours(1);
        
        if(LocalDateTime.now().isBefore(unlockTime)) {
            Duration remaining = Duration.between(LocalDateTime.now(), unlockTime);
            long minutes = remaining.toMinutes();
            response.sendRedirect("LOGIN.html?error=Account locked. Try again in " + minutes + " minutes.");
            return;
        } else {
            // Unlock the account
            pst = con.prepareStatement("UPDATE users SET account_locked = FALSE, login_attempts = 0 WHERE email = ?");
            pst.setString(1, email);
            pst.executeUpdate();
        }
    }
    
    // Get user with password hash
    pst = con.prepareStatement(
        "SELECT u.user_id, u.username, u.password_hash, u.first_name, u.last_name, " +
        "u.email, u.login_attempts, GROUP_CONCAT(r.role_name) as roles " +
        "FROM users u " +
        "LEFT JOIN user_roles ur ON u.user_id = ur.user_id " +
        "LEFT JOIN roles r ON ur.role_id = r.role_id " +
        "WHERE u.email = ? " +
        "GROUP BY u.user_id");
    pst.setString(1, email);
    rs = pst.executeQuery();
    
    if(rs.next()) {
        String storedHash = rs.getString("password_hash");
        int loginAttempts = rs.getInt("login_attempts");
        
        // Verify password (using BCrypt in this example)
        if(BCrypt.checkpw(password, storedHash)) {
            // Login successful - reset attempts
            pst = con.prepareStatement("UPDATE users SET login_attempts = 0, last_login = NOW() WHERE email = ?");
            pst.setString(1, email);
            pst.executeUpdate();
            
            // Record login history
            pst = con.prepareStatement(
                "INSERT INTO login_history (user_id, login_time, ip_address, user_agent, success) " +
                "VALUES (?, NOW(), ?, ?, TRUE)");
            pst.setInt(1, rs.getInt("user_id"));
            pst.setString(2, request.getRemoteAddr());
            pst.setString(3, request.getHeader("User-Agent"));
            pst.executeUpdate();
            
            // Create session
            session.setAttribute("user_id", rs.getInt("user_id"));
            session.setAttribute("username", rs.getString("username"));
            session.setAttribute("email", rs.getString("email"));
            session.setAttribute("first_name", rs.getString("first_name"));
            session.setAttribute("last_name", rs.getString("last_name"));
            session.setAttribute("roles", rs.getString("roles"));
            session.setMaxInactiveInterval(30 * 60); // 30 minutes
            
            // Set cookie if "Remember me" was checked
            if(remember != null && remember.equals("on")) {
                Cookie emailCookie = new Cookie("rememberedEmail", email);
                emailCookie.setMaxAge(30 * 24 * 60 * 60); // 30 days
                emailCookie.setPath("/");
                emailCookie.setHttpOnly(true);
                response.addCookie(emailCookie);
            }
            
            // Redirect based on role
            if(rs.getString("roles").contains("admin")) {
                response.sendRedirect("admin_dashboard.jsp");
            } else {
                response.sendRedirect("user_dashboard.jsp");
            }
            
        } else {
            // Password incorrect - increment attempts
            int newAttempts = loginAttempts + 1;
            pst = con.prepareStatement("UPDATE users SET login_attempts = ? WHERE email = ?");
            pst.setInt(1, newAttempts);
            pst.setString(2, email);
            pst.executeUpdate();
            
            // Record failed login
            pst = con.prepareStatement(
                "INSERT INTO login_history (user_id, login_time, ip_address, user_agent, success) " +
                "VALUES (?, NOW(), ?, ?, FALSE)");
            pst.setInt(1, rs.getInt("user_id"));
            pst.setString(2, request.getRemoteAddr());
            pst.setString(3, request.getHeader("User-Agent"));
            pst.executeUpdate();
            
            // Lock account after 5 attempts
            if(newAttempts >= 5) {
                pst = con.prepareStatement("UPDATE users SET account_locked = TRUE, lock_time = NOW() WHERE email = ?");
                pst.setString(1, email);
                pst.executeUpdate();
                response.sendRedirect("LOGIN.html?error=Too many failed attempts. Account locked for 1 hour.");
            } else {
                response.sendRedirect("LOGIN.html?error=Invalid email or password. Attempts remaining: " + (5 - newAttempts));
            }
        }
    } else {
        // User not found
        response.sendRedirect("LOGIN.html?error=Invalid email or password");
    }
    
} catch(Exception e) {
    e.printStackTrace();
    response.sendRedirect("LOGIN.html?error=An error occurred. Please try again later.");
} finally {
    // Close resources
    if(rs != null) try { rs.close(); } catch(SQLException e) {}
    if(pst != null) try { pst.close(); } catch(SQLException e) {}
    if(con != null) try { con.close(); } catch(SQLException e) {}
}
%>