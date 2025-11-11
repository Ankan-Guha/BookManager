<%@ page import="java.sql.*, java.security.*, java.util.*" %>
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

try {
    // Hash the password (must use same hashing as registration)
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] hashedPassword = md.digest(password.getBytes());
    StringBuilder sb = new StringBuilder();
    for(byte b : hashedPassword) {
        sb.append(String.format("%02x", b));
    }
    String hashedPasswordStr = sb.toString();

    // Check user credentials
    PreparedStatement pst = con.prepareStatement("SELECT id, name, email FROM users WHERE email = ? AND password = ?");
    pst.setString(1, email);
    pst.setString(2, hashedPasswordStr);
    
    ResultSet rs = pst.executeQuery();
    
    if(rs.next()) {
        // Login successful
        int userId = rs.getInt("id");
        String userName = rs.getString("name");
        
        // Create session
        session.setAttribute("user_id", userId);
        session.setAttribute("user_name", userName);
        session.setAttribute("user_email", email);
        session.setMaxInactiveInterval(30 * 60); // 30 minutes session timeout
        
        // Set cookie if "Remember me" was checked
        if(remember != null && remember.equals("on")) {
            Cookie emailCookie = new Cookie("rememberedEmail", email);
            emailCookie.setMaxAge(30 * 24 * 60 * 60); // 30 days
            emailCookie.setPath("/");
            response.addCookie(emailCookie);
        } else {
            // Clear the cookie if not checked
            Cookie emailCookie = new Cookie("rememberedEmail", "");
            emailCookie.setMaxAge(0);
            emailCookie.setPath("/");
            response.addCookie(emailCookie);
        }
        
        // Redirect to home page or original requested page
        String redirectURL = (String) session.getAttribute("redirect_after_login");
        if(redirectURL != null) {
            session.removeAttribute("redirect_after_login");
            response.sendRedirect(redirectURL);
        } else {
            response.sendRedirect("index.jsp");
        }
    } else {
        // Login failed
        response.sendRedirect("LOGIN.html?error=Invalid email or password");
    }
    
} catch(Exception e) {
    // Log error
    System.err.println("Login error: " + e.getMessage());
    response.sendRedirect("LOGIN.html?error=An error occurred. Please try again later.");
} finally {
    if(con != null) {
        try { con.close(); } catch(SQLException e) {}
    }
}
%>