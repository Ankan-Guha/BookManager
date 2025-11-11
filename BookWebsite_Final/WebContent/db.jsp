<%@ page import="java.sql.*" %>
<%
    Connection con = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        con = DriverManager.getConnection("jdbc:mysql://localhost:3306/online_bookstore", "root", "password");
    } catch(Exception e) {
        out.println("Database connection error: " + e.getMessage());
    }
%>