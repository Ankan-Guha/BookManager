<%@ page import="java.sql.*, java.security.*, java.util.*" %>
<%@ include file="db_connection.jsp" %>

<%
// Get form parameters
String name = request.getParameter("name");
String email = request.getParameter("email");
String phone = request.getParameter("phone");
String address = request.getParameter("address");
String password = request.getParameter("password");

// Basic validation
if(name == null || email == null || password == null || 
   name.trim().isEmpty() || email.trim().isEmpty() || password.trim().isEmpty()) {
    response.sendRedirect("REGISTER.html?error=Please fill all required fields");
    return;
}

// Validate email format
if(!email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
    response.sendRedirect("REGISTER.html?error=Invalid email format");
    return;
}

// Validate password strength
if(password.length() < 8) {
    response.sendRedirect("REGISTER.html?error=Password must be at least 8 characters");
    return;
}

try {
    // Check if email already exists
    PreparedStatement checkStmt = con.prepareStatement("SELECT id FROM users WHERE email = ?");
    checkStmt.setString(1, email);
    ResultSet rs = checkStmt.executeQuery();
    
    if(rs.next()) {
        response.sendRedirect("REGISTER.html?error=Email already registered");
        return;
    }
    
    // Hash password (using SHA-256 for demonstration)
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] hashedPassword = md.digest(password.getBytes());
    StringBuilder sb = new StringBuilder();
    for(byte b : hashedPassword) {
        sb.append(String.format("%02x", b));
    }
    String hashedPasswordStr = sb.toString();
    
    // Insert new user with prepared statement
    String sql = "INSERT INTO users (name, email, phone, address, password, created_at) " +
                 "VALUES (?, ?, ?, ?, ?, NOW())";
    
    PreparedStatement pst = con.prepareStatement(sql);
    pst.setString(1, name);
    pst.setString(2, email);
    pst.setString(3, phone);
    pst.setString(4, address);
    pst.setString(5, hashedPasswordStr);
    
    int result = pst.executeUpdate();
    
    if(result > 0) {
        // Registration successful
        response.sendRedirect("LOGIN.html?success=Registration successful. Please login.");
    } else {
        response.sendRedirect("REGISTER.html?error=Registration failed. Please try again.");
    }
    
} catch(Exception e) {
    // Log error
    System.err.println("Registration error: " + e.getMessage());
    response.sendRedirect("REGISTER.html?error=An error occurred. Please try again later.");
} finally {
    if(con != null) {
        try { con.close(); } catch(SQLException e) {}
    }
}
%>